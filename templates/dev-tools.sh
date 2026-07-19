#!/usr/bin/env bash

set -euo pipefail

TOOL_NAMES=(python ruby rg rtk codegraph uv serena)

declare -A TOOL_COMMANDS=(
	[python]="python3"
	[ruby]="ruby"
	[rg]="rg"
	[rtk]="rtk"
	[codegraph]="codegraph"
	[uv]="uv"
	[serena]="serena"
)

declare -A TOOL_RESULTS=()
declare -A TOOL_RESULT_DETAILS=()
declare -A NEW_TOOL_COMMANDS=()
TOOL_FAILURE_COUNT=0
LAST_OPERATION_COMMAND=""
FOUND_TOOL_COMMAND=""
LAST_VERIFICATION_DETAILS=""
DEBUG_ENABLED=0

DEV_TOOLS_MODE="install"
GLOBAL_INSTALL=0

AGENTS_PATH="${DEV_TOOLS_AGENTS_PATH:-AGENTS.md}"
MANAGED_BLOCK_BEGIN='<!-- BEGIN MYDEVSETUP DEV TOOLS -->'
MANAGED_BLOCK_END='<!-- END MYDEVSETUP DEV TOOLS -->'

RTK_INSTALLER_URL="https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh"
CODEGRAPH_INSTALLER_URL="https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh"
UV_INSTALLER_URL="https://astral.sh/uv/install.sh"

print_usage() {
	cat <<'USAGE'
Usage:
	dev-tools.sh [install|init] [--global] [--debug]
	dev-tools.sh --help

Description:
	Install missing development CLI tools or initialize installed tools for the current project.
	The --global option is available only for install mode.
	The --debug option prints external command traces for this run.

Environment:
	DEV_TOOLS_AGENTS_PATH  Override the AGENTS.md path for this run.
USAGE
}

log_info() {
	printf '[INFO] %s\n' "$1"
}

supports_stdout_color() {
	[[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]
}

supports_stderr_color() {
	[[ -t 2 ]] && [[ -z "${NO_COLOR:-}" ]]
}

log_warning() {
	if supports_stdout_color; then
		printf '\033[33m[⚠️WARNING] %s\033[0m\n' "$1"
	else
		printf '[⚠️WARNING] %s\n' "$1"
	fi
}

log_error() {
	if supports_stderr_color; then
		printf '\033[31m[❌️ERROR] %s\033[0m\n' "$1" >&2
	else
		printf '[❌️ERROR] %s\n' "$1" >&2
	fi
}

log_success() {
	if supports_stdout_color; then
		printf '\033[32m[✅️SUCCESS] %s\033[0m\n' "$1"
	else
		printf '[✅️SUCCESS] %s\n' "$1"
	fi
}

log_debug() {
	if [[ "$DEBUG_ENABLED" -eq 1 ]]; then
		printf '[🔵DEBUG] %s\n' "$1" >&2
	fi
}

format_command() {
	local argument=""
	local rendered_command=""
	local rendered_argument=""

	for argument in "$@"; do
		printf -v rendered_argument '%q' "$argument"
		if [[ -n "$rendered_command" ]]; then
			rendered_command+=" "
		fi
		rendered_command+="$rendered_argument"
	done

	printf '%s' "$rendered_command"
}

record_operation_command() {
	LAST_OPERATION_COMMAND="$(format_command "$@")"
	log_debug "Running: $LAST_OPERATION_COMMAND"
}

run_recorded_command() {
	record_operation_command "$@"
	"$@"
}

record_pipeline_operation() {
	LAST_OPERATION_COMMAND="$1"
	log_debug "Running: $LAST_OPERATION_COMMAND"
}

prepend_path() {
	local path_entry="$1"

	if [[ ! -d "$path_entry" ]]; then
		return 0
	fi

	case ":${PATH:-}:" in
		*":$path_entry:"*)
			return 0
			;;
	esac

	PATH="$path_entry:${PATH:-}"
	export PATH
}

prepare_known_tool_paths() {
	local home_directory="${HOME:-}"

	if [[ -n "$home_directory" ]]; then
		prepend_path "$home_directory/.local/bin"
		prepend_path "$home_directory/.proto/bin"
		prepend_path "$home_directory/.asdf/shims"
		prepend_path "$home_directory/.nix-profile/bin"
		prepend_path "$home_directory/.local/share/mise/shims"
	fi

	prepend_path "/nix/var/nix/profiles/default/bin"
}

