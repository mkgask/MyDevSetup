#!/usr/bin/env bash

set -euo pipefail

TESTS_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIRECTORY="$(cd -- "$TESTS_DIRECTORY/.." && pwd)"
HELPER_PATH="$PROJECT_DIRECTORY/templates/dev-tools.sh"
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

prepare_mock_environment() {
	local environment_name="$1"

	MOCK_ROOT="$TEST_ROOT/$environment_name"
	MOCK_BIN="$MOCK_ROOT/bin"
	MOCK_LOG="$MOCK_ROOT/commands.log"
	MOCK_HOME="$MOCK_ROOT/home"
	MOCK_AGENTS="$MOCK_ROOT/AGENTS.md"

	mkdir -p "$MOCK_BIN" "$MOCK_HOME" "$MOCK_ROOT/installers"
	: > "$MOCK_LOG"
	printf '%s\n' '# user content' > "$MOCK_AGENTS"

	HOME="$MOCK_HOME"
	PATH="$MOCK_BIN:/usr/bin:/bin"
	DEV_TOOLS_AGENTS_PATH="$MOCK_AGENTS"
	MOCK_FAIL_TOOL=""
	export HOME PATH DEV_TOOLS_AGENTS_PATH MOCK_ROOT MOCK_BIN MOCK_LOG MOCK_FAIL_TOOL
}

install_failed_tool_stubs() {
	local tool_name=""

	for tool_name in python3 python ruby rg rtk codegraph; do
		write_mock_command "$MOCK_BIN/$tool_name" 'exit 1'
	done
}

prepare_install_mocks() {
	write_mock_command "$MOCK_BIN/apt-get" \
		'if [[ "${1:-}" != "install" ]]; then exit 0; fi' \
		'package_name="${@: -1}"' \
		'tool_name="$package_name"' \
		'case "$package_name" in python3) tool_name=python3 ;; ripgrep) tool_name=rg ;; esac' \
		'printf "system %s\\n" "$*" >> "$MOCK_LOG"' \
		'if [[ "$tool_name" == "$MOCK_FAIL_TOOL" ]]; then exit 1; fi' \
		'printf "%s\\n" "#!/usr/bin/env bash" "exit 0" > "$MOCK_BIN/$tool_name"' \
		'chmod +x "$MOCK_BIN/$tool_name"'
	write_mock_command "$MOCK_BIN/sudo" 'exec "$@"'

	printf '%s\n' \
		'#!/bin/sh' \
		'printf "%s\\n" "official rtk" >> "$MOCK_LOG"' \
		'printf "%s\\n" "#!/usr/bin/env bash" "exit 0" > "$MOCK_BIN/rtk"' \
		'chmod +x "$MOCK_BIN/rtk"' > "$MOCK_ROOT/installers/rtk.sh"
	printf '%s\n' \
		'#!/bin/sh' \
		'printf "%s\\n" "official codegraph" >> "$MOCK_LOG"' \
		'printf "%s\\n" "#!/usr/bin/env bash" "exit 0" > "$MOCK_BIN/codegraph"' \
		'chmod +x "$MOCK_BIN/codegraph"' > "$MOCK_ROOT/installers/codegraph.sh"
	chmod +x "$MOCK_ROOT/installers/rtk.sh" "$MOCK_ROOT/installers/codegraph.sh"

	write_mock_command "$MOCK_BIN/curl" \
		'case "$*" in' \
			'*rtk-ai/rtk*) cat "$MOCK_ROOT/installers/rtk.sh" ;;' \
			'*colbymchenry/codegraph*) cat "$MOCK_ROOT/installers/codegraph.sh" ;;' \
			'*) exit 1 ;;' \
		esac
}

run_helper_with_inputs() {
	local inputs="$1"
	shift
	local output_file="$MOCK_ROOT/output.log"
	local status_file="$MOCK_ROOT/status"
	local command_status=0
	local command=""
	local argument=""
	local quoted_argument=""
	local helper_arguments=""

	for argument in "$@"; do
		printf -v quoted_argument '%q' "$argument"
		helper_arguments+=" $quoted_argument"
	done

	command="env DEV_TOOLS_AGENTS_PATH=\"$MOCK_AGENTS\" HOME=\"$MOCK_HOME\" MOCK_ROOT=\"$MOCK_ROOT\" MOCK_BIN=\"$MOCK_BIN\" MOCK_LOG=\"$MOCK_LOG\" MOCK_FAIL_TOOL=\"$MOCK_FAIL_TOOL\" PATH=\"$PATH\" bash \"$HELPER_PATH\"$helper_arguments; command_status=\$?; printf '%s' \"\$command_status\" > \"$status_file\"; exit \"\$command_status\""
	printf '%s' "$inputs" | script --quiet --flush --command "$command" "$output_file" > "$output_file.stdout" 2>&1 || true
	command_status="$(<"$status_file")"

	cat "$output_file.stdout"
	return "$command_status"
}

