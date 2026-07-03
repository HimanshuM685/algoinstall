# Graph Report - .  (2026-07-03)

## Corpus Check
- Corpus is ~3,313 words - fits in a single context window. You may not need a graph.

## Summary
- 95 nodes · 138 edges · 10 communities (7 shown, 3 thin omitted)
- Extraction: 88% EXTRACTED · 12% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.86)
- Token cost: 26,153 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Project Overview & Concepts|Project Overview & Concepts]]
- [[_COMMUNITY_Shared Utility Helpers|Shared Utility Helpers]]
- [[_COMMUNITY_Installer Orchestration|Installer Orchestration]]
- [[_COMMUNITY_pipx Bootstrap|pipx Bootstrap]]
- [[_COMMUNITY_Linux Package Setup|Linux Package Setup]]
- [[_COMMUNITY_macOS Package Setup|macOS Package Setup]]
- [[_COMMUNITY_Windows Package Setup|Windows Package Setup]]
- [[_COMMUNITY_Python Detection|Python Detection]]
- [[_COMMUNITY_Docker Check|Docker Check]]
- [[_COMMUNITY_Git Check|Git Check]]

## God Nodes (most connected - your core abstractions)
1. `main()` - 9 edges
2. `install.sh` - 9 edges
3. `install_packages_os()` - 6 edges
4. `is_dry_run()` - 6 edges
5. `pipx_exec()` - 6 edges
6. `AlgoInstall` - 6 edges
7. `ensure_pipx()` - 5 edges
8. `install_packages_os()` - 5 edges
9. `run_with_sudo()` - 5 edges
10. `ensure_python_pip()` - 4 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Prerequisite Dependency Checks** — readme_checks_python_sh, readme_checks_pipx_sh, readme_checks_docker_sh, readme_checks_git_sh [INFERRED 0.85]
- **OS-Specific Install Modules** — readme_os_linux_sh, readme_os_mac_sh, readme_os_windows_sh, readme_install_sh [INFERRED 0.85]
- **AlgoKit Installation Flow** — readme_platform_detection, readme_python, readme_pipx, readme_algokit [INFERRED 0.85]

## Communities (10 total, 3 thin omitted)

### Community 0 - "Project Overview & Concepts"
Cohesion: 0.12
Nodes (22): AlgoInstall, AlgoKit, checks/docker.sh, checks/git.sh, checks/pipx.sh, checks/python.sh, Docker, --dry-run option (+14 more)

### Community 1 - "Shared Utility Helpers"
Cohesion: 0.20
Nodes (11): utils.sh script, command_exists(), ensure_path_contains(), fail(), info(), is_dry_run(), pipx_exec(), pipx_package_installed() (+3 more)

### Community 2 - "Installer Orchestration"
Cohesion: 0.26
Nodes (12): bootstrap_modules_if_needed(), download_file(), install_algokit(), main(), parse_args(), plain_fail(), preparse_bootstrap_args(), print_done() (+4 more)

### Community 3 - "pipx Bootstrap"
Cohesion: 0.44
Nodes (8): ensure_pipx(), ensure_python_pip(), install_pipx_with_os_packages(), install_pipx_with_pip(), install_python_pip_with_os_packages(), pipx_exists(), python_pip_available(), pipx.sh script

### Community 4 - "Linux Package Setup"
Cohesion: 0.39
Nodes (7): ensure_deadsnakes(), install_docker_os(), install_git_os(), install_packages_os(), install_python_os(), linux_pkg_update_once(), linux.sh script

### Community 5 - "macOS Package Setup"
Cohesion: 0.48
Nodes (6): ensure_homebrew(), install_docker_os(), install_git_os(), install_packages_os(), install_python_os(), mac.sh script

### Community 6 - "Windows Package Setup"
Cohesion: 0.60
Nodes (4): windows_main(), winget_available(), winget_install_id(), windows.sh script

## Knowledge Gaps
- **12 isolated node(s):** `docker.sh script`, `git.sh script`, `pipx.sh script`, `python.sh script`, `linux.sh script` (+7 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Are the 8 inferred relationships involving `install.sh` (e.g. with `checks/docker.sh` and `checks/git.sh`) actually correct?**
  _`install.sh` has 8 INFERRED edges - model-reasoned connections that need verification._
- **What connects `docker.sh script`, `git.sh script`, `pipx.sh script` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Project Overview & Concepts` be split into smaller, more focused modules?**
  _Cohesion score 0.11688311688311688 - nodes in this community are weakly interconnected._