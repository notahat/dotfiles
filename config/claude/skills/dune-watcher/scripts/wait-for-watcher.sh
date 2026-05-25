#!/usr/bin/env bash
# Drive the dune watcher: mark a baseline before edits, then wait for
# the rebuild triggered by the edits to finish and print a concise
# summary. Bundles the baseline capture so the caller never needs a
# shell-side grep on the watcher log -- one whitelisted script handles
# the whole cycle.
#
# Usage:
#   wait-for-watcher.sh mark <log>            # before your edit
#   # ... edit files ...
#   wait-for-watcher.sh wait <log>            # after; run_in_background
#   # then `Read` the wait command's per-invocation output file
#
# Legacy form (still supported; deprecated):
#   wait-for-watcher.sh <log> <baseline>      # caller-supplied baseline
#
# The baseline is stored in <log>.baseline so `mark` and `wait` can
# share state without the caller threading a number through the shell.
#
# Two-phase, two-counter strategy. See references/dune-watcher.md for
# the full rationale, empirical findings, and rejected alternatives.
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

usage() {
  cat >&2 <<EOF
usage:
  $0 mark <log>                 capture current rebuild count before an edit
  $0 wait <log>                 wait for a rebuild since the last mark
  $0 <log> <baseline>           legacy form (caller supplies baseline)
EOF
  exit 2
}

if [ "$#" -lt 1 ]; then usage; fi

# Phrases dune watch emits verbatim. Both are stable across recent
# dune releases but not part of any documented interface; a future
# dune that reworks watcher output will need these updated.
sentinel_pattern="waiting for filesystem"
start_marker_pattern="********** NEW BUILD"

# Subcommand dispatch. `mark` and `wait` are the new shape; anything
# else falls through to the legacy two-positional form. The baseline
# lives in a sibling file alongside the log so the two subcommands
# share state without the caller carrying a number through the shell.
case "${1:-}" in
  mark)
    [ "$#" -eq 2 ] || usage
    log="$2"
    if [ ! -f "$log" ]; then
      echo "wait-for-watcher: log not found: $log" >&2
      exit 1
    fi
    current_sentinel=$(grep -cF "$sentinel_pattern" "$log" 2>/dev/null || true)
    printf '%s\n' "$current_sentinel" > "${log}.baseline"
    echo "wait-for-watcher: baseline marked at sentinel count $current_sentinel" >&2
    exit 0
    ;;
  wait)
    [ "$#" -eq 2 ] || usage
    log="$2"
    baseline_file="${log}.baseline"
    if [ ! -f "$baseline_file" ]; then
      echo "wait-for-watcher: no baseline found at $baseline_file" >&2
      echo "wait-for-watcher: run \`$0 mark $log\` before the edit" >&2
      exit 2
    fi
    sentinel_baseline=$(cat "$baseline_file")
    ;;
  *)
    # Legacy positional form: <log> <baseline>.
    [ "$#" -eq 2 ] || usage
    log="$1"
    sentinel_baseline="$2"
    ;;
esac

if [ ! -f "$log" ]; then
  echo "wait-for-watcher: log not found: $log" >&2
  exit 1
fi

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

