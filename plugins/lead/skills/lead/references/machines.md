# Machines, capacity, disk

All three are the lead's decisions. Never ask the user which machine or how many workers.

## Pick the machine per worker

A free machine that has the task's toolchain and data: the profile's `Machines`, the user's memory, the session
tools' SSH targets and presets, Remote Control sessions on other computers. Write the machine in the ledger row.

- Run each worker ON the machine that does its heavy work (desktop app: `start_session` with that machine's SSH
  target or preset), not on the lead's machine driving builds over `ssh`. Keep the lead's machine light enough to
  review, merge and hand out the device.
- Give each machine a role by fit: an OS-specific task to that OS; GPU or measurement work to the machine the
  numbers are about; heavy builds, cooks and GPU jobs on different machines so they do not compete.
- Work that needs an attached device (headset, phone, board) stays on the machine it is plugged into, or the built
  artifact is copied there. The device is usually the bottleneck: workers build and dry-run before their slot, each
  device run is one command, the next build is ready when the slot frees, the lead hands the slot on at once.
- A machine without the build cache, cook or dependencies gets a lane-setup task first (sync, one full build), so
  later workers there do incremental builds.
- A worker on another machine uses its own worktree there and never switches that machine's main checkout.
- Re-measure every machine (load, disk, what runs) at each wave and report; the next build goes to the least loaded
  machine with a lane. A machine busy with another lead's work is not taken; check again next wave.
- Say honestly how each machine is used (busy, idle, why), and fix an idle one rather than report it.

## Capacity

Count over every machine the profile lists (this one, SSH hosts, cloud environments the user allowed), measured
now (`uptime`, `df -h`, `sysctl -n hw.ncpu`, locally and over SSH): per machine
`min(cores / 3, free disk / per-worktree cost, its own cap)` building workers. Docs-only and research workers do not
count. Account for global locks (one GPU window, one device, one simulator), shared API quotas and other leads'
workers. Keep a per-machine cap in the profile and one script that reads load, disk and worktrees of all machines in
one call.

## Disk and worktrees

Before a wave and whenever a machine runs short, without asking: measure (`df -h`, each worktree's `build/` size,
`git status --porcelain`, `git rev-list --count origin/<branch>..HEAD`), then free space in this order:

1. build output of finished, pushed and idle workers;
2. worktrees whose branch is merged or fully pushed with a clean tree (`git worktree remove`, then
   `git worktree prune`);
3. regenerable `out/` and caches the profile names.

Then open the worktrees the plan needs. Never delete sources, uncommitted changes, unpushed commits, the main
checkout's state, or anything another session is still writing; when in doubt about a worktree, keep it.
