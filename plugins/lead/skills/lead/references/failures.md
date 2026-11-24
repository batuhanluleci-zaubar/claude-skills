# Failures and answers

| Symptom | Answer |
| --- | --- |
| Worker silent after its turn ended without a report | message it: "report now in the brief's format" |
| Worker idle, "waiting for my build" (its own background command) | message it: check the result now and run the rest in the foreground |
| Sessions cannot be started (turn from an automated event or another session) | run the task as a background subagent with `isolation: "worktree"` and the same brief |
| Worker widened the scope | ask it to move the extra work to a new branch or drop it; the lead decides |
| Worker report longer than the brief's format, or narrating | ask for the format; read only what the format asks |
| Gate red on a flaky test | rerun once; red again is real, back to the worker with the log |
| Gate red on infrastructure (runner, quota, cache) | fix or report the infrastructure; do not blame the worker |
| Two workers need the same file mid-wave | the later one stops at a commit, waits for the earlier merge, merges it in |
| Disk below the profile's floor, or too little for the next workers | free space as `machines.md` says, then start the workers; never sources, uncommitted or unpushed work |
| API quota low | stop watchers, check gates once, space them out |
| CI queue long, runs waiting for runners | cancel superseded runs and every run of a worker branch; one run per integration branch; workers use the local precheck; say why in one line |
| Main checkout dirty or mid-merge by someone else | wait and retry; never commit, abort or reset their state |
| User decision blocks a task | park the task in the ledger, keep the rest moving, ask in one short question |
| Context running low | update the ledger, write the handoff, continue from it |
| Investigation past its timebox | stop it; the lead decides a policy or workaround now, the hunt becomes a follow-up task only if the root cause would change the fix |
| Workers queued on one device or GPU | schedule the lock in the ledger (owner, slot, hand-back); the others keep coding; one batched device pass by the lead |
| Worker past its ETA without a status | message it: "one-line status now: done, blocked on, or new ETA" |
