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
	write_mock_command "$MOCK_ROOT/installers/serena-command" \
		'if [[ "${1:-}" == "--version" ]]; then exit 0; fi' \
		'printf "serena %s\\n" "$*" >> "$MOCK_LOG"' \
		'if [[ "${1:-}" == "init" ]]; then exit 0; fi' \
		'if [[ "${1:-}" == "start-mcp-server" && "${2:-}" == "--help" ]]; then exit 0; fi' \
		'exit 1'
	write_mock_command "$MOCK_ROOT/installers/uv-command" \
		'if [[ "${1:-}" == "--version" ]]; then exit 0; fi' \
		'if [[ "${1:-}" == "tool" && "${2:-}" == "dir" && "${3:-}" == "--bin" ]]; then printf "%s\\n" "$HOME/.local/bin"; exit 0; fi' \
		'if [[ "${1:-}" == "tool" && "${2:-}" == "install" ]]; then printf "uv %s\\n" "$*" >> "$MOCK_LOG"; cp "$MOCK_ROOT/installers/serena-command" "$HOME/.local/bin/serena"; chmod +x "$HOME/.local/bin/serena"; exit 0; fi' \
		'exit 1'
	printf '%s\n' \
		'#!/bin/sh' \
		'[ "${MOCK_FAIL_TOOL:-}" = "uv" ] && exit 1' \
		'mkdir -p "$HOME/.local/bin"' \
		'printf "%s\\n" "official uv" >> "$MOCK_LOG"' \
		'cp "$MOCK_ROOT/installers/uv-command" "$HOME/.local/bin/uv"' \
		'chmod +x "$HOME/.local/bin/uv"' > "$MOCK_ROOT/installers/uv.sh"
	chmod +x "$MOCK_ROOT/installers/rtk.sh" "$MOCK_ROOT/installers/codegraph.sh" "$MOCK_ROOT/installers/uv.sh"

	write_mock_command "$MOCK_BIN/curl" \
		'case "$*" in' \
			'*rtk-ai/rtk*) cat "$MOCK_ROOT/installers/rtk.sh" ;;' \
			'*colbymchenry/codegraph*) cat "$MOCK_ROOT/installers/codegraph.sh" ;;' \
			'*astral.sh/uv/install.sh*) cat "$MOCK_ROOT/installers/uv.sh" ;;' \
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
	write_mock_command "$MOCK_BIN/nix" \
		'if [[ "${1:-}" == "profile" && "${2:-}" == "install" && "${3:-}" == "--help" ]]; then exit 0; fi' \
		'if [[ "${1:-}" == "eval" ]]; then case "$*" in *"nixpkgs#python3.name"*|*"nixpkgs#ruby.name"*|*"nixpkgs#ripgrep.name"*) exit 0 ;; *) exit 1 ;; esac; fi' \
		'exit 1'
	write_mock_command "$MOCK_BIN/proto" 'exit 0'
	write_mock_command "$MOCK_BIN/mise" \
		'if [[ "${1:-}" != "registry" ]]; then exit 1; fi' \
		'[[ "${2:-}" == "python" || "${2:-}" == "ruby" || "${2:-}" == "ripgrep" || "${2:-}" == "rtk" ]]'
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

	routes="$(available_routes_for_tool uv)"
	assert_equal $'official\nskip' "$routes" 'uv official route filtering' || return 1

	routes="$(available_routes_for_tool serena)"
	assert_equal $'skip' "$routes" 'Serena requires uv for route filtering' || return 1

	write_mock_command "$MOCK_BIN/uv" 'exit 0'
	routes="$(available_routes_for_tool serena)"
	assert_equal $'uv-tool\nskip' "$routes" 'Serena uv-tool route filtering' || return 1
	assert_equal 'serena-agent' "$(uv_tool_package_for_tool serena)" 'Serena uv package mapping' || return 1

	GLOBAL_INSTALL=1
	routes="$(available_routes_for_tool python)"

