#!/usr/bin/env bash

set -euo pipefail

SHELLCHECK_VERSION="0.11.0"
SHELLCHECK_RELEASE_BASE_URL="https://github.com/koalaman/shellcheck/releases/download"
AGENTS_PATH="${DEV_TOOLS_AGENTS_PATH:-AGENTS.md}"
MANAGED_BLOCK_BEGIN='<!-- BEGIN MYDEVSETUP DEV TOOLS -->'
MANAGED_BLOCK_END='<!-- END MYDEVSETUP DEV TOOLS -->'

print_usage() {
	cat <<'USAGE'
Usage:
	language-tools.sh <tool> [tool ...]

Available tools:
	shell (ShellCheck)
USAGE
}

log_info() {
	printf '[INFO] %s\n' "$1"
}

log_success() {
	printf '[SUCCESS] %s\n' "$1"
}

log_error() {
	printf '[❌️ERROR] %s\n' "$1" >&2
}

local_shellcheck_command_path() {
	local helper_directory="$1"
	local project_directory=""
	local project_prefix=""
	local helper_relative_path=""

	if ! project_directory="$(pwd -P)"; then
		log_error "Could not resolve the project directory for ShellCheck guidance"
		return 1
	fi

	if [[ "$helper_directory" == "$project_directory" ]]; then
		printf '%s' "bin/shellcheck"
		return 0
	fi

	project_prefix="${project_directory%/}/"
	case "$helper_directory" in
		"$project_prefix"*)
			helper_relative_path="${helper_directory#"$project_prefix"}"
			printf '%s/bin/shellcheck' "$helper_relative_path"
			;;
		*)
			printf '%s/bin/shellcheck' "$helper_directory"
			;;
	esac
}

cleanup_agents_temporary_file() {
	local temporary_file="$1"

	if [[ -n "$temporary_file" ]] && [[ -e "$temporary_file" ]]; then
		if ! rm -f -- "$temporary_file"; then
			log_error "Could not remove temporary AGENTS.md file: $temporary_file"
		fi
	fi
}

