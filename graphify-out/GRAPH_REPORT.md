# Graph Report - .  (2026-06-24)

## Corpus Check
- Corpus is ~4,706 words - fits in a single context window. You may not need a graph.

## Summary
- 101 nodes · 143 edges · 15 communities (8 shown, 7 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 3 edges (avg confidence: 0.92)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Shared Utilities & Helpers|Shared Utilities & Helpers]]
- [[_COMMUNITY_Documentation & Architecture|Documentation & Architecture]]
- [[_COMMUNITY_Install Orchestrator|Install Orchestrator]]
- [[_COMMUNITY_Linux Platform Module|Linux Platform Module]]
- [[_COMMUNITY_Pipx Dependency Check|Pipx Dependency Check]]
- [[_COMMUNITY_macOS Platform Module|macOS Platform Module]]
- [[_COMMUNITY_Windows Platform Module|Windows Platform Module]]
- [[_COMMUNITY_Project Identity & Purpose|Project Identity & Purpose]]
- [[_COMMUNITY_Python Dependency Check|Python Dependency Check]]
- [[_COMMUNITY_Docker Dependency Check|Docker Dependency Check]]
- [[_COMMUNITY_Git Dependency Check|Git Dependency Check]]
- [[_COMMUNITY_Arch Linux Workaround|Arch Linux Workaround]]
- [[_COMMUNITY_Linux Platform Docs|Linux Platform Docs]]
- [[_COMMUNITY_macOS Platform Docs|macOS Platform Docs]]
- [[_COMMUNITY_Windows Platform Docs|Windows Platform Docs]]

## God Nodes (most connected - your core abstractions)
1. `main()` - 9 edges
2. `install.sh Orchestrator` - 8 edges
3. `install_packages_os()` - 7 edges
4. `pipx_exec()` - 6 edges
5. `checks/*.sh Dependency Checks` - 6 edges
6. `os/*.sh Platform Modules` - 6 edges
7. `ensure_pipx()` - 5 edges
8. `install_packages_os()` - 5 edges
9. `is_dry_run()` - 5 edges
10. `run_with_sudo()` - 5 edges

## Surprising Connections (you probably didn't know these)
- `Installation Flow` --references--> `install.sh Orchestrator`  [INFERRED]
  README.md → CLAUDE.md
- `Security Notes` --conceptually_related_to--> `Bootstrap Execution Mode`  [INFERRED]
  README.md → CLAUDE.md
- `Why AlgoInstall Exists` --rationale_for--> `AlgoInstall`  [EXTRACTED]
  README.md → CLAUDE.md
- `Project Structure` --references--> `install.sh Orchestrator`  [EXTRACTED]
  README.md → CLAUDE.md
- `Project Structure` --references--> `utils.sh Shared Helpers`  [EXTRACTED]
  README.md → CLAUDE.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Dependency Ensure Flow** — algoinstall_claude_install_sh, algoinstall_claude_checks_layer, algoinstall_claude_os_layer, algoinstall_claude_utils_sh [EXTRACTED 1.00]
- **Python Installation Strategies** — algoinstall_claude_python_fallback_chain, algoinstall_claude_checks_layer, algoinstall_claude_os_layer, algoinstall_readme_prerequisites [EXTRACTED 1.00]
- **Platform-Specific Guides** — algoinstall_readme_windows_platform, algoinstall_readme_macos_platform, algoinstall_readme_linux_platform, algoinstall_readme_arch_linux_landlock [EXTRACTED 1.00]

## Communities (15 total, 7 thin omitted)

### Community 0 - "Shared Utilities & Helpers"
Cohesion: 0.21
Nodes (9): utils.sh script, command_exists(), ensure_path_contains(), fail(), is_dry_run(), pipx_exec(), pipx_package_installed(), run_cmd() (+1 more)

### Community 1 - "Documentation & Architecture"
Cohesion: 0.20
Nodes (16): AlgoKit Install and Verify, Architecture: What-to-Ensure vs How-to-Install, Bootstrap Execution Mode, checks/*.sh Dependency Checks, Coding Conventions, Dry-Run Verification Pattern, install.sh Orchestrator, Local Execution Mode (+8 more)

### Community 2 - "Install Orchestrator"
Cohesion: 0.26
Nodes (12): install.sh script, bootstrap_modules_if_needed(), download_file(), install_algokit(), main(), parse_args(), plain_fail(), preparse_bootstrap_args() (+4 more)

### Community 3 - "Linux Platform Module"
Cohesion: 0.29
Nodes (9): linux.sh script, ensure_deadsnakes(), install_docker_os(), install_git_os(), install_packages_os(), install_python_from_source_os(), install_python_os(), install_python_source_build_deps_linux() (+1 more)

### Community 4 - "Pipx Dependency Check"
Cohesion: 0.44
Nodes (8): ensure_pipx(), ensure_python_pip(), install_pipx_with_os_packages(), install_pipx_with_pip(), install_python_pip_with_os_packages(), pipx_exists(), python_pip_available(), pipx.sh script

### Community 5 - "macOS Platform Module"
Cohesion: 0.36
Nodes (7): mac.sh script, ensure_homebrew(), install_docker_os(), install_git_os(), install_packages_os(), install_python_from_source_os(), install_python_os()

### Community 6 - "Windows Platform Module"
Cohesion: 0.60
Nodes (4): windows.sh script, windows_main(), winget_available(), winget_install_id()

### Community 7 - "Project Identity & Purpose"
Cohesion: 0.50
Nodes (4): AlgoInstall, AlgoKit, Algorand, Why AlgoInstall Exists

## Knowledge Gaps
- **15 isolated node(s):** `docker.sh script`, `git.sh script`, `pipx.sh script`, `python.sh script`, `linux.sh script` (+10 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `docker.sh script`, `git.sh script`, `pipx.sh script` to the rest of the system?**
  _18 weakly-connected nodes found - possible documentation gaps or missing edges._