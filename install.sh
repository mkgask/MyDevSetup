#!/usr/bin/env bash

set -euo pipefail

FORCE_OVERWRITE=0
SHOW_HELP=0

PASSTHROUGH_ARGS=()

SOURCE_REPOSITORY="mkgask/mydevsetup"
SOURCE_REF="main"
SOURCE_TEMPLATE_PATH="templates/AGENTS.md"
SOURCE_TEMPLATE_URL_BASE="https://raw.githubusercontent.com"

DODKIT_INSTALLER_URL="https://raw.githubusercontent.com/mkgask/dodkit/main/install.sh"
DESTINATION_AGENTS_PATH="AGENTS.md"

print_usage() {
	cat <<'USAGE'
Usage:
	install.sh [arguments-for-dodkit]

Description:
	Install MyDevSetup assets and then run DODKit installer.
	Arguments are forwarded to DODKit as-is.

Examples:
	install.sh
	install.sh copilot
	install.sh cursor --force

Options:
	--force                Also used locally to overwrite AGENTS.md when it already exists.
	-h, --help             Show this help and DODKit help.
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
	local -a dodkit_args=("$@")

	log_info "Running DODKit installer with passthrough arguments"

	if ! curl --proto '=https' --tlsv1.2 -fsSL "$DODKIT_INSTALLER_URL" | bash -s -- "${dodkit_args[@]}"; then
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

	if [[ "$SHOW_HELP" -eq 1 ]]; then
		print_usage
		run_dodkit_installer "${PASSTHROUGH_ARGS[@]}"
		exit 0
	fi

	log_info "Starting MyDevSetup installer source=${SOURCE_REPOSITORY}@${SOURCE_REF}"
	install_agents_template
	run_dodkit_installer "${PASSTHROUGH_ARGS[@]}"
	log_success "MyDevSetup installer finished"
}

if [[ "${BASH_SOURCE[0]:-$0}" == "$0" ]]; then
	main "$@"
fi
