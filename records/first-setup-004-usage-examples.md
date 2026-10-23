# Decision Record: first-setup-004-usage-examples

## Metadata
- Created At: 2026-10-22
- Scope: `first-setup.sh` header usage examples

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to `DECISIONS.yml`.
- Keep each entry as short as the discussion allows.

## Entry List

### Entry 0001 (2026-10-22)
- Why now: The user requested that the `first-setup.sh` file header list expected command examples and explain what each command does.
- Findings / trade-offs:
  - `install.sh` deploys the helper to `.dev/first-setup.sh` by default, and `first-setup.sh` remains a manual-only setup step. A selected custom helper directory may replace `.dev`.
  - With no arguments, the script updates and installs its apt dependency set, then installs the HackGen font pair for the current user if either font file is missing. Non-root apt operations use `sudo`; font installation itself is user-local and must not be run as root on behalf of another user.
  - `--help` and `-h` print usage and exit before checking or invoking `apt-get`. The script requires an apt-get environment and does not install development tools themselves.
  - Existing decisions `installer-011-22-first-setup-dependencies`, `installer-011-23-first-setup-deployment`, and `installer-011-24-executable-helper-deployment` are implementation-approved. The focused test covers help behavior and setup side effects; this change documents existing behavior rather than changing it.
- Focus areas: Add concise header comments for the default installed path, the no-argument setup command, the help command and `-h` alias, the current-user font behavior, and the apt-get / sudo boundary.
- Explicit exclusions: Do not change script behavior, help output, package contents, deployment paths, or README instructions. Do not recommend `sudo bash` for the whole script, since that would direct user-local fonts to root's data directory.
- Current conclusion: Document `bash .dev/first-setup.sh` as the default-path invocation from the target project root, explaining that it installs apt dependencies and installs HackGen fonts for the current user when the pair is incomplete. Document `bash .dev/first-setup.sh --help` as the no-side-effect help command, with `-h` as an alias. State the apt-get environment requirement and that development tools themselves are not installed.
- Next validation target: Confirm that the default command matches `install.sh` deployment, each description matches argument handling and side effects, and the comments do not imply that first-setup runs automatically or installs development tools.
- Promotion to DECISIONS.yml: pending

### Entry 0002 (2026-10-22)
- Discussion-validation: PASS — the scan covered the template, installer deployment path, README command style, focused tests, active dependency/deployment/font decisions, and their linked records. Narrowing the change to the template header is justified because all requested examples describe behavior already implemented and tested.
- Directional fit: `bash .dev/first-setup.sh` from the target project root matches the default deployment path; the help example and `-h` alias match argument handling. The no-argument description must distinguish apt package installation from development-tool installation and explain that HackGen is installed for the current user only when the font pair is incomplete.
- Contract fit: The candidate preserves manual-only execution, Linux/WSL apt-get scope, apt-only sudo escalation, user-local font installation, and the boundary that first-setup does not install development tools or modify shell/PATH/manager settings. No runtime, README, or deployment changes are needed.
- Hidden bindings: Keep the requested header behavior as a concise new sub-decision, `installer-011-22-8-header-usage-examples`, under `installer-011-22-first-setup-dependencies`; it should require the default-path run and help examples to accurately describe the current behavior and environment.
- Promotion to DECISIONS.yml: validated -> `installer-011-22-8-header-usage-examples`
- Evidence / references: `templates/first-setup.sh`; `install.sh`; `tests/first-setup.test.sh`; `README.md`; `DECISIONS.yml`; `records/first-setup-002-installer-deployment.md`; `records/first-setup-003-hackgen-font-installation.md`

### Entry 0003 (2026-10-22)
- Implementation result: Added Japanese header comments to `templates/first-setup.sh` for the default installed invocation and help command. The descriptions cover apt dependencies, user-local HackGen installation when the font pair is incomplete, apt-only sudo escalation, the apt-get environment requirement, and the fact that development tools themselves are not installed. Runtime behavior and the existing user-facing help output are unchanged.
- Validation result: `bash -n templates/first-setup.sh tests/first-setup.test.sh`, `bash tests/first-setup.test.sh` (2 tests), `git diff --check`, a focused header-content check, and PyYAML parsing with unique decision IDs all passed.
- Artifact alignment: `installer-011-22-8-header-usage-examples` was added under `installer-011-22-first-setup-dependencies`; both are `✅️Implementation Approved`, and the parent links to this record.
- Implementation-validation: PASS — the documented commands match the default deployment path and argument handling, and the descriptions preserve the manual-only, apt-get, current-user font, and no-development-tool boundaries. No blocker or newly binding risk remains.
- Promotion to DECISIONS.yml: implementation approved -> `installer-011-22-first-setup-dependencies`, `installer-011-22-8-header-usage-examples`
- Evidence / references: `bash -n templates/first-setup.sh tests/first-setup.test.sh`; `bash tests/first-setup.test.sh`; `git diff --check`; focused PyYAML and header-content checks