tool_command_candidates() {
	local tool_name="$1"

	case "$tool_name" in
		python)
			printf '%s\n' python3 python
			;;
		ruby|rg|rtk|codegraph|uv|serena)
			printf '%s\n' "${TOOL_COMMANDS[$tool_name]}"
			;;
		*)
			return 1
			;;
	esac
}

find_tool_command() {
	local tool_name="$1"
	local command_name=""
	local verification_status=0
	local verification_command=""
	local verification_reason=""

	FOUND_TOOL_COMMAND=""
	LAST_VERIFICATION_DETAILS=""

	while IFS= read -r command_name; do
		verification_command="$(format_command "$command_name" --version)"
		if ! command -v "$command_name" >/dev/null 2>&1; then
			verification_status=127
			verification_reason="command not found"
			if [[ -n "$LAST_VERIFICATION_DETAILS" ]]; then
				LAST_VERIFICATION_DETAILS+='; '
			fi
			LAST_VERIFICATION_DETAILS+="command: $verification_command (exit status $verification_status; $verification_reason)"
			continue
		fi

		record_operation_command "$command_name" --version
		if "$command_name" --version >/dev/null 2>&1; then
			FOUND_TOOL_COMMAND="$command_name"
			return 0
		else
			verification_status="$?"
		fi

		verification_reason="command exited unsuccessfully"
		if [[ -n "$LAST_VERIFICATION_DETAILS" ]]; then
			LAST_VERIFICATION_DETAILS+='; '
		fi
		LAST_VERIFICATION_DETAILS+="command: $verification_command (exit status $verification_status; $verification_reason)"
	done < <(tool_command_candidates "$tool_name")

	return 1
}

system_manager_can_run() {
	if [[ "$EUID" -eq 0 ]]; then
		return 0
	fi

	command -v sudo >/dev/null 2>&1
}

find_system_package_manager() {
	local manager_name=""

	for manager_name in apt-get dnf yum pacman zypper apk brew; do
		if ! command -v "$manager_name" >/dev/null 2>&1; then
			continue
		fi

		if [[ "$manager_name" == "brew" ]] || system_manager_can_run; then
			printf '%s' "$manager_name"
			return 0
		fi
	done

	return 1
}

system_package_for_tool() {
	local tool_name="$1"
	local manager_name="$2"

	case "$tool_name:$manager_name" in
		python:apt-get|python:dnf|python:yum|python:zypper|python:apk)
			printf '%s' python3
			;;
		python:brew)
			printf '%s' python
			;;
		python:pacman)
			printf '%s' python
			;;
		ruby:*)
			printf '%s' ruby
			;;
		rg:*)
			printf '%s' ripgrep
			;;
		*)
			return 1
			;;
	esac
}

system_route_available() {
	local tool_name="$1"
	local manager_name=""

	case "$tool_name" in
		python|ruby|rg)
			manager_name="$(find_system_package_manager)" || return 1
			system_package_for_tool "$tool_name" "$manager_name" >/dev/null
			;;
		*)
			return 1
			;;
	esac
}

nix_package_for_tool() {
	case "$1" in
		python)
			printf '%s' python3
			;;
		ruby)
			printf '%s' ruby
			;;
		rg)
			printf '%s' ripgrep
			;;
		*)
			return 1
			;;
	esac
}

nix_route_available() {
	local tool_name="$1"

	command -v nix >/dev/null 2>&1 || return 1
	nix_package_for_tool "$tool_name" >/dev/null || return 1
	nix profile install --help >/dev/null 2>&1
}

proto_tool_for_tool() {
	case "$1" in
		python|ruby)
			printf '%s' "$1"
			;;
		*)
			return 1
			;;
	esac
}

proto_route_available() {
	local tool_name="$1"

	command -v proto >/dev/null 2>&1 || return 1
	proto_tool_for_tool "$tool_name" >/dev/null || return 1
	proto install --help >/dev/null 2>&1
}

mise_tool_for_tool() {
	case "$1" in
		python|ruby)
			printf '%s' "$1"
			;;
		rg)
			printf '%s' ripgrep
			;;
		rtk)
			printf '%s' rtk
			;;
		*)
			return 1
			;;
	esac
}

