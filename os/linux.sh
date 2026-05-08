#!/usr/bin/env bash

LINUX_PACKAGE_MANAGER=""
LINUX_UPDATED=0

detect_linux_package_manager() {
  if command_exists apt-get; then
    printf 'apt\n'
    return
  fi

  if command_exists dnf; then
    printf 'dnf\n'
    return
  fi

  if command_exists yum; then
    printf 'yum\n'
    return
  fi

  if command_exists pacman; then
    printf 'pacman\n'
    return
  fi

  if command_exists zypper; then
    printf 'zypper\n'
    return
  fi

  if command_exists apk; then
    printf 'apk\n'
    return
  fi

  printf 'unknown\n'
}

linux_pkg_update_once() {
  [[ "$LINUX_UPDATED" -eq 0 ]] || return

  case "$LINUX_PACKAGE_MANAGER" in
    apt)
      run_with_sudo apt-get update
      ;;
    dnf|yum|pacman|zypper|apk)
      ;;
  esac

  LINUX_UPDATED=1
}

install_packages_os() {
  [[ -n "$LINUX_PACKAGE_MANAGER" ]] || LINUX_PACKAGE_MANAGER="$(detect_linux_package_manager)"
  [[ "$LINUX_PACKAGE_MANAGER" != "unknown" ]] || fail "Unsupported Linux package manager"

  linux_pkg_update_once

  case "$LINUX_PACKAGE_MANAGER" in
    apt)
      run_with_sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
      ;;
    dnf)
      run_with_sudo dnf install -y "$@"
      ;;
    yum)
      run_with_sudo yum install -y "$@"
      ;;
    pacman)
      run_with_sudo pacman -Sy --noconfirm --needed "$@"
      ;;
    zypper)
      run_with_sudo zypper --non-interactive install "$@"
      ;;
    apk)
      run_with_sudo apk add --no-cache "$@"
      ;;
    *)
      fail "No install strategy for package manager: $LINUX_PACKAGE_MANAGER"
      ;;
  esac
}

ensure_deadsnakes() {
  if ! command_exists add-apt-repository; then
    info "Installing software-properties-common for add-apt-repository"
    install_packages_os software-properties-common
  fi

  if ! run_with_sudo add-apt-repository -y ppa:deadsnakes/ppa; then
    warn "Failed to add deadsnakes PPA — falling back to distro Python"
    return 1
  fi

  run_with_sudo apt-get update
  LINUX_UPDATED=1
}

install_python_os() {
  [[ -n "$LINUX_PACKAGE_MANAGER" ]] || LINUX_PACKAGE_MANAGER="$(detect_linux_package_manager)"
  [[ "$LINUX_PACKAGE_MANAGER" != "unknown" ]] || fail "Cannot install Python automatically on this Linux distro"

  case "$LINUX_PACKAGE_MANAGER" in
    apt)
      info "Installing Python via apt"
      install_packages_os python3 python3-pip python3-venv

      local pkg_version python_version
      pkg_version="$(python3 --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' || true)"
      python_version="$(python_version_from_bin python3 2>/dev/null || true)"
      local detected_ver="${python_version:-$pkg_version}"

      if [[ -n "$detected_ver" ]] && version_ge "$detected_ver" "$MIN_PYTHON_VERSION"; then
        return
      fi

      warn "Distro Python ($detected_ver) is below $MIN_PYTHON_VERSION — switching to deadsnakes PPA"

      if ensure_deadsnakes; then
        if ! install_packages_os python3.12 python3.12-venv; then
          fail "Failed to install python3.12 from deadsnakes PPA. Try manually: sudo apt-get install -y python3.12 python3.12-venv"
        fi
      else
        fail "Cannot install Python $MIN_PYTHON_VERSION+. deadsnakes PPA is required on this Ubuntu/Debian version. Add it manually: sudo add-apt-repository -y ppa:deadsnakes/ppa && sudo apt-get update && sudo apt-get install -y python3.12 python3.12-venv"
      fi

      if is_dry_run; then
        return
      fi
      ;;
    dnf|yum)
      info "Installing Python via $LINUX_PACKAGE_MANAGER"
      install_packages_os python3.12 python3.12-pip || install_packages_os python3 python3-pip
      ;;
    pacman)
      info "Installing Python via pacman"
      install_packages_os python python-pip
      ;;
    zypper)
      info "Installing Python via zypper"
      install_packages_os python3 python3-pip
      ;;
    apk)
      info "Installing Python via apk"
      install_packages_os python3 py3-pip
      ;;
  esac
}

install_git_os() {
  info "Installing Git"
  install_packages_os git
}

install_docker_os() {
  info "Installing Docker"

  [[ -n "$LINUX_PACKAGE_MANAGER" ]] || LINUX_PACKAGE_MANAGER="$(detect_linux_package_manager)"

  case "$LINUX_PACKAGE_MANAGER" in
    apt)
      install_packages_os docker.io
      ;;
    dnf|yum)
      install_packages_os docker
      ;;
    pacman)
      install_packages_os docker
      ;;
    zypper)
      install_packages_os docker
      ;;
    apk)
      install_packages_os docker docker-cli
      ;;
    *)
      fail "Cannot install Docker automatically for package manager: $LINUX_PACKAGE_MANAGER"
      ;;
  esac

  warn "Docker may require adding your user to the docker group and restarting the session."
}
