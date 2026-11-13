#!/usr/bin/env bash
# Completes a macOS checkout's setup without relying on an existing shell config.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "$(uname -s)" != Darwin ]; then
	echo "This bootstrap is for macOS. On WSL/Linux, run packages.sh then install.sh." >&2
	exit 1
fi
if [ "$(id -u)" = 0 ]; then
	echo "Run as your normal macOS user, without sudo." >&2
	exit 1
fi
if ! xcode-select -p >/dev/null 2>&1; then
	echo "Run xcode-select --install, finish the Apple installer, then rerun this script." >&2
	exit 1
fi

# shellcheck source=scripts/lib/macos.sh
source "$REPO_DIR/scripts/lib/macos.sh"
if ! load_homebrew; then
	echo "Installing Homebrew; macOS may ask for your administrator password."
	installer="$(mktemp)"
	trap 'rm -f "$installer"' EXIT
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"
	/bin/bash "$installer"
	load_homebrew
fi

"$REPO_DIR/scripts/packages.sh"
"$REPO_DIR/scripts/install.sh"

wezterm_src="$REPO_DIR/dotfiles/wezterm/.wezterm.lua"
wezterm_dst="$HOME/.wezterm.lua"
if ! cmp -s "$wezterm_src" "$wezterm_dst"; then
	if [ -e "$wezterm_dst" ] || [ -L "$wezterm_dst" ]; then
		backup_dir="$(mktemp -d "$HOME/.dotfiles-backup-wezterm.XXXXXX")"
		mv "$wezterm_dst" "$backup_dir/.wezterm.lua"
		echo "Backed up existing WezTerm config to $backup_dir/.wezterm.lua"
	fi
	cp "$wezterm_src" "$wezterm_dst"
	echo "Copied WezTerm config"
fi

"$REPO_DIR/scripts/check.sh"
echo
echo "Setup applied. Open a new WezTerm window to load the shell config."
echo "Finish account sign-ins and macOS permissions using the README checklist."
