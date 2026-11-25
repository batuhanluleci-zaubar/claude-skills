# Project profile: `.claude/lead-profile.md`

One file per repo, committed, read by the lead before planning. It holds what this skill cannot know about the
repo. Keep it short; point to the repo's own docs instead of copying them. Copy the block below, delete what does
not apply, fill the rest.

```markdown
# Lead profile: <repo name>

## Commands
- Build: `<command>`
- Test: `<command>`
- Definition of done (local check): `<command>`, success marker `<text>`
- CI gate on a branch or commit: `<command>`, slowest job about <minutes> min
- Worktree setup inside a new worktree: `<command>` (or "none")
- Worktree removal: `<command>` (or `git worktree remove`)
- Repo scanners the review must see clean: `<commands>`

- Other machines for `scripts/preflight.sh --hosts`: `<host1,host2>` (or none)
- Batch token budget default: `<N worker-sessions>` (or the skill's S = 1, M = 2, L = 4)

## Places
- Default branch: `main`; lead branch: `main` (or `lead/<date>`)
- Branch prefixes: `feature/`, `fix/`, `spike/`, `docs/`
- Worktrees directory: `<path>`
- Briefs directory: `<path>` (TASKS files and LEDGER.md)
- Decision records: `<path>`; learnings file: `<path>`
- Doc ownership table: `<README section>`

## Permissions (as granted by the user, with the date)
- Lead may merge into the default branch: yes/no (<date>)
- Lead may push the default branch / worker branches: yes/no (<date>)
- Pull requests: never / lead opens / user opens
- Workers may push their own branch: yes/no

## Machines
- <name>: how to reach it (local, `ssh <host>`, start target / preset, Remote Control), OS, toolchain and version,
  repo clone path, GPU, attached devices, what else runs there (shared GPU, another lead)
- Artifact route: where builds made on one machine are copied to reach the device machine

## Capacity
- Max building workers at once: <n> (why: cores, RAM, per-worktree disk <GB>, licences)
- Global locks: <one app window, one device, one simulator, a port>
- Disk floor: below <GB> free, delete regenerable output first: <paths>; never: <paths>
- Shared quotas: <CI API, paid APIs, rate limits>

## Hot spots (always conflict)
- <lockfiles, generated code, central registries, migrations, CI config>

## Worker rules to put in every common preface
- <background only, no windows; language rules; measurement rules; simulated items>

## Skills workers load
- <project skills>
```

Without a profile, the lead derives these from `CLAUDE.md`, CI config and build files, states the guesses in the
ledger, and offers to save them here.
