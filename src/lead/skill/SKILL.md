---
name: lead
description: "Run several independent tasks in parallel: wave plan, one worker per worktree, two-stage review, merge. Not for a single task."
---

# Lead: many tasks, many workers, one owner

You plan, brief, review, gate, merge and report; workers (sessions, subagents, cloud runs) write the code. You own
the plan and the integration branch, never a worker's diff. Use this for two or more tasks, a backlog or a plan to
execute, or "lead this", "in parallel", "work autonomously". Not for one task.

**Go or no-go first.** Parallel work costs tokens: one agent uses about 4 times a chat's tokens, a multi-agent run
about 15 times (Anthropic, "How we built our multi-agent research system", 2025). It pays only where tasks are
independent. After intake run `scripts/waves.py`: if its verdict is `serial` (no wave holds two building tasks, or
every task waits on the one before), do the tasks yourself in order, or hand the whole chain to one worker, and say so
in one line. Tightly coupled steps of one change (one feature across layers that must land together) are one task.

Read a reference only when its step comes up:
`references/surfaces.md` (start, message, wait for workers per surface), `brief-template.md` (TASKS file, preface,
task block, report), `review-merge.md` (checklist, gate, CI, merge, cleanup), `machines.md` (machines, capacity,
disk), `failures.md` (symptom, answer), `profile-template.md` (`.claude/lead-profile.md`), `ledger-template.md`
(ledger, handoff). Scripts: `scripts/preflight.sh` (git, worktrees, disk, cores, memory, API budget in one call),
`scripts/waves.py` (task list to waves, critical path and the go or no-go verdict), `scripts/drift.py` (files each
running branch really touches, against its brief and the other branches), `evals/` (scenarios to check the skill
after a change).

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
- No busy polling, no sleeping, no watchers stacked up: the platform wakes you when a worker ends a turn. That is not
  supervision: a running worker is inspected at checkpoints (section 5b), which cost a few git calls each.

Speed:

- Start every ready task in the same turn, across all machines; independent tool calls go in one message.
- A few tool calls, or a fix outside every worker's scope that you found: do it yourself now, do not spawn. Inside a
  worker's scope the fix goes back to that worker (section 6).
- Workers prove their branch with the local precheck; CI runs once per wave on the integration branch.
- Pipeline: a dependent task starts from its dependency's reviewed branch, not after the merge.
- Timebox every investigation in its brief: a root-cause hunt gets 30 to 45 minutes. Before funding one, ask "does
  the root cause change the fix?"; if not, ship the fix now. When the box runs out, the lead decides a policy or a
  workaround and grants no extension (`failures.md`, "Investigation past its timebox").
- Every order to a worker carries a hard ETA; at the ETA ask for a one-line status.
- A single global lock (one test device, one GPU) is the critical path. Schedule it in the ledger (owner, slot,
  hand-back); workers code while another worker holds it, and the lead batches the proofs into one integrated device
  pass, not one pass per worker.
- Token budget per batch: write it in the ledger header at intake (default: the tasks' sizes, S = 1, M = 2, L = 4
  worker-sessions' worth). Past 80 % of it, cut the optional tracks and say so in one line; past 100 %, stop starting
  work and ask.
- Main goal at risk: cut the optional tracks. Exploratory variants (training sweeps, A/B tables for the user) get a
  fixed count, and the lead takes a measurable decision itself instead of preparing a table for the user.

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
  end-of-turn buttons. It grants no permission: merging, pushing and paid usage still need the standing permission
  above; without it, finish at "reviewed and gated" and list the batch once. Decide, do, report in one line. What
  needs the user's own hands or accounts (device, signing, paid key, a real third party) is parked in the ledger and
  listed once.

## 2. Set up (once per repo, once per batch)

1. Read `CLAUDE.md`, `README.md`, `.claude/lead-profile.md` and memory. No profile: derive one (commands from CI
   config, `Makefile`, `package.json`, `pyproject.toml`, `Cargo.toml`, `CMakePresets.json`; doc owners from the
   README) and offer to save it (`profile-template.md`).
2. List the machines before any plan: the profile's `Machines`, the session tools' start targets (desktop app:
   `list_start_targets`), `~/.ssh/config`, memory. Never write "not available here" (a GPU, CUDA, another OS, a
   device) into a brief before this list is read; a machine the profile lacks is added to it (`machines.md`).
3. Run `scripts/preflight.sh`. Note a dirty main checkout or `MERGE_HEAD` (another lead; never touch it), open
   worktrees and branches, disk, cores, memory, API budget.
4. Find or create the ledger (section 7). If it exists you are resuming: read it before planning.

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
3. Start the wave as `surfaces.md` says; record id, branch, worktree, machine and the **base commit** (the commit the
   worker starts from) in the ledger at once. Every later diff is taken against that base, never `HEAD~1`.
4. Schedule the first checkpoint (section 5b), then end the turn.

## 5b. Supervise while they run

Waiting for a worker's final report is not leading. Inspect every running worker at a checkpoint: about every 20 to 30
minutes, at each quarter of its time box, and on every turn-end note that is not its final report. One wake-up covers
all workers (a scheduled wake-up or a loop where the surface has one; otherwise each note and each user message is a
checkpoint). A checkpoint reads the work, never the worker's word:

1. `git fetch`; per worker `git log <base>..origin/<branch>` and, where its tree is reachable, `git status --short`
   there: what is committed, what lies uncommitted and for how long. `scripts/drift.py` for paths outside the brief.
2. The top of its doc or WIP notes, and the first lines of new code: is it doing the brief's task, by the brief's
   method, with the tool the brief named (the production tool, not a stand-in)? Read the decision it took first.
3. Its machine: is its job alive (process, GPU or device in use by it and only by it), is a lock held correctly.
4. Act at once on what you see: a wrong direction or a stand-in tool gets a correcting message now, not at the report;
   an hour of uncommitted work gets "commit and push"; no commit and no live job since the last checkpoint gets
   "one-line status now: done, blocked on, or new ETA"; a finding another worker needs is forwarded to it.
5. Read each worker's LAST MESSAGE IN FULL (the session's transcript, not the first lines of a turn-end note: a note
   is cut short and the question sits at the end). A worker that ended its turn on a question, a choice, an offer
   ("shall I...", "which of...") or a request for a go-ahead is STOPPED until someone answers, and that someone is the
   lead. Answer in the same turn, in its session: decide what is the lead's to decide (method, order, scope, which
   variant, time box, a lock) and say why in one line; relay to the user only what is the user's (direction, money,
   accounts, a permission the repo does not grant) and tell the worker what to do meanwhile. Never leave a worker
   idle on a question, and never count "it reported" when the report ends in one.
