#!/usr/bin/env bash

set -euo pipefail

TESTS_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIRECTORY="$(cd -- "$TESTS_DIRECTORY/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
PASS_COUNT=0

cleanup() {
	rm -rf "$TEST_ROOT"
}

trap cleanup EXIT

fail_test() {
	printf '[FAIL] %s\n' "$1" >&2
	return 1
}

assert_contains() {
	local expected="$1"
	local file_path="$2"
	local description="$3"

	if ! grep -Fq -- "$expected" "$file_path"; then
		printf '[FAIL] %s\nmissing: %s\n' "$description" "$expected" >&2
		return 1
	fi
}

assert_not_contains() {
	local unexpected="$1"
	local file_path="$2"
	local description="$3"

	if grep -Fq -- "$unexpected" "$file_path"; then
		printf '[FAIL] %s\nunexpected: %s\n' "$description" "$unexpected" >&2
		return 1
	fi
}

write_mock_command() {
	local command_path="$1"
	shift

	printf '%s\n' '#!/usr/bin/env bash' "$@" > "$command_path"
	chmod +x "$command_path"
}

prepare_fixture() {
	local fixture_name="$1"
	local tool_name=""

	FIXTURE_ROOT="$TEST_ROOT/$fixture_name"
	SOURCE_ROOT="$FIXTURE_ROOT/source"
	TARGET_ROOT="$FIXTURE_ROOT/target"
	MOCK_BIN="$FIXTURE_ROOT/bin"
	MOCK_HOME="$FIXTURE_ROOT/home"
	DODKIT_LOG="$FIXTURE_ROOT/dodkit.log"
	OUTPUT_LOG="$FIXTURE_ROOT/output.log"

	mkdir -p "$SOURCE_ROOT/templates/.docs" "$TARGET_ROOT" "$MOCK_BIN" "$MOCK_HOME"
	cp "$PROJECT_DIRECTORY/install.sh" "$SOURCE_ROOT/install.sh"
	cp "$PROJECT_DIRECTORY/templates/AGENTS.md" "$SOURCE_ROOT/templates/AGENTS.md"
	cp "$PROJECT_DIRECTORY/templates/dev-tools.sh" "$SOURCE_ROOT/templates/dev-tools.sh"
	cp "$PROJECT_DIRECTORY/templates/.docs/PRINCIPLES.md" "$SOURCE_ROOT/templates/.docs/PRINCIPLES.md"

	: > "$DODKIT_LOG"

	write_mock_command "$FIXTURE_ROOT/dodkit.sh" \
		'printf "DODKIT_RAN\n"' \
		'printf "%s\n" "$@" >> "$DODKIT_LOG"'

	write_mock_command "$MOCK_BIN/curl" \
		'if [[ "$*" != *mkgask/dodkit* ]]; then exit 1; fi' \
		'cat "$FIXTURE_ROOT/dodkit.sh"'

	for tool_name in python3 ruby rg rtk codegraph; do
		write_mock_command "$MOCK_BIN/$tool_name" \
			'if [[ "${1:-}" == "--version" ]]; then exit 0; fi' \
			'exit 0'
	done

	export FIXTURE_ROOT SOURCE_ROOT TARGET_ROOT MOCK_BIN MOCK_HOME DODKIT_LOG OUTPUT_LOG
}

run_installer_noninteractive() {
	local fixture_name="$1"
	shift

	prepare_fixture "$fixture_name"
	(
		cd "$TARGET_ROOT"
		setsid --wait env HOME="$MOCK_HOME" PATH="$MOCK_BIN:/usr/bin:/bin" DODKIT_LOG="$DODKIT_LOG" bash "$SOURCE_ROOT/install.sh" "$@" </dev/null > "$OUTPUT_LOG" 2>&1
	)
}

test_default_helper_deployment_and_dodkit_order() {
	local dodkit_line=0
	local helper_line=0

	run_installer_noninteractive default-deployment copilot --custom-flag value

	[[ -f "$TARGET_ROOT/AGENTS.md" ]] || fail_test 'AGENTS.md was not deployed' || return 1
	[[ -f "$TARGET_ROOT/.docs/PRINCIPLES.md" ]] || fail_test 'PRINCIPLES.md was not deployed' || return 1
	[[ -f "$TARGET_ROOT/.dev/dev-tools.sh" ]] || fail_test 'default helper was not deployed' || return 1
	cmp -s "$SOURCE_ROOT/templates/dev-tools.sh" "$TARGET_ROOT/.dev/dev-tools.sh"

	assert_contains 'copilot' "$DODKIT_LOG" 'forward DODKit target argument' || return 1
	assert_contains '--custom-flag' "$DODKIT_LOG" 'forward DODKit custom argument' || return 1
	assert_contains 'value' "$DODKIT_LOG" 'forward DODKit argument value' || return 1
	assert_contains '[INFO] Running optional development-tools helper' "$OUTPUT_LOG" 'run helper after DODKit' || return 1

	dodkit_line="$(grep -n -m1 '^DODKIT_RAN$' "$OUTPUT_LOG" | cut -d: -f1)"
	helper_line="$(grep -n -m1 'Running optional development-tools helper' "$OUTPUT_LOG" | cut -d: -f1)"
	if ! (( dodkit_line < helper_line )); then
		fail_test 'helper ran before DODKit'
	fi
}