update_agents_shellcheck_guidance() {
	local shellcheck_path="$1"
	local shellcheck_command=""
	local awk_shellcheck_entry=""
	local entry=""
	local agents_directory=""
	local temporary_file=""
	local begin_count=0
	local end_count=0
	local required_command=""
	local current_umask=""
	local new_file_mode=""

	for required_command in awk chmod cp dirname grep mkdir mktemp mv rm; do
		if ! command -v "$required_command" >/dev/null 2>&1; then
			log_error "Required command is unavailable for ShellCheck AGENTS.md update: $required_command"
			return 1
		fi
	done

	if [[ -L "$AGENTS_PATH" ]]; then
		log_error "Cannot safely update AGENTS.md: $AGENTS_PATH"
		return 1
	fi

	if [[ -e "$AGENTS_PATH" ]] && [[ ! -f "$AGENTS_PATH" || ! -r "$AGENTS_PATH" ]]; then
		log_error "Cannot safely update AGENTS.md: $AGENTS_PATH"
		return 1
	fi

	if [[ -e "$AGENTS_PATH" && ! -w "$AGENTS_PATH" ]]; then
		log_error "Cannot safely update AGENTS.md: $AGENTS_PATH"
		return 1
	fi

	printf -v shellcheck_command '%q' "$shellcheck_path"
	entry="- \`ShellCheck\`: \`$shellcheck_command\` - Use it to lint shell scripts when relevant."
	awk_shellcheck_entry="${entry//\\/\\\\}"
	awk_shellcheck_entry="${awk_shellcheck_entry//\"/\\\"}"

	if [[ -f "$AGENTS_PATH" ]]; then
		begin_count="$(grep -Fxc "$MANAGED_BLOCK_BEGIN" "$AGENTS_PATH" || true)"
		end_count="$(grep -Fxc "$MANAGED_BLOCK_END" "$AGENTS_PATH" || true)"
	fi

	if [[ "$begin_count" -gt 1 || "$end_count" -gt 1 || "$begin_count" -ne "$end_count" ]]; then
		log_error "Cannot update incomplete AGENTS.md managed block"
		return 1
	fi

	if [[ "$begin_count" -eq 1 ]] && ! awk \
		-v begin_marker="$MANAGED_BLOCK_BEGIN" \
		-v end_marker="$MANAGED_BLOCK_END" '
			$0 == begin_marker {
				if (seen_begin || seen_end) invalid = 1
				seen_begin = 1
			}
			$0 == end_marker {
				if (!seen_begin || seen_end) invalid = 1
				seen_end = 1
			}
			END {
				if (invalid || !seen_begin || !seen_end) exit 1
			}
		' "$AGENTS_PATH"; then
		log_error "Cannot update incomplete AGENTS.md managed block"
		return 1
	fi

	agents_directory="$(dirname "$AGENTS_PATH")"
	if [[ ! -d "$agents_directory" ]] && ! mkdir -p "$agents_directory"; then
		log_error "Could not create AGENTS.md directory: $agents_directory"
		return 1
	fi

	if ! temporary_file="$(mktemp "$agents_directory/.language-tools.XXXXXX")"; then
		log_error "Could not create a temporary AGENTS.md file in $agents_directory"
		return 1
	fi

	if [[ -f "$AGENTS_PATH" ]]; then
		if ! cp -p "$AGENTS_PATH" "$temporary_file"; then
			log_error "Could not preserve AGENTS.md permissions: $AGENTS_PATH"
			cleanup_agents_temporary_file "$temporary_file"
			return 1
		fi
	else
		current_umask="$(umask)"
		new_file_mode="$(printf '%o' "$((0666 & ~(8#$current_umask)))")"
		if ! chmod "$new_file_mode" "$temporary_file"; then
			log_error "Could not set permissions for new AGENTS.md"
			cleanup_agents_temporary_file "$temporary_file"
			return 1
		fi
	fi

	if [[ "$begin_count" -eq 1 ]]; then
		if ! awk \
			-v begin_marker="$MANAGED_BLOCK_BEGIN" \
			-v end_marker="$MANAGED_BLOCK_END" \
			-v shellcheck_entry="$awk_shellcheck_entry" '
				$0 == begin_marker {
					inside_block = 1
					print
					next
				}
				$0 == end_marker {
					if (inside_block && !entry_written) print shellcheck_entry
					inside_block = 0
					print
					next
				}
				inside_block && $0 ~ /^- `ShellCheck`:/ {
					if (!entry_written) print shellcheck_entry
					entry_written = 1
					next
				}
				{ print }
			' "$AGENTS_PATH" > "$temporary_file"; then
			log_error "Could not update the ShellCheck entry in AGENTS.md: $AGENTS_PATH"
			cleanup_agents_temporary_file "$temporary_file"
			return 1
		fi
	else
		if [[ -f "$AGENTS_PATH" ]]; then
			if ! awk \
				-v begin_marker="$MANAGED_BLOCK_BEGIN" \
				-v end_marker="$MANAGED_BLOCK_END" \
				-v shellcheck_entry="$awk_shellcheck_entry" '
					{ print; last_line = $0 }
					END {
						if (NR > 0 && last_line != "") print ""
						print begin_marker
						print "## Installed development tools"
						print shellcheck_entry
						print end_marker
					}
				' "$AGENTS_PATH" > "$temporary_file"; then
				log_error "Could not append ShellCheck guidance to AGENTS.md: $AGENTS_PATH"
				cleanup_agents_temporary_file "$temporary_file"
				return 1
			fi
		elif ! printf '%s\n' \
			"$MANAGED_BLOCK_BEGIN" \
			'## Installed development tools' \
			"$entry" \
			"$MANAGED_BLOCK_END" > "$temporary_file"; then
			log_error "Could not append ShellCheck guidance to AGENTS.md: $AGENTS_PATH"
			cleanup_agents_temporary_file "$temporary_file"
			return 1
		fi
	fi

	if ! mv -f "$temporary_file" "$AGENTS_PATH"; then
		log_error "Could not replace AGENTS.md: $AGENTS_PATH"
		cleanup_agents_temporary_file "$temporary_file"
		return 1
	fi

	log_success "Updated ShellCheck guidance in AGENTS.md: $AGENTS_PATH"
}

release_asset_for_platform() {
	local operating_system="$1"
	local architecture="$2"

	case "$operating_system:$architecture" in
		Linux:x86_64|Linux:amd64)
			printf '%s' "linux.x86_64"
			;;
		Linux:aarch64|Linux:arm64)
			printf '%s' "linux.aarch64"
			;;
		Linux:armv6l|Linux:armv6hf)
			printf '%s' "linux.armv6hf"
			;;
		Linux:riscv64)
			printf '%s' "linux.riscv64"
			;;
		Darwin:x86_64|Darwin:amd64)
			printf '%s' "darwin.x86_64"
			;;
		Darwin:arm64|Darwin:aarch64)
			printf '%s' "darwin.aarch64"
			;;
		*)
			return 1
			;;
	esac
}

