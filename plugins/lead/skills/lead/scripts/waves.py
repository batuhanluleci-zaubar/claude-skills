#!/usr/bin/env python3
# Plans waves from a task list: no two conflicting tasks in one wave, needs before dependents, capacity respected.
#
# Input (JSON file or stdin):
# {
#   "max_parallel": 4,
#   "hot_spots": ["package-lock.json", "db/migrations"],
#   "tasks": [
#     {"id": "A", "name": "REST client", "paths": ["src/net"], "needs": [], "size": "M", "cost": "build"},
#     {"id": "B", "name": "Auth", "paths": ["src/auth", "src/net/http.h"], "needs": ["A"], "size": "L"}
#   ]
# }
# size: S, M or L (default M). cost: build (default), docs, research, device, paid; docs and research do not count
# against max_parallel. Usage: waves.py tasks.json [--json]

import json
import sys

SIZE_WEIGHT = {"S": 1, "M": 2, "L": 3}
FREE_COSTS = {"docs", "research"}


def split_path(path):
    return [part for part in path.strip().strip("/").split("/") if part and part != "."]


def paths_overlap(a, b):
    pa, pb = split_path(a), split_path(b)
    shorter = min(len(pa), len(pb))
    return shorter == 0 or pa[:shorter] == pb[:shorter]


def touched(task, hot_spots):
    paths = list(task.get("paths", []))
    hot = [spot for spot in hot_spots if any(paths_overlap(spot, p) for p in paths)]
    return paths, hot


def conflict_reason(a, b, hot_spots):
    paths_a, hot_a = touched(a, hot_spots)
    paths_b, hot_b = touched(b, hot_spots)
    shared_hot = sorted(set(hot_a) & set(hot_b))
    if shared_hot:
        return "hot spot " + ", ".join(shared_hot)
    for pa in paths_a:
        for pb in paths_b:
            if paths_overlap(pa, pb):
                return f"{pa} ~ {pb}"
    return None


def load(argv):
    source = next((arg for arg in argv[1:] if not arg.startswith("--")), None)
    text = open(source, encoding="utf-8").read() if source else sys.stdin.read()
    return json.loads(text)


def validate(tasks):
    ids = [t["id"] for t in tasks]
    errors = [f"duplicate id {i}" for i in sorted(set(ids)) if ids.count(i) > 1]
    known = set(ids)
    for t in tasks:
        errors += [f"{t['id']} needs unknown {n}" for n in t.get("needs", []) if n not in known]
        if t.get("size", "M") not in SIZE_WEIGHT:
            errors.append(f"{t['id']} has size {t.get('size')}, expected S, M or L")
    return errors


def chain_lengths(tasks):
    by_id = {t["id"]: t for t in tasks}
    dependents = {t["id"]: [] for t in tasks}
    for t in tasks:
        for need in t.get("needs", []):
            dependents[need].append(t["id"])
    memo, visiting = {}, set()

    def length(task_id):
        if task_id in memo:
            return memo[task_id]
        if task_id in visiting:
            raise ValueError(f"dependency cycle through {task_id}")
        visiting.add(task_id)
        own = SIZE_WEIGHT[by_id[task_id].get("size", "M")]
        memo[task_id] = own + max((length(d) for d in dependents[task_id]), default=0)
        visiting.discard(task_id)
        return memo[task_id]

    for t in tasks:
        length(t["id"])
    return memo, dependents


def critical_path(tasks, lengths, dependents):
    roots = [t["id"] for t in tasks if not t.get("needs")]
    if not roots:
        return []
    path = [max(roots, key=lambda i: lengths[i])]
    while dependents[path[-1]]:
        path.append(max(dependents[path[-1]], key=lambda i: lengths[i]))
    return path


def plan(data):
    tasks = data["tasks"]
    hot_spots = data.get("hot_spots", [])
    max_parallel = int(data.get("max_parallel", 4))
    lengths, dependents = chain_lengths(tasks)
    by_id = {t["id"]: t for t in tasks}
    wave_of, waves, deferred = {}, [], {}
    while len(wave_of) < len(tasks):
        number = len(waves) + 1
        ready = [
            t for t in tasks
            if t["id"] not in wave_of and all(wave_of.get(n, number) < number for n in t.get("needs", []))
        ]
        ready.sort(key=lambda t: (-lengths[t["id"]], -SIZE_WEIGHT[t.get("size", "M")], t["id"]))
        wave, building = [], 0
        for t in ready:
            clash = next(
                (f"{o['id']} ({r})" for o in wave if (r := conflict_reason(t, o, hot_spots))), None
            )
            counts = t.get("cost", "build") not in FREE_COSTS
            if clash:
                deferred.setdefault(t["id"], []).append(f"wave {number}: conflicts with {clash}")
            elif counts and building >= max_parallel:
                deferred.setdefault(t["id"], []).append(f"wave {number}: capacity {max_parallel} reached")
            else:
                wave.append(t)
                building += 1 if counts else 0
                wave_of[t["id"]] = number
        if not wave:
            raise ValueError("no task can start; check needs")
        waves.append([t["id"] for t in wave])
    return {
        "waves": waves,
        "critical_path": critical_path(tasks, lengths, dependents),
        "deferred": deferred,
        "names": {i: by_id[i].get("name", i) for i in by_id},
    }


def print_plan(result, tasks):
    by_id = {t["id"]: t for t in tasks}
    for number, wave in enumerate(result["waves"], start=1):
        print(f"Wave {number}")
        for task_id in wave:
            t = by_id[task_id]
            needs = ", ".join(t.get("needs", [])) or "none"
            paths = ", ".join(t.get("paths", [])) or "none"
            print(f"  {task_id}  {t.get('name', '')}  size {t.get('size', 'M')}  cost {t.get('cost', 'build')}"
                  f"  needs {needs}  touches {paths}")
    print("Critical path: " + " -> ".join(result["critical_path"]))
    for task_id, reasons in result["deferred"].items():
        for reason in reasons:
            print(f"Deferred {task_id}: {reason}")


def main(argv):
    data = load(argv)
    errors = validate(data.get("tasks", []))
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 2
    try:
        result = plan(data)
    except ValueError as error:
        print(error, file=sys.stderr)
        return 2
    if "--json" in argv:
        print(json.dumps(result, indent=2))
    else:
        print_plan(result, data["tasks"])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
