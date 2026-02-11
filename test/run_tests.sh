#!/usr/bin/env bash
# test/run_tests.sh — Run all test scripts and report summary.
#
# Usage:
#   bash test/run_tests.sh           # run all tests
#   bash test/run_tests.sh <glob>    # run matching tests (e.g. "editor")

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

_green()  { printf '\033[32m%s\033[0m\n' "$*"; }
_red()    { printf '\033[31m%s\033[0m\n' "$*"; }
_bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

passed=0
failed=0
failed_scripts=()

filter="${1:-}"

for test_script in "$SCRIPT_DIR"/test_*.sh; do
  name="$(basename "$test_script")"

  # Apply filter if provided
  if [[ -n "$filter" && "$name" != *"$filter"* ]]; then
    continue
  fi

  echo ""
  _bold "═══ $name ═══"

  if bash "$test_script"; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
    failed_scripts+=("$name")
  fi
done

echo ""
_bold "═══════════════════════════════════════════"
_bold "Test suite summary"
_bold "═══════════════════════════════════════════"

total=$((passed + failed))
echo "  Scripts run:    $total"
_green "  Scripts passed: $passed"

if [[ $failed -gt 0 ]]; then
  _red "  Scripts failed: $failed"
  for f in "${failed_scripts[@]}"; do
    _red "    - $f"
  done
  echo ""
  _red "FAILED"
  exit 1
else
  echo ""
  _green "ALL PASSED"
  exit 0
fi
