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

Commit small, conventional commits, each ending with "<attribution line>". <Push rule: "Do not push" or "Push your
branch only">. Never merge into <default branch>; the lead does that after review and the gate.

Final report, in this order: what was built; acceptance criteria one by one (met, not met, simulated); test and
check results with their output tail; numbers with their headers; `git log --oneline <default>..HEAD`; open
questions; refuted ideas with their numbers.

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
Builds on: <"main" or "merge <dep branch> first">.
```
````

## Writing good blocks

- Outcome over steps: say what done looks like; let the worker pick the steps unless one is a known trap.
- Name the traps you know: the flaky test, the global lock, the file another wave touches, the earlier refuted idea.
- One task, one branch, one owning doc. If the block needs two branches, it is two tasks.
- Size: a block a worker can finish in one session (a few hours of agent time). Bigger: split by layer or by
  vertical slice, and make the second slice depend on the first.
- Never paste secrets, tokens or personal data into a brief; point to where the worker reads them locally.
