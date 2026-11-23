# Starting, messaging and waiting for workers, per surface

Find out which surface you are on from the tools you have, not from guesses:

| You have | Surface | Workers are |
| --- | --- | --- |
| `start_session`, `list_sessions`, `SendMessage` (desktop app session tools) | Claude desktop app, Code tab | sessions, each in its own worktree |
| `Agent` with `isolation: "worktree"`, `Bash`, no session tools | Claude Code CLI or IDE | background subagents, or extra `claude` processes |
| session tools with `target: "cloud"` allowed | desktop app with cloud access | cloud sessions from a pushed branch |
| no shell, no git (claude.ai chat, a project) | claude.ai | prompts the user pastes into Claude Code |

If a session tool is listed but not loaded, load it first (ToolSearch, `select:<name>`).

## Desktop app

Start one session per task of the wave:

- `initiation`: `"user_asked"` when the user said to start (in their own words); otherwise `"own_initiative"` cards
  they start with a click, or `"offer"` for a task they named in their latest message.
- `context: "fresh"` (the brief carries everything); `"fork"` only while this conversation is short and the task
  leans on it.
- `use_worktree: true`, `source_branch`: the lead branch that holds the committed brief.
- `title`: short task name; `prompt`: "Open `<brief path>`, follow the common preface, do task X, topic T.";
  `background`: how the task fits the waves and which branch it may build on.
- `model`: per the plan (cheaper for read-only or docs work).
- Write a bold title line and one sentence before each start; mark a chapter before starting several.

After starting:

- The result names each session (`local_...` id, short name). Put them in the ledger at once.
- Check the output style and permission mode the user expects (`get_session`; `set_session_output_style`,
  `set_session_permission_mode` only where the user's settings call for it).
- End the turn. The app sends a `<side-sessions-event>` when a session ends a turn and none of yours is still
  working. Its note is the first part of the report, not proof.
- Follow-ups: `SendMessage` to the `local_...` id. Find sessions with `list_sessions` `{"linked": true}`.
- Link every session you mention: `[title](#local_<id>)`.
- After the merge, archive the merged worker's session at once, without asking; before the merge keep it open.
- A turn started by another session or an automated event cannot start sessions: propose cards instead, or run the
  task as a background subagent with `isolation: "worktree"`.

## Claude Code CLI or IDE (no session tools)

Option 1, subagents (inside this process):

- `Agent` with `isolation: "worktree"`, `run_in_background: true`, `subagent_type` per task, the brief as prompt.
  You are re-invoked when each finishes; its final message is its report.
- Follow-ups go to the same agent with `SendMessage` to its id.
- Limits: they share this process's context budget for their reports, and they end when the work ends; a long task
  that needs back-and-forth with the user is better as its own session.

Option 2, separate processes (for long tasks):

- Make the worktree yourself: `git worktree add -b feature/<topic> <worktrees dir>/<topic> <lead branch>`.
- Either ask the user to open a terminal there and run `claude` with the task prompt, or run a headless worker in
  the background with Bash (`run_in_background: true`): `claude -p "<prompt>" --output-format json` from the worktree
  directory, with the permission mode the user allows (check `claude --help` for the flags of the installed
  version; never pick a broader permission mode than the user's own).
- You are notified when the background command exits; read its output file and the branch.

## Cloud sessions

- Only when the user asked for the cloud. The session starts from the pushed lead branch (commit and push the brief
  first) or from the default branch; say which in the brief.
- A cloud session sends no notes back: read its transcript or its pushed branch when the user says it is done.
- It cannot see local-only files (secrets, large content, local tools). Brief it with what exists in the remote.

## claude.ai (no shell, no git)

You can plan and review, not run workers:

1. Build the intake and waves from what the user pastes or a connected source (GitHub connector, uploaded files).
   `scripts/waves.py` runs here if code execution is on.
2. Produce the TASKS file and one ready-to-paste prompt per task (the common preface plus the task block) as a
   document or a file the user downloads.
3. The user starts the workers in Claude Code. They paste each report (or a PR link the connector can read) back
   here; review it with `references/review-merge.md` and answer with the next action.
4. Keep the ledger as a document the user can see; update it on every report.
