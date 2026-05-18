#!/usr/bin/env bash
# Wait for the dune watcher to finish the rebuild triggered by a
# preceding edit, then print the new output so the caller can read
# the result. Designed to be invoked with `run_in_background` so a
# single notification fires the moment the rebuild settles.
#
# Usage:
#   before=$(grep -c "waiting for filesystem" "$LOG")
#   # ... edit a file ...
#   scripts/wait-for-watcher.sh "$LOG" "$before"
#
# Two-phase, two-counter strategy. See docs/dune-watcher.md for the
# full rationale, empirical findings, and rejected alternatives.
#
# Phase 1 (<= 2 s): wait for evidence that dune decided to rebuild.
#   Evidence is either:
#     (a) the sentinel count already advanced past the caller's
#         baseline -- we lost a race; the rebuild settled before we
#         started polling.
#     (b) a new `********** NEW BUILD` line appeared past the
#         script's own baseline -- a rebuild is in flight; go to
#         Phase 2.
#   If neither happens within 2 s, the watcher chose not to rebuild
#   (`touch` with same content, edit to a non-build file, or
#   coalesced into an earlier rebuild that has already settled).
#   Exit 0 with a note.
#
# Phase 2 (hard ceiling 120 s): poll for the sentinel count to
#   advance. No idle-bail -- once Phase 1 saw the start marker we
#   know dune is working, and a real rebuild can have multi-second
#   quiet gaps inside it (compile phases produce no output). On
#   timeout, exit 1.

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <watcher-log-path> <sentinel-baseline>" >&2
  exit 2
fi

log="$1"
sentinel_baseline="$2"

if [ ! -f "$log" ]; then
  echo "wait-for-watcher: log not found: $log" >&2
  exit 1
fi

# Phrases dune watch emits verbatim. Both are stable across recent
# dune releases but not part of any documented interface; a future
# dune that reworks watcher output will need these updated.
sentinel_pattern="waiting for filesystem"
start_marker_pattern="********** NEW BUILD"

# Tunables. Phase 1 is short because dune's measured reaction to an
# fs event is 17-47 ms; 2 s is generous. Phase 2 needs headroom for
# real test work (~22 s observed in this repo, likely to grow).
phase_1_max_wait_seconds=2
phase_1_poll_interval=0.1
phase_2_max_wait_seconds=120
phase_2_poll_interval=0.5

# `grep -c` always prints a number to stdout (the count, including 0)
# but exits 1 when there are no matches; `|| true` keeps the pipeline
# alive under `set -e` without injecting a second "0". `-F` treats the
# pattern as a fixed string so the asterisks in the start marker
# don't need regex-escaping.
count_matches() {
  grep -cF "$1" "$log" 2>/dev/null || true
}

# Print exactly the output of the rebuild we waited on: everything
# from the most recent `NEW BUILD` marker onward. Falls back to a
# generic tail if no marker exists yet (initial-build case).
print_rebuild_output() {
  if grep -qF "$start_marker_pattern" "$log"; then
    awk -v marker="$start_marker_pattern" '
      index($0, marker) == 1 { buffer = ""; capture = 1 }
      capture { buffer = buffer $0 "\n" }
      END { printf "%s", buffer }
    ' "$log"
  else
    tail -100 "$log"
  fi
}

new_build_baseline=$(count_matches "$start_marker_pattern")

# ---- Phase 1: did the watcher decide to rebuild? ----

phase_1_deadline=$(($(date +%s) + phase_1_max_wait_seconds))

while :; do
  current_sentinel=$(count_matches "$sentinel_pattern")
  if [ "$current_sentinel" -gt "$sentinel_baseline" ]; then
    print_rebuild_output
    exit 0
  fi

  current_new_build=$(count_matches "$start_marker_pattern")
  if [ "$current_new_build" -gt "$new_build_baseline" ]; then
    break
  fi

  if [ "$(date +%s)" -ge "$phase_1_deadline" ]; then
    echo "wait-for-watcher: no rebuild triggered (touch / non-build file / hash unchanged). Continuing." >&2
    exit 0
  fi

  sleep "$phase_1_poll_interval"
done

# ---- Phase 2: wait for the rebuild to finish. ----

phase_2_deadline=$(($(date +%s) + phase_2_max_wait_seconds))

while :; do
  current_sentinel=$(count_matches "$sentinel_pattern")
  if [ "$current_sentinel" -gt "$sentinel_baseline" ]; then
    print_rebuild_output
    exit 0
  fi

  if [ "$(date +%s)" -ge "$phase_2_deadline" ]; then
    echo "wait-for-watcher: rebuild did not settle within ${phase_2_max_wait_seconds}s. Watcher may be stuck." >&2
    tail -100 "$log" >&2
    exit 1
  fi

  sleep "$phase_2_poll_interval"
done
