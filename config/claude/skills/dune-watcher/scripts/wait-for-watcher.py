#!/usr/bin/env python3
"""Drive the dune watcher: mark a baseline before edits, then wait for
the rebuild triggered by the edits to finish and print a concise
summary. Bundles the baseline capture so the caller never needs a
shell-side grep on the watcher log -- one whitelisted script handles
the whole cycle.

Usage:
    wait-for-watcher.py mark <log>      # before your edit
    # ... edit files ...
    wait-for-watcher.py wait <log>      # after; run_in_background
    # then `Read` the wait command's per-invocation output file

The baseline is stored in <log>.baseline so `mark` and `wait` can
share state without the caller threading a number through the shell.

Two-phase, two-counter strategy. See references/dune-watcher.md for
the full rationale, empirical findings, and rejected alternatives.

Phase 1 (<= 2 s): wait for evidence that dune decided to rebuild.
  Evidence is either:
    (a) the sentinel count already advanced past the caller's
        baseline -- we lost a race; the rebuild settled before we
        started polling.
    (b) a new `********** NEW BUILD` line appeared past the
        script's own baseline -- a rebuild is in flight; go to
        Phase 2.
  If neither happens within 2 s, the watcher chose not to rebuild
  (`touch` with same content, edit to a non-build file, or coalesced
  into an earlier rebuild that has already settled). Exit 0 with a
  note.

Phase 2 (hard ceiling 120 s): poll for the sentinel count to advance.
  No idle-bail -- once Phase 1 saw the start marker we know dune is
  working, and a real rebuild can have multi-second quiet gaps inside
  it (compile phases produce no output). On timeout, exit 1.
"""

from __future__ import annotations

import re
import sys
import time
from pathlib import Path

# Phrases dune watch emits verbatim. Both are stable across recent
# dune releases but not part of any documented interface; a future
# dune that reworks watcher output will need these updated.
SENTINEL_PATTERN = "waiting for filesystem"
START_MARKER_PATTERN = "********** NEW BUILD"

# Phase 1 is short because dune's measured reaction to an fs event is
# 17-47 ms; 2 s is generous. Phase 2 needs headroom for real test work
# (~22 s observed in the dovetail repo, likely to grow).
PHASE_1_MAX_WAIT = 2.0
PHASE_1_POLL = 0.1
PHASE_2_MAX_WAIT = 120.0
PHASE_2_POLL = 0.5

PROG = "wait-for-watcher"


def usage_and_exit() -> None:
    sys.stderr.write(
        f"usage:\n"
        f"  {PROG} mark <log>   capture current rebuild count before an edit\n"
        f"  {PROG} wait <log>   wait for a rebuild since the last mark\n"
    )
    sys.exit(2)


def log_stderr(message: str) -> None:
    """Write a prefixed informational line to stderr."""
    sys.stderr.write(f"{PROG}: {message}\n")


def count_matches(log_path: Path, pattern: str) -> int:
    """Count occurrences of a fixed-string pattern across lines of the
    log. Missing log returns 0 so the caller can use the count
    unconditionally."""
    try:
        with log_path.open("r", errors="replace") as handle:
            return sum(1 for line in handle if pattern in line)
    except FileNotFoundError:
        return 0


def read_latest_rebuild(log_path: Path) -> list[str] | None:
    """Return the lines of the most recent rebuild block. Normally this
    is everything after the last NEW BUILD marker, but dune only emits
    that marker on rebuilds *after* the first one, so on the initial
    build there is no marker -- in that case the whole log is the
    block. Returns None only when the log is genuinely empty."""
    block: list[str] | None = None
    initial_lines: list[str] = []
    with log_path.open("r", errors="replace") as handle:
        for line in handle:
            stripped = line.rstrip("\n")
            if stripped.startswith(START_MARKER_PATTERN):
                block = []
            elif block is not None:
                block.append(stripped)
            else:
                initial_lines.append(stripped)
    if block is not None:
        return block
    return initial_lines if initial_lines else None


def extract_per_suite(rebuild_lines: list[str]) -> dict[str, str]:
    """Walk a rebuild block and return {suite_name: PASS|FAIL} for
    every suite that ran. A suite block opens with ``Testing `<name>'``
    and stays open until the next Testing line; the suite is FAIL if
    any [FAIL] line appears inside, PASS otherwise."""
    results: dict[str, str] = {}
    current_suite: str | None = None
    for line in rebuild_lines:
        if line.startswith("Testing `"):
            end_quote = line.find("'", 9)
            if end_quote > 0:
                current_suite = line[9:end_quote]
                results.setdefault(current_suite, "PASS")
        elif current_suite is not None and "[FAIL]" in line:
            results[current_suite] = "FAIL"
    return results


