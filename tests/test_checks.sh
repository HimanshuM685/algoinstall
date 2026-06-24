#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/test_runner.sh"
source "$PROJECT_DIR/utils.sh"

# Set globals that checks expect
DRY_RUN=0
SKIP_DOCKER=0
WITH_DOCKER=0
MIN_PYTHON_VERSION="3.12"
PLATFORM="linux"
PYTHON_BIN=""
LINUX_PACKAGE_MANAGER=""

# Stub the OS install functions so checks don't actually install anything
install_python_os() { return 1; }
install_python_with_uv_os() { return 1; }
install_python_from_source_os() { return 1; }
install_git_os() { return 0; }
install_docker_os() { return 0; }
install_packages_os() { return 0; }
detect_linux_package_manager() { printf 'apt\n'; }

source "$PROJECT_DIR/checks/python.sh"
source "$PROJECT_DIR/checks/pipx.sh"
source "$PROJECT_DIR/checks/git.sh"
source "$PROJECT_DIR/checks/docker.sh"

# ── find_python_bin ─────────────────────────────────────

section "find_python_bin"

test_find_python_bin_exists() {
  local bin
  bin="$(find_python_bin)"
  if command -v python3 >/dev/null 2>&1; then
    local ver
    ver="$(python_version_from_bin python3)"
    if [[ -n "$ver" ]] && version_ge "$ver" "$MIN_PYTHON_VERSION"; then
      assert_match "python" "$bin" "should find a python binary"
    fi
  fi
}
run_test "finds python binary if available" test_find_python_bin_exists

test_find_python_bin_respects_min_version() {
  local saved="$MIN_PYTHON_VERSION"
  MIN_PYTHON_VERSION="99.99"
  local bin
  bin="$(find_python_bin)"
  assert_eq "" "$bin" "should find nothing with impossible version"
  MIN_PYTHON_VERSION="$saved"
}
run_test "respects MIN_PYTHON_VERSION" test_find_python_bin_respects_min_version

# ── ensure_docker ───────────────────────────────────────

section "ensure_docker"

test_docker_skip() {
  SKIP_DOCKER=1
  local out
  out="$(ensure_docker)"
  assert_match "Skipped by --skip-docker" "$out"
  SKIP_DOCKER=0
}
run_test "--skip-docker skips docker" test_docker_skip

test_docker_found() {
  if command_exists docker; then
    SKIP_DOCKER=0
    WITH_DOCKER=0
    local out
    out="$(ensure_docker)"
    assert_match "\[ok\] Found Docker" "$out"
  else
    skip_test "docker found message" "docker not installed"
  fi
}
run_test "reports found when docker exists" test_docker_found

test_docker_missing_no_flag() {
  if ! command_exists docker; then
    SKIP_DOCKER=0
    WITH_DOCKER=0
    local out
    out="$(ensure_docker)"
    assert_match "Skipping Docker install" "$out"
    assert_match "--with-docker" "$out"
  else
    skip_test "docker missing skip" "docker is installed"
  fi
}
run_test "skips install without --with-docker" test_docker_missing_no_flag

# ── ensure_git ──────────────────────────────────────────

section "ensure_git"

test_git_found() {
  if command_exists git; then
    local out
    out="$(ensure_git)"
    assert_match "\[ok\] Found Git" "$out"
  else
    skip_test "git found" "git not installed"
  fi
}
run_test "reports found when git exists" test_git_found

# ── pipx_exists ─────────────────────────────────────────

section "pipx_exists"

test_pipx_exists_check() {
  if command_exists pipx || [[ -x "$HOME/.local/bin/pipx" ]]; then
    pipx_exists
    assert_eq 0 $?
  else
    ! pipx_exists
    assert_eq 0 $? "should be false when pipx not installed"
  fi
}
run_test "reflects actual pipx state" test_pipx_exists_check

# ── python_pip_available ────────────────────────────────

section "python_pip_available"

test_pip_no_python_bin() {
  PYTHON_BIN=""
  ! python_pip_available
  assert_eq 0 $? "should fail with no PYTHON_BIN"
}
run_test "fails with empty PYTHON_BIN" test_pip_no_python_bin

test_pip_with_python() {
  if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
    if python3 -m pip --version >/dev/null 2>&1; then
      python_pip_available
      assert_eq 0 $? "should succeed when pip is available"
    fi
  fi
  PYTHON_BIN=""
}
run_test "succeeds when pip available" test_pip_with_python

summary
