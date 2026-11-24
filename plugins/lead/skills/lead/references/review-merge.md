# Review, gate, merge

## Review checklist (read the diff, then tick)

```bash
git fetch --all --prune
git log --oneline <default>..<branch>
git diff --stat <default>...<branch>
git diff <default>...<branch> -- <paths that carry risk>
```

Read the stat first, then only the hunks that carry risk (logic, security, data, concurrency, public API); skip
generated files and pure moves.

- Scope: only the brief's paths, or a stated reason. Unrelated refactors go back.
- Acceptance criteria: each one shown by a test, a command output or a capture, not by prose.
- Tests: new code has tests; they fail without the change (ask the worker to show it for a bug fix).
- Docs: the owning doc changed in the same branch when behaviour or direction changed.
- Numbers: every performance claim has its measurement header (device, build, commit, n) per the repo's rules.
- Names: no guessed API, flag, endpoint or extension names; a source is cited next to new external names.
- Safety: no secrets, keys, tokens or personal data in code, config, logs, fixtures or commit messages.
- Repo scanners: the lint, format and policy scripts the profile names are clean.
- Commits: conventional, small, with the attribution line the repo uses; no merge commits from the wrong direction.
- Decision records: a new number does not collide with one on the default branch; renumber before merging.

For a diff over a few hundred lines, or any change to security, data loss or concurrency, get an independent
review: a fresh subagent given the diff and the brief, not your opinion of it (or `/code-review` if the user wants).

## The gate

- Use the profile's gate: a local check command, CI on the pushed branch, or both, in that order.
- CI needs the branch on the remote. Gate the integration branch, not each worker branch: one run covers the wave.
  Pushing worker branches for handover must not start runs (CI on push only for the default and integration
  branches); cancel superseded runs before each gate (`gh run list`, `gh run cancel`).
- Size the gate to the team: a small team gates each merge on the product's real targets only (a lint, the main
  desktop build, the shipping platform) and runs the full platform matrix nightly or by hand; a red nightly is fixed the
  next day and never blocks a merge.
- Slow CI is usually cold builds, not the queue: per-commit cache keys over the provider's cache quota evict each
  other, and cancelled runs save near-empty caches. Persistent build and ccache dirs on self-hosted runners, or
  per-branch keys restored from the default branch and saved only after a green build, keep builds warm. Check the
  cache usage (`gh api repos/<repo>/actions/cache/usage`) and per-job step times before blaming the runners.
- A newer push to a ref cancels that ref's running CI (concurrency with cancel-in-progress). Batch the lead's own
  fixes and push the integration branch and the default branch once per round; a stream of small pushes means no run
  ever completes. Run the doc-link check before pushing docs to the default branch: a link to a section that exists only
  on an integration branch turns the default branch red on every platform.
- In zsh, quote refspecs built from variables: `git push origin "${b}:refs/heads/${b}"` (a bare `$b:r` is zsh's root
  modifier and silently mangles the refspec); check with `git ls-remote --heads origin` afterwards.
- Fail-fast watch when the repo has one (the profile's gate line, e.g. `ci gate SHA --watch`): start it once, in the
  background, right after the push; it returns at the first failing required job or when all are green, so the
  next step starts then, not after a fixed sleep. Read its exit code: green, red, or no decision (the profile names
  the codes); no decision is never green. Without one, check a run once, in the background, after the slowest job's
  usual time.
- Watch budgets: many parallel `--wait` watchers on a hosted CI can empty an account's API quota for everyone. One
  watcher per commit, polling every few minutes; `gh api rate_limit` shows what is left.
- Before a gate, list queued and running runs (`gh run list`) and cancel every run a newer commit or an integration
  branch supersedes; never leave runs of abandoned or merged branches queued. A long queue: say why in one line.
- Flaky: one rerun. Red twice is real.
- Infrastructure failure (runner, cache, quota, expired token): not the worker's fault; fix or report it.

## Merge protocol

Only with the user's permission (profile, `CLAUDE.md`, memory, or a yes in chat).

1. Main checkout clean: `git -C <main> status --porcelain` shows nothing staged by you, and
   `<main>/.git/MERGE_HEAD` does not exist. Another lead's state: wait and retry, never commit, abort or reset it.
   If the main checkout is busy, merge in a dedicated integration worktree on the default branch instead.
2. Up to date: `git -C <main> pull --ff-only` (if a remote is used).
3. Branch up to date with the default branch: if not, the worker merges the default branch in, tests, pushes, and
   the gate runs again.
4. `git -C <main> merge --no-ff <branch> -m "merge: <summary>"` (or the repo's merge style: squash, rebase).
5. Conflict: `git -C <main> merge --abort` at once; send the conflict to the worker. Never resolve in a shared
   checkout.
6. Push the default branch if allowed. Then delete the branch (local and remote if allowed), remove the worktree
   (`git worktree remove <path>`, or the repo's own command), update the ledger, start what this merge unblocked.
   Before removing a worktree, check that no staged or pending build uses its build output (a cook, `Saved/`,
   `build/`): read the build manifest's source tree. If one does, keep the worktree until that build is shipped or
   dropped (2026-11-24: removing such a worktree invalidated a staged build).
7. Tag a release only if the repo's rules say to.

Repos without merge permission: stop after step 3 with the branch reviewed and gated, and list in one message what
is ready to merge. Never open a PR unless the repo's rules or the user allow it.

## Cleanup

- Merged worktrees and branches: remove them after each merge, not at the end.
- Build output in removed worktrees: gone with the worktree; check `df -h` after a wave.
- Finished but unmerged workers (reported, pushed, idle): delete their `build/` to make room and keep the worktree for
  review fixes; a fix round rebuilds it.
- Workers' sessions: archive each one right after its branch is merged, without asking (unless the repo's rules
  say otherwise). Keep it open until then: review fixes and CI failures go back to it. A session whose branch was
  dropped is archived when the ledger marks it `dropped`.
- Subagent workers (`isolation: "worktree"`): the agent stops when its task ends, but its worktree
  (`.claude/worktrees/agent-*`) and branch stay; remove both after the merge.
- Learnings: every refuted idea, with its number, into the repo's learnings file (profile), in the lead's commit.