def load_suite_state(state_path: Path) -> dict[str, str]:
    """Read the persisted per-suite state file."""
    if not state_path.exists():
        return {}
    state: dict[str, str] = {}
    for line in state_path.read_text().splitlines():
        if "\t" in line:
            name, status = line.split("\t", 1)
            state[name] = status
    return state


def save_suite_state(state_path: Path, state: dict[str, str]) -> None:
    """Write the per-suite state file in sorted order."""
    body = "".join(f"{name}\t{status}\n" for name, status in sorted(state.items()))
    state_path.write_text(body)


def update_and_print_suite_state(
    log_path: Path, rebuild_lines: list[str]
) -> None:
    """Merge the latest rebuild's per-suite results into the session
    state file (fresh results overwrite older entries for the same
    suite; suites not run this rebuild keep their prior status). Then
    print an ``Overall:`` line that reports aggregate health across
    every suite the session has seen.

    This is the cross-rebuild signal the per-rebuild PASS/FAIL line
    can't carry on its own: an incremental rebuild often re-runs only
    the suites whose dependencies changed."""
    state_path = Path(f"{log_path}.suite_state")
    state = load_suite_state(state_path)
    state.update(extract_per_suite(rebuild_lines))
    if not state:
        return
    save_suite_state(state_path, state)
    failing = sorted(name for name, status in state.items() if status == "FAIL")
    green = len(state) - len(failing)
    total = len(state)
    if not failing:
        print(f"Overall: {green}/{total} known suites green.")
    else:
        print(
            f"Overall: {green}/{total} suites green; "
            f"FAIL: {', '.join(failing)}"
        )


FILE_LINE_RE = re.compile(r'^File ".*", line')
HAD_ERRORS_RE = re.compile(r"^Had (\d+) error")


def summarize_counts(rebuild_lines: list[str]) -> dict[str, int]:
    """Tally the markers used to decide PASS vs FAIL and to count test
    suites for the summary line."""
    counts = {
        "ok": 0,
        "fail": 0,
        "suites": 0,
        "errors": 0,
        "had_errors": -1,
    }
    for line in rebuild_lines:
        if "[OK]" in line:
            counts["ok"] += 1
        if "[FAIL]" in line:
            counts["fail"] += 1
        if line.startswith("Testing "):
            counts["suites"] += 1
        # Compile / type-system errors. Both "Error: ..." and
        # "Error (...)..." (warnings-promoted-to-errors) appear.
        if line.startswith("Error: ") or line.startswith("Error ("):
            counts["errors"] += 1
        match = HAD_ERRORS_RE.match(line)
        if match:
            counts["had_errors"] = int(match.group(1))
    return counts


def print_failure_diagnostics(
    rebuild_lines: list[str], counts: dict[str, int]
) -> None:
    """Extract the failure detail blocks from a rebuild and print
    them. Three kinds of failure block appear in dune watcher output:

      1. Compile / type errors: a ``File "...", line N:`` line
         followed by 1-N lines of error message terminated by a blank
         line.
      2. Test failures (alcotest): a [FAIL] line followed by an
         indented detail block (ASSERT / diff / backtrace), terminated
         by a blank line or the next [OK] / Testing.
      3. Dune-level errors that arrive before any File: line (linker
         errors, hook failures). Caught with the ``Had N errors``
         terminal line as a fallback."""
    in_compile_block = False
    in_fail_block = False
    for line in rebuild_lines:
        if FILE_LINE_RE.match(line):
            if in_compile_block or in_fail_block:
                print("")
            in_compile_block, in_fail_block = True, False
            print(line)
            continue
        if in_compile_block:
            print(line)
            if line == "":
                in_compile_block = False
            continue
        if "[FAIL]" in line:
            if in_fail_block:
                print("")
            in_fail_block = True
            print(line)
            continue
        if in_fail_block:
            # Detail lines are indented or boxed; the next [OK] /
            # Testing line, or a blank, ends the block.
            if (
                line == ""
                or "[OK]" in line
                or line.startswith("Testing ")
                or line.startswith("Full ")
            ):
                in_fail_block = False
            else:
                print(line)

    # If we found neither File: blocks nor [FAIL] lines but dune still
    # reported errors (hook failure, linker error, build aborted
    # before any test ran), fall back to printing the tail of the
    # rebuild so the caller has *something* to diagnose from.
    if (
        counts["errors"] == 0
        and counts["fail"] == 0
        and counts["had_errors"] > 0
    ):
        print("(no File: or [FAIL] markers found; tail of rebuild:)")
        for line in rebuild_lines[-30:]:
            print(line)


