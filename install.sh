#!/usr/bin/env bash
set -euo pipefail

resolve_script_dir() {
  local source_path="${BASH_SOURCE[0]:-}"

  if [[ -n "$source_path" && "$source_path" != "stdin" && -f "$source_path" ]]; then
    (cd "$(dirname "$source_path")" && pwd)
    return
  fi

  printf '\n'
}

plain_fail() {
  printf '[error] %s\n' "$1" >&2
  exit 1
}

download_file() {
  local url="$1"
  local dest="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
    return
  fi

  plain_fail "Neither curl nor wget is available for bootstrap download"
}

SCRIPT_DIR="$(resolve_script_dir)"
BOOTSTRAP_DIR=""
ALGOINSTALL_BASE_URL="${ALGOINSTALL_BASE_URL:-https://raw.githubusercontent.com/algoinstall/algoinstall/main}"

bootstrap_modules_if_needed() {
  if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/utils.sh" ]]; then
    return
  fi

  BOOTSTRAP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/algoinstall.XXXXXX")"
  local files=(
    "utils.sh"
    "checks/python.sh"
    "checks/pipx.sh"
    "checks/git.sh"
    "checks/docker.sh"
    "os/linux.sh"
    "os/mac.sh"
    "os/windows.sh"
  )
  local rel dest

  printf 'Bootstrapping AlgoInstall modules from %s\n' "$ALGOINSTALL_BASE_URL"

  for rel in "${files[@]}"; do
    dest="$BOOTSTRAP_DIR/$rel"
    mkdir -p "$(dirname "$dest")"
    download_file "$ALGOINSTALL_BASE_URL/$rel" "$dest" || plain_fail "Failed to download module: $rel"
  done

  SCRIPT_DIR="$BOOTSTRAP_DIR"
}

cleanup_bootstrap_dir() {
  if [[ -n "$BOOTSTRAP_DIR" && -d "$BOOTSTRAP_DIR" ]]; then
    rm -rf "$BOOTSTRAP_DIR"
  fi
}

# Defaults
DRY_RUN=0
SKIP_DOCKER=0
WITH_DOCKER=0
MIN_PYTHON_VERSION="3.12"

PLATFORM=""
PYTHON_BIN=""
ALGOKIT_VERSION=""

usage() {
  cat <<'EOF'
Usage: bash install.sh [options]

Options:
  --dry-run      Show actions without changing the system
  --skip-docker  Skip Docker checks and installation
  --with-docker  Install Docker automatically when missing
  --base-url URL Override module download URL for bootstrap mode
  -h, --help     Show this help message
EOF
}

preparse_bootstrap_args() {
  local args=("$@")
  local i=0

  while [[ "$i" -lt "${#args[@]}" ]]; do
    case "${args[$i]}" in
      --base-url)
        i=$((i + 1))
        [[ "$i" -lt "${#args[@]}" ]] || plain_fail "Missing value for --base-url"
        ALGOINSTALL_BASE_URL="${args[$i]}"
        ;;
    esac
    i=$((i + 1))
  done
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=1
        ;;
      --skip-docker)
        SKIP_DOCKER=1
        ;;
      --with-docker)
        WITH_DOCKER=1
        ;;
      --base-url)
        [[ $# -ge 2 ]] || fail "Missing value for --base-url"
        ALGOINSTALL_BASE_URL="$2"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail "Unknown option: $1"
        ;;
    esac
    shift
  done
}

source_modules() {
  local os_module="$SCRIPT_DIR/os/${PLATFORM}.sh"
  [[ -f "$os_module" ]] || fail "Missing OS module: $os_module"

  source "$os_module"
  source "$SCRIPT_DIR/checks/python.sh"
  source "$SCRIPT_DIR/checks/pipx.sh"
  source "$SCRIPT_DIR/checks/git.sh"
  source "$SCRIPT_DIR/checks/docker.sh"
}

install_algokit() {
  step "Installing AlgoKit"

  if pipx_package_installed "algokit"; then
    info "AlgoKit already installed; upgrading"
    pipx_exec upgrade algokit
  else
    pipx_exec install algokit
  fi

  if is_dry_run; then
    ok "Dry-run: AlgoKit install/upgrade would be attempted"
    return
  fi

  ok "AlgoKit install step completed"
}

verify_algokit() {
  step "Verifying installation"

  if is_dry_run; then
    ok "Dry-run: verification skipped"
    return
  fi

  local algokit_bin=""
  if command_exists algokit; then
    algokit_bin="$(command -v algokit)"
  elif command_exists algokit.exe; then
    algokit_bin="$(command -v algokit.exe)"
  elif [[ -x "$HOME/.local/bin/algokit" ]]; then
    algokit_bin="$HOME/.local/bin/algokit"
    ensure_path_contains "$HOME/.local/bin"
  elif [[ -x "$HOME/.local/bin/algokit.exe" ]]; then
    algokit_bin="$HOME/.local/bin/algokit.exe"
    ensure_path_contains "$HOME/.local/bin"
  fi

  [[ -n "$algokit_bin" ]] || fail "AlgoKit executable not found. Reopen your shell and run 'algokit --version'."

  ALGOKIT_VERSION="$($algokit_bin --version 2>/dev/null)" || fail "AlgoKit verification failed."
  ok "$ALGOKIT_VERSION"
}

print_done() {
  if is_dry_run; then
    printf '\nDry run complete. No changes were made.\n'
    return
  fi

  printf '\nDone! %s\n' "${ALGOKIT_VERSION:-AlgoKit installed}"
  printf 'Next steps:\n'
  printf '  - Open a new shell if PATH was updated.\n'
  printf '  - Run `algokit --version`.\n'
  printf '  - Run `algokit init` to create a new project.\n'
}

main() {
  preparse_bootstrap_args "$@"
  bootstrap_modules_if_needed
  source "$SCRIPT_DIR/utils.sh"
  trap cleanup_bootstrap_dir EXIT

  parse_args "$@"

  printf 'Running AlgoInstall...\n'

  step "Detecting OS"
  PLATFORM="$(detect_platform)"
  [[ "$PLATFORM" != "unsupported" ]] || fail "Unsupported OS: $(uname -s)"
  ok "$PLATFORM"

  source_modules

  ensure_python
  ensure_pipx
  ensure_git
  ensure_docker

  install_algokit
  verify_algokit
  print_done
}

main "$@"
