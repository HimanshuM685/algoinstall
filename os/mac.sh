#!/usr/bin/env bash

ensure_homebrew() {
  if command_exists brew; then
    return
  fi

  info "Installing Homebrew"
  run_cmd /bin/bash -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

  if [[ -x /opt/homebrew/bin/brew ]]; then
    ensure_path_contains /opt/homebrew/bin
  elif [[ -x /usr/local/bin/brew ]]; then
    ensure_path_contains /usr/local/bin
  fi
}

install_packages_os() {
  ensure_homebrew
  run_cmd brew install "$@"
}

install_python_os() {
  info "Installing Python via Homebrew"
  install_packages_os python@3.12
}

install_git_os() {
  info "Installing Git via Homebrew"
  install_packages_os git
}

install_docker_os() {
  info "Installing Docker via Homebrew"
  install_packages_os --cask docker
  warn "Launch Docker Desktop once after installation to finish setup."
}
