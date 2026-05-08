#!/usr/bin/env bash

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

is_dry_run() {
  [[ "${DRY_RUN:-0}" -eq 1 ]]
}

step() {
  printf '\n-> %s\n' "$1"
}

info() {
  printf '   %s\n' "$1"
}

ok() {
  printf '   [ok] %s\n' "$1"
}

warn() {
  printf '   [warn] %s\n' "$1"
}

fail() {
  printf '   [error] %s\n' "$1" >&2
  exit 1
}

run_cmd() {
  if is_dry_run; then
    printf '   [dry-run] '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi

  "$@" </dev/null
}

run_with_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    run_cmd "$@"
    return
  fi

  if ! command_exists sudo; then
    if is_dry_run; then
      run_cmd sudo "$@"
      return
    fi

    fail "sudo is required to install packages"
  fi

  run_cmd sudo "$@"
}

version_ge() {
  local current="$1"
  local required="$2"
  local i max
  local -a current_parts=()
  local -a required_parts=()

  IFS='.' read -r -a current_parts <<< "$current"
  IFS='.' read -r -a required_parts <<< "$required"

  max="${#current_parts[@]}"
  if [[ "${#required_parts[@]}" -gt "$max" ]]; then
    max="${#required_parts[@]}"
  fi

  for ((i = 0; i < max; i++)); do
    local current_num="${current_parts[$i]:-0}"
    local required_num="${required_parts[$i]:-0}"

    [[ "$current_num" =~ ^[0-9]+$ ]] || current_num=0
    [[ "$required_num" =~ ^[0-9]+$ ]] || required_num=0

    if ((current_num > required_num)); then
      return 0
    fi

    if ((current_num < required_num)); then
      return 1
    fi
  done

  return 0
}

python_version_from_bin() {
  "$1" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null
}

detect_platform() {
  local os
  os="$(uname -s)"

  case "$os" in
    Linux*)
      printf 'linux\n'
      ;;
    Darwin*)
      printf 'mac\n'
      ;;
    CYGWIN*|MINGW*|MSYS*)
      printf 'windows\n'
      ;;
    *)
      printf 'unsupported\n'
      ;;
  esac
}

ensure_path_contains() {
  local path_segment="$1"

  case ":$PATH:" in
    *":$path_segment:"*)
      return
      ;;
  esac

  export PATH="$path_segment:$PATH"
}

pipx_exec() {
  local pipx_bin=""

  if command_exists pipx; then
    pipx_bin="$(command -v pipx)"
  elif [[ -x "$HOME/.local/bin/pipx" ]]; then
    pipx_bin="$HOME/.local/bin/pipx"
    ensure_path_contains "$HOME/.local/bin"
  elif is_dry_run; then
    run_cmd pipx "$@"
    return
  else
    fail "pipx not found in PATH or ~/.local/bin"
  fi

  run_cmd "$pipx_bin" "$@"
}

pipx_package_installed() {
  local package="$1"

  if is_dry_run; then
    return 1
  fi

  local pipx_bin=""
  if command_exists pipx; then
    pipx_bin="$(command -v pipx)"
  elif [[ -x "$HOME/.local/bin/pipx" ]]; then
    pipx_bin="$HOME/.local/bin/pipx"
  else
    return 1
  fi

  "$pipx_bin" list --short 2>/dev/null | grep -Eq "^package[[:space:]]+$package([[:space:],]|$)"
}