6. One ledger line per checkpoint (time, per worker: last commit, state, what you did), and one line to the user only
   when something changed.

A checkpoint that finds nothing wrong costs under a minute; skipping them costs the whole time box when a worker
drifted in its first ten minutes.

## 6. Review, gate, merge

When a worker reports (`review-merge.md`), its first line is a status: `DONE`, `DONE_WITH_CONCERNS`,
`NEEDS_CONTEXT` or `BLOCKED`. `NEEDS_CONTEXT` gets the missing facts, `BLOCKED` a decision or a re-plan; the two
`DONE`s go to review. While a wave runs, `scripts/drift.py` shows branches that left their brief's paths or now
overlap: stop the later one before it grows.

1. Review in two stages, each with its own verdict in the ledger, both required: **spec** (does the diff do what the
   brief asked, all acceptance criteria shown, nothing outside scope; "close enough" is a fail) and then **quality**
   (correct, tested, docs with the code, no secrets, no guessed names, repo scanners clean). Read the diff as
   section 0 says, against the recorded base.
2. Gate: the profile's local check per branch; one CI run per wave on the integration branch; cancel superseded
   runs first; check a gate once, in the background, when it can have finished.
3. A gap goes back to the same worker (message its session), never a new one, and the lead does not patch it. Round
   two runs on the next stronger model; after a third failed round the lead re-plans, takes the task itself, or parks
   the finding with a ruling in the ledger. Never drop a finding silently.
4. Merge only with permission, into a clean main checkout (or an integration worktree). Conflict: abort at once,
   the worker merges the default branch in and re-gates.
5. After the merge: push if allowed, delete the branch, remove the worktree (never one whose build output is still
   the base of a staged or pending build, `review-merge.md`), archive the worker's session without
   asking, record refuted ideas in the learnings file, update the ledger, start what the merge unblocked.

## 7. Ledger

`<briefs dir>/LEDGER.md` (`ledger-template.md`): a header with the batch's token budget, then one row per task
with wave, unit, model, machine, worker id, branch, worktree, base commit, spec and quality verdicts, status
(`planned`, `running`, `reported`, `changes requested`, `gated`, `merged`, `dropped`, `parked`),
gate, merge commit, next action. Update on every state change, commit with the lead's commits. On resume the ledger,
`git worktree list` and the workers' last reports are the truth, not the chat. Day end or machine move: write the
handoff from the same template.

## 8. When something goes wrong

`failures.md` has the table. The usual three: a silent worker gets "report now in the brief's format"; a red gate
reruns once if flaky, then goes back with the log; a user decision parks only its task, the rest keeps moving.

## 9. End of batch

What merged (commits), what is open and why, decisions waiting, follow-ups as separate tasks; caveman, a few lines.
Then one line in the ledger on how the skill itself did (a step it missed, a rule that cost time); a repeated one
becomes an eval in `evals/scenarios.md` and a fix here.

## 10. Changing this skill

Every change is checked against `evals/scenarios.md` before it is published: read each scenario, say what the skill
now makes the lead do, and compare with the expected behaviour. A scenario that fails blocks the publish. Project war
stories go in a line of `failures.md` or the repo's profile, never in this file.