mise_route_available() {
	local tool_name="$1"
	local manager_tool=""

	command -v mise >/dev/null 2>&1 || return 1
	manager_tool="$(mise_tool_for_tool "$tool_name")" || return 1
	mise registry "$manager_tool" >/dev/null 2>&1
}

asdf_plugin_for_tool() {
	case "$1" in
		python|ruby)
			printf '%s' "$1"
			;;
		rg)
			printf '%s' ripgrep
			;;
		rtk)
			printf '%s' rtk
			;;
		*)
			return 1
			;;
	esac
}

asdf_route_available() {
	local tool_name="$1"
	local plugin_name=""

	command -v asdf >/dev/null 2>&1 || return 1
	plugin_name="$(asdf_plugin_for_tool "$tool_name")" || return 1
	asdf plugin list 2>/dev/null | grep -Fxq "$plugin_name"
}

official_installer_url_for_tool() {
	case "$1" in
		rtk)
		printf '%s' "$RTK_INSTALLER_URL"
		;;
		codegraph)
		printf '%s' "$CODEGRAPH_INSTALLER_URL"
		;;
		uv)
		printf '%s' "$UV_INSTALLER_URL"
		;;
		*)
			return 1
			;;
	esac
}

official_route_available() {
	local tool_name="$1"

	command -v curl >/dev/null 2>&1 || return 1
	official_installer_url_for_tool "$tool_name" >/dev/null
}

uv_tool_package_for_tool() {
	case "$1" in
		serena)
		printf '%s' serena-agent
		;;
		*)
			return 1
			;;
	esac
}

uv_tool_route_available() {
	local tool_name="$1"

	command -v uv >/dev/null 2>&1 || return 1
	uv_tool_package_for_tool "$tool_name" >/dev/null
}

route_supports_global_scope() {
	case "$1" in
		system|nix|official|uv-tool)
			return 0
			;;
		*)
			return 1
			;;
	esac
}

append_available_route() {
	local tool_name="$1"
	local route_name="$2"
	local route_available=0

	if [[ "$GLOBAL_INSTALL" -eq 1 ]] && ! route_supports_global_scope "$route_name"; then
		return 0
	fi

	case "$route_name" in
		system)
			if system_route_available "$tool_name"; then
				route_available=1
			fi
			;;
		nix)
			if nix_route_available "$tool_name"; then
				route_available=1
			fi
			;;
		proto)
			if proto_route_available "$tool_name"; then
				route_available=1
			fi
			;;
		mise)
			if mise_route_available "$tool_name"; then
				route_available=1
			fi
			;;
		asdf)
			if asdf_route_available "$tool_name"; then
				route_available=1
			fi
			;;
		official)
			if official_route_available "$tool_name"; then
				route_available=1
			fi
			;;
		uv-tool)
			if uv_tool_route_available "$tool_name"; then
				route_available=1
			fi
			;;
		*)
			return 0
			;;
	esac

	if [[ "$route_available" -eq 1 ]]; then
		printf '%s\n' "$route_name"
	fi
}

available_routes_for_tool() {
	local tool_name="$1"

	append_available_route "$tool_name" system
	append_available_route "$tool_name" nix
	append_available_route "$tool_name" proto
	append_available_route "$tool_name" mise
	append_available_route "$tool_name" asdf
	append_available_route "$tool_name" official
	append_available_route "$tool_name" uv-tool

	printf '%s\n' skip
}

default_route_for_tool() {
	case "$1" in
		python|ruby|rg)
			printf '%s' system
			;;
		rtk|codegraph|uv)
			printf '%s' official
			;;
		serena)
			printf '%s' uv-tool
			;;
		*)
			printf '%s' skip
			;;
	esac
}

has_install_route() {
	local tool_name="$1"
	local route_name=""

	while IFS= read -r route_name; do
		if [[ "$route_name" != "skip" ]]; then
			return 0
		fi
	done < <(available_routes_for_tool "$tool_name")

	return 1
}

prompt_is_available() {
	[[ -t 0 || -t 1 ]]
}

