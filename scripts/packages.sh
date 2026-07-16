#!/usr/bin/env bash
# Installs the CLI tools the tracked configs assume are present.
# Safe to re-run: each step skips itself if already satisfied.
# macOS: everything via Homebrew. WSL/Linux: apt where reliable, official
# GitHub release binaries for neovim and lazygit (apt's are missing or stale).
set -euo pipefail

OS="$(uname -s)"
ARCH="$(uname -m)"
LOCAL_BIN="$HOME/.local/bin"

have() { command -v "$1" >/dev/null 2>&1; }

if [ "$OS" = "Darwin" ]; then
	for pkg in tmux ripgrep fd fzf jq lazygit neovim zsh zsh-autosuggestions zsh-syntax-highlighting; do
		if brew list --versions "$pkg" >/dev/null 2>&1; then
			echo "$pkg already installed"
		else
			echo "installing $pkg via Homebrew"
			brew install "$pkg"
		fi
	done
else
	mkdir -p "$LOCAL_BIN"

	# apt-provided tools: collect the missing ones, then one update + install
	apt_need=()
	have curl                 || apt_need+=(curl)
	have rg                   || apt_need+=(ripgrep)
	have fd || have fdfind    || apt_need+=(fd-find)
	have fzf                  || apt_need+=(fzf)
	have jq                   || apt_need+=(jq)
	have tmux                 || apt_need+=(tmux)
	have zsh                  || apt_need+=(zsh)
	[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] || apt_need+=(zsh-autosuggestions)
	[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] || apt_need+=(zsh-syntax-highlighting)

	if [ ${#apt_need[@]} -gt 0 ]; then
		echo "installing via apt: ${apt_need[*]}"
		sudo apt-get update
		sudo apt-get install -y "${apt_need[@]}"
	else
		echo "apt tools already installed"
	fi

	# On Debian/Ubuntu fd ships as fdfind; expose it under the expected name.
	if ! have fd && have fdfind; then
		ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
		echo "linked fd -> fdfind"
	fi

	# neovim: apt's build is too old, install the official release tarball.
	if have nvim; then
		echo "neovim already installed: $(nvim --version | head -1)"
	else
		case "$ARCH" in
			x86_64) nvim_asset="nvim-linux-x86_64" ;;
			aarch64 | arm64) nvim_asset="nvim-linux-arm64" ;;
			*) nvim_asset="" ;;
		esac
		if [ -z "$nvim_asset" ]; then
			echo "skipping neovim: unsupported arch $ARCH"
		else
			echo "installing neovim from GitHub release"
			tmp="$(mktemp -d)"
			curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/${nvim_asset}.tar.gz" -o "$tmp/nvim.tar.gz"
			tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
			rm -rf "$HOME/.local/nvim"
			mv "$tmp/${nvim_asset}" "$HOME/.local/nvim"
			ln -sf "$HOME/.local/nvim/bin/nvim" "$LOCAL_BIN/nvim"
			rm -rf "$tmp"
		fi
	fi

	# lazygit: not packaged for older Ubuntu, install the release binary.
	if have lazygit; then
		echo "lazygit already installed"
	else
		case "$ARCH" in
			x86_64) lg_arch="x86_64" ;;
			aarch64 | arm64) lg_arch="arm64" ;;
			*) lg_arch="" ;;
		esac
		if [ -z "$lg_arch" ]; then
			echo "skipping lazygit: unsupported arch $ARCH"
		else
			echo "installing lazygit from GitHub release"
			ver="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": *"v\K[^"]*')"
			tmp="$(mktemp -d)"
			curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${ver}/lazygit_${ver}_Linux_${lg_arch}.tar.gz" -o "$tmp/lazygit.tar.gz"
			tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
			install -m 755 "$tmp/lazygit" "$LOCAL_BIN/lazygit"
			rm -rf "$tmp"
		fi
	fi
fi

# Make zsh the default login shell. WezTerm opens the login shell (the WSL
# domain on Windows, the native shell on macOS), so this is what makes both
# machines start in zsh. Safe to re-run: skips when zsh is already default.
if have zsh; then
	zsh_path="$(command -v zsh)"
	if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
		echo "registering $zsh_path in /etc/shells"
		echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
	fi
	if [ "$(basename "${SHELL:-}")" = zsh ]; then
		echo "zsh already the default shell"
	else
		echo "setting zsh as the default shell (you may be prompted for your password)"
		if chsh -s "$zsh_path"; then
			echo "default shell set to zsh, restart your terminal to pick it up"
		else
			echo "chsh failed, set it manually with: chsh -s \"$zsh_path\""
		fi
	fi
fi

echo
echo "WezTerm is not handled here, follow programs/wezterm.md to install and configure it on Windows and macOS."
