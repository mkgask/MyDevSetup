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

assert_command_logged() {
	local command_name="$1"
	local file_path="$2"
	local description="$3"

	if ! grep -Eq "^${command_name}( |$)" "$file_path"; then
		printf '[FAIL] %s\nmissing command: %s\n' "$description" "$command_name" >&2
		return 1
	fi
}

assert_command_not_logged() {
	local command_name="$1"
	local file_path="$2"
	local description="$3"

	if grep -Eq "^${command_name}( |$)" "$file_path"; then
		printf '[FAIL] %s\nunexpected command: %s\n' "$description" "$command_name" >&2
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
	local expected_install="apt-get install -y patch bison libdb-dev build-essential libyaml-dev libssl-dev libreadline6-dev libffi-dev autoconf libgdbm-dev zlib1g-dev rustc libncurses5-dev libgdbm6 libgmp-dev fontconfig curl git gh jq unzip gzip xz-utils"
	local expected_prefix="apt-get"
	local mock_root="$TEST_ROOT/apt-commands"
	local mock_bin="$mock_root/bin"
	local mock_log="$mock_root/commands.log"
	local output_file="$mock_root/output.log"
	local error_output="$mock_root/error.log"
	local help_output="$mock_root/help.log"
	local font_data_home="$mock_root/data"
	local font_directory="$font_data_home/fonts/HackGen"
	local update_line=""
	local install_line=""

	mkdir -p "$mock_bin"
	mkdir -p "$font_directory"
	: > "$font_directory/HackGenConsoleNF-Regular.ttf"
	: > "$font_directory/HackGenConsoleNF-Bold.ttf"
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
	assert_contains 'Prepare the user font environment.' "$help_output" 'describe user font preparation generically' || return 1
	assert_not_contains 'proto' "$help_output" 'do not name proto in first-setup help' || return 1
	assert_not_contains 'Ruby' "$help_output" 'do not name Ruby in first-setup help' || return 1

	if ! env NO_COLOR=1 XDG_DATA_HOME="$font_data_home" PATH="$mock_bin:/usr/bin:/bin" MOCK_LOG="$mock_log" "$FIRST_SETUP_PATH" > "$output_file" 2>&1; then
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

test_hackgen_installation() {
	local mock_root="$TEST_ROOT/hackgen-installation"
	local mock_bin="$mock_root/bin"
	local mock_log="$mock_root/commands.log"
	local output_file="$mock_root/output.log"
	local error_output="$mock_root/error.log"
	local font_data_home="$mock_root/data"
	local font_directory="$font_data_home/fonts/HackGen"
	local regular_font="$font_directory/HackGenConsoleNF-Regular.ttf"
	local bold_font="$font_directory/HackGenConsoleNF-Bold.ttf"
	local regular_mode=""

	mkdir -p "$mock_bin"
	: > "$mock_log"
	write_mock_command "$mock_bin/apt-get" \
		'printf "apt-get %s\\n" "$*" >> "$MOCK_LOG"'
	write_mock_command "$mock_bin/sudo" \
		'printf "sudo %s\\n" "$*" >> "$MOCK_LOG"' \
		'exec "$@"'
	write_mock_command "$mock_bin/curl" \
		'printf "curl %s\\n" "$*" >> "$MOCK_LOG"' \
		'case "$*" in' \
		'  *api.github.com*) printf "%s\\n" "{\"assets\":[{\"name\":\"HackGen_NF_v2.10.0.zip\",\"browser_download_url\":\"https://example.test/HackGen_NF_v2.10.0.zip\"}]}" ;;' \
		'  *example.test*) printf "%s" "fake-archive" ;;' \
		'  *) exit 1 ;;' \
		'esac'
	write_mock_command "$mock_bin/jq" \
		'printf "jq %s\\n" "$*" >> "$MOCK_LOG"' \
		'printf "%s\\n" "https://example.test/HackGen_NF_v2.10.0.zip"'
	write_mock_command "$mock_bin/unzip" \
		'printf "unzip %s\\n" "$*" >> "$MOCK_LOG"' \
		'if [[ "$1" == "-Z1" ]]; then' \
		'  if [[ "${MOCK_UNZIP_MODE:-complete}" == "missing-bold" ]]; then' \
		'    printf "%s\\n" "HackGenConsoleNF-Regular.ttf"' \
		'  else' \
		'    printf "%s\\n" "HackGenConsoleNF-Regular.ttf" "HackGenConsoleNF-Bold.ttf"' \
		'  fi' \
		'elif [[ "$1" == "-p" ]]; then' \
		'  case "$3" in' \
		'    *HackGenConsoleNF-Regular.ttf) printf "%s" "regular-font-data" ;;' \
		'    *HackGenConsoleNF-Bold.ttf) printf "%s" "bold-font-data" ;;' \
		'    *) exit 1 ;;' \
		'  esac' \
		'fi'
	write_mock_command "$mock_bin/fc-cache" \
		'printf "fc-cache %s\\n" "$*" >> "$MOCK_LOG"'

	if ! env NO_COLOR=1 HOME="$mock_root/home" XDG_DATA_HOME="$font_data_home" PATH="$mock_bin:/usr/bin:/bin" MOCK_LOG="$mock_log" "$FIRST_SETUP_PATH" > "$output_file" 2>&1; then
		cat "$output_file" >&2
		return 1
	fi

	[[ -f "$regular_font" ]] || fail_test 'install the regular user font' || return 1
	[[ -f "$bold_font" ]] || fail_test 'install the bold user font' || return 1
	assert_contains 'regular-font-data' "$regular_font" 'write the staged regular font' || return 1
	assert_contains 'bold-font-data' "$bold_font" 'write the staged bold font' || return 1
	regular_mode="$(stat -c '%a' "$regular_font")"
	[[ "$regular_mode" == '644' ]] || fail_test 'install the regular font with mode 0644' || return 1
	assert_command_logged 'curl' "$mock_log" 'retrieve release metadata and archive' || return 1
	assert_command_logged 'jq' "$mock_log" 'select the release asset with jq' || return 1
	assert_command_logged 'unzip' "$mock_log" 'inspect the archive contents' || return 1
	assert_command_logged 'fc-cache' "$mock_log" 'refresh the font cache after installation' || return 1

	: > "$mock_log"
	if ! env NO_COLOR=1 HOME="$mock_root/home" XDG_DATA_HOME="$font_data_home" PATH="$mock_bin:/usr/bin:/bin" MOCK_LOG="$mock_log" "$FIRST_SETUP_PATH" > "$output_file" 2>&1; then
		cat "$output_file" >&2
		return 1
	fi

	assert_command_not_logged 'curl' "$mock_log" 'skip network access when both fonts exist' || return 1
	assert_command_not_logged 'jq' "$mock_log" 'skip asset selection when both fonts exist' || return 1
	assert_command_not_logged 'unzip' "$mock_log" 'skip extraction when both fonts exist' || return 1
	assert_command_not_logged 'fc-cache' "$mock_log" 'skip cache refresh when both fonts exist' || return 1

	rm "$bold_font"
	: > "$mock_log"
	if ! env NO_COLOR=1 HOME="$mock_root/home" XDG_DATA_HOME="$font_data_home" PATH="$mock_bin:/usr/bin:/bin" MOCK_LOG="$mock_log" "$FIRST_SETUP_PATH" > "$output_file" 2>&1; then
		cat "$output_file" >&2
		return 1
	fi

	[[ -f "$bold_font" ]] || fail_test 'restore a missing font as a pair' || return 1
	assert_command_logged 'fc-cache' "$mock_log" 'refresh the cache after repairing the pair' || return 1

	local failure_data_home="$mock_root/failure-data"
	local failure_directory="$failure_data_home/fonts/HackGen"
	local failure_regular_font="$failure_directory/HackGenConsoleNF-Regular.ttf"
	mkdir -p "$failure_directory"
	printf '%s' 'existing-regular-font' > "$failure_regular_font"
	: > "$mock_log"
	if env NO_COLOR=1 HOME="$mock_root/home" XDG_DATA_HOME="$failure_data_home" PATH="$mock_bin:/usr/bin:/bin" MOCK_LOG="$mock_log" MOCK_UNZIP_MODE=missing-bold "$FIRST_SETUP_PATH" > "$error_output" 2>&1; then
		fail_test 'reject an archive missing one required font'
		return 1
	fi

	assert_contains 'HackGen font archive must contain exactly one HackGenConsoleNF-Bold.ttf' "$error_output" 'explain the missing required font' || return 1
	assert_contains 'existing-regular-font' "$failure_regular_font" 'preserve the existing partial installation after extraction failure' || return 1
	[[ ! -f "$failure_directory/HackGenConsoleNF-Bold.ttf" ]] || fail_test 'do not install a partial font pair' || return 1
	assert_command_not_logged 'fc-cache' "$mock_log" 'do not refresh the cache after extraction failure' || return 1
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
run_test 'HackGen installation' test_hackgen_installation

printf '%s\n' "Passed $PASS_COUNT focused first-setup tests."
