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
	.zshrc
	.profile
	.zprofile
	.inputrc
	.config/nvim
	.config/herdr/config.toml
	.claude/settings.json
	AGENTS.md
)

# Extra links onto a file already tracked above, so one canonical file serves
# several tools. Format: "<dest under $HOME> <source under dotfiles/home>".
# AGENTS.md is the rule set every agent reads; each entry here is only the name
# that agent insists on:
#   - Claude Code reads CLAUDE.md and never AGENTS.md, and ~/.claude/CLAUDE.md
#     is its one user-level location.
#   - grok looks only in ~/.grok/ for global rules, matching Agents.md,
#     Claude.md, AGENT.md or AGENTS.md. The spelling matters on WSL, whose
#     filesystem is case-sensitive, so an all-caps CLAUDE.md would go unread.
ALIASES=(
	".claude/CLAUDE.md AGENTS.md"
	".grok/AGENTS.md AGENTS.md"
)

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

for rel in "${FILES[@]}"; do
	link "$rel" "$rel"
done

for entry in "${ALIASES[@]}"; do
	read -r dst_rel src_rel <<<"$entry"
	link "$dst_rel" "$src_rel"
done