test_route_filtering() {
	local routes=""

	prepare_mock_environment route-filtering
	write_mock_command "$MOCK_BIN/apt-get" 'exit 0'
	write_mock_command "$MOCK_BIN/sudo" 'exit 0'
	write_mock_command "$MOCK_BIN/nix" 'exit 0'
	write_mock_command "$MOCK_BIN/proto" 'exit 0'
	write_mock_command "$MOCK_BIN/mise" 'exit 0'
	write_mock_command "$MOCK_BIN/asdf" \
		'if [[ "${1:-}" == "plugin" ]]; then printf "%s\\n" python ruby ripgrep rtk; fi'
	write_mock_command "$MOCK_BIN/curl" 'exit 0'

	source "$HELPER_PATH"

	routes="$(available_routes_for_tool python)"
	assert_equal $'system\nnix\nproto\nmise\nasdf\nskip' "$routes" 'python route filtering' || return 1

	routes="$(available_routes_for_tool rg)"
	assert_equal $'system\nnix\nmise\nasdf\nskip' "$routes" 'rg route filtering' || return 1

	routes="$(available_routes_for_tool rtk)"
	assert_equal $'mise\nasdf\nofficial\nskip' "$routes" 'rtk route filtering' || return 1

	routes="$(available_routes_for_tool codegraph)"
	assert_equal $'official\nskip' "$routes" 'codegraph route filtering' || return 1

	GLOBAL_INSTALL=1
	routes="$(available_routes_for_tool python)"
	assert_equal $'system\nnix\nskip' "$routes" 'global python route filtering' || return 1

	routes="$(available_routes_for_tool rtk)"
	assert_equal $'official\nskip' "$routes" 'global rtk route filtering' || return 1
	GLOBAL_INSTALL=0

	assert_equal 'python' "$(system_package_for_tool python brew)" 'Homebrew Python package' || return 1

	write_mock_command "$MOCK_BIN/proto" \
		'if [[ "${1:-}" == "install" ]]; then printf "%s\\n" "$*" >> "$MOCK_LOG"; exit 0; fi' \
		'if [[ "${1:-}" == "bin" ]]; then printf "%s\\n" "$MOCK_BIN/python3"; exit 0; fi' \
		'exit 0'
	write_mock_command "$MOCK_BIN/python3" 'exit 0'
	install_with_proto python
	assert_contains 'install python latest --yes' "$MOCK_LOG" 'proto installs without persistent pinning' || return 1
	assert_not_contains '--pin' "$MOCK_LOG" 'proto does not write a global pin' || return 1
}

test_no_empty_agents_file() {
	prepare_mock_environment no-empty-agents
	source "$HELPER_PATH"

	AGENTS_PATH="$MOCK_ROOT/missing/AGENTS.md"
	NEW_TOOL_COMMANDS=()
	update_agents_managed_block

	if [[ -e "$AGENTS_PATH" ]]; then
		fail_test 'AGENTS.md was created without a newly installed tool'
	fi
}

test_agents_block_is_add_only_and_idempotent() {
	local first_snapshot="$MOCK_ROOT/first.snapshot"
	local second_snapshot="$MOCK_ROOT/second.snapshot"

	prepare_mock_environment agents-block
	source "$HELPER_PATH"

	AGENTS_PATH="$MOCK_AGENTS"
	NEW_TOOL_COMMANDS[python]=python3
	NEW_TOOL_COMMANDS[rg]=rg
	update_agents_managed_block

	assert_contains '# user content' "$AGENTS_PATH" 'preserve existing AGENTS.md content' || return 1
	assert_contains "$MANAGED_BLOCK_BEGIN" "$AGENTS_PATH" 'create managed block marker' || return 1
	assert_contains '- `python`: `python3`' "$AGENTS_PATH" 'record python command' || return 1
	assert_contains '- `rg`: `rg`' "$AGENTS_PATH" 'record rg command' || return 1

	cp "$AGENTS_PATH" "$first_snapshot"
	update_agents_managed_block
	cp "$AGENTS_PATH" "$second_snapshot"
	cmp -s "$first_snapshot" "$second_snapshot"

	printf '%s\n' '# keep this' "$MANAGED_BLOCK_BEGIN" '## Installed development tools' '- `python`: `python3`' "$MANAGED_BLOCK_END" > "$AGENTS_PATH"
	NEW_TOOL_COMMANDS[ruby]=ruby
	update_agents_managed_block
	assert_contains '# keep this' "$AGENTS_PATH" 'preserve managed-block surrounding content' || return 1
	assert_contains '- `ruby`: `ruby`' "$AGENTS_PATH" 'append new managed-block entry' || return 1
	assert_contains '- `python`: `python3`' "$AGENTS_PATH" 'preserve existing managed-block entry' || return 1

	printf '%s\n' '# incomplete' "$MANAGED_BLOCK_BEGIN" > "$AGENTS_PATH"
	NEW_TOOL_COMMANDS[rg]=rg
	if update_agents_managed_block; then
		fail_test 'incomplete managed block was accepted'
	fi
}

