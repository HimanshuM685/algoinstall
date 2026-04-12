#!/usr/bin/env bash

winget_available() {
  command_exists winget || command_exists powershell.exe
}

winget_install_id() {
  local package_id="$1"

  winget_available || fail "winget is required on Windows for automatic installation"

  if command_exists winget; then
    run_cmd winget install --id "$package_id" --exact --accept-source-agreements --accept-package-agreements
    return
  fi

  run_cmd powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "winget install --id '$package_id' --exact --accept-source-agreements --accept-package-agreements"
}

install_python_os() {
  info "Installing Python via winget"
  winget_install_id Python.Python.3.12
}

install_git_os() {
  info "Installing Git via winget"
  winget_install_id Git.Git

  if [[ -d "/c/Program Files/Git/cmd" ]]; then
    ensure_path_contains "/c/Program Files/Git/cmd"
  fi

  if [[ -d "/c/Program Files/Git/bin" ]]; then
    ensure_path_contains "/c/Program Files/Git/bin"
  fi
}

install_docker_os() {
  info "Installing Docker Desktop via winget"
  winget_install_id Docker.DockerDesktop
  warn "Docker Desktop may require a logout/login before the CLI is available."
}
