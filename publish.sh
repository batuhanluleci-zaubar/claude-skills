#!/usr/bin/env bash
# Publishes the skills of this repository: copies src/<name>/ into plugins/<name>/, stamps the version, and lands the
# source change and the published copy on main through ONE squash-merged pull request. Every install then updates itself.
#
#   ./publish.sh                    from main (publishes what main holds) or from a change branch (its commits go along)
#   ./publish.sh --vendor <dir>     also writes the unstamped source of `lead` into <dir> (another repository's copy)
#
# Each publish bumps the plugin's "version", because Claude Code updates only when it changes and claude.ai's
# organization GitHub sync documents its trigger as "a pull request that includes a plugin version bump" merged to the
# default branch (support.claude.com article 13837433, 2026-11-24).
# Until 2026-11-25 this was zaubar-xr-engine's tools/claude-home/publish-skills.sh with the source in that repository.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="batuhanluleci-zaubar/claude-skills"
plugins=(lead aura-video)
vendor=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --vendor) vendor="${2:?--vendor needs a directory}"; shift 2 ;;
    *) echo "usage: ./publish.sh [--vendor <dir>]"; exit 2 ;;
  esac
done

cd "$root"
if [[ -n "$(git status --porcelain)" ]]; then
  echo "zaubar-skills: the tree is dirty; commit the source change first (publish.sh publishes what is committed)"; exit 2
fi
git fetch -q origin main
start_branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$start_branch" == "main" ]]; then
  git pull -q --ff-only
elif ! git merge-base --is-ancestor origin/main HEAD; then
  echo "zaubar-skills: $start_branch is behind origin/main; run: git merge origin/main"; exit 2
fi
source_commit="$(git rev-parse --short HEAD)"

# Publish what is committed, never loose files: export HEAD's src/.
export_dir="$(mktemp -d)"
trap 'rm -rf "$export_dir"' EXIT
git archive HEAD src | tar -x -C "$export_dir"
for name in "${plugins[@]}"; do
  rsync -a --delete --exclude INSTALL.md --exclude .DS_Store \
    "$export_dir/src/$name/skill/" "plugins/$name/skills/$name/"
  # Plugin-level files (hooks/) sit beside the skill in the published plugin.
  if [[ -d "$export_dir/src/$name/plugin" ]]; then
    rsync -a --exclude .DS_Store "$export_dir/src/$name/plugin/" "plugins/$name/"
  fi
done

# Stamps the version into a published copy: "version" in plugin.json, and " · v<YYYY-MM-DD HH:MM>" at the end of
# SKILL.md's description, so the slash menu shows which version is loaded; plugin.json's description becomes the
# skill's, without the stamp. The plugin's SessionStart hook (hooks/version-status.sh) adds " · updated" or
# " · not updated" on each machine.
stamp() {
  python3 - "plugins/$1" "$2" <<'PY'
import json, re, sys
root, version = sys.argv[1], sys.argv[2]
manifest = f"{root}/.claude-plugin/plugin.json"
with open(manifest) as f:
    data = json.load(f)
data["version"] = version
year, monthday, hms = version.split(".")
monthday, hms = monthday.zfill(4), hms.zfill(6)
pretty = f"{year}-{monthday[:2]}-{monthday[2:]} {hms[:2]}:{hms[2:4]}"
skill = f"{root}/skills/{root.rsplit('/', 1)[1]}/SKILL.md"
with open(skill) as f:
    lines = f.read().split("\n")
for i, line in enumerate(lines):
    if line.startswith("description:"):
        quote = '"' if line.rstrip().endswith('"') else ""
        body = line.rstrip()[: len(line.rstrip()) - len(quote)]
        body = re.sub(r" \(v[0-9.]+\)$", "", body)
        body = re.sub(r" · v[0-9-]+ [0-9:]+.*$", "", body)
        data["description"] = body[len("description:"):].strip().lstrip('"')
        lines[i] = f"{body} · v{pretty}{quote}"
        break
with open(skill, "w") as f:
    f.write("\n".join(lines))
with open(manifest, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
}
published_version() {
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("version", ""))' \
    "plugins/$1/.claude-plugin/plugin.json"
}

# Re-stamp the export with the version already published; anything still different is a real change.
changed=()
for name in "${plugins[@]}"; do
  current="$(published_version "$name")"
  [[ -n "$current" ]] && stamp "$name" "$current"
  if [[ -z "$current" || -n "$(git status --porcelain -- "plugins/$name")" ]]; then
    changed+=("$name")
  fi
done

if [[ -n "$vendor" ]]; then
  mkdir -p "$vendor"
  rsync -a --delete --exclude .DS_Store "$export_dir/src/lead/skill/" "$vendor/"
  echo "zaubar-skills: vendored src/lead/skill ($source_commit) into $vendor"
fi

if [[ ${#changed[@]} -eq 0 && "$start_branch" == "main" ]]; then
  echo "zaubar-skills: already up to date"
  exit 0
fi

# <year>.<month><day>.<hour><minute><second> (leading zeros dropped): valid semver, increasing, readable in the menu.
version="$(published_version "${plugins[0]}")"
if [[ ${#changed[@]} -gt 0 ]]; then
  version="$(date +%Y).$((10#$(date +%m%d))).$((10#$(date +%H%M%S)))"
  for name in "${changed[@]}"; do
    stamp "$name" "$version"
  done
fi
claude plugin validate "$root" >/dev/null
# An unquoted description holding ": " is invalid YAML; Claude Code 2.1.330 then hides the skill from the model.
for name in "${plugins[@]}"; do
  if ! grep -q '^description: ".*"$' "plugins/$name/skills/$name/SKILL.md"; then
    echo "zaubar-skills: $name SKILL.md description must be one double-quoted line"; exit 2
  fi
done

branch="$start_branch"
if [[ "$branch" == "main" ]]; then
  branch="publish/$version"
  git checkout -q -b "$branch"
fi
title="skills: publish $source_commit (v$version)"
if [[ -n "$(git status --porcelain -- plugins)" ]]; then
  git add -- plugins
  git commit -qm "$title" -- plugins
fi
git push -q -u origin "$branch"
gh pr create -R "$repo" -B main -H "$branch" -t "$title" \
  -b "Published by publish.sh from src/. A version bump triggers the claude.ai organization sync." >/dev/null
gh pr merge -R "$repo" "$branch" --squash --delete-branch >/dev/null
git checkout -q main
git pull -q --ff-only
git branch -q -D "$branch" 2>/dev/null || true
echo "zaubar-skills: merged $(git rev-parse --short HEAD) v$version (from $source_commit)"