test_interactive_install_and_failure_continuation() {
	local output=""
	local prompt_count=0
	local helper_status=0

	prepare_mock_environment interactive-install
	install_failed_tool_stubs
	prepare_install_mocks

	output="$(run_helper_with_inputs $'1\nsystem\n1\nofficial\n1\n')"
	prompt_count="$(grep -o 'Choose an installation method' <<< "$output" | wc -l)"
	assert_equal '5' "$prompt_count" 'prompt exactly once per missing tool' || return 1
	assert_contains 'Development-tool summary:' "$MOCK_ROOT/output.log.stdout" 'print final summary' || return 1
	assert_contains '- `python`: `python3`' "$MOCK_AGENTS" 'record installed python' || return 1
	assert_contains '- `ruby`: `ruby`' "$MOCK_AGENTS" 'record installed ruby' || return 1
	assert_contains '- `rg`: `rg`' "$MOCK_AGENTS" 'record installed rg' || return 1
	assert_contains '- `rtk`: `rtk`' "$MOCK_AGENTS" 'record installed rtk' || return 1
	assert_contains '- `codegraph`: `codegraph`' "$MOCK_AGENTS" 'record installed codegraph' || return 1

	prepare_mock_environment failure-continuation
	install_failed_tool_stubs
	prepare_install_mocks
	MOCK_FAIL_TOOL=ruby
	export MOCK_FAIL_TOOL
	DEV_TOOLS_DEBUG=1
	export DEV_TOOLS_DEBUG

	if output="$(run_helper_with_inputs $'system\nsystem\nsystem\nofficial\nofficial\n')"; then
		helper_status=0
	else
		helper_status="$?"
	fi
	assert_equal '1' "$helper_status" 'return failure when a tool installation fails' || return 1
	assert_contains 'ruby       failed' "$MOCK_ROOT/output.log.stdout" 'report failed tool' || return 1
	assert_contains 'exit status 1' "$MOCK_ROOT/output.log.stdout" 'report failed operation status' || return 1
	assert_contains 'apt-get install -y ruby' "$MOCK_ROOT/output.log.stdout" 'report failed operation command' || return 1
	assert_not_contains '[DEBUG] Running:' "$MOCK_ROOT/output.log.stdout" 'ignore legacy debug environment variable' || return 1
	assert_not_contains '[🔵DEBUG] Running:' "$MOCK_ROOT/output.log.stdout" 'do not emit trace without debug flag' || return 1
	assert_contains 'rg         installed' "$MOCK_ROOT/output.log.stdout" 'continue after failed tool' || return 1
	assert_not_contains '- `ruby`: `ruby`' "$MOCK_AGENTS" 'do not record failed tool' || return 1
	assert_contains 'official rtk' "$MOCK_LOG" 'run official rtk installer' || return 1
	assert_contains 'official codegraph' "$MOCK_LOG" 'run official codegraph installer' || return 1
	assert_not_contains 'init' "$MOCK_LOG" 'do not run CLI initialization' || return 1

	unset DEV_TOOLS_DEBUG
}

