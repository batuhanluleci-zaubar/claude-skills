# claude-skills

Zaubar's Claude plugin marketplace. One source; every install updates from here.

Source of truth for `lead`: `tools/claude-home/skills/lead/` in zaubar/zaubar-xr-engine. After a change there, run
`tools/claude-home/publish-skills.sh` from that repo; it copies the skill here, commits and pushes.

- Claude Code (any machine): `claude plugin marketplace add zaubar/claude-skills`, then
  `claude plugin install lead@zaubar-skills`; auto-update is on for this marketplace (`/plugin` > Marketplaces).
  Private repo: the background update uses git's credentials (`gh auth setup-git`).
- claude.ai (Team or Enterprise): Organization settings > Plugins, add this repository through the GitHub sync.
  Members then get `lead` in claude.ai and, signed in, in Claude Code as `lead@synced`.

`plugin.json` has no `version`, so every commit is an update.
