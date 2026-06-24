#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/test_runner.sh"
source "$PROJECT_DIR/utils.sh"

# ── command_exists ──────────────────────────────────────

section "command_exists"

test_command_exists_true() {
  command_exists bash
  assert_eq 0 $? "bash should exist"
}
run_test "finds bash" test_command_exists_true

test_command_exists_false() {
  ! command_exists __nonexistent_binary_xyz__
  assert_eq 0 $? "nonexistent binary should not exist"
}
run_test "rejects nonexistent binary" test_command_exists_false

# ── is_dry_run ──────────────────────────────────────────

section "is_dry_run"

test_dry_run_off() {
  DRY_RUN=0
  ! is_dry_run
  assert_eq 0 $? "DRY_RUN=0 should be false"
}
run_test "false when DRY_RUN=0" test_dry_run_off

test_dry_run_on() {
  DRY_RUN=1
  is_dry_run
  assert_eq 0 $? "DRY_RUN=1 should be true"
}
run_test "true when DRY_RUN=1" test_dry_run_on

test_dry_run_unset() {
  local saved="${DRY_RUN:-}"
  unset DRY_RUN
  ! is_dry_run
  assert_eq 0 $? "unset DRY_RUN should be false"
  DRY_RUN="${saved:-0}"
}
run_test "false when DRY_RUN unset" test_dry_run_unset

# ── logging helpers ─────────────────────────────────────

section "logging helpers"

test_step_output() {
  local out
  out="$(step "Testing")"
  assert_match "-> Testing" "$out"
}
run_test "step prints arrow prefix" test_step_output

test_info_output() {
  local out
  out="$(info "detail")"
  assert_match "detail" "$out"
}
run_test "info prints message" test_info_output

test_ok_output() {
  local out
  out="$(ok "success")"
  assert_match "\[ok\] success" "$out"
}
run_test "ok prints [ok] prefix" test_ok_output

test_warn_output() {
  local out
  out="$(warn "caution")"
  assert_match "\[warn\] caution" "$out"
}
run_test "warn prints [warn] prefix" test_warn_output

test_fail_output() {
  local out
  out="$(fail "broken" 2>&1)" || true
  assert_match "\[error\] broken" "$out"
}
run_test "fail prints [error] to stderr" test_fail_output

test_fail_exits() {
  ( fail "die" ) >/dev/null 2>&1
  assert_eq 1 $? "fail should exit 1"
}
run_test "fail exits with code 1" test_fail_exits

# ── run_cmd ─────────────────────────────────────────────

section "run_cmd"

test_run_cmd_dry() {
  DRY_RUN=1
  local out
  out="$(run_cmd echo hello)"
  assert_match "\[dry-run\]" "$out" "should show dry-run tag"
  assert_match "echo" "$out" "should show command"
  DRY_RUN=0
}
run_test "dry-run prints command without executing" test_run_cmd_dry

test_run_cmd_real() {
  DRY_RUN=0
  local out
  out="$(run_cmd echo hello)"
  assert_eq "hello" "$out" "should execute the command"
}
run_test "real mode executes command" test_run_cmd_real

test_run_cmd_preserves_exit() {
  DRY_RUN=0
  run_cmd false || local rc=$?
  assert_eq 1 "${rc:-0}" "should propagate failure exit code"
}
run_test "propagates exit code" test_run_cmd_preserves_exit

test_run_cmd_dry_returns_zero() {
  DRY_RUN=1
  run_cmd false
  assert_eq 0 $? "dry-run should always return 0"
  DRY_RUN=0
}
run_test "dry-run always returns 0" test_run_cmd_dry_returns_zero

# ── version_ge ──────────────────────────────────────────

section "version_ge"

test_version_equal() {
  version_ge "3.12" "3.12"
  assert_eq 0 $?
}
run_test "equal versions" test_version_equal

test_version_greater_major() {
  version_ge "4.0" "3.12"
  assert_eq 0 $?
}
run_test "greater major" test_version_greater_major

test_version_greater_minor() {
  version_ge "3.14" "3.12"
  assert_eq 0 $?
}
run_test "greater minor" test_version_greater_minor

test_version_less_minor() {
  ! version_ge "3.10" "3.12"
  assert_eq 0 $?
}
run_test "less minor" test_version_less_minor

test_version_less_major() {
  ! version_ge "2.7" "3.0"
  assert_eq 0 $?
}
run_test "less major" test_version_less_major

