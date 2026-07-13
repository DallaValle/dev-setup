#!/usr/bin/env bash
# Installs the CLI tools the tracked configs assume are present.
# Safe to re-run: each step skips itself if already satisfied.
set -euo pipefail

OS="$(uname -s)"

if command -v tmux >/dev/null; then
	echo "tmux already installed: $(tmux -V)"
elif [ "$OS" = "Darwin" ]; then
	echo "installing tmux via Homebrew"
	brew install tmux
else
	echo "installing tmux via apt"
	sudo apt-get update
	sudo apt-get install -y tmux
fi

echo
if [ "$OS" = "Darwin" ]; then
	if [ -d /Applications/WezTerm.app ] || command -v wezterm >/dev/null; then
		echo "wezterm already installed"
	else
		echo "installing wezterm via Homebrew"
		brew install --cask wezterm
	fi
	echo "Its config is tracked at windows/.wezterm.lua — copy it to ~/.wezterm.lua."
else
	echo "wezterm is a Windows application and cannot be installed from WSL."
	echo "On the Windows host, run: winget install wez.wezterm"
	echo "Its config (.wezterm.lua) is tracked under windows/ and applied manually."
fi
