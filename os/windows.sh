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

windows_main() {
  step "Windows Setup via WSL2"
  info "AlgoKit on Windows is officially supported and recommended via WSL2."
  
  info "1. Installing VS Code"
  winget_install_id Microsoft.VisualStudioCode

  info "2. Installing Git"
  winget_install_id Git.Git

  info "3. Installing WSL2"
  if command_exists wsl; then
    ok "WSL is already installed."
  else
    if is_dry_run; then
      run_cmd powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process wsl -ArgumentList '--install' -Verb RunAs"
    else
      warn "Installing WSL requires Administrator privileges. A prompt may appear."
      run_cmd powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process wsl -ArgumentList '--install' -Verb RunAs -Wait"
    fi
    warn "A restart may be required to complete WSL installation."
  fi

  info "4. Installing Docker Desktop"
  winget_install_id Docker.DockerDesktop

  printf '\n======================================================\n'
  printf '✅ Windows Host Setup Complete!\n'
  printf '======================================================\n'
  printf 'To finish installing AlgoKit, please follow these steps:\n'
  printf '  1. Restart your computer if prompted by WSL or Docker.\n'
  printf '  2. Open Ubuntu (WSL) from your Start Menu and create a user account if needed.\n'
  printf '  3. Ensure Docker Desktop is running and WSL integration is enabled in its settings.\n'
  printf '  4. Inside your Ubuntu terminal, run this script again:\n'
  printf '       bash install.sh\n'
  printf '======================================================\n\n'
}
