#!/usr/bin/env bash

set -euo pipefail

TESTS_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIRECTORY="$(cd -- "$TESTS_DIRECTORY/.." && pwd)"
HELPER_TEMPLATE_PATH="$PROJECT_DIRECTORY/templates/language-tools.sh"
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

assert_equal() {
	local expected="$1"
	local actual="$2"
	local description="$3"

	if [[ "$expected" != "$actual" ]]; then
		printf '[FAIL] %s\nexpected:\n%s\nactual:\n%s\n' "$description" "$expected" "$actual" >&2
		return 1
	fi
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

	FIXTURE_ROOT="$TEST_ROOT/$fixture_name"
	PROJECT_ROOT="$FIXTURE_ROOT/project"
	HELPER_DIRECTORY="$PROJECT_ROOT/.dev"
	PROJECT_AGENTS_PATH="$PROJECT_ROOT/AGENTS.md"
	MOCK_BIN="$FIXTURE_ROOT/bin"
	MOCK_LOG="$FIXTURE_ROOT/commands.log"
	OUTPUT_LOG="$FIXTURE_ROOT/output.log"

	mkdir -p "$HELPER_DIRECTORY" "$MOCK_BIN"
	cp "$HELPER_TEMPLATE_PATH" "$HELPER_DIRECTORY/language-tools.sh"
	printf '%s\n' '# Project guidance' > "$PROJECT_AGENTS_PATH"
	: > "$MOCK_LOG"
	: > "$OUTPUT_LOG"

	export FIXTURE_ROOT PROJECT_ROOT HELPER_DIRECTORY PROJECT_AGENTS_PATH MOCK_BIN MOCK_LOG OUTPUT_LOG
}

install_command_mocks() {
	local operating_system="$1"
	local architecture="$2"
	local curl_status="${3:-0}"
	local tar_status="${4:-0}"
	local package_manager_status="${5:-0}"

	export MOCK_OS="$operating_system"
	export MOCK_ARCH="$architecture"
	export MOCK_CURL_STATUS="$curl_status"
	export MOCK_TAR_STATUS="$tar_status"
	export MOCK_PACKAGE_MANAGER_STATUS="$package_manager_status"

	write_mock_command "$MOCK_BIN/uname" \
		'case "${1:-}" in' \
		'	-s) printf "%s\n" "$MOCK_OS" ;;' \
		'	-m) printf "%s\n" "$MOCK_ARCH" ;;' \
		'	*) exit 1 ;;' \
		'esac'

	write_mock_command "$MOCK_BIN/curl" \
		'printf "curl %s\n" "$*" >> "$MOCK_LOG"' \
		'[[ "$MOCK_CURL_STATUS" -eq 0 ]] || exit "$MOCK_CURL_STATUS"' \
		'output_path=""' \
		'while (($#)); do' \
		'	if [[ "$1" == "-o" ]]; then output_path="$2"; shift 2; else shift; fi' \
		'done' \
		'[[ -n "$output_path" ]] || exit 2' \
		'printf "fake archive\n" > "$output_path"'

	write_mock_command "$MOCK_BIN/tar" \
		'printf "tar %s\n" "$*" >> "$MOCK_LOG"' \
		'[[ "$MOCK_TAR_STATUS" -eq 0 ]] || exit "$MOCK_TAR_STATUS"' \
		'[[ "${1:-}" == "-xzf" ]] || exit 2' \
		'shift 2' \
		'[[ "${1:-}" == "-C" ]] || exit 2' \
		'destination_directory="$2"' \
		'archive_root="shellcheck-v0.11.0"' \
		'mkdir -p "$destination_directory/$archive_root"' \
		'printf "%s\n" "#!/usr/bin/env bash" \' \
		'	"if [[ \"\${1:-}\" == \"--version\" ]]; then printf \"ShellCheck - shell script analysis tool version 0.11.0\\n\"; exit 0; fi" \' \
		'	"exit 0" > "$destination_directory/$archive_root/shellcheck"' \
		'chmod +x "$destination_directory/$archive_root/shellcheck"'

	write_mock_command "$MOCK_BIN/apt-get" \
		'printf "apt-get %s\n" "$*" >> "$MOCK_LOG"' \
		'exit "$MOCK_PACKAGE_MANAGER_STATUS"'

	write_mock_command "$MOCK_BIN/sudo" \
		'printf "sudo %s\n" "$*" >> "$MOCK_LOG"' \
		'exec "$@"'

	PATH="$MOCK_BIN:/usr/bin:/bin"
	export PATH
}

run_helper() {
	(
		cd "$PROJECT_ROOT"
		bash "$HELPER_DIRECTORY/language-tools.sh" "$@"
	)
}

