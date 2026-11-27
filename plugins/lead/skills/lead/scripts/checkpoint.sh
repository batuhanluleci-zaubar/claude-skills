#!/usr/bin/env bash
# One checkpoint over every running worker, read from git, not from the workers' reports (SKILL.md section 5b).
# Prints, per worker branch: commits since its base (or the last 3), age of the newest commit, the diff size since the
# base, the files with the most changed lines (the hunks worth reading first) and, where its worktree is reachable
# (a local path or host:path over ssh), the uncommitted files. Flags a branch silent longer than SILENT_MIN (45).
#
#   checkpoint.sh [--repo PATH] <branch>[@base][=worktree] ...
#     branch    remote branch name (origin/ is added)
#     @base     the base commit the ledger recorded at launch; without it the last 3 commits are shown
#     =worktree a local path or host:path whose `git status --short` is read
#   SILENT_MIN=45 checkpoint.sh ...
#
# Exit 0 = nothing flagged, 1 = a branch is silent past SILENT_MIN or a worktree holds uncommitted work.
set -uo pipefail
repo="."
if [[ "${1:-}" == "--repo" ]]; then repo="$2"; shift 2; fi
[[ $# -gt 0 ]] || { sed -n '2,13p' "$0"; exit 2; }
silent_min="${SILENT_MIN:-45}"
cd "$repo" || exit 2
git fetch -q --prune origin 2>/dev/null || echo "WARN git fetch failed"
now=$(date +%s)
flag=0
for spec in "$@"; do
  wt=""; base=""; br="$spec"
  [[ "$br" == *=* ]] && { wt="${br#*=}"; br="${br%%=*}"; }
  [[ "$br" == *@* ]] && { base="${br#*@}"; br="${br%%@*}"; }
  ref="origin/$br"
  if ! git rev-parse -q --verify "$ref" >/dev/null; then echo "== $br: NO SUCH REMOTE BRANCH"; flag=1; continue; fi
  ts=$(git log -1 --format=%ct "$ref"); age=$(( (now - ts) / 60 ))
  mark=""; (( age > silent_min )) && { mark="  <-- SILENT ${age} min: ask for a one-line status"; flag=1; }
  echo "== $br  newest commit ${age} min ago$mark"
  if [[ -n "$base" ]]; then
    git log --format='   %h %cr %s' "$base..$ref" | cut -c1-140 | head -12
    git diff --shortstat "$base" "$ref" | sed 's/^/   diff since base:/'
    echo "   largest changes (read these hunks):"
    git diff --numstat "$base" "$ref" | awk '{print $1+$2, $3}' | sort -rn | head -5 | sed 's/^/     /'
  else
    git log -3 --format='   %h %cr %s' "$ref" | cut -c1-140
  fi
  if [[ -n "$wt" ]]; then
    if [[ "$wt" == *:* && ! -d "$wt" ]]; then
      dirty=$(ssh -o ConnectTimeout=5 -o BatchMode=yes "${wt%%:*}" "git -C '${wt#*:}' status --short" 2>/dev/null)
    else
      dirty=$(git -C "$wt" status --short 2>/dev/null)
    fi
    if [[ -n "$dirty" ]]; then
      echo "   uncommitted in $wt ($(echo "$dirty" | wc -l | tr -d ' ') files) <-- 'commit and push' if it is older than an hour"
      echo "$dirty" | head -5 | sed 's/^/     /'
      flag=1
    fi
  fi
done
exit $flag
