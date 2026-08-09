# Decision Record: dev-tools-009-node-tool-installation

## Metadata
- Created At: 2026-08-09
- Scope: Add Node.js to the dev-tools installation inventory

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to DECISIONS.yml.
- Keep each entry as short as the discussion allows.
- Evidence and detailed promotion metadata are optional; omit them when the entry stays clear without them.

## Entry List

### Entry 0001 (2026-08-09)
- Why now: Node.js is now needed alongside the existing development-tool inventory. Python remains useful as an OS-provided runtime, Ruby is used frequently by AI development workflows, and project tooling commonly depends on Node.js. The user requested documentation and implementation updates.
- Findings / trade-offs:
  - `TOOL_NAMES` drives install, init, status, summary, prompt order, and AGENTS.md synchronization. `TOOL_COMMANDS` and `tool_command_candidates` control verified executable names; the canonical Node command should be `node`, with `nodejs` accepted as an OS-specific fallback.
  - The existing `system_package_for_tool` mapping supports only Python, Ruby, and ripgrep. Debian/Ubuntu-style and other Linux package-manager routes use the `nodejs` package, while Homebrew uses the `node` formula.
  - Nix uses a read-only exact-attribute probe, so Node needs a `nodejs` candidate rather than relying on the executable name. `mise registry node` succeeds in the current environment (`core:node`), so the existing generic mise capability path can handle Node. The existing asdf installed-plugin policy needs the conventional `nodejs` alias.
  - The current proto contract has explicit Python/Ruby mappings and no locally confirmed Node mapping from its read-only install help. The official-route table has no Node installer URL. Adding either route would require a separate verified contract; it is not necessary for a Linux system/mise/nix/asdf/brew implementation.
  - `--global` already allows system, nix, brew, official, and uv-tool routes. Node must inherit that existing scope behavior; mise/asdf remain excluded from global candidates. Node is not a package-manager inventory item, and the separate first-setup dependency bootstrap should not be changed.
- Focus areas:
  - Add `node` after Ruby in the canonical tool order, verify `node`/`nodejs`, and include Node in summary and managed AGENTS.md behavior through the existing loops.
  - Add Node mappings for system (`nodejs`), Homebrew (`node`), Nix (`nodejs`), mise (`node`), and installed-only asdf (`nodejs`), with `system` as the configured default route.
  - Extend focused mocks and assertions for route filtering, planned and actual installation commands, prompt count/order, status, dry-run, and AGENTS.md recording. Add Node to README's current tool inventory.
- Explicit exclusions: Do not add a new installer backend, official Node installer, proto Node route, Node package-manager status row, automatic npm/package installation, project initialization, shell-profile changes, first-setup package changes, or install.sh distribution changes.
- Current conclusion: Add Node.js as a normal CLI target using the existing `node` command contract and the smallest confirmed manager mappings. Reuse the existing install/status/dry-run/AGENTS.md loops so Node receives the same failure, verification, and recording behavior as other tools.
- Next validation target: Confirm that the candidate route set is compatible with the active installation, global-scope, dry-run, status, and AGENTS.md contracts; confirm that the focused test can disprove missing mappings or order drift before promotion.
- Promotion to DECISIONS.yml: pending
- Evidence / references: `templates/dev-tools.sh`; `tests/dev-tools.test.sh`; `README.md`; `DECISIONS.yml` decisions `installer-011-optional-tool-installation`, `installer-011-1`, `installer-011-2`, `installer-011-3`, `installer-011-8`, `installer-011-14`, `installer-011-21`; `mise registry node`; `proto --version` and `proto install --help`