def print_rebuild_output(log_path: Path) -> None:
    """Print a concise summary of the latest rebuild captured in the
    log: one PASS line on success, or FAIL with extracted error blocks
    and failing test names on failure. Designed so the caller can read
    this script's per-invocation output file directly with `Read` and
    get the build verdict at a glance -- no shell-side grepping
    needed.

    The full per-rebuild output stays in the watcher log for cases
    where deeper inspection is justified, but the steady-state loop
    should never need it; if it does, that is a bug in this summarizer
    worth fixing here rather than working around in the caller."""
    rebuild_lines = read_latest_rebuild(log_path)
    if rebuild_lines is None:
        # The log exists but is empty -- watcher has produced nothing
        # yet. Nothing useful to summarize; caller should re-invoke
        # once the watcher has emitted at least one build.
        print("(watcher log is empty; no build output yet)")
        return

    counts = summarize_counts(rebuild_lines)
    had_errors = counts["had_errors"]
    bad = had_errors if had_errors > 0 else counts["fail"] + counts["errors"]
    if bad == 0:
        # Happy path: one line, nothing else. This is the case that
        # should never tempt the caller into grepping.
        print(f"PASS: {counts['ok']} tests across {counts['suites']} suites")
    else:
        suffix = f" (dune reports {had_errors} total)" if had_errors >= 0 else ""
        print(
            f"FAIL: {counts['fail']} failing test(s), "
            f"{counts['errors']} compile error(s){suffix}\n"
        )
        print_failure_diagnostics(rebuild_lines, counts)
    update_and_print_suite_state(log_path, rebuild_lines)


def command_mark(log_path: Path) -> int:
    """Capture the current rebuild count and store it in
    <log>.baseline so a later `wait` invocation can detect the
    rebuild triggered by the edit that follows."""
    if not log_path.is_file():
        log_stderr(f"log not found: {log_path}")
        return 1
    current_sentinel = count_matches(log_path, SENTINEL_PATTERN)
    Path(f"{log_path}.baseline").write_text(f"{current_sentinel}\n")
    log_stderr(f"baseline marked at sentinel count {current_sentinel}")
    return 0


def command_wait(log_path: Path) -> int:
    """Wait for the rebuild triggered since the last `mark`, then
    print a concise summary. Phase 1 detects whether dune decided to
    rebuild at all; Phase 2 waits for that rebuild to finish."""
    baseline_path = Path(f"{log_path}.baseline")
    if not baseline_path.is_file():
        log_stderr(f"no baseline found at {baseline_path}")
        log_stderr(f"run `{PROG} mark {log_path}` before the edit")
        return 2
    sentinel_baseline = int(baseline_path.read_text().strip())

    if not log_path.is_file():
        log_stderr(f"log not found: {log_path}")
        return 1

    new_build_baseline = count_matches(log_path, START_MARKER_PATTERN)

    # ---- Phase 1: did the watcher decide to rebuild? ----
    phase_1_deadline = time.monotonic() + PHASE_1_MAX_WAIT
    rebuild_in_flight = False
    while True:
        if count_matches(log_path, SENTINEL_PATTERN) > sentinel_baseline:
            # Lost a race: the rebuild settled before we started
            # polling. Summary is current; we are done.
            print_rebuild_output(log_path)
            return 0
        if count_matches(log_path, START_MARKER_PATTERN) > new_build_baseline:
            rebuild_in_flight = True
            break
        if time.monotonic() >= phase_1_deadline:
            break
        time.sleep(PHASE_1_POLL)

    if not rebuild_in_flight:
        log_stderr(
            "no rebuild triggered (touch / non-build file / hash unchanged)."
        )
        log_stderr(
            "printing the most recent completed rebuild instead, so the "
            "output file still reflects current state."
        )
        print_rebuild_output(log_path)
        return 0

    # ---- Phase 2: wait for the rebuild to finish. ----
    phase_2_deadline = time.monotonic() + PHASE_2_MAX_WAIT
    while True:
        if count_matches(log_path, SENTINEL_PATTERN) > sentinel_baseline:
            print_rebuild_output(log_path)
            return 0
        if time.monotonic() >= phase_2_deadline:
            log_stderr(
                f"rebuild did not settle within {int(PHASE_2_MAX_WAIT)}s. "
                f"Watcher may be stuck."
            )
            try:
                tail = log_path.read_text(errors="replace").splitlines()[-100:]
                sys.stderr.write("\n".join(tail) + "\n")
            except FileNotFoundError:
                pass
            return 1
        time.sleep(PHASE_2_POLL)


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        usage_and_exit()
    subcommand, log = argv[1], Path(argv[2])
    if subcommand == "mark":
        return command_mark(log)
    if subcommand == "wait":
        return command_wait(log)
    usage_and_exit()
    return 2  # unreachable; satisfies the type checker


if __name__ == "__main__":
    sys.exit(main(sys.argv))