test_brew_route_is_explicit() {
	local original_path="$PATH"
	local routes=""
	local global_routes=""
	local planned_command=""

	prepare_mock_environment brew-route
	write_mock_command "$MOCK_BIN/brew" \
		'printf "brew %s\\n" "$*" >> "$MOCK_LOG"'
	write_mock_command "$MOCK_BIN/asdf" \
		'if [[ "${1:-}" == "plugin" && "${2:-}" == "list" ]]; then printf "%s\\n" python; exit 0; fi' \
		'exit 1'
	write_mock_command "$MOCK_BIN/grep" 'exit 0'
	ln -s "$(command -v bash)" "$MOCK_BIN/bash"
	PATH="$MOCK_BIN"
	export PATH
	source "$HELPER_PATH"

	routes="$(available_routes_for_tool python)"
	planned_command="$(planned_install_command_for_route python brew)"

	GLOBAL_INSTALL=1
	global_routes="$(available_routes_for_tool python)"
	GLOBAL_INSTALL=0

	install_with_route python brew
	PATH="$original_path"
	export PATH

	assert_equal $'asdf\nbrew\nskip' "$routes" 'brew is an explicit route after asdf' || return 1
	assert_equal 'brew install python' "$planned_command" 'preview brew command' || return 1
	assert_equal 'python' "$(system_package_for_tool python brew)" 'brew Python package mapping' || return 1
	assert_equal 'ruby' "$(system_package_for_tool ruby brew)" 'brew Ruby package mapping' || return 1
	assert_equal 'ripgrep' "$(system_package_for_tool rg brew)" 'brew ripgrep package mapping' || return 1
	assert_equal $'brew\nskip' "$global_routes" 'global brew route filtering' || return 1
	assert_contains 'brew install python' "$MOCK_LOG" 'brew route executes brew install' || return 1
}
	assert_equal $'system\nnix\nskip' "$routes" 'global python route filtering' || return 1

	routes="$(available_routes_for_tool rtk)"
	assert_equal $'official\nskip' "$routes" 'global rtk route filtering' || return 1

	routes="$(available_routes_for_tool serena)"
	assert_equal $'uv-tool\nskip' "$routes" 'global Serena route filtering' || return 1
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

test_manager_capability_probes() {
	local routes=""

	prepare_mock_environment manager-capability-probes
	write_mock_command "$MOCK_BIN/nix" \
		'if [[ "${1:-}" == "profile" && "${2:-}" == "install" && "${3:-}" == "--help" ]]; then exit 0; fi' \
		'if [[ "${1:-}" == "eval" ]]; then printf "%s\n" "nix capability result"; [[ "$*" == *"nixpkgs#codegraph.name"* ]]; exit $?; fi' \
		'exit 1'
	write_mock_command "$MOCK_BIN/mise" \
		'if [[ "${1:-}" != "registry" ]]; then exit 1; fi' \
		'printf "%s\n" "mise capability result"' \
		'[[ "${2:-}" == "codegraph" || "${2:-}" == "ripgrep" ]]'
	write_mock_command "$MOCK_BIN/asdf" \
		'printf "%s\n" "$*" >> "$MOCK_LOG"' \
		'if [[ "${1:-}" != "plugin" || "${2:-}" != "list" ]]; then exit 1; fi' \
		'printf "%s\n" ripgrep codegraph'
	write_mock_command "$MOCK_BIN/curl" 'exit 0'

	source "$HELPER_PATH"

	assert_equal 'codegraph' "$(nix_package_for_tool codegraph)" 'Nix probe returns a newly supported package' || return 1
	assert_equal 'codegraph' "$(mise_tool_for_tool codegraph)" 'mise probe returns a newly supported tool' || return 1
	assert_equal 'ripgrep' "$(mise_tool_for_tool rg)" 'mise probe preserves the ripgrep alias' || return 1
	assert_equal 'codegraph' "$(asdf_plugin_for_tool codegraph)" 'asdf probe finds an installed plugin by tool name' || return 1
	assert_equal 'ripgrep' "$(asdf_plugin_for_tool rg)" 'asdf probe preserves the ripgrep alias' || return 1

	routes="$(available_routes_for_tool codegraph)"
	assert_equal $'nix\nmise\nasdf\nofficial\nskip' "$routes" 'manager probes control dynamically supported routes' || return 1
	assert_not_contains 'capability result' <(printf '%s\n' "$routes") 'probe output does not leak into route data' || return 1
	assert_not_contains 'plugin list all' "$MOCK_LOG" 'asdf probe does not query remote plugins' || return 1
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
	local uv_install_line=""
	local serena_install_line=""

	prepare_mock_environment interactive-install
	install_failed_tool_stubs
	prepare_install_mocks

	output="$(run_helper_with_inputs $'1\nsystem\n1\nofficial\n1\n1\n1\n')"
	prompt_count="$(grep -o 'Choose an installation method' <<< "$output" | wc -l)"
	assert_equal '7' "$prompt_count" 'prompt exactly once per missing tool' || return 1
	assert_contains 'Development-tool summary:' "$MOCK_ROOT/output.log.stdout" 'print final summary' || return 1
	assert_contains '- `python`: `python3`' "$MOCK_AGENTS" 'record installed python' || return 1
	assert_contains '- `ruby`: `ruby`' "$MOCK_AGENTS" 'record installed ruby' || return 1
	assert_contains '- `rg`: `rg`' "$MOCK_AGENTS" 'record installed rg' || return 1
	assert_contains '- `rtk`: `rtk`' "$MOCK_AGENTS" 'record installed rtk' || return 1
	assert_contains '- `codegraph`: `codegraph`' "$MOCK_AGENTS" 'record installed codegraph' || return 1
	assert_contains '- `uv`: `uv`' "$MOCK_AGENTS" 'record installed uv' || return 1
	assert_contains '- `serena`: `serena`' "$MOCK_AGENTS" 'record installed Serena' || return 1

	prepare_mock_environment failure-continuation
	install_failed_tool_stubs
	prepare_install_mocks
	MOCK_FAIL_TOOL=ruby
	export MOCK_FAIL_TOOL
	DEV_TOOLS_DEBUG=1
	export DEV_TOOLS_DEBUG

	if output="$(run_helper_with_inputs $'system\nsystem\nsystem\nofficial\nofficial\nofficial\nuv-tool\n')"; then
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
	assert_contains 'official uv' "$MOCK_LOG" 'run official uv installer' || return 1
	assert_contains 'uv tool install -p 3.13 serena-agent' "$MOCK_LOG" 'install Serena through uv' || return 1
	uv_install_line="$(grep -n -m1 '^official uv$' "$MOCK_LOG" | cut -d: -f1)"
	serena_install_line="$(grep -n -m1 '^uv tool install -p 3.13 serena-agent$' "$MOCK_LOG" | cut -d: -f1)"
	if ! (( uv_install_line < serena_install_line )); then
		fail_test 'uv was not installed before Serena'
		return 1
	fi
	assert_not_contains 'init' "$MOCK_LOG" 'do not run CLI initialization' || return 1

	unset DEV_TOOLS_DEBUG
}

