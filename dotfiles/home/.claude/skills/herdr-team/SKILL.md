---
name: herdr-team
description: "Coordinate parallel agents in Herdr: each task runs as a named agent in its own Herdr tab, git worktree, branch and PR, with this agent as coordinator. Use when HERDR_ENV=1 and the user asks for sub agents, helpers, a team or parallel work, or the work splits into independent tasks. Not for a single straightforward task: do that yourself. Builds on the herdr skill."
---

# Herdr team

Load the `herdr` skill first: it is the reference for every command below, and this file only adds the team conventions.
Where the two disagree, this file wins: the `herdr` skill defaults to a sibling pane, a team uses one tab per task.

## Pick your role first

Decide before touching anything, and say which one you picked:

* **Just do it.** The user hands you one straightforward task, such as "fix issue 123".
  No coordinator and no new agents: do it yourself on one branch and open one PR.
  This holds even when you are already a coordinator: a quick task does not need a new agent, as long as it touches no files an agent of yours has in flight.
  It also holds when a coordinator started you: you are the worker, so do your task and never start agents of your own.
* **Coordinate.** The user asks for a team or parallel work, or the work splits into independent tasks.
  You plan and split the work, start one agent per task in its own tab, and never implement the tasks yourself.

If the split is unclear (one task or several, which files each owns), ask the user before starting anything.

## Preconditions

* Check `test "${HERDR_ENV:-}" = 1`. If it fails, tell the user you are not inside Herdr and fall back to the built in sub agent tool.
* Inside Herdr, never use in chat subagents (Grok `spawn_subagent`, Claude `Agent`) for implementation: they hide under the chat and share one checkout.
  Your own quick read only lookups may still use them.
* The workspace (`$ws`) is `$HERDR_WORKSPACE_ID` and the worktree root (`$WT`) is a sibling folder `../<repo>-worktrees`.
  A repo's AGENTS.md may override either.

## Become the coordinator

Once, before starting the first agent, label where you are.
Your pane stays on the main checkout and is never killed.

```bash
herdr tab rename "$HERDR_TAB_ID" "<short goal label>"
herdr pane rename "$HERDR_PANE_ID" coordinator
```

## Start one agent per task

One task = one git worktree off `origin/main` = one Herdr tab = one named agent = one branch = one PR.
Name the task with a short slug matching `[a-z][a-z0-9_-]{0,31}`, such as `fix-login` or `api-tests`, and use it as worktree, branch, tab label and agent name.
Never start a second agent on a task or files that are already in flight.

```bash
git fetch origin main
git worktree add -b "$task" "$WT/$task" origin/main

created=$(herdr tab create --workspace "$ws" --cwd "$WT/$task" --label "$task" --no-focus)
pane=$(printf '%s\n' "$created" | jq -r '.result.root_pane.pane_id')

# Input typed while zsh is still starting is discarded
herdr pane wait-output "$pane" --regex '(?m)^\$\s*$' --timeout 30000
herdr agent start "$task" --kind <kind> --pane "$pane" --timeout 120000 -- <mode args>
```

* `--no-focus` keeps the user's view where it is; always read IDs from the returned JSON, never guess them.
* `<kind>`: your own kind (`claude` or `grok`) by default.
  Use `codex` for any task that needs images or visual design: mockups, assets, icons, UI built from a design.
  Use another kind when the user asks for it.
* `<mode args>` reproduce your own permission mode, so agents are never more or less trusted than you.
  For Claude Code that is `--permission-mode <mode>` with `default`, `acceptEdits`, `plan`, `auto` or `bypassPermissions`.
  For another kind, use its equivalent flag, and ask the user if you do not know it.
* On `timeout`, read the pane: if it is back at the shell prompt, retry once.
* If an agent keeps failing (server errors, quota), stop it and start a different kind in the same pane.

## Hand out the work

* Write each prompt to stand alone: an agent has none of your context.
  State the goal, scope, the files it owns, constraints and what done means, which is an open PR.
* Ask each agent to end with a short report: the PR link, what changed and what is open.
* Send every prompt first, then wait for all of them concurrently, so a blocked one surfaces at once:

  ```bash
  herdr agent prompt "$task" "$(cat "$prompt_file")"
  herdr agent wait "$task" --until blocked --until done --timeout 120000
  ```

* After prompting, check with `herdr agent read` that it started; Claude can leave a long prompt unsent in its input box, so send `enter`.
* After a `timeout` or `agent_prompt_stalled`, run `herdr agent read` before retrying, so the same prompt is never sent twice.
* When an agent is `blocked`, read what it asks and bring the question to the user. Never answer approvals on the user's behalf.

## Coordinate

* Watch with `herdr agent read <name> --source recent-unwrapped --lines 120`; follow ups go to the same agent with `herdr agent prompt <name> "…"`, which keeps its context.
* Read the reports, cross check them, and give the user one synthesis with every PR link instead of forwarding each report.
* Tell the user which tab holds which agent.
* Agents open PRs; they never merge.

## Leave the team up

Never close the tabs or the agents you started, and never rename the tab back.
The user closes them by hand.
To stop an agent on request: `herdr agent send-keys <name> ctrl+c`, then `/exit` in the pane if it is still up.
