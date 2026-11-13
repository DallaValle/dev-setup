#!/usr/bin/env bash
# Symlinks tracked files from dotfiles/home/ into $HOME.
# Safe to re-run: adopts real files on first run, backs up anything
# unexpected on later runs, and skips files already linked correctly.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$REPO_DIR/dotfiles/home"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# shellcheck source=scripts/lib/dotfiles.sh
source "$REPO_DIR/scripts/lib/dotfiles.sh"

# Link $2 (under dotfiles/home) to $1 (under $HOME), reporting it as $1.
link() {
	local rel="$1" src="$SRC_DIR/$2" dst="$HOME/$1"

	mkdir -p "$(dirname "$src")" "$(dirname "$dst")"

	if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
		echo "already linked: $rel"
		return
	fi

	if [ ! -e "$src" ]; then
		# An alias points at a file that should already be tracked, so a missing
		# source is a mistake to report, never something to adopt: adopting would
		# move the alias target onto the canonical path and swap the two roles.
		if [ "$rel" != "$2" ]; then
			echo "skipping (missing source $2): $rel"
			return
		fi
		if [ -e "$dst" ]; then
			echo "adopting: $rel"
			mv "$dst" "$src"
		else
			echo "skipping (no source, no target): $rel"
			return
		fi
	elif [ -e "$dst" ] || [ -L "$dst" ]; then
		echo "backing up existing $rel"
		mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
		mv "$dst" "$BACKUP_DIR/$rel"
	fi

	ln -s "$src" "$dst"
	echo "linked: $rel"
}

for rel in "${DOTFILES[@]}"; do
	link "$rel" "$rel"
done

for entry in "${DOTFILE_ALIASES[@]}"; do
	read -r dst_rel src_rel <<<"$entry"
	link "$dst_rel" "$src_rel"
done

# Keep manually installed skills identical across providers.
for skill in "$SRC_DIR/.agents/skills"/*/; do
	[ -f "${skill}SKILL.md" ] || continue
	name="$(basename "$skill")"
	for provider in "${SKILL_PROVIDERS[@]}"; do
		link "$provider/skills/$name" ".agents/skills/$name"
	done
done
