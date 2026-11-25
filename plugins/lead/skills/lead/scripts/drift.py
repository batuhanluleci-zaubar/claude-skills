#!/usr/bin/env python3
# Shows what running branches really touch: files outside each brief's paths, and files two branches both change.
# waves.py checks the plan; this checks the work, while the wave runs, before the conflict reaches a merge.
#
# Input (JSON file or stdin), one entry per running task, base = the base commit the ledger recorded at launch:
# {
#   "hot_spots": ["package-lock.json", "db/migrations"],
#   "tasks": [
#     {"id": "A", "branch": "feature/rest", "base": "1a2b3c4", "paths": ["src/net"]},
#     {"id": "B", "branch": "feature/auth", "base": "1a2b3c4", "paths": ["src/auth", "docs/auth.md"]}
#   ]
# }
# Usage: drift.py tasks.json [--repo PATH] [--json]
# Single branch: drift.py --repo PATH --base SHA --branch NAME --paths src/net docs/net.md
# Exit 0 = clean, 1 = drift or overlap found, 2 = input or git error.

import json
import subprocess
import sys


def split_path(path):
    return [part for part in path.strip().strip("/").split("/") if part and part != "."]


def under(path, prefix):
    pp, pr = split_path(path), split_path(prefix)
    return len(pr) == 0 or pp[: len(pr)] == pr


def changed_files(repo, base, branch):
    out = subprocess.run(
        ["git", "-C", repo, "diff", "--name-only", f"{base}...{branch}"],
        capture_output=True, text=True,
    )
    if out.returncode != 0:
        raise RuntimeError(f"git diff {base}...{branch}: {out.stderr.strip()}")
    return [line for line in out.stdout.splitlines() if line]


def check(data, repo):
    hot_spots = data.get("hot_spots", [])
    touched, report = {}, {"outside": {}, "overlaps": [], "hot_spots": []}
    for task in data["tasks"]:
        files = changed_files(repo, task["base"], task["branch"])
        touched[task["id"]] = set(files)
        declared = task.get("paths", [])
        outside = [f for f in files if declared and not any(under(f, p) for p in declared)]
        if outside:
            report["outside"][task["id"]] = outside
    ids = list(touched)
    for i, a in enumerate(ids):
        for b in ids[i + 1:]:
            shared = sorted(touched[a] & touched[b])
            if shared:
                report["overlaps"].append({"tasks": [a, b], "files": shared})
            hot = sorted({h for h in hot_spots
                          if any(under(f, h) for f in touched[a]) and any(under(f, h) for f in touched[b])})
            if hot:
                report["hot_spots"].append({"tasks": [a, b], "spots": hot})
    report["counts"] = {i: len(touched[i]) for i in ids}
    return report


def parse(argv):
    repo, single, source, as_json = ".", {}, None, "--json" in argv
    args = [a for a in argv[1:] if a != "--json"]
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--repo":
            repo, i = args[i + 1], i + 2
        elif a in ("--base", "--branch"):
            single[a[2:]], i = args[i + 1], i + 2
        elif a == "--paths":
            i += 1
            single["paths"] = []
            while i < len(args) and not args[i].startswith("--"):
                single["paths"].append(args[i])
                i += 1
        else:
            source, i = a, i + 1
    if single:
        if "base" not in single or "branch" not in single:
            raise ValueError("single-branch mode needs --base and --branch")
        data = {"tasks": [{"id": single["branch"], **single}]}
    else:
        text = open(source, encoding="utf-8").read() if source else sys.stdin.read()
        data = json.loads(text)
    return data, repo, as_json


def main(argv):
    try:
        data, repo, as_json = parse(argv)
        for t in data.get("tasks", []):
            for key in ("id", "branch", "base"):
                if key not in t:
                    raise ValueError(f"task {t.get('id', '?')} lacks {key}")
        report = check(data, repo)
    except (ValueError, RuntimeError, OSError, json.JSONDecodeError) as error:
        print(error, file=sys.stderr)
        return 2
    found = bool(report["outside"] or report["overlaps"] or report["hot_spots"])
    if as_json:
        print(json.dumps(report, indent=2))
    else:
        for task_id, count in report["counts"].items():
            print(f"{task_id}: {count} files changed")
        for task_id, files in report["outside"].items():
            print(f"OUTSIDE BRIEF {task_id}: " + ", ".join(files[:10]) + (" ..." if len(files) > 10 else ""))
        for o in report["overlaps"]:
            print(f"OVERLAP {o['tasks'][0]} + {o['tasks'][1]}: " + ", ".join(o["files"][:10]))
        for h in report["hot_spots"]:
            print(f"HOT SPOT {h['tasks'][0]} + {h['tasks'][1]}: " + ", ".join(h["spots"]))
        print("drift found" if found else "clean")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
