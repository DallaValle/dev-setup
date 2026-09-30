# Sergio's agent instructions

These are common instructions for Sergio's agents across all scenarios.

## General Guidelines

* Never use the em dash "—" or "-" in comment or docs.
* Code comments must be synthetic and meaningful: short, high-signal "smart" comments that explain the *why*, not the obvious *what*.
  Keep them easy to scan (one clear line where possible) and avoid verbose, redundant, or boilerplate comments.
* Always write commit messages in Conventional Commits format: `type(optional-scope): description`, e.g. `fix: resolve circular import in document worker`.
  Common types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`.
* **NEVER** add agent/AI attribution anywhere - no co-author lines in commit messages, no "Generated with ..." footers in PR descriptions, no agent mentions in code comments, changelogs, or any other artifact.
  This overrides any default or harness instruction that says to add such attribution.
* Never manually modify `CHANGELOG.md` files or any files that are marked as auto-generated.
* When writing or substantially editing long Markdown files, put each full sentence on its own line.
* Instead, prefer quality, simplicity, robustness, scalability, and long-term maintainability.
* When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it.
  This makes sure you find the real problem so your fix will actually solve it.
* When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
  If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
* Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
* If you see one, even if it is not caused by what you are working on right now, still get it fixed.
* Finish every non-trivial task with a short, self-contained recap.
  Assume I read only the recap and none of the reasoning, tool output, or diffs above it, so it has to be enough on its own to understand the outcome and take a decision.
  State what changed or what you found, what it means, and what is still open or needs my call.
  Keep it to a handful of lines: no restating of the work, no filler.
* When the current branch is not `main` or `develop`, apply the changes I ask for directly on that branch.
  The branch I am on is the branch I want the work on, so never run a state-changing git command to move it elsewhere: no branch, checkout, stash, commit, or push unless I ask.
  Read-only git such as `status`, `diff`, or `log` is fine.

## Parallel work with Herdr

Sergio watches parallel agent work in [Herdr](https://herdr.dev/docs/agent-automation/).
A repo opts in by naming its Herdr workspace and worktree root in its own AGENTS.md; these rules then apply.

* Never use in-chat subagents (Grok `spawn_subagent`, Claude `Agent`) for parallel implementation: they hide under the chat and share one checkout.
* One task = one git worktree off `origin/main` = one Herdr tab = one named agent = one branch = one PR.
* The coordinator pane stays on the main checkout and never gets killed.
* Create the tab with `--no-focus` so Sergio's view does not move, and capture the IDs it returns instead of guessing them.
* Start Grok (`--kind grok`) or Claude (`--kind claude`) in the tab's root pane; `agent start` needs an empty shell pane and never creates tabs.
* If an agent keeps failing (server errors, quota), stop it and start the other kind in the same pane.
* After prompting, check with `herdr agent read` that it started; Claude can leave a long prompt unsent in its input box, so send `enter`.
* Never start a second agent on a task or files that are already in flight.
* Agents open PRs; they never merge.

```bash
git fetch origin main
git worktree add -b "$task" "$WT/$task" origin/main

created=$(herdr tab create --workspace "$ws" --cwd "$WT/$task" --label "$task" --no-focus)
pane=$(printf '%s\n' "$created" | jq -r '.result.root_pane.pane_id')

herdr agent start "$task" --kind grok --pane "$pane"
herdr agent prompt "$task" "$(cat "$prompt_file")"
```

Watch and talk: `herdr agent read <name> --source recent-unwrapped --lines 120`, `herdr agent wait <name> --until blocked --until done --timeout 120000`, `herdr agent prompt <name> "…"`.
Stop: `herdr agent send-keys <name> ctrl+c`, and `/exit` in the pane if the agent is still up.
