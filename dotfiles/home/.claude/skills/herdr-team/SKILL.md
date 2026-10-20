---
name: herdr-team
description: "Run requested sub agents as named agents in Herdr panes, with this agent as their coordinator. Use whenever the user asks to create, spawn, start or delegate to sub agents, helpers, a team or parallel agents, and HERDR_ENV=1. Builds on the herdr skill."
---

# Herdr team

When the user asks for sub agents, each one runs as a real agent in its own Herdr pane instead of through the built in sub agent tool, and this agent becomes their coordinator.
Load the `herdr` skill first: it is the reference for every command below, and this file only adds the team conventions.

## Preconditions

* Check `test "${HERDR_ENV:-}" = 1`. If it fails, tell the user you are not inside Herdr and fall back to the built in sub agent tool.
* This covers the sub agents the user asks for. Your own quick lookups may still use the built in tool.

## Become the coordinator

Do this once, before starting the first sub agent:

```bash
herdr tab rename "$HERDR_TAB_ID" "<short task label>"
herdr pane rename "$HERDR_PANE_ID" coordinator
```

## Start each sub agent

Give every sub agent a short role name matching `[a-z][a-z0-9_-]{0,31}`, such as `reviewer` or `api-tests`, and use it as both pane label and agent name.

1. Split without stealing focus, keeping the coordinator at full height:
   the first sub agent splits the coordinator `right`, later ones split the newest sub agent pane `down`.
   When that column gets too short (check `herdr pane layout`), split a sub agent pane `right` instead.

   ```bash
   herdr pane split <pane> --direction right --cwd "$PWD" --no-focus   # new id at .result.pane.pane_id
   ```

2. Wait for the new shell's prompt, because input typed while zsh is still starting is discarded:

   ```bash
   herdr pane wait-output <new-pane> --regex '(?m)^\$\s*$' --timeout 30000
   ```

3. Label the pane and start the agent:

   ```bash
   herdr pane rename <new-pane> <name>
   herdr agent start <name> --kind <kind> --pane <new-pane> --timeout 120000 -- <mode args>
   ```

   * `<kind>` is your own agent kind (`claude` for Claude Code, `grok` for grok) unless the user asks for another.
   * `<mode args>` reproduce your own permission mode, so sub agents are never more or less trusted than you.
     For Claude Code that is `--permission-mode <mode>` with `default`, `acceptEdits`, `plan`, `auto` or `bypassPermissions`.
     For another kind, use its equivalent flag, and ask the user if you do not know it.
   * On `timeout`, read the pane: if it is back at the shell prompt, retry once.

## Hand out the work

* Write each prompt to stand alone: a sub agent has none of your context.
  State the goal, scope, relevant files, constraints and what done means.
* Ask each sub agent to write its final report as Markdown to `<report dir>/<name>.md` and to reply with only that path.
  Create the report dir once with `mktemp -d`. Files survive scrollback limits and keep the panes readable.
* Send every prompt first without `--wait`, so the agents work in parallel, then wait for each one:

  ```bash
  herdr agent prompt <name> "<prompt>"
  herdr agent wait <name>
  ```

  Prefer waiting on all of them concurrently, for example one background `agent wait` per agent, so a blocked one surfaces at once.
* After a `timeout` or `agent_prompt_stalled`, run `herdr agent read` before retrying, so the same prompt is never sent twice.
* When an agent is `blocked`, read what it asks and bring the question to the user. Never answer approvals on the user's behalf.

## Coordinate

* Read the reports, cross check them, and give the user one synthesis instead of forwarding each report.
* Send follow ups to the same agent with `herdr agent prompt <name>`: it keeps its own context.
* Tell the user which pane holds which agent.

## Leave the team up

Never close the panes, the tab or the agents you started, and never rename the tab back.
The user closes them by hand.
