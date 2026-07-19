#!/usr/bin/env bash

set -euo pipefail

FORCE_OVERWRITE=0
SHOW_HELP=0

PASSTHROUGH_ARGS=()

SOURCE_REPOSITORY="mkgask/mydevsetup"
SOURCE_REF="main"
SOURCE_TEMPLATE_URL_BASE="https://raw.githubusercontent.com"

DODKIT_INSTALLER_URL="https://raw.githubusercontent.com/mkgask/dodkit/main/install.sh"
DEV_TOOLS_SOURCE_TEMPLATE_PATH="templates/dev-tools.sh"
DEV_TOOLS_DEFAULT_DIRECTORY=".dev"
DEV_TOOLS_HELPER_PATH=""

DEPLOYMENT_ASSET_SPECS=(
	"templates/AGENTS.md|AGENTS.md|AGENTS.md"
	"templates/.docs/PRINCIPLES.md|.docs/PRINCIPLES.md|PRINCIPLES.md"
	"templates/dev-tools.sh|.dev/dev-tools.sh|dev-tools.sh"
)

print_usage() {
	cat <<'USAGE'
Usage:
	install.sh [arguments-for-dodkit]

Description:
	Install MyDevSetup assets, deploy the optional development-tools helper, and then run DODKit.
	Arguments are forwarded to DODKit as-is.

Examples:
	install.sh
	install.sh copilot
	install.sh cursor --force

Options:
	--force                Also used locally to overwrite AGENTS.md and .docs/PRINCIPLES.md when they already exist.
	-h, --help             Show this help and DODKit help.
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

die() {
	log_error "$1"
	exit 1
}

require_command() {
	local command_name="$1"

	if ! command -v "$command_name" >/dev/null 2>&1; then
		die "Required command not found: $command_name"
	fi
}

has_tty() {
	[[ -t 0 || -t 1 ]]
}

path_has_symlink_component() {
	local target_path="$1"

	while [[ "$target_path" != "." && "$target_path" != "/" ]]; do

		if [[ -L "$target_path" ]]; then
			return 0
		fi

		target_path="$(dirname "$target_path")"
	done

	return 1
}

confirm_overwrite() {
	local destination_path="$1"
	local answer=""

	if has_tty; then
		if [[ -z "${NO_COLOR:-}" ]]; then
			printf '\033[33m[⚠️WARNING] File exists: %s\033[0m\n' "$destination_path" >/dev/tty
		else
			printf '[⚠️WARNING] File exists: %s\n' "$destination_path" >/dev/tty
		fi
		printf 'Overwrite this file? [y/N]: ' >/dev/tty
		read -r answer </dev/tty || true

		case "$answer" in
			y|Y|yes|YES)
				return 0
				;;
			*)
				return 1
				;;
		esac
	fi

	if [[ ! -t 0 ]]; then
		log_warning "Non-interactive execution detected; preserving existing file: $destination_path"
		return 1
	fi

	if supports_stdout_color; then
		printf '\033[33m[⚠️WARNING] File exists: %s\033[0m\n' "$destination_path"
	else
		printf '[⚠️WARNING] File exists: %s\n' "$destination_path"
	fi
	printf 'Overwrite this file? [y/N]: '
	read -r answer

	case "$answer" in
		y|Y|yes|YES)
			return 0
			;;
		*)
			return 1
			;;
	esac
}

parse_args() {
	local argument=""

	PASSTHROUGH_ARGS=("$@")

	for argument in "$@"; do

		if [[ "$argument" == "--force" ]]; then
			FORCE_OVERWRITE=1
		fi

		if [[ "$argument" == "-h" ]] || [[ "$argument" == "--help" ]]; then
			SHOW_HELP=1
		fi
	done
}

build_template_source_url() {
	local source_template_path="$1"

	printf '%s/%s/%s/%s' "$SOURCE_TEMPLATE_URL_BASE" "$SOURCE_REPOSITORY" "$SOURCE_REF" "$source_template_path"
}

resolve_local_template_path() {
	local source_template_path="$1"
	local script_path="${BASH_SOURCE[0]:-$0}"
	local script_directory=""
	local candidate_path=""

	if [[ -z "$script_path" ]]; then
		return 1
	fi

	script_directory="$(cd -- "$(dirname "$script_path")" >/dev/null 2>&1 && pwd -P || true)"

	if [[ -z "$script_directory" ]]; then
		return 1
	fi

	candidate_path="$script_directory/$source_template_path"

	if [[ -f "$candidate_path" ]]; then
		printf '%s' "$candidate_path"
		return 0
	fi

	return 1
}

download_template_to_file() {
	local source_template_path="$1"
	local output_path="$2"
	local source_url=""
	local local_template_path=""

	if local_template_path="$(resolve_local_template_path "$source_template_path")"; then
		cp "$local_template_path" "$output_path"
		return 0
	fi

	source_url="$(build_template_source_url "$source_template_path")"

	if ! curl --proto '=https' --tlsv1.2 -fsSL "$source_url" -o "$output_path"; then
		return 1
	fi

	return 0
}

ensure_parent_directory_exists() {
	local destination_path="$1"
	local parent_directory=""

	parent_directory="$(dirname "$destination_path")"

	if [[ "$parent_directory" == "." ]]; then
		return 0
	fi

	mkdir -p "$parent_directory"
}