test_uv_dependency_failure() {
	local output=""
	local helper_status=0

	prepare_mock_environment uv-dependency-failure
	install_failed_tool_stubs
	prepare_install_mocks
	MOCK_FAIL_TOOL=uv
	export MOCK_FAIL_TOOL

	if output="$(run_helper_with_inputs $'skip\nskip\nskip\nskip\nskip\nofficial\n')"; then
		helper_status=0
	else
		helper_status="$?"
	fi
	assert_equal '1' "$helper_status" 'return failure when uv installation fails' || return 1
	assert_contains 'uv         failed' "$MOCK_ROOT/output.log.stdout" 'report failed uv installation' || return 1
	assert_contains 'exit status 1' "$MOCK_ROOT/output.log.stdout" 'report uv failure status' || return 1
	assert_contains 'curl --proto' "$MOCK_ROOT/output.log.stdout" 'report uv installer command' || return 1
	assert_contains 'serena     skipped' "$MOCK_ROOT/output.log.stdout" 'skip Serena when uv is unavailable' || return 1
	assert_not_contains 'uv tool install' "$MOCK_LOG" 'do not install Serena after uv failure' || return 1

	unset MOCK_FAIL_TOOL
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

	if output="$(run_helper_with_inputs $'skip\nsystem\nskip\nskip\nskip\nskip\nskip\n' --debug)"; then
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
	shift
	local output_file="$MOCK_ROOT/output.log"
	local command_status=0

	if env DEV_TOOLS_AGENTS_PATH="$MOCK_AGENTS" HOME="$MOCK_HOME" MOCK_ROOT="$MOCK_ROOT" MOCK_BIN="$MOCK_BIN" MOCK_LOG="$MOCK_LOG" MOCK_FAIL_TOOL="$MOCK_FAIL_TOOL" PATH="$PATH" bash "$HELPER_PATH" "$mode" "$@" </dev/null > "$output_file" 2>&1; then
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

	if ! parse_args status --debug; then
		fail_test 'debug flag was rejected for status mode'
		return 1
	fi
	assert_equal 'status' "$DEV_TOOLS_MODE" 'status mode with debug flag' || return 1
	assert_equal '1' "$DEBUG_ENABLED" 'debug flag state for status mode' || return 1

	if ! parse_args install --dry-run --global --debug; then
		fail_test 'dry-run flag was rejected for install mode'
		return 1
	fi
	assert_equal 'install' "$DEV_TOOLS_MODE" 'dry-run install mode' || return 1
	assert_equal '1' "$DRY_RUN" 'dry-run flag state' || return 1
	assert_equal '1' "$GLOBAL_INSTALL" 'global flag state with dry-run' || return 1

	if parse_args init --dry-run; then
		fail_test 'init --dry-run was accepted'
	else
		parse_status="$?"
	fi
	assert_equal '2' "$parse_status" 'init --dry-run parse status' || return 1

	if parse_args status --dry-run; then
		fail_test 'status --dry-run was accepted'
	else
		parse_status="$?"
	fi
	assert_equal '2' "$parse_status" 'status --dry-run parse status' || return 1

	if parse_args init --global; then
		fail_test 'init --global was accepted'
	else
		parse_status="$?"
	fi
	assert_equal '2' "$parse_status" 'init --global parse status' || return 1

	if parse_args status --global; then
		fail_test 'status --global was accepted'
	else
		parse_status="$?"
	fi
	assert_equal '2' "$parse_status" 'status --global parse status' || return 1

	warning_output="$(NO_COLOR=1 log_warning warning)"
	error_output="$(NO_COLOR=1 log_error error 2>&1)"
	success_output="$(NO_COLOR=1 log_success success)"
	assert_equal '[⚠️WARNING] warning' "$warning_output" 'warning log contract' || return 1
	assert_equal '[❌️ERROR] error' "$error_output" 'error log contract' || return 1
	assert_equal '[✅️SUCCESS] success' "$success_output" 'success log contract' || return 1
	print_usage > "$usage_output_file"
	assert_contains 'dev-tools.sh [install|init|status] [--global] [--debug] [--dry-run]' "$usage_output_file" 'document status, debug, and dry-run flags' || return 1
	assert_not_contains 'DEV_TOOLS_DEBUG' "$usage_output_file" 'remove debug environment variable documentation' || return 1
}