find_global_package_manager() {
	local operating_system="$1"
	local manager_name=""
	local -a manager_candidates=()

	case "$operating_system" in
		Darwin)
			manager_candidates=(brew nix)
			;;
		Linux)
			manager_candidates=(apt-get dnf yum pacman zypper apk nix brew)
			;;
		*)
			manager_candidates=(nix brew apt-get dnf yum pacman zypper apk)
			;;
	esac

	for manager_name in "${manager_candidates[@]}"; do
		if command -v "$manager_name" >/dev/null 2>&1; then
			printf '%s' "$manager_name"
			return 0
		fi
	done

	return 1
}

run_as_root() {
	if ((EUID == 0)); then
		"$@"
		return $?
	fi

	if ! command -v sudo >/dev/null 2>&1; then
		log_error "Root privileges are required for global ShellCheck installation; install sudo or run as root"
		return 1
	fi

	sudo "$@"
}

install_shellcheck_globally() {
	local operating_system="$1"
	local manager_name=""

	if ! manager_name="$(find_global_package_manager "$operating_system")"; then
		log_error "No supported global package manager is available for the ShellCheck fallback"
		return 1
	fi

	log_info "Installing ShellCheck globally via $manager_name"

	case "$manager_name" in
		apt-get)
			if ! run_as_root apt-get install -y shellcheck; then
				log_error "Global ShellCheck installation failed via apt-get"
				return 1
			fi
			;;
		dnf)
			if ! run_as_root dnf install -y ShellCheck; then
				log_error "Global ShellCheck installation failed via dnf"
				return 1
			fi
			;;
		yum)
			if ! run_as_root yum install -y ShellCheck; then
				log_error "Global ShellCheck installation failed via yum"
				return 1
			fi
			;;
		pacman)
			if ! run_as_root pacman -S --noconfirm shellcheck; then
				log_error "Global ShellCheck installation failed via pacman"
				return 1
			fi
			;;
		zypper)
			if ! run_as_root zypper --non-interactive install --no-recommends ShellCheck; then
				log_error "Global ShellCheck installation failed via zypper"
				return 1
			fi
			;;
		apk)
			if ! run_as_root apk add --no-cache shellcheck; then
				log_error "Global ShellCheck installation failed via apk"
				return 1
			fi
			;;
		nix)
			if ! nix profile install nixpkgs#shellcheck; then
				log_error "Global ShellCheck installation failed via nix"
				return 1
			fi
			;;
		brew)
			if ! brew install shellcheck; then
				log_error "Global ShellCheck installation failed via brew"
				return 1
			fi
			;;
	esac

	log_success "ShellCheck installation command completed via $manager_name"
}

is_matching_local_shellcheck() {
	local shellcheck_path="$1"
	local version_output=""

	[[ -x "$shellcheck_path" ]] || return 1
	if ! version_output="$("$shellcheck_path" --version 2>&1)"; then
		return 1
	fi

	[[ "$version_output" == *"version $SHELLCHECK_VERSION"* ]]
}

cleanup_local_installation() {
	local temporary_directory="$1"
	local temporary_install_path="$2"

	if [[ -n "$temporary_install_path" ]] && [[ -e "$temporary_install_path" ]]; then
		if ! rm -f -- "$temporary_install_path"; then
			log_error "Could not remove temporary file: $temporary_install_path"
		fi
	fi

	if [[ -n "$temporary_directory" ]] && [[ -d "$temporary_directory" ]]; then
		if ! rm -rf -- "$temporary_directory"; then
			log_error "Could not remove temporary directory: $temporary_directory"
		fi
	fi
}

