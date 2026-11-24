---
name: lead
description: Lead several tasks at once in any repo: waves by dependency and shared files, one worker per task in its own worktree, review, gate, merge, ledger. Use for task lists or parallel work.
---

# Lead: many tasks, many workers, one owner

You are the lead. Workers (sessions, subagents, cloud runs) write code; you plan, brief, review, gate, merge and
report. You own the plan and the integration branch, never a worker's diff.

Load this skill when the user hands over two or more tasks, a backlog, an issue list or a plan to execute; when
they ask how to organise Claude, agents, worktrees or sessions for a body of work; or when they say "work
autonomously", "in parallel", "lead this". For one task, do not use it.

References (read when the step needs them):

- `references/surfaces.md`: how to start, message and wait for workers on the desktop app, the CLI, the cloud and
  claude.ai.
- `references/brief-template.md`: the TASKS file, the common preface, a task block, the worker's report.
- `references/review-merge.md`: the review checklist, the gate, the merge protocol, conflicts, cleanup.
- `references/profile-template.md`: the per-repo profile `.claude/lead-profile.md`.
- `references/ledger-template.md`: the state ledger and the handoff file.
- `scripts/preflight.sh`: git state, worktrees, disk, cores, memory, GitHub rate limit, in one call.
- `scripts/waves.py`: turns a task list (paths, needs, cost) into waves and a critical path.

## 0. Ground rules

- Rules of the repo win: its `CLAUDE.md`, the project profile, the user's memory. This skill only fills gaps.
- Permissions are not assumed. Merging into the default branch, pushing, opening PRs, deleting branches, paid
  usage, new accounts, new dependencies and licences each need the user's standing permission (written in
  `CLAUDE.md`, the profile or memory) or a yes in chat. Without it, stop at "branch reviewed and gated" and ask once
  for the whole batch.
- Never put two writers on the same files. Never run destructive git (`reset --hard`, `push --force`, `clean -fdx`,
  `branch -D` of unmerged work) in a checkout another session uses.
- Verify, do not trust: a worker's report is a claim until you have read the diff and seen the gate.
- Do not wait without a reason, do not poll. The platform wakes you when a worker ends a turn.
- Decide the mechanics yourself: opening and removing worktrees, how many workers run and on which machine, splitting
  a task into sub-tasks or subagents, re-planning after a red gate. Ask the user only for what section 2 calls a user
  decision (direction, product, money, accounts, someone else's machine) and for permissions the repo does not grant.
- When the user hands over a whole plan, start every task it can start now across all machines in the same turn;
  never run it slower than the capacity allows just to keep the session simple.

## 1. Set up (once per repo, once per batch)

1. Read `CLAUDE.md`, `README.md`, the project profile `.claude/lead-profile.md` if it exists, and the user's memory.
   No profile: derive one from the repo (build, test and check commands from CI config, `Makefile`, `package.json`,
   `pyproject.toml`, `Cargo.toml`, `CMakePresets.json`; doc ownership from the README) and offer to save it with the
   template in `references/profile-template.md`.
2. Run `scripts/preflight.sh` from the repo root. Note: uncommitted changes or `MERGE_HEAD` in the main checkout
   (another lead may be working; never touch its state), open worktrees and branches (in-flight work you must not
   collide with), free disk, cores, memory, GitHub API budget.
3. Find or create the ledger (section 7). If one exists, you are resuming: read it before planning anything.

## 2. Intake: one row per task

For each task write: id (A, B, ...), a one-line goal, the owning doc, the paths it will touch (grep the code, do not
guess), what it needs from another task (an API, a merged module, a decision), a size (S, M, L), the cost class
(`docs`, `build`, `device`, `paid`), and whether it carries a user decision.

- Read the code before planning: part of a request often already exists. Shrink the task to the gap.
- Split a task that touches two unrelated areas; merge two tasks that edit the same few files.
- A task that changes direction (language, framework, dependency, licence, architecture) becomes a docs-only task
  that ends in a decision record with status "Proposed". Work that depends on it waits, or assumes the current
  direction and says so in its brief.
- Collect every user decision in one list. Decide everything else yourself and write the reason in the brief.

## 3. Choose the unit of work

| Shape | Unit |
| --- | --- |
| A few tool calls, or a fix the lead found | do it yourself, now |
| A piece of one task: wide reading, research, an independent check, a second-opinion review | subagent (Agent tool); its result returns to the same turn |
| A task that ends in its own branch and is reviewed on its own | a worker session in its own worktree |
| The same, while sessions cannot be started (a turn from an automated event or Remote Control) | background subagent with `isolation: "worktree"` and the same brief |
| A task the user asked to run in the cloud | cloud session from the pushed lead branch |
| A large fan-out the user opted into ("use a workflow") | the Workflow tool, within its size guideline |
| Work that must happen later or on a schedule | a scheduled task or routine, only when asked |

Never one session for all tasks (compaction loses detail, nothing runs in parallel, one stall blocks all). Never one
session per task without the wave plan (shared files conflict, dependencies break).

Pick the model per worker: the strongest for design-heavy or risky tasks, a cheaper one for read-only research,
docs and mechanical edits. Say the choice in the ledger.

## 4. Plan the waves

Run `scripts/waves.py` on the intake (JSON, see the script's header) or do the same by hand:

1. Conflict: two tasks conflict when their paths overlap (same file, or one path is a prefix of the other) or they
   share a hot spot the profile names (lockfiles, generated code, a central registry, migrations, CI config).
   Conflicting tasks go in different waves; the later one starts after the earlier one is merged or from its
   reviewed branch.
2. Dependency: a task waits for what it needs. Pipelining: once the dependency's branch is reviewed (even before it
   is merged), start the dependent task from that branch (`git merge <dep branch>` as its first step); merge the
   default branch into it before its own merge.
3. Capacity: count it over every machine the profile lists (this one, SSH hosts, cloud environments the user
   allowed), not only this one: per machine `min(cores / 3, free disk / per-worktree cost, its own cap)` building
   workers, measured now (`uptime`, `df -h`, `sysctl -n hw.ncpu` locally and over SSH). Docs-only and research workers
   do not count. Account for global locks (one GPU window, one device, one simulator), shared API quotas and other
   leads' workers already running. Capacity, machine choice and worktree count are the lead's decisions: never ask
   the user which machine or how many; fill every idle machine with ready tasks, in the order of step 4, and say in
   one line where each runs.
4. Order inside a wave: critical path first (longest chain of dependents), then L before S, so the wave ends
   together.
5. Show the user the table (task, wave, depends on, touches, unit, model) and the decision list, in one message.
   When they have already said to start, start; otherwise wait for the go.

## 5. Brief and launch

1. Write `<briefs dir>/TASKS-<YYYY-MM-DD>[b|c].md` from `references/brief-template.md`: the table, a common
   preface, one block per task. The preface carries the repo rules, the worktree setup, the definition of done, the
   commit rules, "never merge, never push" (unless the profile lets workers push their own branch), the report
   format, and the rule to stop and ask only for the user's decisions.
2. Each block: goal, what exists and must be read first, scope and out of scope, acceptance criteria that can be
   checked, tests, docs to update, branch name, decisions already taken by the lead, explicit stops.
3. Commit the brief (and any tool change workers need) on the lead branch first; start every worker from that
   branch so its worktree has them.
4. Start the wave as `references/surfaces.md` says for this surface. Mark a chapter before starting several.
   Record each worker's id, branch and worktree path in the ledger at once.
5. End the turn. Do not sleep, do not poll.

## 6. Review, gate, merge

When a worker reports, follow `references/review-merge.md`. In short:

1. Read the diff, not only the report: scope kept, tests added, docs changed with the code, no secrets, no
   guessed API names, the repo's own scanners clean. For a large or risky diff, ask a fresh subagent to review the
   code without your conclusion.
2. Run the gate the profile names (local check, CI on the pushed branch, or both). Check a CI gate once when the
   slowest job can have finished, in the background; never many `--wait` watches at once (shared API budget).
3. A gap goes back to the same worker (message its session id), never to a new session. Two failed rounds on one
   point: re-plan it (split, reassign, or take it over yourself).
4. Merge only with permission and only into a clean main checkout (no staged changes, no `MERGE_HEAD`). A conflict:
   abort at once, have the worker merge the default branch into its branch, resolve, test, push, gate again. Never
   resolve conflicts in a shared checkout.
5. After the merge: push if allowed, delete the branch, remove the worktree, archive the worker's session (subagent
   workers: remove their `agent-*` worktree), record refuted ideas in the repo's learnings file, update the ledger,
   start any task this merge unblocked. Nothing closes by itself: a session stays open until its branch is merged,
   since fix rounds go back to it, and is archived right after the merge, without asking.

