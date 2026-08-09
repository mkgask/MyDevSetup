#!/usr/bin/env bash

set -euo pipefail

TESTS_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIRECTORY="$(cd -- "$TESTS_DIRECTORY/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
PASS_COUNT=0

# shellcheck source=/dev/null
source "$PROJECT_DIRECTORY/install.sh"

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

assert_rw_permissions_unchanged() {
	local expected_permissions="$1"
	local file_path="$2"
	local description="$3"
	local actual_permissions=""

	actual_permissions="$(stat -c '%A' "$file_path")"
	if [[ "${actual_permissions:1:2}" != "${expected_permissions:1:2}" || "${actual_permissions:4:2}" != "${expected_permissions:4:2}" || "${actual_permissions:7:2}" != "${expected_permissions:7:2}" ]]; then
		fail_test "$description (expected rw bits from $expected_permissions, got $actual_permissions)"
		return 1
	fi
}

test_parse_args_accepts_overwrite_policy_and_preserves_passthrough() {
	parse_args copilot --overwrite yes --custom-flag value

	[[ "$OVERWRITE_POLICY" == "yes" ]] || fail_test 'parse_args did not set overwrite=yes' || return 1
	[[ "${PASSTHROUGH_ARGS[*]}" == "copilot --overwrite yes --custom-flag value" ]] || fail_test 'parse_args changed passthrough arguments' || return 1
}

test_parse_args_defaults_to_ask() {
	parse_args copilot

	[[ "$OVERWRITE_POLICY" == "ask" ]] || fail_test 'parse_args did not default overwrite policy to ask' || return 1
}

test_parse_args_tracks_target_without_changing_passthrough() {
	parse_args cursor --overwrite yes

	[[ "$TARGET_CLI" == "cursor" ]] || fail_test 'parse_args did not track the Cursor target' || return 1
	[[ "${PASSTHROUGH_ARGS[*]}" == "cursor --overwrite yes" ]] || fail_test 'target tracking changed passthrough arguments' || return 1

	parse_args --overwrite no
	[[ "$TARGET_CLI" == "copilot" ]] || fail_test 'parse_args did not reset the default target' || return 1
}

test_parse_args_rejects_invalid_overwrite_values() {
	if (parse_args --overwrite maybe 2>/dev/null); then
		fail_test 'parse_args accepted an invalid overwrite value'
		return 1
	fi
}

test_parse_args_forwards_legacy_force_without_special_handling() {
	local output=""

	if ! output="$(
		parse_args copilot --force
		printf 'policy=%s\n' "$OVERWRITE_POLICY"
		printf 'args=%s\n' "${PASSTHROUGH_ARGS[*]}"
	)"; then
		fail_test 'parse_args should not reject the legacy force option locally'
		return 1
	fi

	[[ "$output" == *"policy=ask"* ]] || fail_test 'legacy force passthrough should preserve the default overwrite policy' || return 1
	[[ "$output" == *"args=copilot --force"* ]] || fail_test 'parse_args should preserve the legacy force argument for DODKit' || return 1
}

test_parse_args_rejects_missing_overwrite_value() {
	if (parse_args --overwrite 2>/dev/null); then
		fail_test 'parse_args accepted a missing overwrite value'
		return 1
	fi
}

test_should_overwrite_honors_explicit_policies() {
	OVERWRITE_POLICY=yes
	should_overwrite 'yes-file' || fail_test 'overwrite=yes should accept a changed file' || return 1

	OVERWRITE_POLICY=no
	if should_overwrite 'no-file'; then
		fail_test 'overwrite=no should preserve a changed file'
		return 1
	fi
}

run_overwrite_sequence_in_pty() {
	if ! command -v script >/dev/null 2>&1; then
		printf '[INFO] skipping interactive overwrite test because script is unavailable\n'
		return 0
	fi

	printf 'a\n' | OVERWRITE_INSTALLER_PATH="$PROJECT_DIRECTORY/install.sh" script -qec "bash -c 'source \"\$OVERWRITE_INSTALLER_PATH\"; OVERWRITE_POLICY=ask; if should_overwrite first; then echo first-accepted; else echo first-rejected; fi; if should_overwrite second; then echo second-accepted; else echo second-rejected; fi; echo policy=\$OVERWRITE_POLICY'" /dev/null 2>&1
}

