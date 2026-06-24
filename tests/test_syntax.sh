#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/test_runner.sh"

section "syntax check (bash -n)"

scripts=(
  "install.sh"
  "utils.sh"
  "checks/python.sh"
  "checks/pipx.sh"
  "checks/git.sh"
  "checks/docker.sh"
  "os/linux.sh"
  "os/mac.sh"
  "os/windows.sh"
)

for script in "${scripts[@]}"; do
  name="$script"
  path="$PROJECT_DIR/$script"
  if bash -n "$path" 2>/dev/null; then
    run_test "$name" true
  else
    test_fn() { assert_eq 0 1 "syntax error in $name"; }
    run_test "$name" test_fn
  fi
done

section "shellcheck (if available)"

if command -v shellcheck >/dev/null 2>&1; then
  for script in "${scripts[@]}"; do
    name="$script"
    path="$PROJECT_DIR/$script"
    local_errors=""
    local_errors="$(shellcheck -S error "$path" 2>&1)" || true
    if [[ -z "$local_errors" ]]; then
      run_test "shellcheck $name" true
    else
      test_fn() { assert_eq "" "$local_errors" "shellcheck errors"; }
      run_test "shellcheck $name (errors only)" test_fn
    fi
  done
else
  skip_test "shellcheck all scripts" "shellcheck not installed"
fi

summary