test_no_arguments_print_usage_only() {
	local output=""

	prepare_fixture no-arguments
	install_command_mocks Linux x86_64

	output="$(run_helper)"
	assert_equal $'Usage:\n\tlanguage-tools.sh <tool> [tool ...]\n\nAvailable tools:\n\tshell (ShellCheck)' "$output" 'no-argument invocation should print only Usage' || return 1
	[[ ! -e "$HELPER_DIRECTORY/bin" ]] || fail_test 'Usage-only invocation should not create an installation directory' || return 1
	assert_not_contains 'MYDEVSETUP DEV TOOLS' "$PROJECT_AGENTS_PATH" 'Usage-only invocation should not change AGENTS.md' || return 1
}

test_unknown_arguments_fail_before_side_effects() {
	local output=""
	local status=0

	prepare_fixture unknown-tool
	install_command_mocks Linux x86_64

	if output="$(run_helper python shell 2>&1)"; then
		status=0
	else
		status="$?"
	fi

	[[ "$status" -eq 1 ]] || fail_test 'unknown tools should fail' || return 1
	[[ "$output" == *'Unsupported tool: python'* ]] || fail_test 'unknown tool error should identify the unsupported argument' || return 1
	assert_not_contains 'curl ' "$MOCK_LOG" 'unknown arguments should be rejected before downloading' || return 1
	assert_not_contains 'apt-get ' "$MOCK_LOG" 'unknown arguments should be rejected before global installation' || return 1
	[[ ! -e "$HELPER_DIRECTORY/bin" ]] || fail_test 'unknown arguments should not create an installation directory' || return 1
	assert_not_contains 'MYDEVSETUP DEV TOOLS' "$PROJECT_AGENTS_PATH" 'unknown arguments should not change AGENTS.md' || return 1
}

test_shell_installs_pinned_local_binary_and_reuses_it() {
	local output=""
	local curl_count=""
	local shellcheck_path=""

	prepare_fixture local-install
	install_command_mocks Linux x86_64
	shellcheck_path="$HELPER_DIRECTORY/bin/shellcheck"

	if ! output="$(run_helper shell shell 2>&1)"; then
		fail_test 'shell argument should install ShellCheck locally'
		return 1
	fi

	[[ -x "$shellcheck_path" ]] || fail_test 'project-local ShellCheck binary should be executable' || return 1
	[[ "$output" == *"$shellcheck_path"* ]] || fail_test 'install output should report the local binary path' || return 1
	assert_contains 'shellcheck-v0.11.0.linux.x86_64.tar.gz' "$MOCK_LOG" 'local install should fetch the pinned official Linux release' || return 1
	assert_not_contains 'apt-get ' "$MOCK_LOG" 'local install should not use the global fallback' || return 1
	assert_contains '# Project guidance' "$PROJECT_AGENTS_PATH" 'local install should preserve existing AGENTS.md content' || return 1
	assert_contains '- `ShellCheck`: `.dev/bin/shellcheck` - Use it to lint shell scripts when relevant.' "$PROJECT_AGENTS_PATH" 'local install should document the project binary for agents' || return 1

	curl_count="$(grep -c '^curl ' "$MOCK_LOG" || true)"
	assert_equal 1 "$curl_count" 'duplicate shell arguments should install only once' || return 1

	if ! output="$(run_helper shell 2>&1)"; then
		fail_test 'an existing matching local ShellCheck should be reused'
		return 1
	fi
	curl_count="$(grep -c '^curl ' "$MOCK_LOG" || true)"
	assert_equal 1 "$curl_count" 'a matching local ShellCheck should not be downloaded again' || return 1
	assert_equal 1 "$(grep -Fxc -- '- `ShellCheck`: `.dev/bin/shellcheck` - Use it to lint shell scripts when relevant.' "$PROJECT_AGENTS_PATH")" 'repeated setup should keep one ShellCheck AGENTS entry' || return 1
}

