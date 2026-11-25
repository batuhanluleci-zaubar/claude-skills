# claude-skills

Zaubar's Claude plugin marketplace and, since 2026-11-25, the source of its skills. One repository; every install
updates from here.

| Path | What |
| --- | --- |
| `src/<name>/skill/` | **the source** of a skill: `SKILL.md`, `references/`, `scripts/`, `evals/`. Edit here. |
| `src/<name>/plugin/` | plugin-level source files (hooks) that sit beside the skill in the published plugin |
| `plugins/<name>/` | **the published plugin** Claude Code and claude.ai install: a stamped copy. Never edit by hand. |
| `.claude-plugin/marketplace.json` | the marketplace `zaubar-skills` |
| `publish.sh` | copies `src/` into `plugins/`, stamps the version, lands everything through one pull request |

## Changing a skill

```bash
git checkout -b change/<topic>          # from an up-to-date main
# edit src/lead/skill/...
git add -- src && git commit -m "lead: <what is true now>"
./publish.sh                            # stamps plugins/, opens the PR, squash-merges it, returns to main
```

`publish.sh` publishes what is COMMITTED on the current branch, refuses a dirty tree, bumps `version` in `plugin.json`
(Claude Code updates only when it changes; claude.ai's organization sync triggers on a merged pull request with a version
bump) and checks that `SKILL.md`'s description is one double-quoted line (an unquoted `: ` hides the skill from the
model in Claude Code 2.1.330). `./publish.sh --vendor <dir>` also writes the unstamped source into another repository's
folder (zaubar-xr-engine keeps such a copy for its cloud sessions).

Until 2026-11-25 the source lived in zaubar/zaubar-xr-engine under `tools/claude-home/skills/lead/` and was published by
`tools/claude-home/publish-skills.sh` there. That script is retired: running an old copy of it would publish an old skill
over this one.

## Installing

- Claude Code (any machine): `claude plugin marketplace add batuhanluleci-zaubar/claude-skills`, then
  `claude plugin install lead@zaubar-skills`; turn auto-update on for this marketplace (`/plugin` > Marketplaces).
  By hand: `claude plugin marketplace update zaubar-skills && claude plugin update lead@zaubar-skills`.
- claude.ai (any plan): Customize > Plugins > Add > Add marketplace, enter `batuhanluleci-zaubar/claude-skills`, keep
  "Sync automatically" on, then install `lead`.

Details and the cloud-session route: `src/lead/skill/INSTALL.md`.
