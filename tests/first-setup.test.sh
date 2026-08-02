#!/usr/bin/env bash

set -euo pipefail

TESTS_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIRECTORY="$(cd -- "$TESTS_DIRECTORY/.." && pwd)"
FIRST_SETUP_PATH="$PROJECT_DIRECTORY/templates/first-setup.sh"
ORIGINAL_PATH="$PATH"
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

test_apt_commands() {
	local expected_install="apt-get install -y patch bison libdb-dev build-essential libyaml-dev libssl-dev libreadline6-dev libffi-dev autoconf libgdbm-dev zlib1g-dev rustc libncurses5-dev libgdbm6 libgmp-dev curl git gh unzip gzip xz-utils"
	local expected_prefix="apt-get"
	local mock_root="$TEST_ROOT/apt-commands"
	local mock_bin="$mock_root/bin"
	local mock_log="$mock_root/commands.log"
	local output_file="$mock_root/output.log"
	local error_output="$mock_root/error.log"
	local help_output="$mock_root/help.log"
	local update_line=""
	local install_line=""

	mkdir -p "$mock_bin"
	: > "$mock_log"
	write_mock_command "$mock_bin/apt-get" \
		'printf "apt-get %s\\n" "$*" >> "$MOCK_LOG"'
	write_mock_command "$mock_bin/sudo" \
		'printf "sudo %s\\n" "$*" >> "$MOCK_LOG"' \
		'exec "$@"'

	if [[ "$EUID" -ne 0 ]]; then
		expected_prefix='sudo apt-get'
	fi

	if ! env NO_COLOR=1 PATH="$mock_bin:/usr/bin:/bin" "$FIRST_SETUP_PATH" --help > "$help_output" 2>&1; then
		cat "$help_output" >&2
		return 1
	fi

	assert_contains 'Install the apt packages required by the development tools.' "$help_output" 'describe generic development tool dependencies' || return 1
	assert_not_contains 'proto' "$help_output" 'do not name proto in first-setup help' || return 1
	assert_not_contains 'Ruby' "$help_output" 'do not name Ruby in first-setup help' || return 1

	if ! env NO_COLOR=1 PATH="$mock_bin:/usr/bin:/bin" MOCK_LOG="$mock_log" "$FIRST_SETUP_PATH" > "$output_file" 2>&1; then
		cat "$output_file" >&2
		return 1
	fi

	update_line="$(awk -v expected="$expected_prefix update" '$0 == expected { print NR; exit }' "$mock_log")"
	install_line="$(awk -v expected="$expected_prefix install -y" '$0 ~ ("^" expected " ") { print NR; exit }' "$mock_log")"

	assert_contains "$expected_install" "$mock_log" 'install all development tool dependencies' || return 1
	assert_not_contains 'proto ' "$mock_log" 'do not invoke proto during first setup' || return 1
	assert_contains '[INFO] Updating apt package index' "$output_file" 'use the shared info label' || return 1
	assert_contains '[INFO] Installing development tool dependencies' "$output_file" 'describe generic dependency installation' || return 1
	assert_contains '[✅️SUCCESS] Development tool dependencies are installed' "$output_file" 'use the generic success label' || return 1
	assert_not_contains 'proto' "$output_file" 'do not name proto in first-setup output' || return 1
	assert_not_contains 'Ruby' "$output_file" 'do not name Ruby in first-setup output' || return 1
	assert_not_contains $'\033[' "$output_file" 'do not color output when NO_COLOR is set' || return 1
	if [[ -z "$update_line" || -z "$install_line" || "$update_line" -ge "$install_line" ]]; then
		fail_test 'update apt package index before installing first-setup dependencies'
		return 1
	fi

	if env NO_COLOR=1 PATH="$mock_bin:/usr/bin:/bin" MOCK_LOG="$mock_log" "$FIRST_SETUP_PATH" --invalid > "$error_output" 2>&1; then
		fail_test 'reject unsupported first-setup arguments'
		return 1
	fi
	assert_contains '[❌️ERROR] Unsupported argument: --invalid' "$error_output" 'use the shared error label' || return 1
	assert_not_contains $'\033[' "$error_output" 'do not color errors when NO_COLOR is set' || return 1
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

PATH="$ORIGINAL_PATH"
export PATH

run_test 'apt commands' test_apt_commands

printf '%s\n' "Passed $PASS_COUNT focused first-setup tests."
