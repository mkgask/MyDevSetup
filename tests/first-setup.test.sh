#!/usr/bin/env bash

set -euo pipefail

TESTS_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIRECTORY="$(cd -- "$TESTS_DIRECTORY/.." && pwd)"
FIRST_SETUP_PATH="$PROJECT_DIRECTORY/first-setup.sh"
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

write_mock_manager_installers() {
	local mock_root="$1"
	local mock_bin="$2"
	local manager_script_directory="$mock_root/manager-installers"

	mkdir -p "$manager_script_directory"
	write_mock_command "$manager_script_directory/proto.sh" \
		'printf "proto-installer %s\n" "$*" >> "$MOCK_LOG"' \
		'if [[ "${MOCK_PROTO_INSTALL_FAIL:-0}" == 1 ]]; then exit 42; fi' \
		'mkdir -p "$HOME/.proto/bin"' \
		'printf "%s\n" "#!/usr/bin/env bash" "exit 0" > "$HOME/.proto/bin/proto"' \
		'chmod +x "$HOME/.proto/bin/proto"'
	write_mock_command "$manager_script_directory/mise.sh" \
		'printf "mise-installer %s\n" "$*" >> "$MOCK_LOG"' \
		'if [ "${MOCK_MISE_INSTALL_FAIL:-0}" = 1 ]; then exit 43; fi' \
		'mkdir -p "$HOME/.local/bin"' \
		'printf "%s\n" "#!/usr/bin/env bash" "exit 0" > "$HOME/.local/bin/mise"' \
		'chmod +x "$HOME/.local/bin/mise"'
	write_mock_command "$mock_bin/curl" \
		'printf "curl %s\n" "$*" >> "$MOCK_LOG"' \
		'case "$*" in' \
		'  *moonrepo.dev/install/proto.sh*) cat "$MOCK_MANAGER_SCRIPT_DIR/proto.sh" ;;' \
		'  *mise.run*) cat "$MOCK_MANAGER_SCRIPT_DIR/mise.sh" ;;' \
		'  *) exit 1 ;;' \
		'esac'
}

write_fake_installed_managers() {
	local home_directory="$1"

	mkdir -p "$home_directory/.proto/bin" "$home_directory/.local/bin"
	write_mock_command "$home_directory/.proto/bin/proto" 'exit 0'
	write_mock_command "$home_directory/.local/bin/mise" 'exit 0'
}

