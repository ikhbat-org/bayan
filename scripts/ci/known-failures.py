#!/usr/bin/env python3
"""Compare the failed tests of a scripts/test.sh run against a list of known failures.

usage: known-failures.py LIST REPORT...
  LIST    one test id per line; blank lines and # comments are ignored
  REPORT  the saved output of scripts/test.sh (bash scripts/test.sh | tee report.txt); every REPORT needs a summary line
Each `test: <part> FAIL ... log: <dir>/<part>.log` line of REPORT names a part that failed and the log kept for it
(when that path does not exist, tmp/<last directory>/<part>.log under the current directory is tried). The ids of a failed part:
  golden   <kind>/<case>, from the log lines `failed <kind>/<case>` and `timed out <kind>/<case>` (src/driver/golden.byn goldenPrint)
  bayan    <module>: <name>, from the log lines `  ✗ <module>: <name>` (src/driver/test.byn)
  other    the part name (scripts, runtime), and the part name of golden or bayan when its log names no test
exit 0: every failed id is listed and every listed id failed
exit 1: an unlisted failure, or a listed id that did not fail (it passes, or its part did not run); each is named
exit 2: usage error, unreadable list, report or log, or no `test:` summary line in a report
"""
import os
import re
import sys

SUMMARY = re.compile(r"^test: (\w+)\s+(pass|FAIL|skip)\b(.*)$")
LOG = re.compile(r"log: (.+)\)\s*$")
GOLDEN = re.compile(r"^(?:failed|timed out) (\S+/\S+)\s*$")
BAYAN = re.compile(r"^  ✗ (.+)$")  # indent 2 only: a nested ✗ (a build error inside a test's detail) is not a test name


def read(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        return f.read().splitlines()


def log_ids(part, log):
    pattern = GOLDEN if part == "golden" else BAYAN if part == "bayan" else None
    ids = set()
    if pattern:
        for line in log:
            m = pattern.match(line)
            if m:
                ids.add(m.group(1))
    return ids or {part}


def main(argv):
    if len(argv) < 3:
        print("known-failures: usage: known-failures.py LIST REPORT...")
        return 2
    list_path, report_paths = argv[1], argv[2:]
    try:
        listed = {l.strip() for l in read(list_path) if l.strip() and not l.lstrip().startswith("#")}
        reports = [(path, read(path)) for path in report_paths]
    except OSError as e:
        print(f"known-failures: cannot read {e.filename}: {e.strerror}")
        return 2
    failed = set()
    for report_path, report in reports:
        parts = 0
        for line in report:
            m = SUMMARY.match(line)
            if not m:
                continue
            parts += 1
            part, status, rest = m.groups()
            if status != "FAIL":
                continue
            lm = LOG.search(rest)
            if not lm:
                print(f"known-failures: no log path in the FAIL line of {part}")
                return 2
            log_path = lm.group(1)
            if not os.path.exists(log_path):
                log_path = os.path.join("tmp", os.path.basename(os.path.dirname(log_path)), os.path.basename(log_path))
            try:
                failed |= log_ids(part, read(log_path))
            except OSError as e:
                print(f"known-failures: cannot read {e.filename}: {e.strerror}")
                return 2
        if parts == 0:
            print(f"known-failures: no 'test: <part>' summary line in {report_path}")
            return 2
    new = sorted(failed - listed)
    passing = sorted(listed - failed)
    for n in new:
        print(f"new failure: {n}")
    for n in passing:
        print(f"now passes: remove it from {list_path}: {n}")
    print(f"known-failures: {len(failed)} failed, {len(failed & listed)} known, {len(new)} new, {len(passing)} now passing")
    return 1 if new or passing else 0


sys.exit(main(sys.argv))
