#!/usr/bin/env bash
# SessionStart: marks the lead skill's slash-menu text "· updated" or "· not updated" by comparing the installed
# version with the one published on GitHub. Runs in the background and never fails the session.
root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
data="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/lead-plugin}"
url="https://raw.githubusercontent.com/batuhanluleci-zaubar/claude-skills/main/plugins/lead/.claude-plugin/plugin.json"
(
  mkdir -p "$data" 2>/dev/null
  cache="$data/latest-version"
  # Network at most once an hour; offline, the last answer stands.
  if [[ ! -s "$cache" || -n "$(find "$cache" -mmin +60 2>/dev/null)" ]]; then
    latest="$(curl -fsS --max-time 4 "$url" 2>/dev/null | sed -n 's/.*"version": *"\([0-9.]*\)".*/\1/p')"
    [[ -n "$latest" ]] && printf '%s\n' "$latest" >"$cache"
  fi
  python3 - "$root" "$cache" <<'PY' 2>/dev/null
import json, re, sys
root, cache = sys.argv[1], sys.argv[2]
installed = json.load(open(f"{root}/.claude-plugin/plugin.json")).get("version", "")
try:
    latest = open(cache).read().strip()
except OSError:
    latest = ""
key = lambda v: tuple(int(p) for p in v.split(".") if p.isdigit())
valid = lambda v: bool(re.fullmatch(r"[0-9]+(\.[0-9]+)*", v))
if not (valid(latest) and valid(installed)):
    status = ""
elif key(installed) >= key(latest):
    status = " · updated"
else:
    status = " · not updated: /plugin update lead"
skill = f"{root}/skills/lead/SKILL.md"
text = open(skill).read()
def mark(m):
    return f'{m.group(1)}{status}"'
new = re.sub(r'^(description: ".*? · v[0-9-]+ [0-9:]+)(?: · [^"]*)?"$', mark, text, count=1, flags=re.M)
if new != text:
    open(skill, "w").write(new)
PY
) >/dev/null 2>&1 &
exit 0
