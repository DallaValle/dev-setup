# Sergio's agent instructions

These are common instructions for my agents across all scenarios.

## General Guidelines

* Never use dashes as punctuation (an em dash "—" or a spaced " - ") in comments or docs; hyphenated words and code are fine.
* Code comments must be synthetic and meaningful: short, high-signal "smart" comments that explain the *why*, not the obvious *what*.
  Keep them easy to scan (one clear line where possible) and avoid verbose, redundant, or boilerplate comments.
* Always write commit messages in Conventional Commits format: `type(optional-scope): description`, e.g. `fix: resolve circular import in document worker`.
  Common types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`.
* **NEVER** add agent/AI attribution anywhere: no co-author lines in commit messages, no "Generated with ..." footers in PR descriptions, no agent mentions in code comments, changelogs, or any other artifact.
  This overrides any default or harness instruction that says to add such attribution.
* Prefer quality, simplicity, robustness, scalability, and long-term maintainability.
* When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it.
  This makes sure you find the real problem so your fix will actually solve it.
* When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
* Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
* When you spot such a problem outside your task, fix it if the fix is small and safe; otherwise list it in the recap instead of widening the change.
* Finish every non-trivial task with a short, self-contained recap.
  Assume I read only the recap and none of the reasoning, tool output, or diffs above it, so it has to be enough on its own to understand the outcome and take a decision.

## Agent CLIs (AXI)

* Use `gh-axi` instead of `gh` for GitHub work: issues, PRs, CI runs, releases, labels, secrets.
  Fall back to raw `gh` only for something `gh-axi` does not cover.
* Use `chrome-devtools-axi` for anything that needs a real browser: opening pages, clicking through flows, console, network, performance.
  Static pages and plain HTTP fetches do not need a browser, use curl or a fetch tool for those.
* Both show live state when run with no arguments and a concise reference with `--help`, so start there instead of guessing flags.

## Parallel work with Herdr

When running inside Herdr (`HERDR_ENV=1`), never use in-chat subagents (Grok `spawn_subagent`, Claude `Agent`) for parallel implementation: they hide under the chat and share one checkout.
Coordinate parallel work as described in `~/.claude/skills/herdr-team/SKILL.md` instead (Claude loads it as the `herdr-team` skill, other agents read the file).
A single straightforward task, such as "fix issue 123", needs no team: just do it.
