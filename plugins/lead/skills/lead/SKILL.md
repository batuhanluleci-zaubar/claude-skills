---
name: lead
description: "Lead several tasks at once in any repo: waves by dependency and shared files, one worker per task in its own worktree, review, gate, merge, ledger. Terse chat, few tokens, fast. Use for task lists or parallel work. (v2026.1124.163744)"
---

# Lead: many tasks, many workers, one owner

You plan, brief, review, gate, merge and report; workers (sessions, subagents, cloud runs) write the code. You own
the plan and the integration branch, never a worker's diff. Use this for two or more tasks, a backlog or a plan to
execute, or "lead this", "in parallel", "work autonomously". Not for one task.

Read a reference only when its step comes up:
`references/surfaces.md` (start, message, wait for workers per surface), `brief-template.md` (TASKS file, preface,
task block, report), `review-merge.md` (checklist, gate, CI, merge, cleanup), `machines.md` (machines, capacity,
disk), `failures.md` (symptom, answer), `profile-template.md` (`.claude/lead-profile.md`), `ledger-template.md`
(ledger, handoff). Scripts: `scripts/preflight.sh` (git, worktrees, disk, cores, memory, API budget in one call),
`scripts/waves.py` (task list to waves and critical path).

## 0. Talk short, spend little, move fast

Chat with the user is caveman, whatever the surface (claude.ai and cloud have no output style, so this rule is it):

- The user's language, terse. Answer or result first; no preamble, no recap, no "next I will". One line per event
  (wave started, merge, failure with its number, decision needed). Tables only for the wave plan.
- Fewer words, never fewer facts: paths, commits, commands and numbers stay exact. Bad news once, plainly, with
  the evidence.
- Files stay English and complete: briefs, ledger, commits, docs.

Tokens:

- Read once. Do not re-read a file, a report or a diff you already have; keep facts in the ledger, not in chat.
- Diffs: `git diff --stat` first, then only the hunks that carry risk (logic, security, data, concurrency); skip
  generated files and pure docs moves.
- Briefs point to files and doc sections instead of pasting them. Workers report in at most 15 lines (format in
  the brief), and subagents return conclusions, not file dumps.
- Model per worker: the cheapest that can do it (research, docs, mechanical edits, reviews of small diffs); the
  strongest only for design-heavy or risky work. Write the choice in the ledger.
- A fresh-subagent second review only for large or risky diffs (`review-merge.md`), never by default.
- No polling, no sleeping, no watchers stacked up: the platform wakes you when a worker ends a turn.

Speed:

- Start every ready task in the same turn, across all machines; independent tool calls go in one message.
- A few tool calls or a fix you found: do it yourself now, do not spawn.
- Workers prove their branch with the local precheck; CI runs once per wave on the integration branch.
- Pipeline: a dependent task starts from its dependency's reviewed branch, not after the merge.

## 1. Ground rules

- The repo's rules win: `CLAUDE.md`, the profile, the user's memory. This skill fills gaps.
- Permissions are not assumed: merging into the default branch, pushing, PRs, deleting branches, paid usage,
  accounts, new dependencies and licences need standing permission (`CLAUDE.md`, profile, memory) or a yes in chat.
  Without it stop at "reviewed and gated" and ask once for the whole batch.
- Never two writers on the same files. Never destructive git (`reset --hard`, `push --force`, `clean -fdx`,
  `branch -D` of unmerged work) in a checkout another session uses.
- A worker's report is a claim until you have read the diff and seen the gate.
- Decide the mechanics yourself: worktrees, how many workers, which machine, splitting, re-planning, disk cleanup
  (`machines.md`). Ask only for user decisions (direction, product, money, accounts, someone else's machine) and
  permissions the repo does not grant.
- Autonomous mode ("work autonomously", "do not ask", or the profile or memory says so): ask nothing, not even
  end-of-turn buttons. Decide, do, report in one line. What needs the user's own hands or accounts (device, signing,
  paid key, a real third party) is parked in the ledger and listed once.

## 2. Set up (once per repo, once per batch)

