#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/test_runner.sh"
source "$PROJECT_DIR/utils.sh"

DRY_RUN=0

# Source linux module (safe since we're on Linux and won't call install functions)
source "$PROJECT_DIR/os/linux.sh"

# ── detect_linux_package_manager ────────────────────────

section "detect_linux_package_manager"

test_detect_pkg_manager() {
  local mgr
  mgr="$(detect_linux_package_manager)"
  assert_match "^(apt|dnf|yum|pacman|zypper|apk|unknown)$" "$mgr" "should be a known package manager"
}
run_test "returns valid package manager" test_detect_pkg_manager

test_detect_pkg_manager_on_debian() {
  if command_exists apt-get; then
    local mgr
    mgr="$(detect_linux_package_manager)"
    assert_eq "apt" "$mgr"
  else
    skip_test "detects apt on Debian/Ubuntu" "apt-get not available"
  fi
}
run_test "detects apt when apt-get exists" test_detect_pkg_manager_on_debian

# ── linux_pkg_update_once ───────────────────────────────

section "linux_pkg_update_once"

test_update_once_idempotent() {
  DRY_RUN=1
  LINUX_UPDATED=0
  LINUX_PACKAGE_MANAGER="apt"
  local out1 out2
  out1="$(linux_pkg_update_once)"
  assert_eq 1 "$LINUX_UPDATED" "first call sets flag"
  out2="$(linux_pkg_update_once)"
  assert_eq "" "$out2" "second call is no-op"
  LINUX_UPDATED=0
  DRY_RUN=0
}
run_test "only runs once" test_update_once_idempotent

# ── install_packages_os dispatch ────────────────────────

section "install_packages_os (dry-run)"

test_install_packages_apt_dry() {
  DRY_RUN=1
  LINUX_PACKAGE_MANAGER="apt"
  LINUX_UPDATED=0
  local out
  out="$(install_packages_os some-package 2>&1)"
  assert_match "\[dry-run\]" "$out" "should show dry-run"
  assert_match "some-package" "$out" "should include package name"
  DRY_RUN=0
  LINUX_UPDATED=0
}
run_test "apt dispatch in dry-run" test_install_packages_apt_dry

test_install_packages_dnf_dry() {
  DRY_RUN=1
  LINUX_PACKAGE_MANAGER="dnf"
  LINUX_UPDATED=0
  local out
  out="$(install_packages_os some-package 2>&1)"
  assert_match "\[dry-run\]" "$out"
  assert_match "dnf" "$out"
  DRY_RUN=0
  LINUX_UPDATED=0
}
run_test "dnf dispatch in dry-run" test_install_packages_dnf_dry

test_install_packages_pacman_dry() {
  DRY_RUN=1
  LINUX_PACKAGE_MANAGER="pacman"
  LINUX_UPDATED=0
  local out
  out="$(install_packages_os some-package 2>&1)"
  assert_match "\[dry-run\]" "$out"
  assert_match "pacman" "$out"
  DRY_RUN=0
  LINUX_UPDATED=0
}
run_test "pacman dispatch in dry-run" test_install_packages_pacman_dry

test_install_packages_zypper_dry() {
  DRY_RUN=1
  LINUX_PACKAGE_MANAGER="zypper"
  LINUX_UPDATED=0
  local out
  out="$(install_packages_os some-package 2>&1)"
  assert_match "\[dry-run\]" "$out"
  assert_match "zypper" "$out"
  DRY_RUN=0
  LINUX_UPDATED=0
}
run_test "zypper dispatch in dry-run" test_install_packages_zypper_dry

test_install_packages_apk_dry() {
  DRY_RUN=1
  LINUX_PACKAGE_MANAGER="apk"
  LINUX_UPDATED=0
  local out
  out="$(install_packages_os some-package 2>&1)"
  assert_match "\[dry-run\]" "$out"
  assert_match "apk" "$out"
  DRY_RUN=0
  LINUX_UPDATED=0
}
run_test "apk dispatch in dry-run" test_install_packages_apk_dry

test_install_packages_unknown_fails() {
  DRY_RUN=0
  LINUX_PACKAGE_MANAGER="unknown"
  LINUX_UPDATED=0
  ( install_packages_os some-package ) >/dev/null 2>&1
  assert_eq 1 $? "unknown package manager should fail"
  LINUX_UPDATED=0
}
run_test "unknown package manager fails" test_install_packages_unknown_fails

summary