test_apt_commands() {
	local expected_install="apt-get install -y patch bison libdb-dev build-essential libyaml-dev libssl-dev libreadline6-dev libffi-dev autoconf libgdbm-dev zlib1g-dev rustc libncurses5-dev libgdbm6 libgmp-dev fontconfig curl git gh jq unzip gzip xz-utils tar"
	local expected_prefix="sudo apt-get"
	local mock_root="$TEST_ROOT/apt-commands"
	local mock_bin="$mock_root/bin"
	local mock_log="$mock_root/commands.log"
	local output_file="$mock_root/output.log"
	local error_output="$mock_root/error.log"
	local help_output="$mock_root/help.log"
	local home_directory="$mock_root/home"
	local font_data_home="$mock_root/data"
	local font_directory="$font_data_home/fonts/HackGen"
	local manager_path_line='export PATH="$HOME/.proto/bin:$HOME/.local/bin:$PATH"'
	local update_line=""
	local install_line=""
	local path_line_count=""

	mkdir -p "$mock_bin" "$home_directory"
	mkdir -p "$font_directory"
	: > "$font_directory/HackGenConsoleNF-Regular.ttf"
	: > "$font_directory/HackGenConsoleNF-Bold.ttf"
	: > "$mock_log"
	write_mock_manager_installers "$mock_root" "$mock_bin"
	write_mock_command "$mock_bin/apt-get" \
		'printf "apt-get %s\\n" "$*" >> "$MOCK_LOG"'
	write_mock_command "$mock_bin/sudo" \
		'printf "sudo %s\\n" "$*" >> "$MOCK_LOG"' \
		'exec "$@"'

	if ! env NO_COLOR=1 PATH="$mock_bin:/usr/bin:/bin" "$FIRST_SETUP_PATH" --help > "$help_output" 2>&1; then
		cat "$help_output" >&2
		return 1
	fi

	assert_contains 'Install the apt packages required by the development tools.' "$help_output" 'describe generic development tool dependencies' || return 1
	assert_contains 'Install missing development-library manager binaries.' "$help_output" 'describe manager bootstrap generically' || return 1
	assert_contains 'Prepare the user font environment.' "$help_output" 'describe user font preparation generically' || return 1
	assert_not_contains 'proto' "$help_output" 'do not name proto in first-setup help' || return 1
	assert_not_contains 'Ruby' "$help_output" 'do not name Ruby in first-setup help' || return 1

	if ! env NO_COLOR=1 HOME="$home_directory" XDG_DATA_HOME="$font_data_home" PATH="$mock_bin:/usr/bin:/bin" MOCK_LOG="$mock_log" MOCK_MANAGER_SCRIPT_DIR="$mock_root/manager-installers" "$FIRST_SETUP_PATH" > "$output_file" 2>&1; then
		cat "$output_file" >&2
		return 1
	fi

	update_line="$(awk -v expected="$expected_prefix update" '$0 == expected { print NR; exit }' "$mock_log")"
	install_line="$(awk -v expected="$expected_prefix install -y" '$0 ~ ("^" expected " ") { print NR; exit }' "$mock_log")"

	assert_contains "$expected_install" "$mock_log" 'install all development tool dependencies' || return 1
	assert_command_logged 'proto-installer' "$mock_log" 'install missing proto with the official installer' || return 1
	assert_command_logged 'mise-installer' "$mock_log" 'install missing mise with the official installer' || return 1
	assert_contains '[INFO] Updating apt package index' "$output_file" 'use the shared info label' || return 1
	assert_contains '[INFO] Installing development tool dependencies' "$output_file" 'describe generic dependency installation' || return 1
	assert_contains '[✅️SUCCESS] Development tool dependencies are installed' "$output_file" 'use the generic success label' || return 1
	assert_contains '[INFO] Preparing development tool managers' "$output_file" 'describe manager setup generically' || return 1
	assert_contains '[✅️SUCCESS] Development tool managers are ready' "$output_file" 'use a generic manager success label' || return 1
	assert_not_contains 'proto' "$output_file" 'do not name proto in first-setup output' || return 1
	assert_not_contains 'Ruby' "$output_file" 'do not name Ruby in first-setup output' || return 1
	assert_not_contains $'\033[' "$output_file" 'do not color output when NO_COLOR is set' || return 1
	assert_contains "$manager_path_line" "$home_directory/.bashrc" 'add only manager PATH entries to the user bash profile' || return 1
	if [[ -z "$update_line" || -z "$install_line" || "$update_line" -ge "$install_line" ]]; then
		fail_test 'update apt package index before installing first-setup dependencies'
		return 1
	fi

	: > "$mock_log"
	if ! env NO_COLOR=1 HOME="$home_directory" XDG_DATA_HOME="$font_data_home" PATH="$mock_bin:/usr/bin:/bin" MOCK_LOG="$mock_log" MOCK_MANAGER_SCRIPT_DIR="$mock_root/manager-installers" "$FIRST_SETUP_PATH" > "$output_file" 2>&1; then
		cat "$output_file" >&2
		return 1
	fi
	assert_command_not_logged 'proto-installer' "$mock_log" 'skip reinstalling an existing proto manager' || return 1
	assert_command_not_logged 'mise-installer' "$mock_log" 'skip reinstalling an existing mise manager' || return 1
	assert_command_not_logged 'curl' "$mock_log" 'skip manager downloads after both managers are installed' || return 1
	path_line_count="$(grep -Fxc -- "$manager_path_line" "$home_directory/.bashrc")"
	[[ "$path_line_count" == '1' ]] || fail_test 'keep the manager PATH entry idempotent across runs' || return 1

	if env NO_COLOR=1 PATH="$mock_bin:/usr/bin:/bin" MOCK_LOG="$mock_log" "$FIRST_SETUP_PATH" --invalid > "$error_output" 2>&1; then
		fail_test 'reject unsupported first-setup arguments'
		return 1
	fi
	assert_contains '[❌️ERROR] Unsupported argument: --invalid' "$error_output" 'use the shared error label' || return 1
	assert_not_contains $'\033[' "$error_output" 'do not color errors when NO_COLOR is set' || return 1
}