test_existing_managed_block_is_updated_without_touching_user_content() {
	prepare_fixture existing-managed-block
	install_command_mocks Linux x86_64
	printf '%s\n' \
		'# User guidance before tools' \
		'<!-- BEGIN MYDEVSETUP DEV TOOLS -->' \
		'## Installed development tools' \
		'- `ShellCheck`: `shellcheck` - stale command' \
		'- `ShellCheck`: `old-shellcheck` - duplicate entry' \
		'- `python`: `python3`' \
		'<!-- END MYDEVSETUP DEV TOOLS -->' \
		'# User guidance after tools' > "$PROJECT_AGENTS_PATH"

	if ! run_helper shell > "$OUTPUT_LOG" 2>&1; then
		fail_test 'local installation should update the existing managed block'
		return 1
	fi

	assert_contains '# User guidance before tools' "$PROJECT_AGENTS_PATH" 'managed-block update should preserve preceding user content' || return 1
	assert_contains '# User guidance after tools' "$PROJECT_AGENTS_PATH" 'managed-block update should preserve following user content' || return 1
	assert_contains '- `ShellCheck`: `.dev/bin/shellcheck` - Use it to lint shell scripts when relevant.' "$PROJECT_AGENTS_PATH" 'managed ShellCheck entry should use the current local command' || return 1
	assert_contains '- `python`: `python3`' "$PROJECT_AGENTS_PATH" 'other managed tool entries should be preserved' || return 1
	assert_not_contains 'old-shellcheck' "$PROJECT_AGENTS_PATH" 'stale duplicate ShellCheck entries should be removed' || return 1
	assert_equal 1 "$(grep -Fxc -- '- `ShellCheck`: `.dev/bin/shellcheck` - Use it to lint shell scripts when relevant.' "$PROJECT_AGENTS_PATH")" 'managed block should contain one ShellCheck entry' || return 1
}

test_existing_local_binary_updates_custom_agents_path() {
	local shellcheck_path=""
	local custom_agents_path=""

	prepare_fixture local-reuse-custom-agents
	install_command_mocks Linux x86_64
	shellcheck_path="$HELPER_DIRECTORY/bin/shellcheck"
	custom_agents_path="$FIXTURE_ROOT/custom/AGENTS.md"
	mkdir -p "$(dirname "$shellcheck_path")"
	printf '%s\n' '#!/usr/bin/env bash' 'printf "ShellCheck - shell script analysis tool version 0.11.0\n"' > "$shellcheck_path"
	chmod +x "$shellcheck_path"

	if ! DEV_TOOLS_AGENTS_PATH="$custom_agents_path" run_helper shell > "$OUTPUT_LOG" 2>&1; then
		fail_test "existing local ShellCheck should still update the selected AGENTS.md: $(<"$OUTPUT_LOG")"
		return 1
	fi

	[[ -f "$custom_agents_path" ]] || fail_test 'selected AGENTS.md should be created when missing' || return 1
	assert_contains '- `ShellCheck`: `.dev/bin/shellcheck` - Use it to lint shell scripts when relevant.' "$custom_agents_path" 'existing local binary should be registered in the selected AGENTS.md' || return 1
	assert_not_contains 'curl ' "$MOCK_LOG" 'matching local ShellCheck should not be downloaded again' || return 1
}

test_custom_helper_path_is_recorded_for_local_install() {
	local shellcheck_path=""

	prepare_fixture local-custom-helper-path
	HELPER_DIRECTORY="$PROJECT_ROOT/.custom tools"
	export HELPER_DIRECTORY
	mkdir -p "$HELPER_DIRECTORY"
	cp "$HELPER_TEMPLATE_PATH" "$HELPER_DIRECTORY/language-tools.sh"
	install_command_mocks Linux x86_64
	shellcheck_path="$HELPER_DIRECTORY/bin/shellcheck"

	if ! run_helper shell > "$OUTPUT_LOG" 2>&1; then
		fail_test 'custom helper directory should support ShellCheck installation'
		return 1
	fi

	[[ -x "$shellcheck_path" ]] || fail_test 'custom helper directory should contain the local ShellCheck binary' || return 1
	if ! grep -Fq -- '- `ShellCheck`: `.custom\ tools/bin/shellcheck` - Use it to lint shell scripts when relevant.' "$PROJECT_AGENTS_PATH"; then
		fail_test "AGENTS.md should record the escaped custom local path: $(<"$PROJECT_AGENTS_PATH")"
		return 1
	fi
}

test_darwin_arm_uses_matching_local_asset() {
	prepare_fixture darwin-arm
	install_command_mocks Darwin arm64

	if ! run_helper shell > "$OUTPUT_LOG" 2>&1; then
		fail_test 'ShellCheck should install locally on supported macOS architecture'
		return 1
	fi

	assert_contains 'shellcheck-v0.11.0.darwin.aarch64.tar.gz' "$MOCK_LOG" 'macOS arm64 should select the matching official release asset' || return 1
}

test_unsupported_local_architecture_uses_global_package_manager() {
	prepare_fixture global-fallback
	install_command_mocks Linux ppc64le

	if ! run_helper shell > "$OUTPUT_LOG" 2>&1; then
		fail_test 'unsupported local architecture should use the global fallback'
		return 1
	fi

	assert_contains 'apt-get install -y shellcheck' "$MOCK_LOG" 'global fallback should install ShellCheck with the available system manager' || return 1
	assert_not_contains 'curl ' "$MOCK_LOG" 'global fallback should not download an unsupported local release' || return 1
	assert_contains '- `ShellCheck`: `shellcheck` - Use it to lint shell scripts when relevant.' "$PROJECT_AGENTS_PATH" 'global installation should document its command for agents' || return 1
}

