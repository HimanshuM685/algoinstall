# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

AlgoInstall is a cross-platform Bash installer for AlgoKit (Algorand's dev toolkit). It detects the OS, installs only missing prerequisites (Python 3.12+, pipx, Git, optional Docker), installs AlgoKit, and verifies the result. It is served as a static site from `algoinstall.007575.xyz` (GitHub Pages via `CNAME`) and is meant to be run as `curl -fsSL https://algoinstall.007575.xyz/install.sh | bash`.

There is no build step, package manager, or test framework — the deliverable is the shell scripts themselves, served verbatim.

## Common commands

```bash
bash install.sh --dry-run        # Print every action without changing the system (primary dev/test loop)
bash install.sh                  # Real local run (sources sibling modules directly)
bash install.sh --skip-docker    # Skip Docker entirely
bash install.sh --with-docker    # Auto-install Docker when missing
bash install.sh --base-url URL   # Override module download source for bootstrap testing
bash -n install.sh               # Syntax check (do this after editing any script)
shellcheck install.sh utils.sh os/*.sh checks/*.sh   # Lint, if shellcheck is available
bash tests/run_tests.sh          # Run the full test suite (78 tests, no sudo/network)
bash tests/run_tests.sh test_utils  # Run a single suite
```

**`--dry-run` is the primary verification tool**: it routes every state-changing command through `run_cmd`, which prints `[dry-run] <quoted args>` instead of executing. When adding install logic, always wrap the actual command in `run_cmd` / `run_with_sudo` so `--dry-run` stays accurate.

**`tests/run_tests.sh`** is the automated test suite. It uses a self-contained test runner (no external deps). Tests cover: syntax validation, `utils.sh` pure functions (`version_ge`, `detect_platform`, `ensure_path_contains`, etc.), argument parsing, dry-run behavior, dependency checks, and all Linux package manager dispatch paths. All tests run without `sudo` or network — OS install functions are stubbed.

## Architecture

The code separates **"what to ensure"** from **"how to install it per-platform"**:

- **`install.sh`** — orchestrator and the only entrypoint. `main()` does: detect OS → `source_modules` → `ensure_python`/`ensure_pipx`/`ensure_git`/`ensure_docker` → `install_algokit` → `verify_algokit`. Windows short-circuits to `windows_main` and exits.
- **`utils.sh`** — shared helpers sourced first: logging (`step`/`info`/`ok`/`warn`/`fail`), `command_exists`, `is_dry_run`, the `run_cmd`/`run_with_sudo` execution wrappers, `version_ge` (hand-rolled dotted-version comparator), `detect_platform`, `ensure_path_contains`, and the `pipx_exec`/`pipx_package_installed` wrappers.
- **`checks/<dep>.sh`** — one `ensure_<dep>()` per dependency. These are platform-agnostic: they check whether the dep is present and, if not, call the OS-provided `install_<dep>_os()` hook. `checks/python.sh` owns the multi-stage Python fallback chain.
- **`os/<platform>.sh`** — exactly one of `linux.sh`/`mac.sh`/`windows.sh` is sourced, chosen by `detect_platform`. Each defines the `install_*_os()` functions the checks call (`install_python_os`, `install_python_with_uv_os`, `install_python_from_source_os`, `install_git_os`, `install_docker_os`, `install_packages_os`).

**The contract between layers:** `checks/*.sh` may only call `install_*_os` functions that every platform module defines (or that it guards with `declare -F ... >/dev/null`). When adding a new per-platform install step, add the function to *all three* `os/*.sh` files (or guard the call site), or you'll break a platform.

### Two execution modes (important)

`install.sh` runs in two distinct modes, decided by `bootstrap_modules_if_needed`:

1. **Local mode** — when `$SCRIPT_DIR/utils.sh` exists next to the script, modules are sourced from disk. This is what you get running `bash install.sh` in the repo.
2. **Bootstrap mode** — when piped via `curl | bash`, `BASH_SOURCE` isn't a real file, so the script downloads the 8 module files (listed explicitly in `bootstrap_modules_if_needed`) from `ALGOINSTALL_BASE_URL` into a `mktemp` dir, sets `SCRIPT_DIR` to it, and registers an `EXIT` trap to clean up.

**Consequence:** if you add a new module file under `os/` or `checks/`, you MUST also add it to the `files=(...)` array in `bootstrap_modules_if_needed`, or `curl | bash` users won't get it (local mode would still work, hiding the bug). `--base-url` is pre-parsed before bootstrap by `preparse_bootstrap_args` so it can redirect downloads for testing.

### Python fallback chain

`checks/python.sh:ensure_python` tries, in order, until a usable `>= MIN_PYTHON_VERSION` (3.12) binary is found:
1. Distro package via `install_python_os` (apt path even adds the deadsnakes PPA for 3.12 when distro Python is too old; Debian-non-Ubuntu is explicitly bailed out).
2. `uv` installing Python 3.14 (`install_python_with_uv_os`).
3. Building Python 3.14.5 from source (`install_python_from_source_os`).

`MIN_PYTHON_VERSION` is 3.12 but fallbacks target 3.14 — this asymmetry is intentional.

### AlgoKit install/verify

`install_algokit` prefers `pipx install --python "$PYTHON_BIN"` and falls back to `uv tool install`; it also handles the already-installed upgrade path. `verify_algokit` locates the `algokit` binary and, if it's not on the user's *original* PATH (`ORIGINAL_PATH`, captured before any PATH mutation), symlinks it into a writable PATH dir or `/usr/local/bin` so the command works in a fresh shell.

## Conventions

- `set -euo pipefail` is on; reference optional vars with `${VAR:-}` defaults.
- All user-facing output goes through the `utils.sh` logging helpers, not raw `echo`/`printf`, except for the final multi-line summaries.
- Linux supports apt/dnf/yum/pacman/zypper/apk; `install_packages_os` in `os/linux.sh` is the single dispatch point — extend the `case` there rather than scattering package-manager checks.
- Keep scripts POSIX-portable Bash and readable: this code is downloaded and (per the README's security posture) expected to be reviewed by users before being piped to Bash.
