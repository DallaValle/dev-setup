#!/usr/bin/env bash
# Installs the CLI tools the tracked configs assume are present.
# Safe to re-run: each step skips itself if already satisfied.
# macOS: Homebrew. WSL/Linux: apt where reliable, official GitHub release
# binaries for neovim and lazygit (apt's are missing or stale).
# herdr is installed the same way on both, via its official installer.
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
	# Pinned, not "latest": neovim > 0.10.x links glibc 2.32+, but Ubuntu 20.04
	# (focal) ships glibc 2.31, so a "latest" binary installs but won't run here.
	# v0.10.4 is the last focal-compatible release. Bump when the base OS does.
	nvim_version="v0.10.4"
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
			echo "installing neovim $nvim_version from GitHub release"
			tmp="$(mktemp -d)"
			curl -fsSL "https://github.com/neovim/neovim/releases/download/${nvim_version}/${nvim_asset}.tar.gz" -o "$tmp/nvim.tar.gz"
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

# herdr: terminal workspace manager for AI coding agents, a single binary.
# Same installer on macOS and WSL/Linux: the brew formula builds it (and llvm/rust)
# from source, so we use the official installer, which drops a prebuilt binary into
# ~/.local/bin. Not pinned like neovim: herdr updates itself with `herdr update`.
if have herdr; then
	echo "herdr already installed: $(herdr --version)"
else
	echo "installing herdr from herdr.dev/install.sh"
	curl -fsSL https://herdr.dev/install.sh | sh
fi

# treehouse: reusable git worktree pool for parallel AI agent sessions.
# Official installer drops a prebuilt binary into ~/.local/bin on both platforms.
# Not pinned: treehouse updates itself with `treehouse update`.
if have treehouse; then
	echo "treehouse already installed: $(treehouse --version)"
else
	echo "installing treehouse from kunchenguid.github.io/treehouse/install.sh"
	curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh
fi

# grok: xAI's agentic coding CLI, installed via its official installer into
# ~/.grok/bin (it also symlinks into ~/.local/bin). The installer appends its own
# PATH/completions block to .zshrc, which is a symlink into this repo, so it edits
# the tracked .zshrc directly. That block is already committed, and the installer
# replaces it in place rather than duplicating, so re-running is safe.
if have grok; then
	echo "grok already installed: $(grok --version)"
else
	echo "installing grok from x.ai/cli/install.sh"
	curl -fsSL https://x.ai/cli/install.sh | bash
fi

# VS Code: a GUI app, so it is installed per host, not per shell.
# On macOS the cask provides both the app and the `code` CLI. On WSL the editor
# lives on the Windows host and `code` reaches the distro through PATH interop
# (the Remote-WSL extension), so installing a Linux build inside WSL is wrong.
vscode_app="/Applications/Visual Studio Code.app"
vscode_cli="$vscode_app/Contents/Resources/app/bin/code"
if [ "$OS" = "Darwin" ]; then
	if [ -d "$vscode_app" ]; then
		echo "VS Code already installed"
	else
		echo "installing VS Code via Homebrew cask"
		brew install --cask visual-studio-code
	fi

	# Link the CLI ourselves instead of trusting the cask's binary symlink: the app
	# may have been drag-installed outside brew, which leaves no `code` on PATH.
	# ~/.local/bin is already first on PATH in .zshrc, so this works either way.
	if [ -x "$vscode_cli" ]; then
		mkdir -p "$LOCAL_BIN"
		ln -sf "$vscode_cli" "$LOCAL_BIN/code"
		echo "linked code -> $vscode_cli"
	else
		echo "skipping code CLI: $vscode_cli not found"
	fi
elif have code; then
	echo "VS Code reachable as 'code' (Windows host via WSL interop)"
else
	echo "VS Code not on PATH: install it on the Windows host, see programs/vscode.md"
fi

# Make zsh the default login shell. WezTerm opens the login shell (the WSL
# domain on Windows, the native shell on macOS), so this is what makes both
# machines start in zsh. Safe to re-run: skips when zsh is already default.
if have zsh; then
	zsh_path="$(command -v zsh)"
	if [ "$(basename "${SHELL:-}")" = zsh ]; then
		echo "zsh already the default shell"
	else
		# Only touch /etc/shells when we are actually about to chsh: it needs sudo,
		# and on macOS command -v finds Homebrew's zsh while the default stays
		# /bin/zsh, so registering unconditionally means a sudo prompt on every run.
		if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
			echo "registering $zsh_path in /etc/shells"
			echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
		fi
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