test_dry_run_mode() {
	local output=""
	local helper_status=0
	local agents_snapshot=""

	prepare_mock_environment dry-run
	install_failed_tool_stubs
	prepare_install_mocks
	agents_snapshot="$(mktemp)"
	cp "$MOCK_AGENTS" "$agents_snapshot"

	if output="$(run_helper_mode install --dry-run)"; then
		helper_status=0
	else
		helper_status="$?"
	fi
	assert_equal '0' "$helper_status" 'non-interactive dry-run succeeds' || return 1
	assert_contains 'Development-tool dry-run:' "$MOCK_ROOT/output.log" 'print dry-run title' || return 1
	grep -Eq '^  python[[:space:]]+planned[[:space:]]+system: .*apt-get install -y python3' "$MOCK_ROOT/output.log" || fail_test 'preview the default system route for python' || return 1
	grep -Eq '^  rtk[[:space:]]+planned[[:space:]]+official: .*rtk' "$MOCK_ROOT/output.log" || fail_test 'preview the default official route for RTK' || return 1
	grep -Eq '^  uv[[:space:]]+planned[[:space:]]+official: .*uv/install.sh' "$MOCK_ROOT/output.log" || fail_test 'preview the default official route for uv' || return 1
	grep -Eq '^  serena[[:space:]]+skipped[[:space:]]+' "$MOCK_ROOT/output.log" || fail_test 'skip Serena without an available uv route' || return 1
	assert_not_contains 'Choose an installation method' "$MOCK_ROOT/output.log" 'non-interactive dry-run does not prompt' || return 1
	assert_not_contains 'install' "$MOCK_LOG" 'dry-run does not execute installation commands' || return 1
	cmp -s "$agents_snapshot" "$MOCK_AGENTS" || fail_test 'dry-run changed AGENTS.md' || return 1

	prepare_mock_environment dry-run-interactive
	install_failed_tool_stubs
	prepare_install_mocks
	write_mock_command "$MOCK_BIN/brew" 'exit 0'
	write_mock_command "$MOCK_BIN/nix" \
		'if [[ "${1:-}" == "profile" && "${2:-}" == "install" && "${3:-}" == "--help" ]]; then exit 0; fi' \
		'if [[ "${1:-}" == "eval" ]]; then exit 0; fi' \
		'exit 1'

	if output="$(run_helper_with_inputs $'brew\nsystem\nsystem\nofficial\nofficial\nofficial\n' install --dry-run)"; then
		helper_status=0
	else
		helper_status="$?"
	fi
	assert_equal '0' "$helper_status" 'interactive dry-run succeeds' || return 1
	assert_contains 'python     planned   brew: brew install python' "$MOCK_ROOT/output.log.stdout" 'preview the interactively selected brew route' || return 1
	assert_not_contains 'install python latest' "$MOCK_LOG" 'interactive dry-run does not execute manager commands' || return 1
	assert_not_contains 'brew install' "$MOCK_LOG" 'interactive dry-run does not execute brew commands' || return 1
}