test_root_rejection() {
	local mock_root="$TEST_ROOT/root-rejection"
	local mock_bin="$mock_root/bin"
	local mock_log="$mock_root/commands.log"
	local output_file="$mock_root/output.log"
	local home_directory="$mock_root/home"

	mkdir -p "$mock_bin" "$home_directory"
	: > "$mock_log"
	write_mock_command "$mock_bin/apt-get" \
		'printf "apt-get %s\\n" "$*" >> "$MOCK_LOG"'
	write_mock_command "$mock_bin/sudo" \
		'printf "sudo %s\\n" "$*" >> "$MOCK_LOG"' \
		'exec "$@"'

	if [[ "$EUID" -eq 0 ]]; then
		if env NO_COLOR=1 HOME="$home_directory" PATH="$mock_bin:/usr/bin:/bin" MOCK_LOG="$mock_log" "$FIRST_SETUP_PATH" > "$output_file" 2>&1; then
			fail_test 'reject setup execution as root'
			return 1
		fi
	elif command -v unshare >/dev/null 2>&1 && unshare --user --map-root-user true 2>/dev/null; then
		if unshare --user --map-root-user env NO_COLOR=1 HOME="$home_directory" PATH="$mock_bin:/usr/bin:/bin" MOCK_LOG="$mock_log" "$FIRST_SETUP_PATH" > "$output_file" 2>&1; then
			fail_test 'reject setup execution as root in a user namespace'
			return 1
		fi
	else
		printf '[SKIP] root rejection could not be exercised without user namespaces\n'
		return 0
	fi

	assert_contains '[❌️ERROR] first-setup.sh must be run as a regular user' "$output_file" 'explain the root execution restriction' || return 1
	assert_command_not_logged 'apt-get' "$mock_log" 'reject root before apt side effects' || return 1
	assert_command_not_logged 'sudo' "$mock_log" 'reject root before sudo side effects' || return 1
	[[ ! -e "$home_directory/.bashrc" ]] || fail_test 'do not modify shell startup files when rejecting root' || return 1
}

test_manager_installation_failure() {
	local mock_root="$TEST_ROOT/manager-installation-failure"
	local mock_bin="$mock_root/bin"
	local mock_log="$mock_root/commands.log"
	local output_file="$mock_root/output.log"
	local home_directory="$mock_root/home"
	local font_data_home="$mock_root/data"
	local font_directory="$font_data_home/fonts/HackGen"

	mkdir -p "$mock_bin" "$home_directory" "$font_directory"
	: > "$font_directory/HackGenConsoleNF-Regular.ttf"
	: > "$font_directory/HackGenConsoleNF-Bold.ttf"
	: > "$mock_log"
	write_mock_manager_installers "$mock_root" "$mock_bin"
	write_mock_command "$mock_bin/apt-get" \
		'printf "apt-get %s\\n" "$*" >> "$MOCK_LOG"'
	write_mock_command "$mock_bin/sudo" \
		'printf "sudo %s\\n" "$*" >> "$MOCK_LOG"' \
		'exec "$@"'

	if env NO_COLOR=1 HOME="$home_directory" XDG_DATA_HOME="$font_data_home" PATH="$mock_bin:/usr/bin:/bin" MOCK_LOG="$mock_log" MOCK_MANAGER_SCRIPT_DIR="$mock_root/manager-installers" MOCK_PROTO_INSTALL_FAIL=1 "$FIRST_SETUP_PATH" > "$output_file" 2>&1; then
		fail_test 'report a nonzero proto installation failure'
		return 1
	fi

	assert_contains '[❌️ERROR] Failed to install proto' "$output_file" 'name the manager installation failure' || return 1
	assert_command_logged 'proto-installer' "$mock_log" 'run the proto installer before reporting failure' || return 1
	assert_command_not_logged 'mise-installer' "$mock_log" 'stop before attempting mise after proto installation fails' || return 1
	[[ ! -e "$home_directory/.bashrc" ]] || fail_test 'do not update PATH after manager installation failure' || return 1
}

