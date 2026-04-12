#!/usr/bin/env bash

ensure_git() {
  step "Checking Git"

  if command_exists git; then
    ok "Found Git"
    return
  fi

  warn "Git is missing"
  install_git_os

  command_exists git || fail "Git installation failed"
  ok "Git installed"
}