# Print a concise summary of the latest rebuild captured in the log:
# one PASS line on success, or FAIL with extracted error blocks and
# failing test names on failure. Designed so the caller can read this
# script's per-invocation output file directly with `Read` and get
# the build verdict in a glance -- no shell-side grepping needed.
#
# The full per-rebuild output stays in $log (the long-running watcher
# log) for cases where deeper inspection is justified, but the
# steady-state loop should never need it; if it does, that is a bug
# in this summarizer worth fixing here rather than working around in
# the caller.
print_rebuild_output() {
  if ! grep -qF "$start_marker_pattern" "$log"; then
    # Initial-build edge case: no NEW BUILD marker yet. Tail is the
    # least-bad signal; the caller can re-invoke after a real rebuild.
    echo "(no NEW BUILD marker in log yet; showing last 40 lines)"
    tail -40 "$log"
    return
  fi
  awk -v marker="$start_marker_pattern" '
    # Reset state on every NEW BUILD marker so we keep only the most
    # recent rebuild block.
    index($0, marker) == 1 {
      capture = 1
      ok_count = 0; fail_count = 0; suite_count = 0
      error_count = 0; had_errors = -1
      output_lines = 0
      delete buffer
      next
    }
    capture {
      output_lines++
      buffer[output_lines] = $0
      if (index($0, "[OK]") > 0) ok_count++
      if (index($0, "[FAIL]") > 0) fail_count++
      if (substr($0, 1, 8) == "Testing ") suite_count++
      # Compile / type-system errors. Both "Error: ..." and
      # "Error (...)..." (warnings-promoted-to-errors) appear.
      if (substr($0, 1, 7) == "Error: " || substr($0, 1, 7) == "Error (") error_count++
      # Authoritative terminal summary from dune watcher.
      if (match($0, /^Had ([0-9]+) error/)) {
        n = substr($0, RSTART + 4, RLENGTH - 10)
        had_errors = n + 0
      }
    }
    END {
      if (!capture) {
        print "(no rebuild captured in log)"
        exit
      }
      bad = (had_errors > 0) ? had_errors \
            : ((fail_count + error_count > 0) ? fail_count + error_count : 0)
      if (bad == 0) {
        # Happy path: one line, nothing else. This is the case that
        # should never tempt the caller into grepping.
        printf "PASS: %d tests across %d suites\n", ok_count, suite_count
      } else {
        printf "FAIL: %d failing test(s), %d compile error(s)", \
               fail_count, error_count
        if (had_errors >= 0) printf " (dune reports %d total)", had_errors
        printf "\n\n"
        # Diagnostic extraction. Three kinds of failure block in dune
        # watcher output:
        #   1. Compile / type errors: a `File "...", line N:` line
        #      followed by 1-N lines of error message terminated by a
        #      blank line.
        #   2. Test failures (alcotest): a [FAIL] line followed by an
        #      indented detail block (ASSERT / diff / backtrace),
        #      terminated by a blank line or the next [OK] / Testing.
        #   3. Dune-level errors that arrive before any File: line
        #      (linker errors, hook failures). Catch with the
        #      `Had N errors` terminal line context as a fallback.
        in_compile_block = 0
        in_fail_block = 0
        for (i = 1; i <= output_lines; i++) {
          line = buffer[i]
          if (line ~ /^File ".*", line/) {
            if (in_compile_block || in_fail_block) print ""
            in_compile_block = 1; in_fail_block = 0
            print line
            continue
          }
          if (in_compile_block) {
            print line
            if (line == "") in_compile_block = 0
            continue
          }
          if (index(line, "[FAIL]") > 0) {
            if (in_fail_block) print ""
            in_fail_block = 1
            print line
            continue
          }
          if (in_fail_block) {
            # Detail lines are indented or boxed; the next [OK] /
            # Testing line, or a blank, ends the block.
            if (line == "" || index(line, "[OK]") > 0 \
                || substr(line, 1, 8) == "Testing " \
                || substr(line, 1, 5) == "Full ") {
              in_fail_block = 0
              if (line == "") next
            } else {
              print line
            }
          }
        }
        # If we found neither File: blocks nor [FAIL] lines but dune
        # still reported errors (hook failure, linker error, build
        # aborted before any test ran), fall back to printing the
        # last 30 lines of the rebuild so the caller has *something*
        # to diagnose from.
        if (error_count == 0 && fail_count == 0 && had_errors > 0) {
          print "(no File: or [FAIL] markers found; tail of rebuild:)"
          start_tail = output_lines - 30
          if (start_tail < 1) start_tail = 1
          for (i = start_tail; i <= output_lines; i++) print buffer[i]
        }
      }
    }
  ' "$log"
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
    echo "wait-for-watcher: no rebuild triggered (touch / non-build file / hash unchanged)." >&2
    echo "wait-for-watcher: printing the most recent completed rebuild instead, so the output file still reflects current state." >&2
    print_rebuild_output
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
