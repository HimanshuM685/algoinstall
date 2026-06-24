#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/test_runner.sh"

# Source utils first (install.sh expects it)
source "$PROJECT_DIR/utils.sh"

# We can't source install.sh directly (it calls main), so we extract testable
# functions by sourcing a filtered version.
eval "$(sed -n '/^resolve_script_dir/,/^}/p; /^plain_fail/,/^}/p; /^download_file/,/^}/p; /^usage/,/^}/p; /^preparse_bootstrap_args/,/^}/p; /^parse_args/,/^}/p; /^print_done/,/^}/p' "$PROJECT_DIR/install.sh")"

# Defaults matching install.sh
DRY_RUN=0
SKIP_DOCKER=0
WITH_DOCKER=0
MIN_PYTHON_VERSION="3.12"
ALGOINSTALL_BASE_URL="https://algoinstall.007575.xyz"

# ── parse_args ──────────────────────────────────────────

section "parse_args"

test_parse_dry_run() {
  DRY_RUN=0
  parse_args --dry-run
  assert_eq 1 "$DRY_RUN"
  DRY_RUN=0
}
run_test "--dry-run sets DRY_RUN=1" test_parse_dry_run

test_parse_skip_docker() {
  SKIP_DOCKER=0
  parse_args --skip-docker
  assert_eq 1 "$SKIP_DOCKER"
  SKIP_DOCKER=0
}
run_test "--skip-docker sets SKIP_DOCKER=1" test_parse_skip_docker

test_parse_with_docker() {
  WITH_DOCKER=0
  parse_args --with-docker
  assert_eq 1 "$WITH_DOCKER"
  WITH_DOCKER=0
}
run_test "--with-docker sets WITH_DOCKER=1" test_parse_with_docker

test_parse_base_url() {
  ALGOINSTALL_BASE_URL="https://algoinstall.007575.xyz"
  parse_args --base-url "https://example.com"
  assert_eq "https://example.com" "$ALGOINSTALL_BASE_URL"
  ALGOINSTALL_BASE_URL="https://algoinstall.007575.xyz"
}
run_test "--base-url sets URL" test_parse_base_url

test_parse_combined() {
  DRY_RUN=0
  SKIP_DOCKER=0
  parse_args --dry-run --skip-docker
  assert_eq 1 "$DRY_RUN"
  assert_eq 1 "$SKIP_DOCKER"
  DRY_RUN=0
  SKIP_DOCKER=0
}
run_test "multiple flags combine" test_parse_combined

test_parse_unknown_fails() {
  ( parse_args --bogus ) >/dev/null 2>&1
  assert_eq 1 $? "unknown flag should fail"
}
run_test "unknown flag fails" test_parse_unknown_fails

test_parse_help_exits_zero() {
  ( parse_args --help ) >/dev/null 2>&1
  assert_eq 0 $? "-h/--help should exit 0"
}
run_test "--help exits 0" test_parse_help_exits_zero

test_parse_base_url_missing_value() {
  ( parse_args --base-url ) >/dev/null 2>&1
  assert_eq 1 $? "missing --base-url value should fail"
}
run_test "--base-url without value fails" test_parse_base_url_missing_value

# ── preparse_bootstrap_args ─────────────────────────────

section "preparse_bootstrap_args"

test_preparse_base_url() {
  ALGOINSTALL_BASE_URL="https://algoinstall.007575.xyz"
  preparse_bootstrap_args --dry-run --base-url "https://custom.example.com" --skip-docker
  assert_eq "https://custom.example.com" "$ALGOINSTALL_BASE_URL"
  ALGOINSTALL_BASE_URL="https://algoinstall.007575.xyz"
}
run_test "extracts --base-url from mixed args" test_preparse_base_url

test_preparse_no_base_url() {
  ALGOINSTALL_BASE_URL="https://algoinstall.007575.xyz"
  preparse_bootstrap_args --dry-run --skip-docker
  assert_eq "https://algoinstall.007575.xyz" "$ALGOINSTALL_BASE_URL"
}
run_test "leaves default when no --base-url" test_preparse_no_base_url

# ── usage ───────────────────────────────────────────────

section "usage"

test_usage_output() {
  local out
  out="$(usage)"
  assert_match "Usage:" "$out"
  assert_match "--dry-run" "$out"
  assert_match "--skip-docker" "$out"
  assert_match "--with-docker" "$out"
  assert_match "--base-url" "$out"
}
run_test "usage includes all flags" test_usage_output

# ── print_done ──────────────────────────────────────────

section "print_done"

test_print_done_dry_run() {
  DRY_RUN=1
  local out
  out="$(print_done)"
  assert_match "Dry run complete" "$out"
  assert_match "No changes" "$out"
  DRY_RUN=0
}
run_test "dry-run message" test_print_done_dry_run

test_print_done_real() {
  DRY_RUN=0
  ALGOKIT_VERSION="algokit 1.2.3"
  local out
  out="$(print_done)"
  assert_match "Done!" "$out"
  assert_match "algokit 1.2.3" "$out"
  assert_match "algokit init" "$out"
  ALGOKIT_VERSION=""
}
run_test "real done message" test_print_done_real

# ── resolve_script_dir ──────────────────────────────────

section "resolve_script_dir"

test_resolve_script_dir() {
  local dir
  dir="$(resolve_script_dir)"
  # When sourced, BASH_SOURCE[0] is the test file, so resolve_script_dir
  # returns the dir of install.sh (which is PROJECT_DIR)
  # But we eval'd it, so BASH_SOURCE may vary. Just check it's non-empty or empty.
  # The function should not error out.
  assert_eq 0 $?
}
run_test "does not error" test_resolve_script_dir

# ── dry-run integration ────────────────────────────────

section "dry-run integration"

test_full_dry_run_syntax() {
  # Run install.sh --dry-run and check it produces output without errors
  local out rc
  out="$(bash "$PROJECT_DIR/install.sh" --dry-run 2>&1)" || rc=$?
  # On a system without python 3.12+, it might fail at ensure_python,
  # but it should at least get past arg parsing and OS detection
  assert_match "Running AlgoInstall" "$out" "should start running"
  assert_match "Detecting OS" "$out" "should detect OS"
}
run_test "install.sh --dry-run starts correctly" test_full_dry_run_syntax

test_dry_run_help() {
  local out rc=0
  out="$(bash "$PROJECT_DIR/install.sh" --help 2>&1)" || rc=$?
  assert_eq 0 "$rc" "help should exit 0"
  assert_match "Usage:" "$out"
}
run_test "install.sh --help works" test_dry_run_help

summary
