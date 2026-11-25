# Installing the lead skill

`lead/` holds `SKILL.md`, `references/` and `scripts/`. It is repo-agnostic: project specifics live in each repo's
`.claude/lead-profile.md` (template in `references/profile-template.md`).

Since 2026-11-23 it is published as the plugin `lead` of the marketplace `zaubar-skills`, the public repository
batuhanluleci-zaubar/claude-skills, so every install updates from one place. Since 2026-11-25 that repository is also the
source of truth (`src/lead/skill/`, plugin-level files in `src/lead/plugin/`); it moved out of zaubar-xr-engine's
`tools/claude-home/`. After a change, `./publish.sh` in that repository stamps the version into `plugins/lead/` and lands
source and published copy through one squash-merged pull request.

## Route A: Claude Code on a machine (desktop app, CLI, IDE)

Sources: https://code.claude.com/docs/en/plugins/create-marketplace.md, https://code.claude.com/docs/en/plugins/host-marketplace.md

```bash
gh auth setup-git
claude plugin marketplace add batuhanluleci-zaubar/claude-skills
claude plugin install lead@zaubar-skills
```

Then set `"autoUpdate": true` on `extraKnownMarketplaces.zaubar-skills` in `~/.claude/settings.json` (or `/plugin` >
Marketplaces). Updates run in the background after a session's first message; the repository is public, so they need
no credentials (`gh auth setup-git` is only for pushing from `publish.sh`). Claude Code updates when `version` in
`plugin.json` changes; `publish.sh` sets it to `<year>.<month><day>.<hour><minute><second>` on every publish, so never push to
`plugins/` by hand. zaubar-xr-engine's `tools/claude-home/install.sh` does all of this and removes an old copy in `~/.claude/skills/lead`
(a copy there and the plugin would load the skill twice).

## Route B: claude.ai (any plan)

Sources: https://claude.com/docs/cowork/guide/plugins, https://claude.com/docs/plugins/org-sync.md

The repository moved to the public batuhanluleci-zaubar/claude-skills on 2026-11-24: zaubar's GitHub organization lets members neither
transfer repositories nor install the Claude GitHub App, and the user's claude.ai account is not on a Team or Enterprise
plan, so organization settings are not available. A public repository needs no GitHub App. On claude.ai: Customize >
Plugins (https://claude.ai/customize/plugins) > Add > Add marketplace, enter `batuhanluleci-zaubar/claude-skills`, keep "Sync automatically"
on, then install `lead` and remove the manually uploaded `lead` under My Uploads. Claude in Chrome is refused on those
pages, so the user does this once. Claude Code signed in with that account may then load the skill twice (`lead@synced`
and `lead@zaubar-skills`); turn one off. The docs disagree on what triggers a sync (every push to the default branch,
or a merged pull request with a plugin version bump), so `publish.sh` does both: version bump, PR, squash
merge. The manual fallback is the single-file build from zaubar-xr-engine's `tools/claude-home/pack-skill.sh --inline lead` (a zip upload
kept only `SKILL.md` on 2026-11-22).

On claude.ai the skill has no shell or git: it plans, writes briefs and reviews pasted reports
(`references/surfaces.md`, "claude.ai").

## Route C: a repo's cloud sessions

A cloud session does not add marketplaces a repository declares (that needs a trust dialog it never shows), so it
reads the skill from the repository. zaubar-xr-engine links `.claude/skills/lead -> ../../tools/claude-home/skills/lead`,
which since 2026-11-25 is a vendored copy: refresh it with `./publish.sh --vendor <checkout>/tools/claude-home/skills/lead`
and commit it there; never edit it in place.
On a machine with Route A that copy would show up twice (`lead` from the project, `lead:lead` from the plugin), so
`install.sh` sets `"skillOverrides": {"lead": "off"}` in `~/.claude/settings.json`; that hides project and personal
skills named `lead` only, never the plugin's (https://code.claude.com/docs/en/skills.md). The plugin's description ends
with its version, `(v<year>.<month><day>.<hour><minute><second>)`, stamped by `publish.sh`.
