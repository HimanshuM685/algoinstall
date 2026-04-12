#!/usr/bin/env bash

pipx_exists() {
  command_exists pipx || [[ -x "$HOME/.local/bin/pipx" ]]
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
    run_cmd "$PYTHON_BIN" -m pipx ensurepath
    ok "Dry-run: pipx installation would be attempted"
    return
  fi

  [[ -n "${PYTHON_BIN:-}" ]] || fail "Python must be installed before pipx"

  warn "pipx is missing"

  if [[ "$PLATFORM" == "linux" || "$PLATFORM" == "mac" ]]; then
    run_cmd "$PYTHON_BIN" -m pip install --user pipx
  elif [[ "$PLATFORM" == "windows" ]]; then
    run_cmd "$PYTHON_BIN" -m pip install --user pipx
  else
    fail "Unsupported platform for pipx installation: $PLATFORM"
  fi

  run_cmd "$PYTHON_BIN" -m pipx ensurepath
  ensure_path_contains "$HOME/.local/bin"

  pipx_exists || fail "pipx installation failed"
  ensure_path_contains "$HOME/.local/bin"
  ok "pipx installed"
}