prompt_for_route() {
	local tool_name="$1"
	local prompt_input="/dev/tty"
	local prompt_output="/dev/tty"
	local configured_default_route="$(default_route_for_tool "$tool_name")"
	local default_route="skip"
	local answer=""
	local selected_route="skip"
	local route_name=""
	local index=0
	local route_count=0
	local -a routes=()

	while IFS= read -r route_name; do
		routes+=("$route_name")
	done < <(available_routes_for_tool "$tool_name")

	for route_name in "${routes[@]}"; do
		if [[ "$route_name" == "$configured_default_route" ]]; then
			default_route="$configured_default_route"
			break
		fi
	done

	if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
		prompt_input="/dev/stdin"
		prompt_output="/dev/stdout"
	fi

	for index in "${!routes[@]}"; do
		route_name="${routes[$index]}"
		if [[ "$route_name" == "$default_route" ]]; then
			printf '%s\n' "  $((index + 1))) $route_name (default)" > "$prompt_output"
		else
			printf '%s\n' "  $((index + 1))) $route_name" > "$prompt_output"
		fi
	done

	route_count="${#routes[@]}"
	printf 'Choose an installation method for %s [default: %s]: ' "$tool_name" "$default_route" > "$prompt_output"
	read -r answer < "$prompt_input" || answer=""

	if [[ -z "$answer" ]]; then
		for route_name in "${routes[@]}"; do
			if [[ "$route_name" == "$default_route" ]]; then
				selected_route="$default_route"
				break
			fi
		done
	elif [[ "$answer" =~ ^[0-9]+$ ]] && (( answer >= 1 && answer <= route_count )); then
		selected_route="${routes[$((answer - 1))]}"
	else
		for route_name in "${routes[@]}"; do
			if [[ "$route_name" == "$answer" ]]; then
				selected_route="$answer"
				break
			fi
		done
	fi

	printf '%s' "$selected_route"
}

run_as_root() {
	local -a command=("$@")

	if [[ "$EUID" -ne 0 ]]; then
		command=(sudo "${command[@]}")
	fi

	run_recorded_command "${command[@]}"
}

install_with_system() {
	local tool_name="$1"
	local manager_name="$(find_system_package_manager)"
	local package_name="$(system_package_for_tool "$tool_name" "$manager_name")"

	case "$manager_name" in
		apt-get|dnf|yum)
			run_as_root "$manager_name" install -y "$package_name" || return $?
			;;
		pacman)
			run_as_root "$manager_name" -S --noconfirm "$package_name" || return $?
			;;
		zypper)
			run_as_root "$manager_name" --non-interactive install --no-recommends "$package_name" || return $?
			;;
		apk)
			run_as_root "$manager_name" add --no-cache "$package_name" || return $?
			;;
		brew)
			run_recorded_command "$manager_name" install "$package_name" || return $?
			;;
		*)
			return 1
			;;
	esac
}

install_with_nix() {
	local tool_name="$1"
	local package_name="$(nix_package_for_tool "$tool_name")"

	run_recorded_command nix profile install "nixpkgs#$package_name" || return $?
	prepend_path "${HOME:-}/.nix-profile/bin"
	prepend_path "/nix/var/nix/profiles/default/bin"
}

install_with_proto() {
	local tool_name="$1"
	local manager_tool="$(proto_tool_for_tool "$tool_name")"
	local executable_path=""

	run_recorded_command proto install "$manager_tool" latest --yes || return $?
	record_operation_command proto bin "$manager_tool" latest
	if executable_path="$(proto bin "$manager_tool" latest 2>/dev/null)"; then
		:
	else
		return $?
	fi

	[[ -x "$executable_path" ]] || return 1
	prepend_path "$(dirname "$executable_path")"
}

refresh_mise_path() {
	local manager_tool="$1"
	local path_entry=""

	record_operation_command mise bin-paths "$manager_tool@latest"
	while IFS= read -r path_entry; do
		prepend_path "$path_entry"
	done < <(mise bin-paths "$manager_tool@latest" 2>/dev/null || true)
}

install_with_mise() {
	local tool_name="$1"
	local manager_tool="$(mise_tool_for_tool "$tool_name")"

	run_recorded_command mise install "$manager_tool@latest" || return $?
	refresh_mise_path "$manager_tool"
}

install_with_asdf() {
	local tool_name="$1"
	local plugin_name="$(asdf_plugin_for_tool "$tool_name")"
	local version=""
	local environment_name=""

	run_recorded_command asdf install "$plugin_name" latest || return $?
	record_operation_command asdf latest "$plugin_name"
	if version="$(asdf latest "$plugin_name")"; then
		:
	else
		return $?
	fi

	[[ -n "$version" ]] || return 1
	run_recorded_command asdf reshim "$plugin_name" "$version" || return $?
	environment_name="ASDF_${plugin_name^^}_VERSION"
	export "$environment_name=$version"
	prepend_path "${ASDF_DATA_DIR:-${HOME:-}/.asdf}/shims"
}