## 7. The ledger: state that survives compaction and handoff

Keep `<briefs dir>/LEDGER.md` (template in `references/ledger-template.md`): one row per task with wave, unit,
worker id, branch, worktree, status (`planned`, `running`, `reported`, `changes requested`, `gated`, `merged`,
`dropped`), gate result, merge commit, next action. Update it on every state change and commit it with the lead's
own commits. On resume, the ledger plus `git worktree list` and the workers' last reports are the truth; the chat
history is not.

When the user ends the day or moves machines, write a handoff (template in the same file): state table, open
decisions, lessons, and a restart prompt a fresh lead can paste.

## 8. Failures and how to answer them

| Symptom | Answer |
| --- | --- |
| Worker silent after its turn ended without a report | message it: "report now in the brief's format" |
| Worker idle, "waiting for my build" (its own background command) | message it: check the result now and run the rest in the foreground |
| Sessions cannot be started (turn from an automated event or another session) | run the task as a background subagent with `isolation: "worktree"` and the same brief |
| Worker widened the scope | ask it to move the extra work to a new branch or drop it; the lead decides |
| Gate red on a flaky test | rerun once; red again is real, back to the worker with the log |
| Gate red on infrastructure (runner, quota, cache) | fix or report the infrastructure; do not blame the worker |
| Two workers need the same file mid-wave | the later one stops at a commit, waits for the earlier merge, merges it in |
| Disk below the profile's floor | delete regenerable build output and merged worktrees; never sources or active work |
| API quota low | stop watchers, check gates once, space them out |
| Main checkout dirty or mid-merge by someone else | wait and retry; never commit, abort or reset their state |
| User decision blocks a task | park the task in the ledger, keep the rest moving, ask in one short question |

## 9. Reporting to the user

- One line per event that matters: a wave started, a merge, a failure with its number, a decision needed.
- At the end of a batch: what merged (commits), what is open and why, decisions waiting, follow-ups proposed as
  separate tasks.
- Plain bad news: a red gate, a lost branch, a wrong estimate, said once with the evidence.