### Entry 0002 (2026-08-09)
- Discussion-validation: PASS. The bounded scan covered the helper's canonical inventory, command verification, system/nix/mise/asdf/brew route layers, global filtering, dry-run planned commands, status and AGENTS.md synchronization, README inventory, the separate first-setup artifact, focused tests, and the active decisions governing those boundaries.
- Directional fit: Adding Node as a normal optional CLI directly serves the request. Reusing the existing tool loops avoids a second installation or recording mechanism, while the explicit exclusion of proto and official routes avoids claiming support that was not confirmed by the current local contract.
- Contract fit: The candidate preserves Linux/WSL scope, one prompt per missing tool, latest/default route behavior, manager/plugin non-installation, read-only capability probes, process-scoped activation, global route filtering, dry-run side-effect limits, status read-only behavior, failure continuation, and managed-block-only AGENTS.md updates. `node`/`nodejs` verification and `nodejs`/`node` package aliases are implementation details needed to satisfy those existing contracts.
- Hidden bindings: The canonical order must be Python, Ruby, Node, ripgrep, RTK, CodeGraph, uv, Serena; Node's configured default must remain `system`; Node must not be added to `PACKAGE_MANAGER_NAMES`; and README's inventory must match the helper. The first-setup dependency list and install.sh distribution remain unchanged.
- Promotion targets: Update `installer-011-optional-tool-installation`, `installer-011-1-tool-order-and-prompt`, `installer-011-2-installation-backends`, `installer-011-3-command-and-version-contract`, and `installer-011-8-install-method-selection`; add a small Node mapping sub-decision under `installer-011-2`; and update `installer-003-4-readme-scope` to keep the public inventory documentation aligned. The existing global and dry-run decisions inherit the route behavior and need no independent new rule.
- Validation result: PASS. The candidate fits the original objective and active constraints, the narrowed focus is justified by the bounded scan, and the focused implementation test can disprove missing route mappings, wrong prompt order, wrong package/formula identifiers, status omission, dry-run drift, or AGENTS.md recording drift.
- Promotion to DECISIONS.yml: ready -> `installer-011-optional-tool-installation`, `installer-011-1-tool-order-and-prompt`, `installer-011-2-installation-backends`, `installer-011-3-command-and-version-contract`, `installer-011-8-install-method-selection`, new Node mapping sub-decision, `installer-003-4-readme-scope`
- Evidence / references: `templates/dev-tools.sh`; `tests/dev-tools.test.sh`; `README.md`; `templates/first-setup.sh`; `tests/first-setup.test.sh`; `DECISIONS.yml`; `mise registry node`; baseline `bash tests/dev-tools.test.sh` (20 focused tests passed)

### Entry 0003 (2026-08-09)
- Implementation result: `templates/dev-tools.sh` now tracks Node.js after Ruby, verifies `node` before `nodejs`, and reuses the existing install, status, dry-run, summary, and AGENTS.md synchronization loops. Node uses `nodejs` for Linux system packages and Nix, `node` for Homebrew and mise, and an already-installed `nodejs` asdf plugin; its configured default route is `system`.
- Scope preserved: Node has no proto or official route, no npm/pnpm package installation, no project initialization, no first-setup dependency change, and no install.sh distribution change. The AGENTS.md matcher accepts both `node` and `nodejs` so fallback verification remains idempotent.
- Documentation and test result: `README.md` lists Node.js (`node`) after Ruby. Focused mocks cover route filtering, global scope, planned commands, actual system installation, fallback status, prompt order, dry-run output, and AGENTS.md recording. The installer fixture now represents the complete eight-tool inventory so deployment tests do not block on an unmocked prompt.
- Evidence / references: `templates/dev-tools.sh`; `tests/dev-tools.test.sh`; `tests/install.test.sh`; `README.md`; `DECISIONS.yml`

### Entry 0004 (2026-08-09)
- Implementation-validation result: PASS. `bash tests/dev-tools.test.sh` passed 21 focused tests, `bash tests/first-setup.test.sh` passed 1 focused test, and `bash tests/install.test.sh` passed 18 focused tests. Bash syntax checks for the affected helpers and tests passed; editor diagnostics, `git diff --check`, YAML parsing, and recursive decision-ID uniqueness checks also passed.
- Artifact alignment: The canonical tool order, Node command fallback, manager identifiers, route scope, README inventory, focused tests, and linked decision record agree. The test suite uses deterministic mocks; no live third-party installation was performed.

