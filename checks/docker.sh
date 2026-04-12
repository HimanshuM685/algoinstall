#!/usr/bin/env bash

ensure_docker() {
  if [[ "${SKIP_DOCKER:-0}" -eq 1 ]]; then
    step "Checking Docker"
    info "Skipped by --skip-docker"
    return
  fi

  step "Checking Docker"

  if command_exists docker; then
    ok "Found Docker"
    return
  fi

  warn "Docker is missing"

  if [[ "${WITH_DOCKER:-0}" -eq 1 ]]; then
    install_docker_os
    if command_exists docker; then
      ok "Docker installed"
      return
    fi

    warn "Docker install completed but docker command is not available yet"
    return
  fi

  info "Skipping Docker install (use --with-docker to auto-install)"
}
