#!/usr/bin/env bash

find_python_bin() {
  local candidates=(python3.14 python3.13 python3.12 python3 python)
  local candidate version

  for candidate in "${candidates[@]}"; do
    if ! command_exists "$candidate"; then
      continue
    fi

    version="$(python_version_from_bin "$candidate")"
    if [[ -n "$version" ]] && version_ge "$version" "$MIN_PYTHON_VERSION"; then
      printf '%s\n' "$candidate"
      return
    fi
  done

  printf '\n'
}

ensure_python() {
  step "Checking Python"

  local version=""
  PYTHON_BIN="$(find_python_bin)"

  if [[ -n "$PYTHON_BIN" ]]; then
    version="$(python_version_from_bin "$PYTHON_BIN")"
    ok "Found $PYTHON_BIN ($version)"
    return
  fi

  warn "Python $MIN_PYTHON_VERSION+ is missing"
  install_python_os

  if is_dry_run; then
    PYTHON_BIN="python3.12"
    ok "Dry-run: Python installation would be attempted"
    return
  fi

  PYTHON_BIN="$(find_python_bin)"
  if [[ -z "$PYTHON_BIN" ]]; then
    if command_exists python3; then
      version="$(python_version_from_bin python3)"
      if [[ -n "$version" ]] && version_ge "$version" "$MIN_PYTHON_VERSION"; then
        PYTHON_BIN="python3"
        ok "Installed $PYTHON_BIN ($version)"
        return
      fi
      fail "Python installation succeeded, but version $version is below required $MIN_PYTHON_VERSION"
    fi

    fail "Python $MIN_PYTHON_VERSION+ installation did not produce a usable binary. Install it manually and re-run."
  fi

  version="$(python_version_from_bin "$PYTHON_BIN")"
  ok "Installed $PYTHON_BIN ($version)"
}