install_shellcheck_locally() {
	local helper_directory="$1"
	local release_asset="$2"
	local install_directory="$helper_directory/bin"
	local install_path="$install_directory/shellcheck"
	local archive_name="shellcheck-v${SHELLCHECK_VERSION}.${release_asset}.tar.gz"
	local archive_binary="shellcheck-v${SHELLCHECK_VERSION}/shellcheck"
	local download_url="$SHELLCHECK_RELEASE_BASE_URL/v${SHELLCHECK_VERSION}/$archive_name"
	local temporary_directory=""
	local temporary_install_path=""
	local required_command=""

	if is_matching_local_shellcheck "$install_path"; then
		log_info "ShellCheck v$SHELLCHECK_VERSION is already installed at $install_path"
		return 0
	fi

	for required_command in curl tar mktemp mkdir cp chmod mv rm; do
		if ! command -v "$required_command" >/dev/null 2>&1; then
			log_error "Required command is unavailable for local ShellCheck installation: $required_command"
			return 1
		fi
	done

	if ! mkdir -p "$install_directory"; then
		log_error "Could not create project-local tool directory: $install_directory"
		return 1
	fi

	if ! temporary_directory="$(mktemp -d)"; then
		log_error "Could not create a temporary directory for ShellCheck installation"
		return 1
	fi

	if ! curl --proto '=https' --tlsv1.2 -fsSL "$download_url" -o "$temporary_directory/$archive_name"; then
		log_error "Failed to download ShellCheck v$SHELLCHECK_VERSION from the official release"
		cleanup_local_installation "$temporary_directory" "$temporary_install_path"
		return 1
	fi

	if ! tar -xzf "$temporary_directory/$archive_name" -C "$temporary_directory" "$archive_binary"; then
		log_error "Failed to extract ShellCheck v$SHELLCHECK_VERSION from the official release"
		cleanup_local_installation "$temporary_directory" "$temporary_install_path"
		return 1
	fi

	if [[ ! -f "$temporary_directory/$archive_binary" ]]; then
		log_error "The ShellCheck release archive did not contain the expected binary"
		cleanup_local_installation "$temporary_directory" "$temporary_install_path"
		return 1
	fi

	if ! temporary_install_path="$(mktemp "$install_directory/.shellcheck.XXXXXX")"; then
		log_error "Could not create a temporary install file in $install_directory"
		cleanup_local_installation "$temporary_directory" "$temporary_install_path"
		return 1
	fi

	if ! cp "$temporary_directory/$archive_binary" "$temporary_install_path"; then
		log_error "Could not copy the ShellCheck binary into $install_directory"
		cleanup_local_installation "$temporary_directory" "$temporary_install_path"
		return 1
	fi

	if ! chmod 0755 "$temporary_install_path"; then
		log_error "Could not make the project-local ShellCheck binary executable"
		cleanup_local_installation "$temporary_directory" "$temporary_install_path"
		return 1
	fi

	if ! mv -f "$temporary_install_path" "$install_path"; then
		log_error "Could not install the project-local ShellCheck binary at $install_path"
		cleanup_local_installation "$temporary_directory" "$temporary_install_path"
		return 1
	fi

	if [[ -e "$temporary_install_path" ]]; then
		cleanup_local_installation "" "$temporary_install_path"
	fi
	if [[ -d "$temporary_directory" ]] && ! rm -rf -- "$temporary_directory"; then
		log_error "ShellCheck was installed, but temporary files could not be removed"
		return 1
	fi

	log_success "Installed ShellCheck v$SHELLCHECK_VERSION at $install_path"
}

install_shellcheck() {
	local helper_directory="$1"
	local operating_system="$2"
	local architecture="$3"
	local release_asset=""
	local shellcheck_path=""

	if release_asset="$(release_asset_for_platform "$operating_system" "$architecture")"; then
		if ! install_shellcheck_locally "$helper_directory" "$release_asset"; then
			return 1
		fi
		if ! shellcheck_path="$(local_shellcheck_command_path "$helper_directory")"; then
			return 1
		fi
	else
		if ! install_shellcheck_globally "$operating_system"; then
			return 1
		fi
		shellcheck_path="shellcheck"
	fi

	update_agents_shellcheck_guidance "$shellcheck_path"
}

main() {
	local requested_tool=""
	local operating_system=""
	local architecture=""
	local helper_directory="${BASH_SOURCE[0]%/*}"

	if (($# == 0)); then
		print_usage
		return 0
	fi

	for requested_tool in "$@"; do
		if [[ "$requested_tool" != "shell" ]]; then
			print_usage
			log_error "Unsupported tool: $requested_tool"
			return 1
		fi
	done

	if [[ "$helper_directory" == "${BASH_SOURCE[0]}" ]]; then
		helper_directory="."
	fi
	if ! helper_directory="$(cd -- "$helper_directory" && pwd -P)"; then
		log_error "Could not resolve the language-tools helper directory"
		return 1
	fi

	if ! operating_system="$(uname -s)" || ! architecture="$(uname -m)"; then
		log_error "Could not determine the operating system and architecture for ShellCheck"
		return 1
	fi

	for requested_tool in "$@"; do
		case "$requested_tool" in
			shell)
				if ! install_shellcheck "$helper_directory" "$operating_system" "$architecture"; then
					return 1
				fi
				;;
		esac
	done
}

if [[ "${BASH_SOURCE[0]:-$0}" == "$0" ]]; then
	main "$@"
fi
