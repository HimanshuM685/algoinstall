#!/usr/bin/env bash

PYTHON_SOURCE_VERSION="3.14.5"
PYTHON_SOURCE_URL="https://www.python.org/ftp/python/3.14.5/Python-3.14.5.tar.xz"

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

install_python_from_source_os() {
  info "Installing Python $PYTHON_SOURCE_VERSION from source"

  if ! command_exists xcode-select || ! xcode-select -p >/dev/null 2>&1; then
    warn "Xcode Command Line Tools are required to build Python from source."
    return 1
  fi

  ensure_homebrew
  run_cmd brew install openssl@3 readline sqlite3 xz zlib tcl-tk || return 1

  local brew_prefix openssl_prefix readline_prefix sqlite_prefix xz_prefix zlib_prefix tcltk_prefix
  brew_prefix="$(brew --prefix)"
  openssl_prefix="$(brew --prefix openssl@3)"
  readline_prefix="$(brew --prefix readline)"
  sqlite_prefix="$(brew --prefix sqlite3)"
  xz_prefix="$(brew --prefix xz)"
  zlib_prefix="$(brew --prefix zlib)"
  tcltk_prefix="$(brew --prefix tcl-tk)"

  local build_dir archive_path src_dir
  build_dir="$(mktemp -d "${TMPDIR:-/tmp}/python-src.XXXXXX")"
  archive_path="$build_dir/Python-$PYTHON_SOURCE_VERSION.tar.xz"
  src_dir="$build_dir/Python-$PYTHON_SOURCE_VERSION"

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
    export CFLAGS="-I$openssl_prefix/include -I$readline_prefix/include -I$sqlite_prefix/include -I$xz_prefix/include -I$zlib_prefix/include -I$tcltk_prefix/include"
    export LDFLAGS="-L$openssl_prefix/lib -L$readline_prefix/lib -L$sqlite_prefix/lib -L$xz_prefix/lib -L$zlib_prefix/lib -L$tcltk_prefix/lib"
    export CPPFLAGS="$CFLAGS"
    export PKG_CONFIG_PATH="$openssl_prefix/lib/pkgconfig:$readline_prefix/lib/pkgconfig:$sqlite_prefix/lib/pkgconfig:$xz_prefix/lib/pkgconfig:$zlib_prefix/lib/pkgconfig:$tcltk_prefix/lib/pkgconfig"
    export PATH="$brew_prefix/bin:$PATH"
    run_cmd ./configure --prefix=/usr/local --enable-optimizations --with-ensurepip=install || exit 1
    run_cmd make -j"$(sysctl -n hw.ncpu 2>/dev/null || printf '2')" || exit 1
    run_with_sudo make altinstall || exit 1
  ) || return 1

  ensure_path_contains /usr/local/bin
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
