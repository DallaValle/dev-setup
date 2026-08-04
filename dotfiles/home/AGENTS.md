# Sergio's agent instructions

These are common instructions for Sergio's agents across all scenarios.

## General Guidelines

* Never use the em dash "—". Use plain dash "-" instead or comma.
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
