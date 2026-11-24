# Ledger and handoff

## `LEDGER.md` (in the briefs directory, committed by the lead)

```markdown
# Lead ledger

Updated: <YYYY-MM-DD HH:MM>, lead: <session id or name>, lead branch: <branch>.

| # | Task | Wave | Unit | Worker | Branch | Worktree | Status | Gate | Merge | Next action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A | REST client | 1 | session | local_ab12 | feature/rest | ../wt/rest | gated | CI 1234 green | | merge after B's review |
| B | Auth | 2 | session | | feature/auth | | planned | | | starts from A's branch once A is reviewed |

Statuses: planned, running, reported, changes requested, gated, merged, dropped, parked (user decision).

## Machines (re-measured each wave)

| Machine | Load / cores | Free disk | Lane (cook, cache) | Runs now | Device |
| --- | --- | --- | --- | --- | --- |
| <name> | <n / n> | <GB> | <ready / setup needed> | <workers, other leads> | <attached device or none> |

## Decisions waiting for the user
- <question> (blocks: <tasks>)

## Decided by the lead
- <decision>: <reason> (<date>)

## Learnings this batch
- <refuted idea, with its number>; <lesson about tools, CI, quotas>
```

Rules: one row per task; update on every state change; the next action is a verb a fresh lead can do. On resume,
compare the ledger with `git worktree list`, `git branch -a` and the workers' last reports, and fix the ledger first.

## Handoff (end of day, machine move, context running out)

`<briefs dir>/HANDOFF-<YYYY-MM-DD>.md`:

1. State: the ledger table as of now, with the commit of the default branch.
2. In flight: each running worker, what it was doing, what it reported last.
3. Waiting on the user: the decision list.
4. Lessons: what went wrong and the rule that prevents it now.
5. Restart prompt, ready to paste:

```text
You are the lead for <repo> at <path>. Load the skill `lead`. Read CLAUDE.md, .claude/lead-profile.md, then
<briefs dir>/HANDOFF-<date>.md and LEDGER.md. Compare the ledger with git worktree list and the branches, fix it,
then continue: <the next actions, in merge order>. Ask me only: <decisions>. <Chat language and style.>
```
