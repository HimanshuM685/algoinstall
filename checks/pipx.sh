#!/usr/bin/env bash

pipx_exists() {
  command_exists pipx || [[ -x "$HOME/.local/bin/pipx" ]]
}

install_pipx_with_pip() {
  if ! run_cmd "$PYTHON_BIN" -m pip install --user pipx; then
    return 1
  fi

  run_cmd "$PYTHON_BIN" -m pipx ensurepath
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
    run_cmd "$PYTHON_BIN" -m pip install --user pipx
    if [[ "$PLATFORM" == "linux" ]]; then
      run_cmd sudo apt-get update
      run_cmd sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y pipx python3-venv
      run_cmd pipx ensurepath
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