install_template_asset() {
	local source_template_path="$1"
	local destination_path="$2"
	local asset_name="$3"
	local temporary_file=""
	local allows_unconditional_overwrite=0

	if [[ "$source_template_path" == "$DEV_TOOLS_SOURCE_TEMPLATE_PATH" ]]; then
		allows_unconditional_overwrite=1
	fi

	temporary_file="$(mktemp)"

	if ! download_template_to_file "$source_template_path" "$temporary_file"; then
		rm -f "$temporary_file"
		die "Failed to download template: $(build_template_source_url "$source_template_path")"
	fi

	if path_has_symlink_component "$destination_path"; then
		rm -f "$temporary_file"
		die "Refusing to write through symlink path: $destination_path"
	fi

	if [[ -f "$destination_path" ]]; then

		if cmp -s "$temporary_file" "$destination_path"; then
			rm -f "$temporary_file"
			log_info "$asset_name is already up-to-date"
			return 0
		fi

		if [[ "$allows_unconditional_overwrite" -ne 1 ]] && [[ "$FORCE_OVERWRITE" -ne 1 ]] && ! confirm_overwrite "$destination_path"; then
			rm -f "$temporary_file"
			log_warning "Skipped existing file: $destination_path"
			return 0
		fi
	fi

	ensure_parent_directory_exists "$destination_path"
	cp "$temporary_file" "$destination_path"
	chmod 0644 "$destination_path"
	rm -f "$temporary_file"
	log_success "Installed: $destination_path"
}

install_template_assets() {
	local asset_spec=""
	local source_template_path=""
	local destination_path=""
	local asset_name=""

	for asset_spec in "${DEPLOYMENT_ASSET_SPECS[@]}"; do
		IFS='|' read -r source_template_path destination_path asset_name <<< "$asset_spec"

		if [[ -z "$source_template_path" ]] || [[ -z "$destination_path" ]] || [[ -z "$asset_name" ]]; then
			die "Invalid deployment asset spec: $asset_spec"
		fi

		install_template_asset "$source_template_path" "$destination_path" "$asset_name"
	done
}

select_dev_tools_destination() {
	local destination_directory="$DEV_TOOLS_DEFAULT_DIRECTORY"
	local destination_path=""
	local answer=""

	if [[ -e "$DEV_TOOLS_DEFAULT_DIRECTORY" ]] && [[ ! -d "$DEV_TOOLS_DEFAULT_DIRECTORY" ]]; then
		die "Cannot use $DEV_TOOLS_DEFAULT_DIRECTORY as a directory"
	fi

	if [[ -d "$DEV_TOOLS_DEFAULT_DIRECTORY" ]]; then
		if has_tty; then
			printf 'Directory for dev-tools.sh [default: %s]: ' "$DEV_TOOLS_DEFAULT_DIRECTORY" >/dev/tty
			read -r answer </dev/tty || answer=""
			if [[ -n "$answer" ]]; then
				destination_directory="$answer"
			fi
		else
			log_warning "Non-interactive execution detected; using default helper directory: $DEV_TOOLS_DEFAULT_DIRECTORY"
		fi
	fi

	destination_path="$destination_directory/dev-tools.sh"
	if path_has_symlink_component "$destination_path"; then
		die "Refusing to write through symlink path: $destination_path"
	fi

	if [[ -e "$destination_directory" ]] && [[ ! -d "$destination_directory" ]]; then
		die "Cannot use helper destination as a directory: $destination_directory"
	fi

	mkdir -p "$destination_directory"
	DEV_TOOLS_HELPER_PATH="$destination_path"
	DEPLOYMENT_ASSET_SPECS[2]="$DEV_TOOLS_SOURCE_TEMPLATE_PATH|$DEV_TOOLS_HELPER_PATH|dev-tools.sh"
}

run_dev_tools_helper() {
	local helper_status=0

	log_info "Running optional development-tools helper"

	if DEV_TOOLS_AGENTS_PATH="AGENTS.md" bash "$DEV_TOOLS_HELPER_PATH"; then
		return 0
	else
		helper_status="$?"
	fi

	die "Development-tools helper failed (exit status $helper_status)"
}

run_dodkit_installer() {
	local -a dodkit_args=("$@")
	local dodkit_status=0

	log_info "Running DODKit installer with passthrough arguments"

	if curl --proto '=https' --tlsv1.2 -fsSL "$DODKIT_INSTALLER_URL" | bash -s -- "${dodkit_args[@]}"; then
		return 0
	else
		dodkit_status="$?"
	fi

	die "DODKit installer failed (exit status $dodkit_status)"
}

main() {
	parse_args "$@"
	require_command "curl"
	require_command "mktemp"
	require_command "cmp"
	require_command "cp"
	require_command "dirname"
	require_command "mkdir"

	if [[ "$SHOW_HELP" -eq 1 ]]; then
		print_usage
		run_dodkit_installer "${PASSTHROUGH_ARGS[@]}"
		exit 0
	fi

	log_info "Starting MyDevSetup installer source=${SOURCE_REPOSITORY}@${SOURCE_REF}"
	select_dev_tools_destination
	install_template_assets
	run_dodkit_installer "${PASSTHROUGH_ARGS[@]}"
	run_dev_tools_helper
	log_success "MyDevSetup installer finished"
}

if [[ "${BASH_SOURCE[0]:-$0}" == "$0" ]]; then
	main "$@"
fi
