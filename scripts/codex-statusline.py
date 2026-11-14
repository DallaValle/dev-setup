#!/usr/bin/env python3
"""Apply footer preferences without tracking private Codex config."""

import os
from pathlib import Path
import re


def configure(text):
    setting = 'status_line = ["model-with-reasoning", "context-remaining", "five-hour-limit", "weekly-limit"]\n'
    section = re.search(r"(?m)^\[tui\][ \t]*(?:#.*)?\n", text)
    if section is None:
        return text.rstrip() + "\n\n[tui]\n" + setting

    start = section.end()
    following = re.search(r"(?m)^\[", text[start:])
    end = start + following.start() if following else len(text)
    body = text[start:end]
    existing = re.search(
        r"(?m)^status_line[ \t]*=[ \t]*(?:\[[^\]]*\]|[^\n]*)[^\n]*(?:\n|$)",
        body,
    )
    if existing:
        body = body[:existing.start()] + setting + body[existing.end():]
    else:
        body = setting + body
    return text[:start] + body + text[end:]


if __name__ == "__main__":
    home = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
    config = home / "config.toml"
    home.mkdir(parents=True, exist_ok=True)
    original = config.read_text() if config.exists() else ""
    updated = configure(original)
    if updated != original:
        config.write_text(updated)
    print("Codex footer configured with five-hour and weekly usage remaining.")
