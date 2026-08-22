#!/usr/bin/env bash

set -euo pipefail

APT_PACKAGES=(
	patch
	bison
	libdb-dev
	build-essential
	libyaml-dev
	libssl-dev
	libreadline6-dev
	libffi-dev
	autoconf
	libgdbm-dev
	zlib1g-dev
	rustc
	libncurses5-dev
	libgdbm6
	libgmp-dev
	fontconfig
	curl
	git
	gh
	jq
	unzip
	gzip
	xz-utils
)

HACKGEN_RELEASE_API_URL='https://api.github.com/repos/yuru7/HackGen/releases/latest'
HACKGEN_REGULAR_FONT='HackGenConsoleNF-Regular.ttf'
HACKGEN_BOLD_FONT='HackGenConsoleNF-Bold.ttf'

log_info() {
	printf '[INFO] %s\n' "$1"
}

supports_stdout_color() {
	[[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]
}

supports_stderr_color() {
	[[ -t 2 ]] && [[ -z "${NO_COLOR:-}" ]]
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

extract_hackgen_font() {
	local archive_path="$1"
	local font_name="$2"
	local destination_path="$3"
	local archive_entries=""
	local archive_entry=""
	local matching_entry=""
	local match_count=0

	if ! archive_entries="$(unzip -Z1 "$archive_path")"; then
		log_error 'Failed to inspect the HackGen font archive'
		return 1
	fi

	while IFS= read -r archive_entry; do
		case "$archive_entry" in
			"$font_name"|*/"$font_name")
				match_count=$((match_count + 1))
				matching_entry="$archive_entry"
				;;
		esac
	done <<< "$archive_entries"

	if [[ "$match_count" -ne 1 ]]; then
		log_error "HackGen font archive must contain exactly one $font_name"
		return 1
	fi

	if ! unzip -p "$archive_path" "$matching_entry" > "$destination_path"; then
		log_error "Failed to extract $font_name from the HackGen font archive"
		return 1
	fi

	if [[ ! -s "$destination_path" ]]; then
		log_error "$font_name extracted from the HackGen font archive is empty"
		return 1
	fi
}

install_hackgen_fonts() (
	local data_home="${XDG_DATA_HOME:-}"
	local font_directory=""
	local work_directory=""
	local metadata_path=""
	local archive_path=""
	local asset_url=""
	local staged_regular_path=""
	local staged_bold_path=""

	if [[ -z "$data_home" ]]; then
		if [[ -z "${HOME:-}" ]]; then
			log_error 'HOME is required for user font installation'
			return 1
		fi
		data_home="$HOME/.local/share"
	fi

	font_directory="$data_home/fonts/HackGen"
	if [[ -f "$font_directory/$HACKGEN_REGULAR_FONT" && -f "$font_directory/$HACKGEN_BOLD_FONT" ]]; then
		log_info 'User font pair is already installed; skipping download'
		return 0
	fi

	for command_name in curl jq unzip fc-cache; do
		if ! command -v "$command_name" >/dev/null 2>&1; then
			log_error "$command_name is required for user font installation"
			return 1
		fi
	done

	work_directory="$(mktemp -d)"
	trap 'rm -rf -- "$work_directory"' EXIT
	metadata_path="$work_directory/latest-release.json"
	archive_path="$work_directory/HackGen_NF.zip"
	staged_regular_path="$work_directory/$HACKGEN_REGULAR_FONT"
	staged_bold_path="$work_directory/$HACKGEN_BOLD_FONT"

	if ! curl --fail --silent --show-error --location "$HACKGEN_RELEASE_API_URL" > "$metadata_path"; then
		log_error 'Failed to retrieve the latest HackGen release metadata'
		return 1
	fi

	if ! asset_url="$(jq -er '[.assets[]? | select(.name? | strings | test("^HackGen_NF_.*\\.zip$")) | select(.browser_download_url? | strings | length > 0) | .browser_download_url] | if length == 1 then .[0] else error("expected exactly one matching asset") end' "$metadata_path")"; then
		log_error 'Could not select exactly one HackGen font archive'
		return 1
	fi

	if [[ -z "$asset_url" ]]; then
		log_error 'The selected HackGen font archive URL is empty'
		return 1
	fi

	if ! curl --fail --silent --show-error --location "$asset_url" > "$archive_path"; then
		log_error 'Failed to download the latest HackGen font archive'
		return 1
	fi

	extract_hackgen_font "$archive_path" "$HACKGEN_REGULAR_FONT" "$staged_regular_path" || return 1
	extract_hackgen_font "$archive_path" "$HACKGEN_BOLD_FONT" "$staged_bold_path" || return 1

	if ! mkdir -p -- "$font_directory"; then
		log_error 'Failed to create the user font directory'
		return 1
	fi

	if ! install -m 0644 -- "$staged_regular_path" "$font_directory/$HACKGEN_REGULAR_FONT"; then
		log_error "Failed to install $HACKGEN_REGULAR_FONT"
		return 1
	fi

	if ! install -m 0644 -- "$staged_bold_path" "$font_directory/$HACKGEN_BOLD_FONT"; then
		log_error "Failed to install $HACKGEN_BOLD_FONT"
		return 1
	fi

	if ! fc-cache -f "$font_directory"; then
		log_error 'Failed to refresh the user font cache'
		return 1
	fi

	log_success 'User fonts are installed'
)

print_usage() {
	cat <<'USAGE'
Usage:
	first-setup.sh [--help]

Description:
	Install the apt packages required by the development tools.
	Prepare the user font environment.
	This script does not install development tools.
USAGE
}

if [[ "$#" -gt 0 ]]; then
	case "$1" in
		--help|-h)
			print_usage
			exit 0
			;;
		*)
			log_error "Unsupported argument: $1"
			exit 2
			;;
	esac
fi

if ! command -v apt-get >/dev/null 2>&1; then
	log_error 'apt-get is required; this script supports Debian/Ubuntu-style systems only'
	exit 1
fi

APT_COMMAND=(apt-get)
if [[ "$EUID" -ne 0 ]]; then
	if ! command -v sudo >/dev/null 2>&1; then
		log_error 'sudo is required when first-setup.sh is not run as root'
		exit 1
	fi
	APT_COMMAND=(sudo apt-get)
fi

log_info 'Updating apt package index'
"${APT_COMMAND[@]}" update

log_info 'Installing development tool dependencies'
"${APT_COMMAND[@]}" install -y "${APT_PACKAGES[@]}"

log_success 'Development tool dependencies are installed'
install_hackgen_fonts