test_mise_installation_failure() {
	local mock_root="$TEST_ROOT/mise-installation-failure"
	local mock_bin="$mock_root/bin"
	local mock_log="$mock_root/commands.log"
	local output_file="$mock_root/output.log"
	local home_directory="$mock_root/home"
	local font_data_home="$mock_root/data"
	local font_directory="$font_data_home/fonts/HackGen"

	mkdir -p "$mock_bin" "$home_directory" "$font_directory"
	: > "$font_directory/HackGenConsoleNF-Regular.ttf"
	: > "$font_directory/HackGenConsoleNF-Bold.ttf"
	: > "$mock_log"
	write_mock_manager_installers "$mock_root" "$mock_bin"
	write_mock_command "$mock_bin/apt-get" \
		'printf "apt-get %s\\n" "$*" >> "$MOCK_LOG"'
	write_mock_command "$mock_bin/sudo" \
		'printf "sudo %s\\n" "$*" >> "$MOCK_LOG"' \
		'exec "$@"'

	if env NO_COLOR=1 HOME="$home_directory" XDG_DATA_HOME="$font_data_home" PATH="$mock_bin:/usr/bin:/bin" MOCK_LOG="$mock_log" MOCK_MANAGER_SCRIPT_DIR="$mock_root/manager-installers" MOCK_MISE_INSTALL_FAIL=1 "$FIRST_SETUP_PATH" > "$output_file" 2>&1; then
		fail_test 'report a nonzero mise installation failure'
		return 1
	fi

	assert_contains '[❌️ERROR] Failed to install mise' "$output_file" 'name the mise installation failure' || return 1
	assert_command_logged 'proto-installer' "$mock_log" 'install proto before attempting mise' || return 1
	assert_command_logged 'mise-installer' "$mock_log" 'run the mise installer before reporting failure' || return 1
	[[ ! -e "$home_directory/.bashrc" ]] || fail_test 'do not update PATH after a manager installation failure' || return 1
}

test_manager_path_failure() {
	local mock_root="$TEST_ROOT/manager-path-failure"
	local mock_bin="$mock_root/bin"
	local mock_log="$mock_root/commands.log"
	local output_file="$mock_root/output.log"
	local home_directory="$mock_root/home"
	local font_data_home="$mock_root/data"
	local font_directory="$font_data_home/fonts/HackGen"

	mkdir -p "$mock_bin" "$home_directory/.bashrc" "$font_directory"
	: > "$font_directory/HackGenConsoleNF-Regular.ttf"
	: > "$font_directory/HackGenConsoleNF-Bold.ttf"
	: > "$mock_log"
	write_mock_manager_installers "$mock_root" "$mock_bin"
	write_mock_command "$mock_bin/apt-get" \
		'printf "apt-get %s\\n" "$*" >> "$MOCK_LOG"'
	write_mock_command "$mock_bin/sudo" \
		'printf "sudo %s\\n" "$*" >> "$MOCK_LOG"' \
		'exec "$@"'

	if env NO_COLOR=1 HOME="$home_directory" XDG_DATA_HOME="$font_data_home" PATH="$mock_bin:/usr/bin:/bin" MOCK_LOG="$mock_log" MOCK_MANAGER_SCRIPT_DIR="$mock_root/manager-installers" "$FIRST_SETUP_PATH" > "$output_file" 2>&1; then
		fail_test 'report a manager PATH profile update failure'
		return 1
	fi

	assert_contains '[❌️ERROR] The user .bashrc path is a directory' "$output_file" 'explain why manager PATH could not be updated' || return 1
	assert_not_contains 'Development tool managers are ready' "$output_file" 'do not report success after a PATH profile failure' || return 1
	[[ -d "$home_directory/.bashrc" ]] || fail_test 'preserve the conflicting .bashrc directory' || return 1
}

test_hackgen_installation() {
	local mock_root="$TEST_ROOT/hackgen-installation"
	local mock_bin="$mock_root/bin"
	local mock_log="$mock_root/commands.log"
	local output_file="$mock_root/output.log"
	local error_output="$mock_root/error.log"
	local home_directory="$mock_root/home"
	local font_data_home="$mock_root/data"
	local font_directory="$font_data_home/fonts/HackGen"
	local regular_font="$font_directory/HackGenConsoleNF-Regular.ttf"
	local bold_font="$font_directory/HackGenConsoleNF-Bold.ttf"
	local regular_mode=""

	mkdir -p "$mock_bin" "$home_directory"
	write_fake_installed_managers "$home_directory"
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
	assert_not_contains 'moonrepo.dev/install/proto.sh' "$mock_log" 'skip reinstalling an existing proto manager' || return 1
	assert_not_contains 'mise.run' "$mock_log" 'skip reinstalling an existing mise manager' || return 1
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
run_test 'root execution rejection' test_root_rejection
run_test 'manager installation failure' test_manager_installation_failure
run_test 'mise installation failure' test_mise_installation_failure
run_test 'manager PATH update failure' test_manager_path_failure
run_test 'HackGen installation' test_hackgen_installation

printf '%s\n' "Passed $PASS_COUNT focused first-setup tests."