test_dry_run_planned_commands() {
	local expected_system_command=""
	local official_command=""

	prepare_mock_environment dry-run-planned-commands
	write_mock_command "$MOCK_BIN/apt-get" 'exit 0'
	write_mock_command "$MOCK_BIN/sudo" 'exit 0'
	write_mock_command "$MOCK_BIN/brew" 'printf "brew %s\\n" "$*" >> "$MOCK_LOG"'
	write_mock_command "$MOCK_BIN/nix" 'exit 0'
	write_mock_command "$MOCK_BIN/proto" 'exit 0'
	write_mock_command "$MOCK_BIN/mise" \
		'if [[ "${1:-}" == "registry" ]]; then exit 0; fi' \
		'exit 1'
	write_mock_command "$MOCK_BIN/asdf" \
		'if [[ "${1:-}" == "plugin" && "${2:-}" == "list" ]]; then printf "%s\n" ripgrep; exit 0; fi' \
		'exit 1'
	source "$HELPER_PATH"

	if [[ "$EUID" -eq 0 ]]; then
		expected_system_command='apt-get install -y python3'
	else
		expected_system_command='sudo apt-get install -y python3'
	fi
	assert_equal "$expected_system_command" "$(planned_install_command_for_route python system)" 'preview system command' || return 1
	assert_equal 'nix profile install nixpkgs#python3' "$(planned_install_command_for_route python nix)" 'preview nix command' || return 1
	assert_equal 'proto install python latest --yes' "$(planned_install_command_for_route python proto)" 'preview proto command' || return 1
	assert_equal 'mise install python@latest' "$(planned_install_command_for_route python mise)" 'preview mise command' || return 1
	assert_equal 'asdf install ripgrep latest' "$(planned_install_command_for_route rg asdf)" 'preview asdf alias command' || return 1
	assert_equal 'brew install python' "$(planned_install_command_for_route python brew)" 'preview brew command' || return 1
	official_command="$(planned_install_command_for_route rtk official)"
	assert_contains 'rtk-ai/rtk' <(printf '%s\n' "$official_command") 'preview official installer URL' || return 1
	assert_equal 'uv tool install -p 3.13 serena-agent' "$(planned_install_command_for_route serena uv-tool)" 'preview uv-tool command' || return 1
}

