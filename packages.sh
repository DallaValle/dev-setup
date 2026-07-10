#!/usr/bin/env bash
# Installs the CLI tools the tracked configs assume are present.
# Safe to re-run: each step skips itself if already satisfied.
set -euo pipefail

if command -v tmux >/dev/null; then
	echo "tmux already installed: $(tmux -V)"
else
	echo "installing tmux via apt"
	sudo apt-get update
	sudo apt-get install -y tmux
fi

if command -v nvim >/dev/null; then
	echo "nvim already installed: $(nvim --version | head -1)"
else
	echo "installing nvim from GitHub releases"
	mkdir -p ~/.local/bin
	tmp="$(mktemp -d)"
	url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
	curl -fL "$url" -o "$tmp/nvim.tar.gz" \
		|| curl -fL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz" -o "$tmp/nvim.tar.gz"
	tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
	cp "$tmp"/nvim-linux*/bin/nvim ~/.local/bin/nvim
	rm -rf "$tmp"
	echo "installed: $(nvim --version | head -1)"
fi

echo
echo "wezterm is a Windows application and cannot be installed from WSL."
echo "On the Windows host, run: winget install wez.wezterm"
echo "Its config (.wezterm.lua) is tracked under windows/ and applied manually."