test_version_three_parts() {
  version_ge "3.12.1" "3.12.0"
  assert_eq 0 $?
}
run_test "three-part versions" test_version_three_parts

test_version_three_vs_two() {
  version_ge "3.12.1" "3.12"
  assert_eq 0 $?
}
run_test "three-part vs two-part (equal base)" test_version_three_vs_two

test_version_two_vs_three() {
  version_ge "3.12" "3.12.1"
  assert_eq 0 $? "3.12 treated as 3.12.0, which < 3.12.1"
  # Actually 3.12 = 3.12.0, and 3.12.0 < 3.12.1, so this should fail
}
# Correction: 3.12 = 3.12.0 which is < 3.12.1
test_version_two_vs_three_correct() {
  ! version_ge "3.12" "3.12.1"
  assert_eq 0 $? "3.12 (=3.12.0) is less than 3.12.1"
}
run_test "two-part < three-part with patch" test_version_two_vs_three_correct

test_version_zero() {
  version_ge "0.1" "0.1"
  assert_eq 0 $?
}
run_test "zero major" test_version_zero

test_version_single_digit() {
  version_ge "4" "3"
  assert_eq 0 $?
}
run_test "single digit" test_version_single_digit

test_version_single_vs_dotted() {
  version_ge "4" "3.99"
  assert_eq 0 $?
}
run_test "single vs dotted" test_version_single_vs_dotted

test_version_non_numeric_part() {
  version_ge "3.12.0rc1" "3.12"
  assert_eq 0 $? "non-numeric parts treated as 0"
}
run_test "non-numeric parts treated as 0" test_version_non_numeric_part

# ── detect_platform ─────────────────────────────────────

section "detect_platform"

test_detect_platform() {
  local platform
  platform="$(detect_platform)"
  # We're on Linux, so it should be "linux"
  assert_match "^(linux|mac|windows|unsupported)$" "$platform" "should be a known platform"
}
run_test "returns a valid platform" test_detect_platform

test_detect_linux() {
  if [[ "$(uname -s)" == Linux* ]]; then
    local platform
    platform="$(detect_platform)"
    assert_eq "linux" "$platform"
  fi
}
run_test "detects linux on Linux" test_detect_linux

# ── ensure_path_contains ────────────────────────────────

section "ensure_path_contains"

test_path_add_new() {
  local saved_path="$PATH"
  ensure_path_contains "/tmp/__test_path_xyz__"
  assert_match "/tmp/__test_path_xyz__" "$PATH" "should add to PATH"
  PATH="$saved_path"
}
run_test "adds new directory to PATH" test_path_add_new

test_path_no_duplicate() {
  local saved_path="$PATH"
  ensure_path_contains "/usr/bin"
  local count
  count=$(echo "$PATH" | tr ':' '\n' | grep -c "^/usr/bin$")
  assert_eq 1 "$count" "should not duplicate /usr/bin"
  PATH="$saved_path"
}
run_test "does not duplicate existing entry" test_path_no_duplicate

test_path_prepends() {
  local saved_path="$PATH"
  ensure_path_contains "/tmp/__test_first__"
  local first
  first="$(echo "$PATH" | cut -d: -f1)"
  assert_eq "/tmp/__test_first__" "$first" "should prepend"
  PATH="$saved_path"
}
run_test "prepends to PATH" test_path_prepends

# ── pipx_package_installed ──────────────────────────────

section "pipx_package_installed"

test_pipx_installed_dry_run() {
  DRY_RUN=1
  ! pipx_package_installed "anything"
  assert_eq 0 $? "always false in dry-run"
  DRY_RUN=0
}
run_test "always false in dry-run" test_pipx_installed_dry_run

# ── run_with_sudo ───────────────────────────────────────

section "run_with_sudo"

test_run_with_sudo_dry() {
  DRY_RUN=1
  local out
  out="$(run_with_sudo echo hello)"
  assert_match "\[dry-run\]" "$out"
  DRY_RUN=0
}
run_test "dry-run shows sudo command" test_run_with_sudo_dry

test_run_with_sudo_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    DRY_RUN=0
    local out
    out="$(run_with_sudo echo hello)"
    assert_eq "hello" "$out" "as root, runs without sudo"
  else
    DRY_RUN=1
    local out
    out="$(run_with_sudo echo hello)"
    assert_match "\[dry-run\]" "$out"
    DRY_RUN=0
  fi
}
run_test "runs command (dry-run as non-root)" test_run_with_sudo_as_root

summary