test_interactive_overwrite_all_switches_remaining_files_to_yes() {
	local output=""
	local prompt_count=""

	output="$(run_overwrite_sequence_in_pty)"
	assert_contains 'Overwrite this file? [Y/n/a] (a = all remaining files):' <(printf '%s\n' "$output") 'interactive overwrite prompt should expose the all option' || return 1
	assert_contains 'first-accepted' <(printf '%s\n' "$output") 'all response should accept the current file' || return 1
	assert_contains 'second-accepted' <(printf '%s\n' "$output") 'all response should accept subsequent files' || return 1
	assert_contains 'policy=yes' <(printf '%s\n' "$output") 'all response should switch the session policy to yes' || return 1

	prompt_count="$(printf '%s' "$output" | grep -o 'Overwrite this file?' | wc -l | tr -d ' ')"
	[[ "$prompt_count" == "1" ]] || fail_test "all response should prompt only once (actual=$prompt_count)" || return 1
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
	HELPER_ARGS_LOG="$FIXTURE_ROOT/helper-args.log"

	mkdir -p "$SOURCE_ROOT/templates/.docs" "$TARGET_ROOT" "$MOCK_BIN" "$MOCK_HOME"
	cp "$PROJECT_DIRECTORY/install.sh" "$SOURCE_ROOT/install.sh"
	cp "$PROJECT_DIRECTORY/templates/AGENTS.md" "$SOURCE_ROOT/templates/AGENTS.md"
	cp "$PROJECT_DIRECTORY/templates/dev-tools.sh" "$SOURCE_ROOT/templates/dev-tools.sh"
	cp "$PROJECT_DIRECTORY/templates/first-setup.sh" "$SOURCE_ROOT/templates/first-setup.sh"
	cp "$PROJECT_DIRECTORY/templates/.docs/PRINCIPLES.md" "$SOURCE_ROOT/templates/.docs/PRINCIPLES.md"

	: > "$DODKIT_LOG"
	: > "$HELPER_ARGS_LOG"
	FIRST_SETUP_EXECUTION_MARKER="$FIXTURE_ROOT/first-setup-executed"
	write_mock_command "$SOURCE_ROOT/templates/first-setup.sh" \
		'printf "first-setup-ran\n" > "$FIRST_SETUP_EXECUTION_MARKER"' \
		'exit 77'

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

	export FIXTURE_ROOT SOURCE_ROOT TARGET_ROOT MOCK_BIN MOCK_HOME DODKIT_LOG OUTPUT_LOG HELPER_ARGS_LOG FIRST_SETUP_EXECUTION_MARKER
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
	[[ -f "$TARGET_ROOT/.dev/first-setup.sh" ]] || fail_test 'first-setup helper was not deployed' || return 1
	[[ -x "$TARGET_ROOT/.dev/dev-tools.sh" ]] || fail_test 'deployed dev-tools helper should be executable' || return 1
	[[ -x "$TARGET_ROOT/.dev/first-setup.sh" ]] || fail_test 'deployed first-setup helper should be executable' || return 1
	[[ ! -x "$TARGET_ROOT/AGENTS.md" ]] || fail_test 'AGENTS.md should remain non-executable' || return 1
	[[ ! -x "$TARGET_ROOT/.docs/PRINCIPLES.md" ]] || fail_test 'PRINCIPLES.md should remain non-executable' || return 1
	cmp -s "$SOURCE_ROOT/templates/dev-tools.sh" "$TARGET_ROOT/.dev/dev-tools.sh"
	cmp -s "$SOURCE_ROOT/templates/first-setup.sh" "$TARGET_ROOT/.dev/first-setup.sh" || fail_test 'first-setup helper content was not copied' || return 1
	[[ ! -e "$FIRST_SETUP_EXECUTION_MARKER" ]] || fail_test 'first-setup helper should not run automatically' || return 1

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


test_current_helpers_are_made_executable_on_reinstall() {
	local dev_tools_permissions=""
	local first_setup_permissions=""
	local agents_permissions=""
	local principles_permissions=""

	prepare_fixture current-helper-permissions

	(
		cd "$TARGET_ROOT"
		setsid --wait env HOME="$MOCK_HOME" PATH="$MOCK_BIN:/usr/bin:/bin" DODKIT_LOG="$DODKIT_LOG" bash "$SOURCE_ROOT/install.sh" copilot </dev/null > "$OUTPUT_LOG" 2>&1
	)

	chmod 0640 "$TARGET_ROOT/.dev/dev-tools.sh"
	chmod 0604 "$TARGET_ROOT/.dev/first-setup.sh"
	chmod 0640 "$TARGET_ROOT/AGENTS.md"
	chmod 0604 "$TARGET_ROOT/.docs/PRINCIPLES.md"
	dev_tools_permissions="$(stat -c '%A' "$TARGET_ROOT/.dev/dev-tools.sh")"
	first_setup_permissions="$(stat -c '%A' "$TARGET_ROOT/.dev/first-setup.sh")"
	agents_permissions="$(stat -c '%A' "$TARGET_ROOT/AGENTS.md")"
	principles_permissions="$(stat -c '%A' "$TARGET_ROOT/.docs/PRINCIPLES.md")"

	(
		cd "$TARGET_ROOT"
		setsid --wait env HOME="$MOCK_HOME" PATH="$MOCK_BIN:/usr/bin:/bin" DODKIT_LOG="$DODKIT_LOG" bash "$SOURCE_ROOT/install.sh" copilot </dev/null > "$OUTPUT_LOG" 2>&1
	)

	[[ -x "$TARGET_ROOT/.dev/dev-tools.sh" ]] || fail_test 'reinstall should restore dev-tools executable permission' || return 1
	[[ -x "$TARGET_ROOT/.dev/first-setup.sh" ]] || fail_test 'reinstall should restore first-setup executable permission' || return 1
	assert_rw_permissions_unchanged "$dev_tools_permissions" "$TARGET_ROOT/.dev/dev-tools.sh" 'reinstall should preserve dev-tools rw permissions' || return 1
	assert_rw_permissions_unchanged "$first_setup_permissions" "$TARGET_ROOT/.dev/first-setup.sh" 'reinstall should preserve first-setup rw permissions' || return 1
	assert_rw_permissions_unchanged "$agents_permissions" "$TARGET_ROOT/AGENTS.md" 'reinstall should preserve AGENTS.md permissions' || return 1
	assert_rw_permissions_unchanged "$principles_permissions" "$TARGET_ROOT/.docs/PRINCIPLES.md" 'reinstall should preserve PRINCIPLES.md permissions' || return 1
}

test_helper_receives_selected_target() {
	prepare_fixture helper-target-copilot
	write_mock_command "$SOURCE_ROOT/templates/dev-tools.sh" \
		'printf "%s\\n" "$@" > "$HELPER_ARGS_LOG"'

	(
		cd "$TARGET_ROOT"
		setsid --wait env HOME="$MOCK_HOME" PATH="$MOCK_BIN:/usr/bin:/bin" DODKIT_LOG="$DODKIT_LOG" HELPER_ARGS_LOG="$HELPER_ARGS_LOG" bash "$SOURCE_ROOT/install.sh" copilot </dev/null > "$OUTPUT_LOG" 2>&1
	)

	assert_contains '--agent' "$HELPER_ARGS_LOG" 'pass the helper agent option for Copilot' || return 1
	assert_contains 'copilot' "$HELPER_ARGS_LOG" 'pass the Copilot target to the helper' || return 1

	prepare_fixture helper-target-cursor
	write_mock_command "$SOURCE_ROOT/templates/dev-tools.sh" \
		'printf "%s\\n" "$@" > "$HELPER_ARGS_LOG"'

	(
		cd "$TARGET_ROOT"
		setsid --wait env HOME="$MOCK_HOME" PATH="$MOCK_BIN:/usr/bin:/bin" DODKIT_LOG="$DODKIT_LOG" HELPER_ARGS_LOG="$HELPER_ARGS_LOG" bash "$SOURCE_ROOT/install.sh" cursor </dev/null > "$OUTPUT_LOG" 2>&1
	)

	assert_contains '--agent' "$HELPER_ARGS_LOG" 'pass the helper agent option for Cursor' || return 1
	assert_contains 'cursor' "$HELPER_ARGS_LOG" 'pass the Cursor target to the helper' || return 1
}

test_existing_assets_updated_by_default_and_helper_overwritten() {
	local existing_agents='# user-owned AGENTS.md'
	local existing_principles='# user-owned PRINCIPLES.md'
	local existing_helper='# stale helper'
	local existing_first_setup='# stale first-setup'

	prepare_fixture protected-assets
	mkdir -p "$TARGET_ROOT/.dev" "$TARGET_ROOT/.docs"
	printf '%s\n' "$existing_agents" > "$TARGET_ROOT/AGENTS.md"
	printf '%s\n' "$existing_principles" > "$TARGET_ROOT/.docs/PRINCIPLES.md"
	printf '%s\n' "$existing_helper" > "$TARGET_ROOT/.dev/dev-tools.sh"
	printf '%s\n' "$existing_first_setup" > "$TARGET_ROOT/.dev/first-setup.sh"

	(
		cd "$TARGET_ROOT"
		setsid --wait env HOME="$MOCK_HOME" PATH="$MOCK_BIN:/usr/bin:/bin" DODKIT_LOG="$DODKIT_LOG" bash "$SOURCE_ROOT/install.sh" copilot </dev/null > "$OUTPUT_LOG" 2>&1
	)

	cmp -s "$SOURCE_ROOT/templates/AGENTS.md" "$TARGET_ROOT/AGENTS.md" || fail_test 'default ask policy should update AGENTS.md without a TTY' || return 1
	cmp -s "$SOURCE_ROOT/templates/.docs/PRINCIPLES.md" "$TARGET_ROOT/.docs/PRINCIPLES.md" || fail_test 'default ask policy should update PRINCIPLES.md without a TTY' || return 1
	cmp -s "$SOURCE_ROOT/templates/dev-tools.sh" "$TARGET_ROOT/.dev/dev-tools.sh"
	cmp -s "$SOURCE_ROOT/templates/first-setup.sh" "$TARGET_ROOT/.dev/first-setup.sh" || fail_test 'default ask policy should update first-setup.sh without a TTY' || return 1
	assert_contains 'using default helper directory: .dev' "$OUTPUT_LOG" 'use default destination without a TTY' || return 1
}

test_overwrite_no_preserves_local_assets_and_forwards_policy() {
	local existing_agents='# user-owned AGENTS.md'
	local existing_principles='# user-owned PRINCIPLES.md'

	prepare_fixture overwrite-no
	mkdir -p "$TARGET_ROOT/.docs" "$TARGET_ROOT/.dev"
	printf '%s\n' "$existing_agents" > "$TARGET_ROOT/AGENTS.md"
	printf '%s\n' "$existing_principles" > "$TARGET_ROOT/.docs/PRINCIPLES.md"
	printf '%s\n' '# stale helper' > "$TARGET_ROOT/.dev/dev-tools.sh"

	(
		cd "$TARGET_ROOT"
		setsid --wait env HOME="$MOCK_HOME" PATH="$MOCK_BIN:/usr/bin:/bin" DODKIT_LOG="$DODKIT_LOG" bash "$SOURCE_ROOT/install.sh" copilot --overwrite no </dev/null > "$OUTPUT_LOG" 2>&1
	)

	assert_contains "$existing_agents" "$TARGET_ROOT/AGENTS.md" 'overwrite=no should preserve AGENTS.md' || return 1
	assert_contains "$existing_principles" "$TARGET_ROOT/.docs/PRINCIPLES.md" 'overwrite=no should preserve PRINCIPLES.md' || return 1
	cmp -s "$SOURCE_ROOT/templates/dev-tools.sh" "$TARGET_ROOT/.dev/dev-tools.sh" || fail_test 'overwrite=no should not suppress unconditional helper updates' || return 1
	cmp -s "$SOURCE_ROOT/templates/first-setup.sh" "$TARGET_ROOT/.dev/first-setup.sh" || fail_test 'overwrite=no should not suppress first-setup helper updates' || return 1
	assert_contains '--overwrite' "$DODKIT_LOG" 'forward overwrite option to DODKit' || return 1
	assert_contains 'no' "$DODKIT_LOG" 'forward overwrite policy value to DODKit' || return 1
}

test_overwrite_yes_updates_local_assets_and_forwards_policy() {
	prepare_fixture overwrite-yes
	mkdir -p "$TARGET_ROOT/.docs"
	printf '%s\n' '# stale AGENTS.md' > "$TARGET_ROOT/AGENTS.md"
	printf '%s\n' '# stale PRINCIPLES.md' > "$TARGET_ROOT/.docs/PRINCIPLES.md"

	(
		cd "$TARGET_ROOT"
		setsid --wait env HOME="$MOCK_HOME" PATH="$MOCK_BIN:/usr/bin:/bin" DODKIT_LOG="$DODKIT_LOG" bash "$SOURCE_ROOT/install.sh" copilot --overwrite yes </dev/null > "$OUTPUT_LOG" 2>&1
	)

	cmp -s "$SOURCE_ROOT/templates/AGENTS.md" "$TARGET_ROOT/AGENTS.md" || fail_test 'overwrite=yes should update AGENTS.md' || return 1
	cmp -s "$SOURCE_ROOT/templates/.docs/PRINCIPLES.md" "$TARGET_ROOT/.docs/PRINCIPLES.md" || fail_test 'overwrite=yes should update PRINCIPLES.md' || return 1
	assert_contains '--overwrite' "$DODKIT_LOG" 'forward overwrite option to DODKit' || return 1
	assert_contains 'yes' "$DODKIT_LOG" 'forward overwrite policy value to DODKit' || return 1
}

test_legacy_force_is_forwarded_to_dodkit() {
	prepare_fixture legacy-force

	(
		cd "$TARGET_ROOT"
		if ! setsid --wait env HOME="$MOCK_HOME" PATH="$MOCK_BIN:/usr/bin:/bin" DODKIT_LOG="$DODKIT_LOG" bash "$SOURCE_ROOT/install.sh" copilot --force </dev/null > "$OUTPUT_LOG" 2>&1; then
			fail_test 'installer should forward the legacy force option to DODKit'
			return 1
		fi
	)

	assert_contains '--force' "$DODKIT_LOG" 'forward the legacy force option to DODKit'
}

test_existing_dev_directory_destination_prompt() {
	prepare_fixture prompted-destination
	mkdir -p "$TARGET_ROOT/.dev"

	(
		cd "$TARGET_ROOT"
		printf '%s\n' '.custom-tools' | script --quiet --flush --command "env HOME=\"$MOCK_HOME\" PATH=\"$MOCK_BIN:/usr/bin:/bin\" DODKIT_LOG=\"$DODKIT_LOG\" bash \"$SOURCE_ROOT/install.sh\" copilot" "$OUTPUT_LOG" > "$OUTPUT_LOG.stdout" 2>&1
	)

	[[ -f "$TARGET_ROOT/.custom-tools/dev-tools.sh" ]] || fail_test 'selected helper destination was not used' || return 1
	[[ -f "$TARGET_ROOT/.custom-tools/first-setup.sh" ]] || fail_test 'selected first-setup destination was not used' || return 1
	[[ -x "$TARGET_ROOT/.custom-tools/dev-tools.sh" ]] || fail_test 'selected dev-tools helper should be executable' || return 1
	[[ -x "$TARGET_ROOT/.custom-tools/first-setup.sh" ]] || fail_test 'selected first-setup helper should be executable' || return 1
	[[ ! -e "$TARGET_ROOT/.dev/dev-tools.sh" ]] || fail_test 'default helper destination was used despite selection' || return 1
	[[ ! -e "$TARGET_ROOT/.dev/first-setup.sh" ]] || fail_test 'default first-setup destination was used despite selection' || return 1
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
run_test 'overwrite parser preserves explicit passthrough' test_parse_args_accepts_overwrite_policy_and_preserves_passthrough
run_test 'overwrite parser defaults to ask' test_parse_args_defaults_to_ask
run_test 'target parser preserves passthrough' test_parse_args_tracks_target_without_changing_passthrough
run_test 'overwrite parser rejects invalid values' test_parse_args_rejects_invalid_overwrite_values
run_test 'overwrite parser forwards legacy force' test_parse_args_forwards_legacy_force_without_special_handling
run_test 'overwrite parser rejects missing values' test_parse_args_rejects_missing_overwrite_value
run_test 'overwrite policy honors explicit values' test_should_overwrite_honors_explicit_policies
run_test 'interactive overwrite all switches remaining files' test_interactive_overwrite_all_switches_remaining_files_to_yes
run_test 'default overwrite updates assets and helper' test_existing_assets_updated_by_default_and_helper_overwritten
run_test 'reinstall restores helper executable permissions' test_current_helpers_are_made_executable_on_reinstall
run_test 'overwrite=no preserves local assets' test_overwrite_no_preserves_local_assets_and_forwards_policy
run_test 'overwrite=yes updates local assets' test_overwrite_yes_updates_local_assets_and_forwards_policy
run_test 'legacy force option is forwarded to DODKit' test_legacy_force_is_forwarded_to_dodkit
run_test 'helper receives selected target' test_helper_receives_selected_target
run_test 'existing .dev destination prompt' test_existing_dev_directory_destination_prompt
run_test 'helper failure status is reported' test_helper_failure_status_is_reported
run_test 'DODKit failure status is reported' test_dodkit_failure_status_is_reported

printf '%s\n' "Passed $PASS_COUNT focused installer tests."