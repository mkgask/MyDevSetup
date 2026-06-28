#!/usr/bin/env bash

set -euo pipefail

TARGET_CLI="copilot"
FORCE_OVERWRITE=0

SOURCE_REPOSITORY="mkgask/MyDevSetup"
SOURCE_REF="main"
SOURCE_TEMPLATE_PATH="templates/AGENTS.md"
SOURCE_TEMPLATE_URL_BASE="https://raw.githubusercontent.com"

DODKIT_INSTALLER_URL="https://raw.githubusercontent.com/mkgask/dodkit/main/install.sh"
DESTINATION_AGENTS_PATH="AGENTS.md"

print_usage() {
	cat <<'USAGE'
Usage:
  install.sh [copilot|cursor] [--force]

Description:
  Install MyDevSetup assets and then run DODKit installer for the selected target.

Arguments:
  copilot                Optional target for GitHub Copilot assets. Default is copilot.
  cursor                 Optional target for Cursor assets.

Options:
  --force                Overwrite AGENTS.md when it already exists.
  -h, --help             Show this help.
USAGE
}

log_info() {
	printf '[INFO] %s\n' "$1"
}

log_warning() {
	printf '[WARNING] %s\n' "$1"
}

log_error() {
	printf '[ERROR] %s\n' "$1" >&2
}

log_success() {
	printf '[SUCCESS] %s\n' "$1"
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
	[[ -r /dev/tty ]] && [[ -w /dev/tty ]]
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
		printf '[WARNING] File exists: %s\n' "$destination_path" >/dev/tty
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

	printf '[WARNING] File exists: %s\n' "$destination_path"
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

validate_target() {
	case "$TARGET_CLI" in
		copilot|cursor)
			return 0
			;;
		*)
			die "Unsupported target '$TARGET_CLI'. Supported targets are: copilot, cursor."
			;;
	esac
}

parse_args() {
	while [[ $# -gt 0 ]]; do

		case "$1" in
			copilot|cursor)
				TARGET_CLI="$1"
				shift
				;;
			--force)
				FORCE_OVERWRITE=1
				shift
				;;
			-h|--help)
				print_usage
				exit 0
				;;
			*)
				die "Unknown argument: $1"
				;;
		esac
	done
}

build_template_source_url() {
	printf '%s/%s/%s/%s' "$SOURCE_TEMPLATE_URL_BASE" "$SOURCE_REPOSITORY" "$SOURCE_REF" "$SOURCE_TEMPLATE_PATH"
}

resolve_local_template_path() {
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

	candidate_path="$script_directory/$SOURCE_TEMPLATE_PATH"

	if [[ -f "$candidate_path" ]]; then
		printf '%s' "$candidate_path"
		return 0
	fi

	return 1
}

download_template_to_file() {
	local output_path="$1"
	local source_url=""
	local local_template_path=""

	if local_template_path="$(resolve_local_template_path)"; then
		cp "$local_template_path" "$output_path"
		return 0
	fi

	source_url="$(build_template_source_url)"

	if ! curl --proto '=https' --tlsv1.2 -fsSL "$source_url" -o "$output_path"; then
		return 1
	fi

	return 0
}

install_agents_template() {
	local destination_path="$DESTINATION_AGENTS_PATH"
	local temporary_file=""

	temporary_file="$(mktemp)"

	if ! download_template_to_file "$temporary_file"; then
		rm -f "$temporary_file"
		die "Failed to download template: $(build_template_source_url)"
	fi

	if path_has_symlink_component "$destination_path"; then
		rm -f "$temporary_file"
		die "Refusing to write AGENTS.md through symlink path: $destination_path"
	fi

	if [[ -f "$destination_path" ]]; then

		if cmp -s "$temporary_file" "$destination_path"; then
			rm -f "$temporary_file"
			log_info "AGENTS.md is already up-to-date"
			return 0
		fi

		if [[ "$FORCE_OVERWRITE" -ne 1 ]] && ! confirm_overwrite "$destination_path"; then
			rm -f "$temporary_file"
			log_warning "Skipped existing file: $destination_path"
			return 0
		fi
	fi

	cp "$temporary_file" "$destination_path"
	chmod 0644 "$destination_path"
	rm -f "$temporary_file"
	log_success "Installed: $destination_path"
}

run_dodkit_installer() {
	log_info "Running DODKit installer with target=$TARGET_CLI"

	if ! curl --proto '=https' --tlsv1.2 -fsSL "$DODKIT_INSTALLER_URL" | bash -s -- "$TARGET_CLI" --force; then
		die "DODKit installer failed"
	fi
}

main() {
	parse_args "$@"
	require_command "curl"
	require_command "mktemp"
	require_command "cmp"
	require_command "cp"
	require_command "dirname"
	validate_target

	log_info "Starting MyDevSetup installer target=$TARGET_CLI source=${SOURCE_REPOSITORY}@${SOURCE_REF}"
	install_agents_template
	run_dodkit_installer
	log_success "MyDevSetup installer finished"
}

if [[ "${BASH_SOURCE[0]:-$0}" == "$0" ]]; then
	main "$@"
fi
