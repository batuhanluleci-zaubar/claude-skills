# The TASKS file

Path: `<briefs dir>/TASKS-<YYYY-MM-DD>.md` (a second batch the same day: `...b.md`). Commit it on the lead branch
before starting workers. Everything a worker needs is in its block plus the common preface; a worker never needs
this conversation.

````markdown
# Tasks, <date>

<One paragraph: where the batch came from, which waves run now, which wait and for what.>

| # | Task | Wave | Depends on | Touches | Unit | Model |
| --- | --- | --- | --- | --- | --- | --- |
| A | <name> | 1 | none | `src/net` | session | strong |
| B | <name> | 2 | A reviewed | `src/auth`, `docs/auth.md` | session | strong |
| C | <name> | 1 | none | docs only | subagent | cheap |

Decisions for the user: <list, or "none">.

## Common preface (paste first in every worker)

```text
Repo: <path or remote>. Read CLAUDE.md and README.md first, then the document that owns your topic.
Load the skills <project skills>.

You run in your OWN worktree on branch <prefix>/<topic>. First step: <worktree init command, or "none">.
Never touch the main checkout (<path>) or another worktree.

Rules that bind you: <the repo's code rules, in one line each, or "CLAUDE.md section X">. A change that
contradicts a document updates that document in the same commit. A change of direction gets a decision record
(<adr dir>, next free number, status Proposed). Never guess an API, endpoint, flag or extension name: use the
official docs and cite the source next to the code. No secrets in code, config, logs or commits.

Definition of done: <build command> and <test command> pass, <check command> prints <success marker>, tests
cover the new code, the owning doc is updated. If a step cannot run here (device, paid key, window, server), say so
and simulate it, marked "simulated".

Run builds, tests and benches in the foreground and wait for them: an idle session is not woken by its own
background command, so a worker that backgrounds its build and ends its turn stalls until the lead nudges it.

Do not start subagents, workflows or other sessions of your own, reviewers included: the lead reviews, and every
extra agent multiplies tokens and memory on a machine other workers share.

Commit small, conventional commits, each ending with "<attribution line>". <Push rule: "Do not push" or "Push your
branch only">. Never merge into <default branch>; the lead does that after review and the gate.

Work quietly: no narration, no recaps, do not re-read files you already read, run independent commands in one
message. Final report, at most 15 lines, in this order: a status line, exactly one of `DONE`, `DONE_WITH_CONCERNS: <what>`,
`NEEDS_CONTEXT: <the fact you need>`, `BLOCKED: <the decision or lock you wait for>`; branch and last commit; acceptance criteria one per line
(met, not met, simulated); check result (one line, plus the failing tail only if red); numbers with their headers;
open questions; refuted ideas with their numbers. Nothing else: the lead reads the diff itself.

Questions go to the lead, never to the user: put them FIRST in the message as `QUESTION FOR THE LEAD: <one decision,
your recommendation>`, and keep working on whatever does not depend on the answer. Do not end a turn on a question to
the user or an offer of choices; the lead answers in your session.

The user does not read your session. Never end a turn with a question box, buttons or "shall I ...": nobody will click
them and you will sit idle. While a long job of yours runs (a training run, a build, a cook), do the work that does not
need its result (the next step's code, the scoring script, the doc, the hand-over notes); end a turn only when nothing
is left but waiting, and say in that last line what you wait for and until when.

Stop and ask only for decisions that are the user's (scope, dependency, licence, account, paid usage, direction).
Decide everything else, and write the reason in the commit message.
```

## A. <Task name> (wave 1)

```text
Task A, topic <topic>, branch <prefix>/<topic>.

Goal: <one or two sentences, the outcome, not the steps>.

Read first: <files, docs, earlier branches, issues>. Already exists: <what the lead found, so you do not rebuild it>.

Scope:
1. <...>
2. <...>
Out of scope: <...>.

Acceptance criteria (each checkable):
- <command or observation> gives <result>.
- <...>

Tests: <which, where>. Docs to update: <...>.

Decided by the lead: <decision and the reason>.
Stops (ask the lead): <user decisions this task may hit>.
Builds on: <"main" or "merge <dep branch> first">. Base commit: <sha the lead recorded>.
ETA: <hours>; timebox for any root-cause hunt: <minutes>.
```
````

## Writing good blocks

- Outcome over steps: say what done looks like; let the worker pick the steps unless one is a known trap.
- Name the traps you know: the flaky test, the global lock, the file another wave touches, the earlier refuted idea.
- One task, one branch, one owning doc. If the block needs two branches, it is two tasks.
- Size: a block a worker can finish in one session (a few hours of agent time). Bigger: split by layer or by
  vertical slice, and make the second slice depend on the first.
- Never paste secrets, tokens or personal data into a brief; point to where the worker reads them locally.
- Short blocks: point to files and doc sections, never paste them; the preface is written once per batch.

## Critic (one per batch, optional; SKILL.md 5b)

```text
You are the CRITIC of the lead's running workers. You write no product code and run no build, training or device job.
Tree <path>, branch <critic branch>; you write ONE file, <briefs dir>/CRITIC-LOG.md, and commit and push it by path.
Workers: <id, session, tree, branch, doc, code paths, what runs now, where its logs are> ...   Lead: <session id>.

One round, about every 10 minutes while a worker has a live job or uncommitted work:
1. Fetch; per worker the DIFF of its new commits (risky hunks, not the stat), uncommitted files, the changed parts of
   its doc, its live jobs and logs, its last message in full.
2. Criticise: every number (tool, data, views, seed, like for like, noise, measured or estimated, gate met in substance),
   every claim against its evidence, the code against what the doc says it does, leakage between training and held-out
   data, paths outside the task, licences, big files, uncommitted hours, dead jobs, misused locks, idle or waiting workers.
3. Act with the lead's authority for: a correction or challenge to the worker (start the message `CRITIC (for the
   lead):`, name file:line or commit and the evidence, at most 3 findings, most damaging first), "commit and push now",
   a METHOD answer, stopping a plainly wrong run. Never: a new task, a change of scope, box or gate, a lock, the device,
   merges, the user's rules or money - send those to the lead as `CRITIC -> LEAD: <decision needed, recommendation>`.
   The lead's order wins over yours.
4. Log the round: time, commits read, findings (wrong / unproven / weak / fine), message sent, the worker's answer to
   earlier findings (fixed / disputed / ignored); open findings stay in a table at the top.
5. Message the lead only when it must decide or a finding is disputed.
Schedule your next round yourself if a wake-up tool exists; otherwise end each turn with `NEXT ROUND: needs a wake-up
message`. No subagents, no question boxes. Stop when every worker reported final and every finding is closed or ruled on.
```