test_dry_run_official_routes_without_curl() {
	local original_path="$PATH"
	local no_curl_bin=""
	local rtk_routes=""
	local codegraph_routes=""
	local uv_routes=""
	local normal_rtk_routes=""
	local rtk_planned_command=""
	local codegraph_planned_command=""
	local uv_planned_command=""

	prepare_mock_environment dry-run-official-no-curl
	no_curl_bin="$MOCK_ROOT/no-curl-bin"
	mkdir -p "$no_curl_bin"
	ln -s "$(command -v grep)" "$no_curl_bin/grep"
	PATH="$MOCK_BIN:$no_curl_bin"
	export PATH
	source "$HELPER_PATH"

	DRY_RUN=1
	rtk_routes="$(available_routes_for_tool rtk)"
	codegraph_routes="$(available_routes_for_tool codegraph)"
	uv_routes="$(available_routes_for_tool uv)"
	rtk_planned_command="$(planned_install_command_for_route rtk official)"
	codegraph_planned_command="$(planned_install_command_for_route codegraph official)"
	uv_planned_command="$(planned_install_command_for_route uv official)"

	DRY_RUN=0
	normal_rtk_routes="$(available_routes_for_tool rtk)"

	PATH="$original_path"
	export PATH

	assert_equal $'official\nskip' "$rtk_routes" 'dry-run previews RTK official route without curl' || return 1
	assert_equal $'official\nskip' "$codegraph_routes" 'dry-run previews CodeGraph official route without curl' || return 1
	assert_equal $'official\nskip' "$uv_routes" 'dry-run previews uv official route without curl' || return 1
	assert_contains 'rtk-ai/rtk' <(printf '%s\n' "$rtk_planned_command") 'preview RTK official URL without curl' || return 1
	assert_contains 'colbymchenry/codegraph' <(printf '%s\n' "$codegraph_planned_command") 'preview CodeGraph official URL without curl' || return 1
	assert_contains 'astral.sh/uv/install.sh' <(printf '%s\n' "$uv_planned_command") 'preview uv official URL without curl' || return 1
	assert_equal 'skip' "$normal_rtk_routes" 'normal install keeps official route unavailable without curl' || return 1
}

