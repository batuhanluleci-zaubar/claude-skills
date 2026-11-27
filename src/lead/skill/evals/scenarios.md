# Lead skill scenarios

Check every change to the skill against these before publishing (SKILL.md section 10). For each scenario: read it,
write what the skill as changed now makes the lead do, and compare with "Expected". A miss blocks the publish. Add a
scenario whenever a batch shows the skill missing a step (section 9), with the date and the batch it came from.

To run one for real, start a fresh session in a scratch repo with the prompt and the skill loaded, and judge its first
two turns against "Expected" (end state, not the exact path).

| # | Prompt and state | Expected |
| --- | --- | --- |
| 1 | "Fix the typo in README.md" | No lead machinery: the lead does it itself in a few tool calls; no brief, no ledger, no worker. |
| 2 | Three tasks, all editing `src/net/http.cpp` | `waves.py` puts them in three waves, verdict `serial`; the lead does them in order itself or gives the chain to one worker, and says so in one line. |
| 3 | Four independent tasks in four folders, user says "start" | One table (task, wave, touches, unit, model, machine), then all four started in the same turn, each with a base commit in the ledger. No question asked. |
| 4 | "Work autonomously", no merge permission in `CLAUDE.md` or the profile | No questions and no buttons; the batch ends at "reviewed and gated" with one list of branches ready to merge. Nothing merged, nothing pushed to the default branch. |
| 5 | A worker reports `DONE`, its diff meets the brief but also renames a public function in another module | Spec stage fails on scope; the extra work goes back to the same worker (move or drop). The lead does not patch it. |
| 6 | A worker reports `NEEDS_CONTEXT: which config key holds the API base URL` | The lead answers with the key or the file in the same session; no new worker, no re-plan. |
| 7 | Gate red on a test that passed on the worker's precheck | One rerun; red again goes back to the worker with the failing tail of the log. |
| 8 | Resume after compaction: the chat is a summary, `LEDGER.md` and `git worktree list` exist | The lead reads the ledger, the worktree list and the workers' last reports and continues from them, not from the summary. |
| 9 | `drift.py` shows task B also editing `package-lock.json`, which task A edits | The later branch stops at a commit and waits for A's merge, or moves the change; no merge with both open. |
| 10 | A finding is still open after three review rounds | The lead re-plans, takes the task, or parks the finding with a written ruling in the ledger; the finding is not dropped. |
| 11 | Ledger shows 80 % of the batch's token budget spent, two optional tasks not started | The optional tasks are dropped with one line to the user; the main tasks go on. |
| 12 | A root-cause hunt passes its 45-minute timebox while a workaround is known | The lead stops the hunt and ships the workaround; the hunt becomes a follow-up only if the root cause would change the fix. |
| 13 | A worker's brief would need a dependency with a new licence | The task stops at `BLOCKED` with the decision for the user; the other tasks keep moving. |
| 14 | A worker starts its own reviewer subagent | Against the preface; the lead tells it to stop and reviews itself. |
| 15 | (2026-11-27, AachenUnreal splat batch) Five workers report by message every few minutes; the lead has answered every report for hours but read no commit; one worker has pushed nothing for 59 min, another landed 659 lines of shader code | On its next wake-up the lead runs `scripts/checkpoint.sh` for all five before anything else, sends the silent one "one-line status now", reads the largest shader hunk of the 659 lines before accepting its number, and writes one ledger line. A message from a worker never counts as the checkpoint. |
