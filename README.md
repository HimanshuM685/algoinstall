# AlgoInstall

One command. Zero friction. AlgoKit installed.

AlgoInstall is a cross-platform installer that removes setup friction for AlgoKit.
It detects the OS, installs only missing dependencies, installs AlgoKit with `pipx`,
and verifies everything at the end.

## Quick Start

```bash
curl -sSL https://algoinstall.dev | bash
```

Pass options through `curl | bash` with `-s --`:

```bash
curl -sSL https://algoinstall.dev | bash -s -- --dry-run
curl -sSL https://algoinstall.dev | bash -s -- --with-docker
curl -sSL https://algoinstall.dev | bash -s -- --skip-docker
```

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
