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

VS Code is recommended for smart contract development, but it is not required to
run the installer.

## Recommended IDE Extensions

For the best Algorand smart contract experience in VS Code, install the Algorand
TypeScript and Python extensions.

## Quick Start

Install everything in one go:

```bash
curl -fsSL https://raw.githubusercontent.com/HimanshuM685/algoinstall/main/install.sh | bash -s -- --base-url https://raw.githubusercontent.com/HimanshuM685/algoinstall/main
```

Pass options through `curl | bash` with `-s --`:

```bash
curl -fsSL https://raw.githubusercontent.com/HimanshuM685/algoinstall/main/install.sh | bash -s -- --base-url https://raw.githubusercontent.com/HimanshuM685/algoinstall/main --dry-run
curl -fsSL https://raw.githubusercontent.com/HimanshuM685/algoinstall/main/install.sh | bash -s -- --base-url https://raw.githubusercontent.com/HimanshuM685/algoinstall/main --with-docker
curl -fsSL https://raw.githubusercontent.com/HimanshuM685/algoinstall/main/install.sh | bash -s -- --base-url https://raw.githubusercontent.com/HimanshuM685/algoinstall/main --skip-docker
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

## Verify The Installation

```bash
algokit --version
```

Expected output:

```text
algokit, version 2.6.0
```

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
