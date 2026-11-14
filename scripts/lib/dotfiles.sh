#!/usr/bin/env bash

# Keep installation and verification on the same config and provider lists.
# shellcheck disable=SC2034
DOTFILES=(
	.bashrc
	.zshrc
	.zshenv
	.profile
	.zprofile
	.inputrc
	.config/herdr/config.toml
	.claude/settings.json
	.claude/statusline.sh
	.claude/agents
	.codex/config.toml
	.grok/config.toml
	AGENTS.md
)

if [ "$(uname -s)" = Darwin ]; then
	DOTFILES+=("Library/Services/New WezTerm Tab at Folder.workflow")
fi

DOTFILE_ALIASES=(
	".claude/CLAUDE.md AGENTS.md"
	".grok/AGENTS.md AGENTS.md"
	".codex/AGENTS.md AGENTS.md"
)

SKILL_PROVIDERS=(.agents .claude .codex .grok)