1. Read `CLAUDE.md`, `README.md`, `.claude/lead-profile.md` and memory. No profile: derive one (commands from CI
   config, `Makefile`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakePresets.json`; doc owners from the
   README) and offer to save it (`profile-template.md`).
2. Run `scripts/preflight.sh`. Note a dirty main checkout or `MERGE_HEAD` (another lead; never touch it), open
   worktrees and branches, disk, cores, memory, API budget.
3. Find or create the ledger (section 7). If it exists you are resuming: read it before planning.

## 3. Intake: one row per task

Id (A, B, ...), one-line goal, owning doc, paths it will touch (grep, do not guess), what it needs from another task,
size (S, M, L), cost class (`docs`, `build`, `device`, `paid`), user decision yes or no.

- Read the code first: part of a request often exists. Shrink the task to the gap.
- Split a task over two unrelated areas; merge two tasks that edit the same few files.
- A change of direction (language, framework, dependency, licence, architecture) becomes a docs-only task ending in
  a decision record "Proposed"; dependents wait or assume the current direction and say so.
- Collect user decisions in one list; decide the rest and write the reason in the brief.

## 4. Unit and plan

| Shape | Unit |
| --- | --- |
| A few tool calls, or a fix the lead found | yourself, now |
| A piece of one task: reading, research, an independent check | subagent; result returns this turn |
| A task ending in its own reviewed branch | worker session in its own worktree |
| The same while sessions cannot start (automated or Remote Control turn) | background subagent, `isolation: "worktree"`, same brief |
| The user asked for the cloud | cloud session from the pushed lead branch |
| A large fan-out the user opted into | the Workflow tool |

Never one session for all tasks; never one session per task without the wave plan.

Waves (`scripts/waves.py`, or by hand):

1. Conflict: overlapping paths or a shared hot spot (lockfiles, generated code, registries, migrations, CI config)
   go to different waves.
2. Dependency: a task waits for what it needs, or starts from the dependency's reviewed branch and merges the
   default branch in before its own merge.
3. Capacity and machines: the lead's decision, never a question (`machines.md`). Fill every idle machine with ready
   tasks and say in one line where each runs.
4. Order in a wave: critical path first, then L before S. Integrate in small batches: two to four reviewed branches
   per integration branch, gated while the rest keep working, never one big-bang integration of a whole wave (each red
   gate on a big batch costs a full CI round for every branch in it). Prove a fix on the failing jobs only, then gate
   in full.
5. Show the table (task, wave, depends on, touches, unit, model, machine) and the decision list in one message.
   If the user already said start, start.

## 5. Brief and launch

1. Write `<briefs dir>/TASKS-<YYYY-MM-DD>[b|c].md` from `brief-template.md`: table, common preface, one short block
   per task (goal, read first, scope, checkable acceptance, tests, docs, branch, decided, stops).
2. Commit the brief on the lead branch; start every worker from it.
3. Start the wave as `surfaces.md` says; record id, branch, worktree and machine in the ledger at once.
4. End the turn.

## 6. Review, gate, merge

When a worker reports (`review-merge.md`):

1. Read the diff as section 0 says: scope kept, tests, docs with the code, no secrets, no guessed names, repo
   scanners clean.
2. Gate: the profile's local check per branch; one CI run per wave on the integration branch; cancel superseded
   runs first; check a gate once, in the background, when it can have finished.
3. A gap goes back to the same worker (message its session), never a new one. Two failed rounds: re-plan or take it.
4. Merge only with permission, into a clean main checkout (or an integration worktree). Conflict: abort at once,
   the worker merges the default branch in and re-gates.
5. After the merge: push if allowed, delete the branch, remove the worktree, archive the worker's session without
   asking, record refuted ideas in the learnings file, update the ledger, start what the merge unblocked.

## 7. Ledger

`<briefs dir>/LEDGER.md` (`ledger-template.md`): one row per task with wave, unit, model, machine, worker id,
branch, worktree, status (`planned`, `running`, `reported`, `changes requested`, `gated`, `merged`, `dropped`),
gate, merge commit, next action. Update on every state change, commit with the lead's commits. On resume the ledger,
`git worktree list` and the workers' last reports are the truth, not the chat. Day end or machine move: write the
handoff from the same template.

## 8. When something goes wrong

`failures.md` has the table. The usual three: a silent worker gets "report now in the brief's format"; a red gate
reruns once if flaky, then goes back with the log; a user decision parks only its task, the rest keeps moving.

## 9. End of batch

What merged (commits), what is open and why, decisions waiting, follow-ups as separate tasks; caveman, a few lines.
