#!/usr/bin/env bash
# Symlinks tracked files from home/ into $HOME.
# Safe to re-run: adopts real files on first run, backs up anything
# unexpected on later runs, and skips files already linked correctly.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$REPO_DIR/dotfiles/home"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

FILES=(
	.bashrc
	.profile
	.claude/settings.json
	.claude/CLAUDE.md
)

for rel in "${FILES[@]}"; do
	src="$SRC_DIR/$rel"
	dst="$HOME/$rel"

	mkdir -p "$(dirname "$src")" "$(dirname "$dst")"

	if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
		echo "already linked: $rel"
		continue
	fi

	if [ ! -e "$src" ]; then
		if [ -e "$dst" ]; then
			echo "adopting: $rel"
			mv "$dst" "$src"
		else
			echo "skipping (no source, no target): $rel"
			continue
		fi
	elif [ -e "$dst" ] || [ -L "$dst" ]; then
		echo "backing up existing $rel"
		mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
		mv "$dst" "$BACKUP_DIR/$rel"
	fi

	ln -s "$src" "$dst"
	echo "linked: $rel"
done