test_status_mode() {
	local output=""
	local helper_status=0
	local agents_snapshot=""
	local package_manager_status_line=""
	local tool_status_line=""
	local uv_status_count=""

	prepare_mock_environment status-unavailable
	install_failed_tool_stubs
	write_mock_command "$MOCK_BIN/python3" \
		'if [[ "${1:-}" == "--version" ]]; then printf "%s\n" "Python 3.13.5"; exit 0; fi' \
		'exit 1'
	write_mock_command "$MOCK_BIN/ruby" \
		'if [[ "${1:-}" == "--version" ]]; then printf "%s\n" "ruby 3.4.1"; exit 0; fi' \
		'exit 1'
	write_mock_command "$MOCK_BIN/uv" \
		'if [[ "${1:-}" == "--version" ]]; then printf "%s\n" "uv 0.8.0"; exit 0; fi' \
		'exit 1'
	write_mock_command "$MOCK_BIN/apt-get" \
		'if [[ "${1:-}" == "--version" ]]; then printf "%s\\n" "apt 2.6.1"; exit 0; fi' \
		'exit 1'
	write_mock_command "$MOCK_BIN/brew" \
		'if [[ "${1:-}" == "--version" ]]; then printf "%s\\n" "Homebrew 4.5.0"; exit 0; fi' \
		'exit 1'
	write_mock_command "$MOCK_BIN/nix" 'exit 9'
	agents_snapshot="$(mktemp)"
	cp "$MOCK_AGENTS" "$agents_snapshot"

	if output="$(run_helper_mode status)"; then
		helper_status=0
	else
		helper_status="$?"
	fi
	assert_equal '1' "$helper_status" 'status reports unavailable tools' || return 1
	assert_contains 'Development-tool status:' "$MOCK_ROOT/output.log" 'status title' || return 1
	package_manager_status_line="$(grep -n -m1 '^Package-manager status:$' "$MOCK_ROOT/output.log" | cut -d: -f1)"
	tool_status_line="$(grep -n -m1 '^Development-tool status:$' "$MOCK_ROOT/output.log" | cut -d: -f1)"
	if ! (( package_manager_status_line < tool_status_line )); then
		fail_test 'package-manager status is displayed before tool status'
		return 1
	fi
	assert_contains "python     present   3.13.5 $MOCK_BIN/python3" "$MOCK_ROOT/output.log" 'status reports python version and path' || return 1
	assert_contains "ruby       present   3.4.1 $MOCK_BIN/ruby" "$MOCK_ROOT/output.log" 'status reports ruby version and path' || return 1
	assert_contains "uv         present   0.8.0 $MOCK_BIN/uv" "$MOCK_ROOT/output.log" 'status reports uv version and path' || return 1
	uv_status_count="$(grep -Ec '^  uv[[:space:]]+' "$MOCK_ROOT/output.log")"
	assert_equal '1' "$uv_status_count" 'status reports uv only in the tool section' || return 1
	assert_contains 'Package-manager status:' "$MOCK_ROOT/output.log" 'status title for package managers' || return 1
	assert_contains "apt-get    present   2.6.1 $MOCK_BIN/apt-get" "$MOCK_ROOT/output.log" 'status reports package manager version and path' || return 1
	assert_contains "brew       present   4.5.0 $MOCK_BIN/brew" "$MOCK_ROOT/output.log" 'status reports brew version and path' || return 1
	assert_contains 'nix        unavailable' "$MOCK_ROOT/output.log" 'status reports package manager version failure' || return 1
	assert_contains 'command: nix --version' "$MOCK_ROOT/output.log" 'status preserves package manager diagnostics' || return 1
	assert_contains 'rg         unavailable' "$MOCK_ROOT/output.log" 'status reports unavailable rg' || return 1
	assert_contains 'rtk        unavailable' "$MOCK_ROOT/output.log" 'status reports version failure' || return 1
	assert_contains 'codegraph  unavailable' "$MOCK_ROOT/output.log" 'status reports missing codegraph' || return 1
	assert_contains 'serena     unavailable' "$MOCK_ROOT/output.log" 'status reports missing Serena' || return 1
	assert_contains 'command: rtk --version' "$MOCK_ROOT/output.log" 'status preserves version diagnostics' || return 1
	assert_not_contains 'Choose an installation method' "$MOCK_ROOT/output.log" 'status does not prompt' || return 1
	assert_not_contains 'install' "$MOCK_LOG" 'status does not install tools' || return 1
	assert_not_contains 'init' "$MOCK_LOG" 'status does not initialize tools' || return 1
	cmp -s "$agents_snapshot" "$MOCK_AGENTS" || fail_test 'status changed AGENTS.md' || return 1

	if output="$(run_helper_with_inputs '' status --debug)"; then
		helper_status=0
	else
		helper_status="$?"
	fi
	assert_equal '1' "$helper_status" 'debug status preserves unavailable exit status' || return 1
	assert_contains '[🔵DEBUG] Running: python3 --version' "$MOCK_ROOT/output.log.stdout" 'status emits version trace with explicit debug flag' || return 1
	rm -f "$agents_snapshot"

	prepare_mock_environment status-available
	for command_name in python3 ruby rg rtk codegraph uv serena; do
		write_mock_command "$MOCK_BIN/$command_name" \
			'if [[ "${1:-}" == "--version" ]]; then exit 0; fi' \
			'exit 1'
	done
	write_mock_command "$MOCK_BIN/apt-get" 'exit 1'
	agents_snapshot="$(mktemp)"
	cp "$MOCK_AGENTS" "$agents_snapshot"

	if output="$(run_helper_mode status)"; then
		helper_status=0
	else
		helper_status="$?"
	fi
	assert_equal '0' "$helper_status" 'status succeeds when all tools are available' || return 1
	assert_contains 'Development-tool status:' "$MOCK_ROOT/output.log" 'status title for available tools' || return 1
	assert_contains 'apt-get    unavailable' "$MOCK_ROOT/output.log" 'manager absence is informational' || return 1
	assert_not_contains 'python     unavailable' "$MOCK_ROOT/output.log" 'python is available' || return 1
	assert_not_contains 'ruby       unavailable' "$MOCK_ROOT/output.log" 'ruby is available' || return 1
	assert_not_contains 'rg         unavailable' "$MOCK_ROOT/output.log" 'rg is available' || return 1
	assert_not_contains 'rtk        unavailable' "$MOCK_ROOT/output.log" 'rtk is available' || return 1
	assert_not_contains 'codegraph  unavailable' "$MOCK_ROOT/output.log" 'codegraph is available' || return 1
	assert_not_contains 'uv         unavailable' "$MOCK_ROOT/output.log" 'uv is available' || return 1
	assert_not_contains 'serena     unavailable' "$MOCK_ROOT/output.log" 'Serena is available' || return 1
	cmp -s "$agents_snapshot" "$MOCK_AGENTS" || fail_test 'successful status changed AGENTS.md' || return 1
	rm -f "$agents_snapshot"
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
	write_mock_command "$MOCK_BIN/uv" \
		'if [[ "${1:-}" == "--version" ]]; then exit 0; fi' \
		'printf "uv %s\\n" "$*" >> "$MOCK_LOG"' \
		'exit 1'
	write_mock_command "$MOCK_BIN/serena" \
		'if [[ "${1:-}" == "--version" ]]; then exit 0; fi' \
		'printf "serena %s\\n" "$*" >> "$MOCK_LOG"' \
		'if [[ "${1:-}" == "init" ]]; then exit 0; fi' \
		'if [[ "${1:-}" == "start-mcp-server" && "${2:-}" == "--help" ]]; then exit 0; fi' \
		'exit 1'
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
	grep -Eq '^  serena[[:space:]]+initialized[[:space:]]' "$MOCK_ROOT/output.log" || fail_test 'initialize Serena server runtime' || return 1
	grep -Eq '^  python[[:space:]]+skipped[[:space:]]' "$MOCK_ROOT/output.log" || fail_test 'skip tools without project initialization' || return 1
	grep -Eq '^  uv[[:space:]]+skipped[[:space:]]' "$MOCK_ROOT/output.log" || fail_test 'skip uv during init' || return 1
	assert_contains 'rtk init' "$MOCK_LOG" 'run local RTK initialization' || return 1
	assert_contains 'codegraph install --target=auto --location=local --yes' "$MOCK_LOG" 'run local CodeGraph agent setup' || return 1
	assert_contains 'codegraph init' "$MOCK_LOG" 'run CodeGraph project initialization' || return 1
	assert_contains 'serena init' "$MOCK_LOG" 'run Serena runtime initialization' || return 1
	assert_contains 'serena start-mcp-server --help' "$MOCK_LOG" 'verify Serena MCP server command' || return 1
	assert_not_contains 'uv init' "$MOCK_LOG" 'do not initialize a Python project with uv' || return 1
	assert_not_contains 'uv sync' "$MOCK_LOG" 'do not sync dependencies during init' || return 1
	assert_not_contains 'uv venv' "$MOCK_LOG" 'do not create a Python environment during init' || return 1
	assert_not_contains 'serena project' "$MOCK_LOG" 'do not create a Serena project' || return 1
	assert_not_contains 'serena index' "$MOCK_LOG" 'do not index a Serena project' || return 1
	assert_not_contains 'serena daemon' "$MOCK_LOG" 'do not start a Serena daemon' || return 1
	assert_not_contains 'serena http' "$MOCK_LOG" 'do not start Serena HTTP mode' || return 1
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

	output="$(run_helper_with_inputs $'\n\nskip\n\nskip\nskip\n')"
	assert_contains 'python     installed' "$MOCK_ROOT/output.log.stdout" 'blank input selects python default' || return 1
	assert_contains 'ruby       installed' "$MOCK_ROOT/output.log.stdout" 'blank input selects ruby default' || return 1
	assert_contains 'rg         skipped' "$MOCK_ROOT/output.log.stdout" 'skip leaves rg uninstalled' || return 1
	assert_contains 'rtk        installed' "$MOCK_ROOT/output.log.stdout" 'blank input selects rtk default' || return 1
	assert_contains 'codegraph  skipped' "$MOCK_ROOT/output.log.stdout" 'skip leaves codegraph uninstalled' || return 1
	assert_contains 'uv         skipped' "$MOCK_ROOT/output.log.stdout" 'skip leaves uv uninstalled' || return 1
	assert_contains 'serena     skipped' "$MOCK_ROOT/output.log.stdout" 'skip leaves Serena uninstalled' || return 1
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
run_test 'explicit brew route' test_brew_route_is_explicit
run_test 'manager capability probes' test_manager_capability_probes
run_test 'no empty AGENTS.md' test_no_empty_agents_file
run_test 'AGENTS.md managed block' test_agents_block_is_add_only_and_idempotent
run_test 'interactive install and failure continuation' test_interactive_install_and_failure_continuation
run_test 'uv dependency failure' test_uv_dependency_failure
run_test 'debug flag and verification failure' test_debug_flag_and_verification_failure
run_test 'default routes and skip selection' test_default_route_and_skip_selection
run_test 'mode parsing and logging' test_mode_parsing_and_logging
run_test 'dry-run mode' test_dry_run_mode
run_test 'dry-run planned commands' test_dry_run_planned_commands
run_test 'dry-run official routes without curl' test_dry_run_official_routes_without_curl
run_test 'status mode' test_status_mode
run_test 'project initialization mode' test_project_init_mode

printf '%s\n' "Passed $PASS_COUNT focused dev-tools tests."