test_local_download_failure_does_not_fall_back_globally() {
	local status=0
	local agents_snapshot=""

	prepare_fixture local-download-failure
	install_command_mocks Linux x86_64 22
	agents_snapshot="$FIXTURE_ROOT/agents.before"
	cp "$PROJECT_AGENTS_PATH" "$agents_snapshot"

	if run_helper shell > "$OUTPUT_LOG" 2>&1; then
		status=0
	else
		status="$?"
	fi

	[[ "$status" -eq 1 ]] || fail_test 'local download failure should be reported' || return 1
	assert_contains 'curl ' "$MOCK_LOG" 'local installation should attempt the official release download' || return 1
	assert_not_contains 'apt-get ' "$MOCK_LOG" 'local download failure must not trigger global fallback' || return 1
	cmp -s "$agents_snapshot" "$PROJECT_AGENTS_PATH" || fail_test 'failed ShellCheck setup should not change AGENTS.md' || return 1
}

test_global_package_manager_failure_is_reported() {
	local status=0

	prepare_fixture global-install-failure
	install_command_mocks Linux ppc64le 0 0 7

	if run_helper shell > "$OUTPUT_LOG" 2>&1; then
		status=0
	else
		status="$?"
	fi

	[[ "$status" -eq 1 ]] || fail_test 'global package manager failure should be reported' || return 1
	assert_contains 'apt-get install -y shellcheck' "$MOCK_LOG" 'global fallback should invoke the selected manager' || return 1
	assert_contains 'failed' "$OUTPUT_LOG" 'global installation failure should be surfaced to the user' || return 1
	assert_not_contains 'MYDEVSETUP DEV TOOLS' "$PROJECT_AGENTS_PATH" 'failed global installation should not change AGENTS.md' || return 1
}

test_agents_update_failure_is_explicit_after_install() {
	local status=0
	local shellcheck_path=""

	prepare_fixture invalid-agents-block
	install_command_mocks Linux x86_64
	shellcheck_path="$HELPER_DIRECTORY/bin/shellcheck"
	printf '%s\n' \
		'<!-- BEGIN MYDEVSETUP DEV TOOLS -->' \
		'## Installed development tools' > "$PROJECT_AGENTS_PATH"

	if run_helper shell > "$OUTPUT_LOG" 2>&1; then
		status=0
	else
		status="$?"
	fi

	[[ "$status" -eq 1 ]] || fail_test 'AGENTS.md update failure should fail the setup command' || return 1
	assert_contains 'Cannot update incomplete AGENTS.md managed block' "$OUTPUT_LOG" 'invalid managed block should be reported' || return 1
	[[ -x "$shellcheck_path" ]] || fail_test 'successful ShellCheck installation should remain after AGENTS.md update failure' || return 1
	assert_not_contains '- `ShellCheck`:' "$PROJECT_AGENTS_PATH" 'failed AGENTS.md update should not write a partial ShellCheck entry' || return 1
}

run_test() {
	local test_name="$1"
	local test_function="$2"

	if "$test_function"; then
		PASS_COUNT=$((PASS_COUNT + 1))
		printf '[PASS] %s\n' "$test_name"
	else
		exit 1
	fi
}

run_test 'no arguments print Usage only' test_no_arguments_print_usage_only
run_test 'unknown tools fail before side effects' test_unknown_arguments_fail_before_side_effects
run_test 'shell installs and reuses pinned local binary' test_shell_installs_pinned_local_binary_and_reuses_it
run_test 'existing managed block is updated without touching user content' test_existing_managed_block_is_updated_without_touching_user_content
run_test 'existing local binary updates custom AGENTS.md' test_existing_local_binary_updates_custom_agents_path
run_test 'custom helper path is recorded for local install' test_custom_helper_path_is_recorded_for_local_install
run_test 'Darwin arm selects local release' test_darwin_arm_uses_matching_local_asset
run_test 'unsupported architecture uses global package manager' test_unsupported_local_architecture_uses_global_package_manager
run_test 'local download failure does not use global fallback' test_local_download_failure_does_not_fall_back_globally
run_test 'global package-manager failure is explicit' test_global_package_manager_failure_is_reported
run_test 'AGENTS.md update failure is explicit after installation' test_agents_update_failure_is_explicit_after_install

printf 'Passed %d language-tools tests.\n' "$PASS_COUNT"