test_debug_flag_and_verification_failure() {
	local output=""
	local helper_status=0

	prepare_mock_environment debug-flag
	install_failed_tool_stubs
	prepare_install_mocks
	write_mock_command "$MOCK_BIN/apt-get" \
		'package_name="${@: -1}"' \
		'printf "system %s\\n" "$*" >> "$MOCK_LOG"' \
		'printf "%s\\n" "#!/usr/bin/env bash" "exit 7" > "$MOCK_BIN/$package_name"' \
		'chmod +x "$MOCK_BIN/$package_name"'

	if output="$(run_helper_with_inputs $'skip\nsystem\nskip\nskip\nskip\n' --debug)"; then
		helper_status=0
	else
		helper_status="$?"
	fi
	assert_equal '1' "$helper_status" 'return failure when command verification fails' || return 1
	assert_contains '[🔵DEBUG] Running: ruby --version' "$MOCK_ROOT/output.log.stdout" 'emit debug trace with explicit flag' || return 1
	assert_not_contains '[DEBUG] Running:' "$MOCK_ROOT/output.log.stdout" 'remove legacy debug label' || return 1
	assert_contains 'ruby       failed' "$MOCK_ROOT/output.log.stdout" 'report command verification failure' || return 1
	assert_contains 'exit status 7' "$MOCK_ROOT/output.log.stdout" 'report verification status' || return 1
	assert_contains 'command: ruby --version' "$MOCK_ROOT/output.log.stdout" 'report verification command' || return 1
}

run_helper_mode() {
	local mode="$1"
	local output_file="$MOCK_ROOT/output.log"
	local command_status=0

	if env DEV_TOOLS_AGENTS_PATH="$MOCK_AGENTS" HOME="$MOCK_HOME" MOCK_ROOT="$MOCK_ROOT" MOCK_BIN="$MOCK_BIN" MOCK_LOG="$MOCK_LOG" MOCK_FAIL_TOOL="$MOCK_FAIL_TOOL" PATH="$PATH" bash "$HELPER_PATH" "$mode" > "$output_file" 2>&1; then
		command_status=0
	else
		command_status="$?"
	fi

	cat "$output_file"
	return "$command_status"
}

test_mode_parsing_and_logging() {
	local parse_status=0
	local warning_output=""
	local error_output=""
	local success_output=""
	local usage_output_file="$MOCK_ROOT/usage.output"

	prepare_mock_environment mode-and-logging
	source "$HELPER_PATH"

	if ! parse_args --debug --global; then
		fail_test 'debug and global flags were rejected'
		return 1
	fi
	assert_equal '1' "$DEBUG_ENABLED" 'debug flag state' || return 1
	assert_equal '1' "$GLOBAL_INSTALL" 'global flag state with debug' || return 1

	parse_args --global
	assert_equal 'install' "$DEV_TOOLS_MODE" 'global defaults to install mode' || return 1
	assert_equal '1' "$GLOBAL_INSTALL" 'global flag state' || return 1
	assert_equal '0' "$DEBUG_ENABLED" 'debug flag resets between parses' || return 1

	if ! parse_args init --debug; then
		fail_test 'debug flag was rejected for init mode'
		return 1
	fi
	assert_equal 'init' "$DEV_TOOLS_MODE" 'init mode with debug flag' || return 1
	assert_equal '1' "$DEBUG_ENABLED" 'debug flag state for init mode' || return 1

	if parse_args init --global; then
		fail_test 'init --global was accepted'
	else
		parse_status="$?"
	fi
	assert_equal '2' "$parse_status" 'init --global parse status' || return 1

	warning_output="$(NO_COLOR=1 log_warning warning)"
	error_output="$(NO_COLOR=1 log_error error 2>&1)"
	success_output="$(NO_COLOR=1 log_success success)"
	assert_equal '[⚠️WARNING] warning' "$warning_output" 'warning log contract' || return 1
	assert_equal '[❌️ERROR] error' "$error_output" 'error log contract' || return 1
	assert_equal '[✅️SUCCESS] success' "$success_output" 'success log contract' || return 1
	print_usage > "$usage_output_file"
	assert_contains 'dev-tools.sh [install|init] [--global] [--debug]' "$usage_output_file" 'document debug flag' || return 1
	assert_not_contains 'DEV_TOOLS_DEBUG' "$usage_output_file" 'remove debug environment variable documentation' || return 1
}

write_init_tool_mocks() {
	write_mock_command "$MOCK_BIN/rtk" \
		'if [[ "${1:-}" == "--version" ]]; then exit 0; fi' \
		'printf "rtk %s\\n" "$*" >> "$MOCK_LOG"' \
		'exit 0'
	write_mock_command "$MOCK_BIN/codegraph" \
		'if [[ "${1:-}" == "--version" ]]; then exit 0; fi' \
		'printf "codegraph %s\\n" "$*" >> "$MOCK_LOG"' \
		'exit 0'
}

