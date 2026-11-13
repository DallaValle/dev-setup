#!/usr/bin/env bash
# Checks installation without launching apps or exposing account credentials.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"
failures=0

have() { command -v "$1" >/dev/null 2>&1; }

check() {
	local label="$1"
	shift
	if "$@"; then
		echo "OK: $label"
	else
		echo "MISSING: $label"
		failures=$((failures + 1))
	fi
}

linked() {
	[ -L "$HOME/$1" ] && [ "$(readlink "$HOME/$1")" = "$REPO_DIR/dotfiles/home/$2" ] && [ -e "$HOME/$1" ]
}

if [ "$(uname -s)" != Darwin ]; then
	echo "This installation check currently covers macOS." >&2
	exit 1
fi

# shellcheck source=scripts/lib/macos.sh
source "$REPO_DIR/scripts/lib/macos.sh"
# shellcheck source=scripts/lib/dotfiles.sh
source "$REPO_DIR/scripts/lib/dotfiles.sh"
check Homebrew load_homebrew
for cmd in git gh rg fd fzf jq lazygit node npm zsh gh-axi chrome-devtools-axi herdr treehouse codex claude code; do
	check "command $cmd" have "$cmd"
done

for app in "${MACOS_APPS[@]}"; do
	name="${app#*:}"
	if [ -d "/Applications/$name.app" ] || [ -d "$HOME/Applications/$name.app" ]; then
		echo "OK: $name"
	else
		echo "MISSING: $name"
		failures=$((failures + 1))
	fi
done

for rel in "${DOTFILES[@]}"; do
	[ -e "$REPO_DIR/dotfiles/home/$rel" ] || continue
	check "config $rel" linked "$rel" "$rel"
done
for entry in "${DOTFILE_ALIASES[@]}"; do
	read -r dst_rel src_rel <<<"$entry"
	check "$dst_rel" linked "$dst_rel" "$src_rel"
done
for skill in "$REPO_DIR/dotfiles/home/.agents/skills"/*/; do
	[ -f "${skill}SKILL.md" ] || continue
	name="$(basename "$skill")"
	for provider in "${SKILL_PROVIDERS[@]}"; do
		check "skill $provider/$name" linked "$provider/skills/$name" ".agents/skills/$name"
	done
done
check "WezTerm config matches repo" cmp -s "$REPO_DIR/dotfiles/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"
check "zsh config syntax" zsh -n "$REPO_DIR/dotfiles/home/.zshrc"

echo
if [ "$failures" -gt 0 ]; then
	echo "Installation checks failed: $failures. Rerun ./scripts/bootstrap.sh to apply setup."
	exit 1
fi
echo "Installation checks passed. Account sign-ins and app permissions need manual verification."