test_existing_assets_protected_and_helper_overwritten() {
	local existing_agents='# user-owned AGENTS.md'
	local existing_helper='# stale helper'

	prepare_fixture protected-assets
	mkdir -p "$TARGET_ROOT/.dev"
	printf '%s\n' "$existing_agents" > "$TARGET_ROOT/AGENTS.md"
	printf '%s\n' "$existing_helper" > "$TARGET_ROOT/.dev/dev-tools.sh"

	(
		cd "$TARGET_ROOT"
		setsid --wait env HOME="$MOCK_HOME" PATH="$MOCK_BIN:/usr/bin:/bin" DODKIT_LOG="$DODKIT_LOG" bash "$SOURCE_ROOT/install.sh" copilot </dev/null > "$OUTPUT_LOG" 2>&1
	)

	assert_contains "$existing_agents" "$TARGET_ROOT/AGENTS.md" 'preserve existing AGENTS.md without force' || return 1
	cmp -s "$SOURCE_ROOT/templates/dev-tools.sh" "$TARGET_ROOT/.dev/dev-tools.sh"
	assert_contains 'using default helper directory: .dev' "$OUTPUT_LOG" 'use default destination without a TTY' || return 1
}

test_existing_dev_directory_destination_prompt() {
	prepare_fixture prompted-destination
	mkdir -p "$TARGET_ROOT/.dev"

	(
		cd "$TARGET_ROOT"
		printf '%s\n' '.custom-tools' | script --quiet --flush --command "env HOME=\"$MOCK_HOME\" PATH=\"$MOCK_BIN:/usr/bin:/bin\" DODKIT_LOG=\"$DODKIT_LOG\" bash \"$SOURCE_ROOT/install.sh\" copilot" "$OUTPUT_LOG" > "$OUTPUT_LOG.stdout" 2>&1
	)

	[[ -f "$TARGET_ROOT/.custom-tools/dev-tools.sh" ]] || fail_test 'selected helper destination was not used' || return 1
	[[ ! -e "$TARGET_ROOT/.dev/dev-tools.sh" ]] || fail_test 'default helper destination was used despite selection' || return 1
}

test_helper_failure_status_is_reported() {
	prepare_fixture helper-failure
	write_mock_command "$SOURCE_ROOT/templates/dev-tools.sh" \
		'printf "helper failure details\\n" >&2' \
		'exit 7'

	(
		cd "$TARGET_ROOT"
		if setsid --wait env HOME="$MOCK_HOME" PATH="$MOCK_BIN:/usr/bin:/bin" DODKIT_LOG="$DODKIT_LOG" bash "$SOURCE_ROOT/install.sh" copilot </dev/null > "$OUTPUT_LOG" 2>&1; then
			fail_test 'installer ignored helper failure'
		fi
	)

	assert_contains 'helper failure details' "$OUTPUT_LOG" 'preserve helper diagnostic output' || return 1
	assert_contains 'Development-tools helper failed (exit status 7)' "$OUTPUT_LOG" 'report helper exit status' || return 1
}

test_dodkit_failure_status_is_reported() {
	prepare_fixture dodkit-failure
	write_mock_command "$FIXTURE_ROOT/dodkit.sh" \
		'printf "DODKit failure details\\n" >&2' \
		'exit 9'

	(
		cd "$TARGET_ROOT"
		if setsid --wait env HOME="$MOCK_HOME" PATH="$MOCK_BIN:/usr/bin:/bin" DODKIT_LOG="$DODKIT_LOG" bash "$SOURCE_ROOT/install.sh" copilot </dev/null > "$OUTPUT_LOG" 2>&1; then
			fail_test 'installer ignored DODKit failure'
		fi
	)

	assert_contains 'DODKit failure details' "$OUTPUT_LOG" 'preserve DODKit diagnostic output' || return 1
	assert_contains 'DODKit installer failed (exit status 9)' "$OUTPUT_LOG" 'report DODKit exit status' || return 1
}

run_test() {
	local test_name="$1"
	shift

	if "$@"; then
		PASS_COUNT=$((PASS_COUNT + 1))
		printf '[PASS] %s\n' "$test_name"
		return 0
	fi

	return 1
}

run_test 'default helper deployment and DODKit order' test_default_helper_deployment_and_dodkit_order
run_test 'protected assets and helper overwrite' test_existing_assets_protected_and_helper_overwritten
run_test 'existing .dev destination prompt' test_existing_dev_directory_destination_prompt
run_test 'helper failure status is reported' test_helper_failure_status_is_reported
run_test 'DODKit failure status is reported' test_dodkit_failure_status_is_reported

printf '%s\n' "Passed $PASS_COUNT focused installer tests."