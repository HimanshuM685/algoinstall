# AlgoInstall

One command. Zero friction. AlgoKit installed.

AlgoInstall is a cross-platform installer that removes setup friction for AlgoKit.
It detects the OS, installs only missing dependencies, installs AlgoKit with `pipx`,
and verifies everything at the end.

## Prerequisites

AlgoInstall installs the core prerequisites for you in one go:

- Python 3.12 or higher
- pipx
- Git
- Docker

If your distro/package manager does not provide Python 3.12+, AlgoInstall falls back
to installing Python 3.14 via `uv`. If that fails, it falls back to building
Python 3.14.5 from source using:
`https://www.python.org/ftp/python/3.14.5/Python-3.14.5.tar.xz`

VS Code is recommended for smart contract development, but it is not required to
run the installer.

## Recommended IDE Extensions

For the best Algorand smart contract experience in VS Code, install the Algorand
TypeScript and Python extensions.

## Quick Start

Install everything in one go:

```bash
curl -fsSL https://algoinstall.007575.xyz/install.sh | bash
```

Pass options through `curl | bash` with `-s --`:

```bash
curl -fsSL https://algoinstall.007575.xyz/install.sh | bash -s -- --dry-run
curl -fsSL https://algoinstall.007575.xyz/install.sh | bash -s -- --with-docker
curl -fsSL https://algoinstall.007575.xyz/install.sh | bash -s -- --skip-docker
```

Use `raw.githubusercontent.com` for installer links. Avoid `githubraw.com` URLs.

For local development:

```bash
bash install.sh
```

## CLI Options

- `--dry-run` Print every action without making changes.
- `--skip-docker` Skip Docker checks and installation.
- `--with-docker` Auto-install Docker when missing.
- `--base-url URL` Override module download source in bootstrap mode.
- `-h`, `--help` Show usage.

## Installation Flow

1. Detect platform (`linux`, `mac`, `windows`).
2. Check Python 3.12+, pipx, Git, and optional Docker.
3. Install only what is missing.
4. Install or upgrade AlgoKit.
5. Verify with `algokit --version`.

## Install AlgoKit

If you want to install AlgoKit manually after prerequisites are present:

```bash
pipx install algokit
```

If AlgoKit is already installed:

```bash
pipx upgrade algokit
```

Restart the terminal after installation if PATH changed.

## Platform Guide

### Windows

If you are on Windows, use WSL for the smoothest experience.

```bash
wsl --install
```

Then run AlgoInstall from inside your WSL Linux shell.

### macOS

If you install AlgoKit with Homebrew, it will install the latest Python 3 release
as a dependency. If you already have Python 3.10+ installed, you may prefer `pipx`
so you can control the Python version used.

Ensure these prerequisites are installed:

- Homebrew
- Git
- Docker, or `brew install --cask docker`

Tip: Docker requires macOS 11+.

Install with Homebrew:

```bash
brew install algorandfoundation/tap/algokit
```

Restart the terminal so `algokit` is available on your `PATH`.

### Linux / OS Agnostic

Ensure these prerequisites are installed:

- Python 3.12+
- pipx
- Git
- Docker

#### Arch Linux Containers (LXC/LXD)

If running inside an Arch Linux container on a host kernel older than Linux 5.13,
pacman may fail with Landlock sandboxing errors:

```text
error: restricting filesystem access failed because Landlock is not supported by the kernel!
```

Before running the installer, disable Landlock sandboxing in pacman:

```bash
echo 'DisableSandbox = yes' >> /etc/pacman.conf
```

Re-enable it after installation if the container moves to a newer kernel.

Install AlgoKit with `pipx`:

```bash
pipx install algokit

If `pipx` cannot resolve the package in your environment, install with `uv`:

```bash
uv tool install algokit --python 3.12
```
```

If you used AlgoKit before, update it with:

```bash
pipx upgrade algokit
```

Restart the terminal after installation.

## Verify The Installation

```bash
algokit --version
```

Expected output:

```text
algokit, version 2.6.0
```

## Testing

The project includes a self-contained Bash test suite with no external dependencies.

```bash
bash tests/run_tests.sh
```

Run a single suite:

```bash
bash tests/run_tests.sh test_utils
bash tests/run_tests.sh test_install
```

### Test Coverage

| Suite | Covers | Tests |
|---|---|---|
| `test_syntax` | `bash -n` + shellcheck on all 9 scripts | 9 |
| `test_utils` | `command_exists`, `is_dry_run`, logging, `run_cmd`, `run_with_sudo`, `version_ge`, `detect_platform`, `ensure_path_contains`, `pipx_package_installed` | 35 |
| `test_install` | `parse_args`, `preparse_bootstrap_args`, `usage`, `print_done`, `resolve_script_dir`, `--dry-run` integration, `--help` | 16 |
| `test_checks` | `find_python_bin`, `ensure_docker` (skip/found/missing), `ensure_git`, `pipx_exists`, `python_pip_available` | 9 |
| `test_os_linux` | `detect_linux_package_manager`, `linux_pkg_update_once`, `install_packages_os` dispatch (apt/dnf/pacman/zypper/apk/unknown) | 9 |

All tests run without `sudo` or network access. OS install functions are stubbed so tests are safe on any machine.

## Project Structure

```text
algoinstall/
|- install.sh
|- utils.sh
|- os/
|  |- linux.sh
|  |- mac.sh
|  `- windows.sh
|- checks/
|  |- python.sh
|  |- pipx.sh
|  |- docker.sh
|  `- git.sh
|- tests/
|  |- run_tests.sh
|  |- test_runner.sh
|  |- test_syntax.sh
|  |- test_utils.sh
|  |- test_install.sh
|  |- test_checks.sh
|  `- test_os_linux.sh
`- README.md
```

## Security Notes

- Script is plain Bash and intentionally readable.
- Use `--dry-run` before running in production or shared machines.
- Prefer reviewing `install.sh` and helper modules before piping to Bash.
- You can publish checksums for tagged releases for stricter verification.

## Why This Exists

AlgoKit onboarding should be immediate. Setup should not be a separate project.
AlgoInstall turns dependency setup into a single, idempotent command.