install_with_official() {
	local tool_name="$1"
	local installer_url="$(official_installer_url_for_tool "$tool_name")"
	local pipeline_command=""

	pipeline_command="$(format_command curl --proto '=https' --tlsv1.2 -fsSL "$installer_url") | sh"
	record_pipeline_operation "$pipeline_command"
	if curl --proto '=https' --tlsv1.2 -fsSL "$installer_url" | sh; then
		:
	else
		return $?
	fi

	prepend_path "${HOME:-}/.local/bin"
}

refresh_uv_tool_path() {
	local tool_bin_directory=""

	record_operation_command uv tool dir --bin
	if tool_bin_directory="$(uv tool dir --bin 2>/dev/null)"; then
		:
	else
		return $?
	fi

	[[ -n "$tool_bin_directory" ]] || return 1
	prepend_path "$tool_bin_directory"
}

install_with_uv_tool() {
	local tool_name="$1"
	local package_name="$(uv_tool_package_for_tool "$tool_name")"

	run_recorded_command uv tool install -p 3.13 "$package_name" || return $?
	refresh_uv_tool_path
}

install_with_route() {
	local tool_name="$1"
	local route_name="$2"

	case "$route_name" in
		system)
		install_with_system "$tool_name"
		;;
		nix)
		install_with_nix "$tool_name"
		;;
		proto)
		install_with_proto "$tool_name"
		;;
		mise)
		install_with_mise "$tool_name"
		;;
		asdf)
		install_with_asdf "$tool_name"
		;;
		official)
		install_with_official "$tool_name"
		;;
		uv-tool)
		install_with_uv_tool "$tool_name"
		;;
		*)
		return 1
		;;
	esac
}

run_project_initialization() {
	local tool_name="$1"
	local command_name="$2"

	case "$tool_name" in
		rtk)
			run_recorded_command "$command_name" init
		;;
		codegraph)
			run_recorded_command "$command_name" install --target=auto --location=local --yes || return $?
			run_recorded_command "$command_name" init
		;;
		serena)
			run_recorded_command "$command_name" init || return $?
			run_recorded_command "$command_name" start-mcp-server --help
		;;
		*)
			return 1
			;;
	esac
}

set_tool_result() {
	local tool_name="$1"
	local result_name="$2"
	local result_detail="$3"

	TOOL_RESULTS["$tool_name"]="$result_name"
	TOOL_RESULT_DETAILS["$tool_name"]="$result_detail"
	if [[ "$result_name" == "failed" ]]; then
		TOOL_FAILURE_COUNT=$((TOOL_FAILURE_COUNT + 1))
	fi
}

process_install_tool() {
	local tool_name="$1"
	local installed_command=""
	local selected_route=""
	local operation_status=0
	local operation_command=""
	local verification_detail=""

	if find_tool_command "$tool_name"; then
		installed_command="$FOUND_TOOL_COMMAND"
		set_tool_result "$tool_name" present "$installed_command"
		log_info "$tool_name is already available as $installed_command"
		return 0
	fi

	if ! has_install_route "$tool_name"; then
		set_tool_result "$tool_name" skipped "no available installation method"
		log_warning "No installation method is available for $tool_name; skipping"
		return 0
	fi

	if ! prompt_is_available; then
		set_tool_result "$tool_name" skipped "non-interactive execution"
		log_warning "Non-interactive execution detected; skipping $tool_name"
		return 0
	fi

	selected_route="$(prompt_for_route "$tool_name")"
	if [[ "$selected_route" == "skip" ]]; then
		set_tool_result "$tool_name" skipped "user selected skip"
		return 0
	fi

	if install_with_route "$tool_name" "$selected_route"; then
		:
	else
		operation_status="$?"
		operation_command="${LAST_OPERATION_COMMAND:-unknown command}"
		set_tool_result "$tool_name" failed "$selected_route (exit status $operation_status; command: $operation_command)"
		log_error "Failed to install $tool_name via $selected_route (exit status $operation_status; command: $operation_command)"
		return 0
	fi

	if ! find_tool_command "$tool_name"; then
		verification_detail="${LAST_VERIFICATION_DETAILS:-unknown command verification failure}"
		set_tool_result "$tool_name" failed "$selected_route (command verification failed; $verification_detail)"
		log_error "Installed $tool_name via $selected_route but command verification failed; $verification_detail"
		return 0
	fi

	installed_command="$FOUND_TOOL_COMMAND"
	NEW_TOOL_COMMANDS["$tool_name"]="$installed_command"
	set_tool_result "$tool_name" installed "$installed_command via $selected_route"
	log_success "Installed $tool_name as $installed_command via $selected_route"
}

