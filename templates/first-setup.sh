#!/usr/bin/env bash

set -euo pipefail

APT_PACKAGES=(
	patch
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
	curl
	git
	gh
	unzip
	gzip
	xz-utils
)

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

print_usage() {
	cat <<'USAGE'
Usage:
	first-setup.sh [--help]

Description:
	Install the apt packages required by proto's Ruby source build.
	This script does not install proto or Ruby.
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

log_info 'Installing proto Ruby build dependencies'
"${APT_COMMAND[@]}" install -y "${APT_PACKAGES[@]}"

log_success 'Proto Ruby build dependencies are installed'