test_project_init_mode() {
	local output=""
	local agents_snapshot=""
	local helper_status=0

	prepare_mock_environment project-init
	install_failed_tool_stubs
	write_init_tool_mocks
	agents_snapshot="$(mktemp)"
	cp "$MOCK_AGENTS" "$agents_snapshot"

	output="$(run_helper_mode init)"
	assert_not_contains 'Choose an installation method' "$MOCK_ROOT/output.log" 'init does not prompt for installation' || return 1
	grep -Eq '^  rtk[[:space:]]+initialized[[:space:]]' "$MOCK_ROOT/output.log" || fail_test 'initialize installed RTK' || return 1
	grep -Eq '^  codegraph[[:space:]]+initialized[[:space:]]' "$MOCK_ROOT/output.log" || fail_test 'initialize installed CodeGraph' || return 1
	grep -Eq '^  python[[:space:]]+skipped[[:space:]]' "$MOCK_ROOT/output.log" || fail_test 'skip tools without project initialization' || return 1
	assert_contains 'rtk init' "$MOCK_LOG" 'run local RTK initialization' || return 1
	assert_contains 'codegraph install --target=auto --location=local --yes' "$MOCK_LOG" 'run local CodeGraph agent setup' || return 1
	assert_contains 'codegraph init' "$MOCK_LOG" 'run CodeGraph project initialization' || return 1
	cmp -s "$agents_snapshot" "$MOCK_AGENTS" || fail_test 'init changed AGENTS.md through install recording' || return 1
	rm -f "$agents_snapshot"

	prepare_mock_environment project-init-failure
	install_failed_tool_stubs
	write_init_tool_mocks
	write_mock_command "$MOCK_BIN/rtk" \
		'if [[ "${1:-}" == "--version" ]]; then exit 0; fi' \
		'printf "rtk %s\\n" "$*" >> "$MOCK_LOG"' \
		'exit 1'

	if output="$(run_helper_mode init)"; then
		helper_status=0
	else
		helper_status="$?"
	fi
	assert_equal '1' "$helper_status" 'return failure when project initialization fails' || return 1
	grep -Eq '^  rtk[[:space:]]+failed[[:space:]]' "$MOCK_ROOT/output.log" || fail_test 'report RTK init failure' || return 1
	assert_contains 'exit status 1' "$MOCK_ROOT/output.log" 'report initialization status' || return 1
	assert_contains 'command: rtk init' "$MOCK_ROOT/output.log" 'report initialization command' || return 1
	grep -Eq '^  codegraph[[:space:]]+initialized[[:space:]]' "$MOCK_ROOT/output.log" || fail_test 'continue with CodeGraph after RTK failure' || return 1
}

test_default_route_and_skip_selection() {
	local output=""

	prepare_mock_environment defaults-and-skip
	install_failed_tool_stubs
	prepare_install_mocks

	output="$(run_helper_with_inputs $'\n\nskip\n\nskip\n')"
	assert_contains 'python     installed' "$MOCK_ROOT/output.log.stdout" 'blank input selects python default' || return 1
	assert_contains 'ruby       installed' "$MOCK_ROOT/output.log.stdout" 'blank input selects ruby default' || return 1
	assert_contains 'rg         skipped' "$MOCK_ROOT/output.log.stdout" 'skip leaves rg uninstalled' || return 1
	assert_contains 'rtk        installed' "$MOCK_ROOT/output.log.stdout" 'blank input selects rtk default' || return 1
	assert_contains 'codegraph  skipped' "$MOCK_ROOT/output.log.stdout" 'skip leaves codegraph uninstalled' || return 1
	assert_contains '- `python`: `python3`' "$MOCK_AGENTS" 'record default-installed python' || return 1
	assert_contains '- `ruby`: `ruby`' "$MOCK_AGENTS" 'record default-installed ruby' || return 1
	assert_contains '- `rtk`: `rtk`' "$MOCK_AGENTS" 'record default-installed rtk' || return 1
	assert_not_contains '- `rg`: `rg`' "$MOCK_AGENTS" 'do not record skipped rg' || return 1
	assert_not_contains '- `codegraph`: `codegraph`' "$MOCK_AGENTS" 'do not record skipped codegraph' || return 1
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

run_test 'route filtering' test_route_filtering
run_test 'no empty AGENTS.md' test_no_empty_agents_file
run_test 'AGENTS.md managed block' test_agents_block_is_add_only_and_idempotent
run_test 'interactive install and failure continuation' test_interactive_install_and_failure_continuation
run_test 'debug flag and verification failure' test_debug_flag_and_verification_failure
run_test 'default routes and skip selection' test_default_route_and_skip_selection
run_test 'mode parsing and logging' test_mode_parsing_and_logging
run_test 'project initialization mode' test_project_init_mode

printf '%s\n' "Passed $PASS_COUNT focused dev-tools tests."