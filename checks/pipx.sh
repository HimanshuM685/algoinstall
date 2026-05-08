#!/usr/bin/env bash

pipx_exists() {
  command_exists pipx || [[ -x "$HOME/.local/bin/pipx" ]]
}

python_pip_available() {
  [[ -n "${PYTHON_BIN:-}" ]] || return 1
  "$PYTHON_BIN" -m pip --version >/dev/null 2>&1
}

install_python_pip_with_os_packages() {
  [[ "$PLATFORM" == "linux" ]] || return 1

  [[ -n "${LINUX_PACKAGE_MANAGER:-}" ]] || LINUX_PACKAGE_MANAGER="$(detect_linux_package_manager)"
  [[ "$LINUX_PACKAGE_MANAGER" != "unknown" ]] || return 1

  case "$LINUX_PACKAGE_MANAGER" in
    apt)
      info "Installing python3-pip/python3-venv via apt"
      install_packages_os python3-pip python3-venv
      ;;
    dnf|yum)
      info "Installing python3-pip via $LINUX_PACKAGE_MANAGER"
      install_packages_os python3-pip
      ;;
    pacman)
      info "Installing python-pip via pacman"
      install_packages_os python-pip
      ;;
    zypper)
      info "Installing python3-pip via zypper"
      install_packages_os python3-pip
      ;;
    apk)
      info "Installing py3-pip via apk"
      install_packages_os py3-pip
      ;;
    *)
      return 1
      ;;
  esac
}

ensure_python_pip() {
  python_pip_available && return 0

  warn "pip is missing for $PYTHON_BIN"

  if run_cmd "$PYTHON_BIN" -m ensurepip --upgrade && python_pip_available; then
    return 0
  fi

  install_python_pip_with_os_packages || return 1
  python_pip_available
}

install_pipx_with_pip() {
  ensure_python_pip || return 1

  if ! run_cmd "$PYTHON_BIN" -m pip install --user pipx; then
    return 1
  fi

  if ! run_cmd "$PYTHON_BIN" -m pipx ensurepath; then
    return 1
  fi

  return 0
}

install_pipx_with_os_packages() {
  [[ "$PLATFORM" == "linux" ]] || return 1

  [[ -n "${LINUX_PACKAGE_MANAGER:-}" ]] || LINUX_PACKAGE_MANAGER="$(detect_linux_package_manager)"
  [[ "$LINUX_PACKAGE_MANAGER" != "unknown" ]] || return 1

  if [[ "$LINUX_PACKAGE_MANAGER" == "apt" ]]; then
    info "Falling back to apt for pipx (PEP 668-safe)"
    install_packages_os pipx python3-venv
  else
    info "Falling back to $LINUX_PACKAGE_MANAGER for pipx"
    install_packages_os pipx
  fi

  if command_exists pipx; then
    run_cmd pipx ensurepath || true
  fi

  if is_dry_run; then
    return 0
  fi

  pipx_exists
}

ensure_pipx() {
  step "Checking pipx"

  if pipx_exists; then
    ok "Found pipx"
    ensure_path_contains "$HOME/.local/bin"
    return
  fi

  if is_dry_run; then
    warn "pipx is missing"
    run_cmd "$PYTHON_BIN" -m ensurepip --upgrade
    run_cmd "$PYTHON_BIN" -m pip install --user pipx
    if [[ "$PLATFORM" == "linux" ]]; then
      install_python_pip_with_os_packages || true
      install_pipx_with_os_packages || true
    fi
    ok "Dry-run: pipx installation would be attempted"
    return
  fi

  [[ -n "${PYTHON_BIN:-}" ]] || fail "Python must be installed before pipx"

  warn "pipx is missing"

  if ! install_pipx_with_pip; then
    if ! install_pipx_with_os_packages; then
      fail "pipx installation failed. On Debian/Ubuntu, install with: sudo apt update && sudo apt install -y pipx python3-venv"
    fi
  fi

  ensure_path_contains "$HOME/.local/bin"

  pipx_exists || fail "pipx installation failed"
  ensure_path_contains "$HOME/.local/bin"
  ok "pipx installed"
}