process_init_tool() {
	local tool_name="$1"
	local installed_command=""
	local operation_status=0
	local operation_command=""

	case "$tool_name" in
		rtk|codegraph|serena)
			;;
		uv)
			set_tool_result "$tool_name" skipped "install-only tool"
			log_info "$tool_name is install-only; skipping project initialization"
			return 0
			;;
		*)
			set_tool_result "$tool_name" skipped "no project initialization required"
			log_info "$tool_name does not require project initialization"
			return 0
			;;
	esac

	if ! find_tool_command "$tool_name"; then
		set_tool_result "$tool_name" skipped "command not available"
		log_warning "$tool_name is not available; skipping project initialization"
		return 0
	fi

	installed_command="$FOUND_TOOL_COMMAND"

	if run_project_initialization "$tool_name" "$installed_command"; then
		:
	else
		operation_status="$?"
		operation_command="${LAST_OPERATION_COMMAND:-unknown command}"
		set_tool_result "$tool_name" failed "project initialization failed (exit status $operation_status; command: $operation_command)"
		log_error "Failed to initialize $tool_name for the current project (exit status $operation_status; command: $operation_command)"
		return 0
	fi

	set_tool_result "$tool_name" initialized "$installed_command"
	log_success "Initialized $tool_name for the current project"
}

process_tool() {
	if [[ "$DEV_TOOLS_MODE" == "init" ]]; then
		process_init_tool "$1"
		return 0
	fi

	process_install_tool "$1"
}

agents_contains_tool() {
	local tool_name="$1"
	local pattern=""

	[[ -f "$AGENTS_PATH" ]] || return 1

	case "$tool_name" in
		python)
			pattern='(^|[^[:alnum:]_-])python(3)?([^[:alnum:]_-]|$)'
			;;
		*)
			pattern="(^|[^[:alnum:]_-])${tool_name}([^[:alnum:]_-]|$)"
			;;
	esac

	grep -Eqi "$pattern" "$AGENTS_PATH"
}

build_new_agents_entries() {
	local tool_name=""
	local command_name=""

	for tool_name in "${TOOL_NAMES[@]}"; do
		if [[ -z "${NEW_TOOL_COMMANDS[$tool_name]:-}" ]]; then
			continue
		fi

		if agents_contains_tool "$tool_name"; then
			continue
		fi

		command_name="${NEW_TOOL_COMMANDS[$tool_name]}"
		printf -- '- `%s`: `%s`\n' "$tool_name" "$command_name"
	done
}

