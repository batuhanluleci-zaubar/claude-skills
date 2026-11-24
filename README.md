# claude-skills

Zaubar's Claude plugin marketplace. One source; every install updates from here.

Source of truth for `lead`: `tools/claude-home/skills/lead/` in zaubar/zaubar-xr-engine. After a change there, run
`tools/claude-home/publish-skills.sh` from that repo; it copies the skill here, bumps `version` in `plugin.json` and
lands it through a squash-merged pull request.

- Claude Code (any machine): `claude plugin marketplace add batuhanluleci-zaubar/claude-skills`, then
  `claude plugin install lead@zaubar-skills`; turn auto-update on for this marketplace (`/plugin` > Marketplaces).
- claude.ai (any plan): Customize > Plugins > Add > Add marketplace, enter `batuhanluleci-zaubar/claude-skills`, keep
  "Sync automatically" on, then install `lead`.

Claude Code updates when `version` changes, so never push here by hand.
