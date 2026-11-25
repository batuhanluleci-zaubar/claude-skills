#!/usr/bin/env bash
# Prints what a lead must know before starting a wave: git state, worktrees, branches, disk, cores, memory, API budget.
# --hosts h1,h2 (or LEAD_HOSTS) adds load, cores, memory and free disk of each SSH host, read in one call per host.
set -uo pipefail

hosts="${LEAD_HOSTS:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --hosts) hosts="${2:-}"; shift 2 ;;
    *) echo "usage: preflight.sh [--hosts h1,h2]"; exit 2 ;;
  esac
done

repo="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not inside a git repository"; exit 2; }
common="$(git rev-parse --git-common-dir)"
main_checkout="$(cd "$common/.." 2>/dev/null && pwd)"
default_branch="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
default_branch="${default_branch:-main}"

echo "== repo"
echo "here: $repo"
echo "main checkout: $main_checkout"
echo "default branch: $default_branch, current: $(git branch --show-current)"
for f in CLAUDE.md .claude/lead-profile.md; do
  [[ -e "$main_checkout/$f" ]] && echo "found: $f"
done

echo "== main checkout state"
if [[ -e "$common/MERGE_HEAD" ]]; then echo "MERGE IN PROGRESS in the main checkout: do not touch it"; fi
if [[ -e "$common/rebase-merge" || -e "$common/rebase-apply" ]]; then echo "REBASE IN PROGRESS in the main checkout"; fi
dirty="$(git -C "$main_checkout" status --porcelain 2>/dev/null)"
if [[ -n "$dirty" ]]; then
  echo "uncommitted changes (maybe another lead's; leave them):"
  printf '%s\n' "$dirty" | head -20
else
  echo "clean"
fi

echo "== worktrees"
git worktree list

echo "== branches not merged into $default_branch"
git branch --no-merged "$default_branch" --format='%(refname:short) %(committerdate:short) %(subject)' 2>/dev/null | head -30

echo "== ahead/behind remote"
if git rev-parse --verify --quiet "origin/$default_branch" >/dev/null; then
  git rev-list --left-right --count "$default_branch...origin/$default_branch" | awk '{print "local ahead " $1 ", behind " $2 " (last fetch)"}'
fi

echo "== machine"
if command -v sysctl >/dev/null && sysctl -n hw.ncpu >/dev/null 2>&1; then
  echo "cores: $(sysctl -n hw.ncpu), memory: $(( $(sysctl -n hw.memsize) / 1073741824 )) GB"
elif command -v nproc >/dev/null; then
  echo "cores: $(nproc), memory: $(awk '/MemTotal/ {printf "%d GB", $2/1048576}' /proc/meminfo)"
fi
df -h "$repo" | tail -1 | awk '{print "disk free: " $4 " of " $2 " (" $5 " used)"}'

if [[ -n "$hosts" ]]; then
  echo "== other machines"
  IFS=',' read -r -a host_list <<<"$hosts"
  for h in "${host_list[@]}"; do
    line="$(ssh -o BatchMode=yes -o ConnectTimeout=5 "$h" '
      c=$(sysctl -n hw.ncpu 2>/dev/null || nproc); m=$(( $(sysctl -n hw.memsize 2>/dev/null || awk "/MemTotal/ {print \$2*1024}" /proc/meminfo) / 1073741824 ))
      l=$(uptime | sed "s/.*load averages*: //"); d=$(df -h ~ | tail -1 | awk "{print \$4}")
      echo "cores $c, memory $m GB, load $l, free disk $d"' 2>/dev/null)" || line="unreachable"
    echo "$h: $line"
  done
fi

echo "== GitHub API budget"
if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
  gh api rate_limit --jq '.resources.core | "core: \(.remaining) of \(.limit) left, resets \(.reset | todate)"' 2>/dev/null \
    || echo "rate limit not readable"
else
  echo "gh not installed or not signed in"
fi