update_agents_managed_block() {
	local additions_file=""
	local temporary_file=""
	local addition_count=0
	local begin_count=0
	local end_count=0
	local agents_directory=""
	local last_byte=""

	if [[ -L "$AGENTS_PATH" ]]; then
		log_error "Cannot safely update AGENTS.md: $AGENTS_PATH"
		return 1
	fi

	if [[ -e "$AGENTS_PATH" ]] && [[ ! -f "$AGENTS_PATH" || ! -r "$AGENTS_PATH" ]]; then
		log_error "Cannot safely update AGENTS.md: $AGENTS_PATH"
		return 1
	fi

	additions_file="$(mktemp)"
	build_new_agents_entries > "$additions_file"
	addition_count="$(wc -l < "$additions_file")"
	if [[ "$addition_count" -eq 0 ]]; then
		rm -f "$additions_file"
		return 0
	fi

	if [[ -e "$AGENTS_PATH" && ! -w "$AGENTS_PATH" ]]; then
		rm -f "$additions_file"
		log_error "Cannot safely update AGENTS.md: $AGENTS_PATH"
		return 1
	fi

	if [[ ! -e "$AGENTS_PATH" ]]; then
		agents_directory="$(dirname "$AGENTS_PATH")"
		mkdir -p "$agents_directory"
		: > "$AGENTS_PATH"
	fi

	begin_count="$(grep -Fxc "$MANAGED_BLOCK_BEGIN" "$AGENTS_PATH" || true)"
	end_count="$(grep -Fxc "$MANAGED_BLOCK_END" "$AGENTS_PATH" || true)"
	if [[ "$begin_count" -eq 1 && "$end_count" -eq 1 ]]; then
		temporary_file="$(mktemp)"
		awk -v end_marker="$MANAGED_BLOCK_END" -v additions_path="$additions_file" '
			$0 == end_marker {
				while ((getline addition < additions_path) > 0) {
					print addition
				}
				close(additions_path)
			}
			{ print }
		' "$AGENTS_PATH" > "$temporary_file"
	else
		if [[ "$begin_count" -ne 0 || "$end_count" -ne 0 ]]; then
			rm -f "$additions_file"
			log_error "Cannot update incomplete AGENTS.md managed block"
			return 1
		fi

		if [[ -s "$AGENTS_PATH" ]]; then
			last_byte="$(tail -c 1 "$AGENTS_PATH" | od -An -t x1 | tr -d '[:space:]')"
			if [[ "$last_byte" != "0a" ]]; then
				printf '\n' >> "$AGENTS_PATH"
			fi
		fi

		temporary_file="$(mktemp)"
		{
			cat "$AGENTS_PATH"
			printf '\n%s\n' "$MANAGED_BLOCK_BEGIN"
			printf '%s\n' '## Installed development tools'
			cat "$additions_file"
			printf '%s\n' "$MANAGED_BLOCK_END"
		} > "$temporary_file"
	fi

	chmod --reference="$AGENTS_PATH" "$temporary_file" 2>/dev/null || true
	mv "$temporary_file" "$AGENTS_PATH"
	rm -f "$additions_file"
	log_success "Updated the managed development-tools block in $AGENTS_PATH"
}

print_summary() {
	local tool_name=""
	local result_name=""
	local result_detail=""

	printf '\n%s\n' 'Development-tool summary:'
	for tool_name in "${TOOL_NAMES[@]}"; do
		result_name="${TOOL_RESULTS[$tool_name]:-skipped}"
		result_detail="${TOOL_RESULT_DETAILS[$tool_name]:-not processed}"
		printf '  %-10s %-9s %s\n' "$tool_name" "$result_name" "$result_detail"
	done
}

parse_args() {
	local mode_seen=0

	DEV_TOOLS_MODE="install"
	GLOBAL_INSTALL=0
	DEBUG_ENABLED=0

	while (($# > 0)); do
		case "$1" in
			install|init)
				if [[ "$mode_seen" -eq 1 ]]; then
					log_error "Only one mode may be specified"
					return 2
				fi
				DEV_TOOLS_MODE="$1"
				mode_seen=1
				;;
			--global)
				GLOBAL_INSTALL=1
				;;
			--debug)
				DEBUG_ENABLED=1
				;;
			-h|--help)
				print_usage
				return 1
				;;
			*)
				log_error "Unknown argument: $1"
				return 2
				;;
		esac
		shift
	done

	if [[ "$DEV_TOOLS_MODE" == "init" && "$GLOBAL_INSTALL" -eq 1 ]]; then
		log_error "The --global option is only valid with install mode"
		return 2
	fi

	return 0
}

main() {
	local tool_name=""
	local parse_status=0
	local agents_status=0

	if parse_args "$@"; then
		:
	else
		parse_status="$?"
		if [[ "$parse_status" -eq 1 ]]; then
			return 0
		fi
		return "$parse_status"
	fi

	if [[ "$(uname -s)" != "Linux" ]]; then
		log_warning "This helper supports Linux and WSL only; skipping optional tools"
		return 0
	fi

	prepare_known_tool_paths
	for tool_name in "${TOOL_NAMES[@]}"; do
		process_tool "$tool_name"
	done

	if [[ "$DEV_TOOLS_MODE" == "install" ]]; then
		if ! update_agents_managed_block; then
			agents_status=1
		fi
	fi

	print_summary
	if [[ "$agents_status" -ne 0 || "$TOOL_FAILURE_COUNT" -ne 0 ]]; then
		return 1
	fi

	return 0
}

if [[ "${BASH_SOURCE[0]:-$0}" == "$0" ]]; then
	main "$@"
fi