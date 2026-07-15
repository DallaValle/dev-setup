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
echo "WezTerm is not handled here, follow programs/wezterm.md to install and configure it on Windows and macOS."
