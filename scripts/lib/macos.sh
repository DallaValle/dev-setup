#!/usr/bin/env bash

# Consumed by both the installer and the read-only installation check.
# shellcheck disable=SC2034
MACOS_APPS=(
	"brave-browser:Brave Browser"
	"tailscale-app:Tailscale"
	"wezterm:WezTerm"
	"maccy:Maccy"
	"visual-studio-code:Visual Studio Code"
	"docker-desktop:Docker"
	"keepingyouawake:KeepingYouAwake"
	"google-chrome:Google Chrome"
)

load_homebrew() {
	local brew_path
	# New shells may not know Homebrew's location until dotfiles are linked.
	if ! command -v brew >/dev/null 2>&1; then
		for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
			if [ -x "$brew_path" ]; then
				export PATH="${brew_path%/*}:$PATH"
				break
			fi
		done
	fi
	command -v brew >/dev/null 2>&1 || return 1
	local brew_env
	brew_env="$(brew shellenv)" || return 1
	eval "$brew_env"
}
