#!/usr/bin/env bash

LINUX_PACKAGE_MANAGER=""
LINUX_UPDATED=0
PYTHON_SOURCE_VERSION="3.14.5"
PYTHON_SOURCE_URL="https://www.python.org/ftp/python/3.14.5/Python-3.14.5.tar.xz"

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
      run_with_sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
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
  if grep -qi "debian" /etc/os-release && ! grep -qi "ubuntu" /etc/os-release; then
    warn "Debian natively provides Python < 3.12 and does not support the deadsnakes PPA."
    return 1
  fi

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
  [[ "$LINUX_PACKAGE_MANAGER" != "unknown" ]] || return 1

  case "$LINUX_PACKAGE_MANAGER" in
    apt)
      info "Installing Python via apt"
      install_packages_os python3 python3-pip python3-venv || return 1

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
          warn "Failed to install python3.12 from deadsnakes PPA."
          return 1
        fi
      else
        warn "Cannot install Python $MIN_PYTHON_VERSION+ from apt/deadsnakes path."
        return 1
      fi

      if is_dry_run; then
        return
      fi
      ;;
    dnf|yum)
      info "Installing Python via $LINUX_PACKAGE_MANAGER"
      install_packages_os python3.12 python3.12-pip || install_packages_os python3 python3-pip || return 1
      ;;
    pacman)
      info "Installing Python via pacman"
      install_packages_os python python-pip || return 1
      ;;
    zypper)
      info "Installing Python via zypper"
      install_packages_os python312 python312-pip || install_packages_os python3.12 python3.12-pip || install_packages_os python3 python3-pip || return 1
      ;;
    apk)
      info "Installing Python via apk"
      install_packages_os python3 py3-pip || return 1
      ;;
  esac
}

install_python_source_build_deps_linux() {
  case "$LINUX_PACKAGE_MANAGER" in
    apt)
      install_packages_os build-essential curl xz-utils libssl-dev zlib1g-dev libncurses-dev libreadline-dev libsqlite3-dev libgdbm-dev libdb5.3-dev libbz2-dev libexpat1-dev liblzma-dev tk-dev uuid-dev libffi-dev
      ;;
    dnf)
      install_packages_os gcc make curl xz openssl-devel zlib-devel ncurses-devel readline-devel sqlite-devel gdbm-devel bzip2-devel expat-devel xz-devel tk-devel libuuid-devel libffi-devel
      ;;
    yum)
      install_packages_os gcc make curl xz openssl-devel zlib-devel ncurses-devel readline-devel sqlite-devel gdbm-devel bzip2-devel expat-devel xz-devel tk-devel libuuid-devel libffi-devel
      ;;
    pacman)
      install_packages_os base-devel curl xz openssl zlib ncurses readline sqlite gdbm bzip2 expat tk libffi util-linux-libs
      ;;
    zypper)
      install_packages_os gcc make curl xz libopenssl-devel zlib-devel ncurses-devel readline-devel sqlite3-devel gdbm-devel libbz2-devel libexpat-devel liblzma-devel tk-devel libuuid-devel libffi-devel
      ;;
    apk)
      install_packages_os build-base curl xz openssl-dev zlib-dev ncurses-dev readline-dev sqlite-dev gdbm-dev bzip2-dev expat-dev xz-dev tk-dev util-linux-dev libffi-dev
      ;;
    *)
      return 1
      ;;
  esac
}

install_python_from_source_os() {
  [[ -n "$LINUX_PACKAGE_MANAGER" ]] || LINUX_PACKAGE_MANAGER="$(detect_linux_package_manager)"
  [[ "$LINUX_PACKAGE_MANAGER" != "unknown" ]] || return 1

  info "Installing Python $PYTHON_SOURCE_VERSION from source"
  install_python_source_build_deps_linux || return 1

  local build_dir archive_dir archive_path src_dir
  build_dir="$(mktemp -d "${TMPDIR:-/tmp}/python-src.XXXXXX")"
  archive_dir="$build_dir/archive"
  archive_path="$archive_dir/Python-$PYTHON_SOURCE_VERSION.tar.xz"
  src_dir="$build_dir/Python-$PYTHON_SOURCE_VERSION"
  mkdir -p "$archive_dir"

  if command_exists curl; then
    run_cmd curl -fsSL "$PYTHON_SOURCE_URL" -o "$archive_path" || return 1
  elif command_exists wget; then
    run_cmd wget -qO "$archive_path" "$PYTHON_SOURCE_URL" || return 1
  else
    warn "Neither curl nor wget is available to download Python source"
    return 1
  fi

  run_cmd tar -xJf "$archive_path" -C "$build_dir" || return 1
  [[ -d "$src_dir" ]] || return 1

  (
    cd "$src_dir" || exit 1
    run_cmd ./configure --enable-optimizations --with-ensurepip=install || exit 1
    run_cmd make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '2')" || exit 1
    run_with_sudo make altinstall || exit 1
  ) || return 1

  ensure_path_contains /usr/local/bin
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