### Entry 0006 (2026-08-09)
- Discussion-validation: PASS. The bounded re-scan covered the proto mapping and capability gate, the shared proto install and dry-run command builders, route ordering and global filtering, focused route tests, the active Node backend contract, and the existing prebuilt/source-build split.
- Directional fit: Adding the proto choice directly addresses the reported missing option. The installed proto 0.59.0 returned Node versions from `proto versions node --json` and identified the built-in `node` plugin as Node.js, so the prior exclusion was based on insufficient evidence rather than an unsupported target.
- Contract fit: The candidate keeps Linux/WSL scope, explicit non-mutating route selection, manager/plugin non-installation, `--global` exclusion of proto, process-scoped proto activation, dry-run command fidelity, and no source-build fallback. Node uses the existing prebuilt proto contract and therefore must use `--no-build`.
- Hidden bindings: The proto route must be added to the existing Node mapping sub-decision and the prebuilt proto sub-decision must name Node alongside Python. The helper must not add a remote version-list probe; the explicit `node` mapping remains the route capability contract.
- Promotion targets: Update `installer-011-2-1-proto-prebuilt` and `installer-011-2-4-node-installation-mapping`; keep the existing parent backend, route-order, global-scope, command-verification, post-install activation, and documentation contracts aligned through their inherited route behavior.
- Validation result: PASS. The candidate satisfies the original request and current constraints, and focused tests can disprove missing proto mapping, incorrect build mode, route-order drift, and accidental global proto exposure.
- Promotion to DECISIONS.yml: ready -> `installer-011-2-1-proto-prebuilt`, `installer-011-2-4-node-installation-mapping`
- Evidence / references: `templates/dev-tools.sh`; `tests/dev-tools.test.sh`; `DECISIONS.yml`; proto 0.59.0; `proto versions node --json`; `proto status --json`

### Entry 0007 (2026-08-09)
- Implementation result: `templates/dev-tools.sh` now maps Node.js to the existing proto backend and uses `proto install node latest --no-build --yes`, while the shared route probe, post-install activation, status verification, and AGENTS.md synchronization remain unchanged.
- Test result: The focused Node route test passed after failing first on the missing proto mapping. The complete focused suites passed: `bash tests/dev-tools.test.sh` (21), `bash tests/first-setup.test.sh` (1), and `bash tests/install.test.sh` (18).
- Implementation-validation result: PASS. Shell syntax, `git diff --check`, and VS Code diagnostics passed for the changed artifacts. The route list includes proto for Node in normal scope and excludes it under `--global`; planned and executed commands both use the prebuilt `--no-build` mode.
- Scope preserved: No proto remote version-list probe, source-build fallback, official Node installer, npm/pnpm package installation, project initialization, first-setup package change, or install.sh distribution change was added. No live Node installation was performed; proto capability was verified read-only.
- Evidence / references: `templates/dev-tools.sh`; `tests/dev-tools.test.sh`; `tests/first-setup.test.sh`; `tests/install.test.sh`; `DECISIONS.yml`

### Entry 0005 (2026-08-09)
- Why now: The user reported that Node.js did not show a proto installation choice and asked whether the capability check was failing.
- Broad-scan findings:
  - The helper's `proto_tool_for_tool` and `proto_build_mode_for_tool` accept only Python and Ruby. `proto_route_available node` therefore returns before running the common `proto install --help` probe; the missing choice is an intentional mapping exclusion, not a failed Node capability check.
  - The installed proto 0.59.0 confirms Node support without installing it: `proto versions node --json` returns Node versions, and `proto status --json` lists the built-in `node` plugin as Node.js. The helper must not run remote version discovery during route selection because the existing contract limits probes to non-mutating checks and explicit mappings.
  - The existing proto install and dry-run paths both consume `proto_tool_for_tool` and `proto_build_mode_for_tool`, so one explicit Node mapping can keep the displayed and executed commands aligned.
- Focus areas:
  - Add `node` to the proto tool mapping and use the prebuilt command `proto install node latest --no-build --yes`.
  - Verify the proto route appears only when the existing proto binary/help probe succeeds, preserve the existing route order and `--global` filtering, and cover both planned and mocked execution commands.
  - Update the active Node installation contract and this record so the corrected proto scope is no longer contradicted by the previous exclusion.
- Explicit exclusions: Do not add proto remote version discovery to route selection, source-build fallback, an official Node installer, npm/pnpm package installation, project initialization, first-setup package changes, or install.sh distribution changes.
- Current conclusion: Node.js is a confirmed proto target and should use the existing proto prebuilt route. The prior proto exclusion was based on insufficient local evidence and is superseded by the read-only version/plugin confirmation.
- Next validation target: Confirm the focused route test can disprove missing proto mapping, incorrect `--no-build` command generation, route-order drift, and accidental global proto exposure before promotion.
- Promotion to DECISIONS.yml: pending
- Evidence / references: `templates/dev-tools.sh`; `tests/dev-tools.test.sh`; `DECISIONS.yml`; proto 0.59.0; `proto versions node --json`; `proto status --json`
