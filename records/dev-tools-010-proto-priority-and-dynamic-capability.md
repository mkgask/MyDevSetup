# Decision Record: dev-tools-010-proto-priority-and-dynamic-capability

## Metadata
- Created At: 2026-08-09
- Scope: Use proto name-based capability detection and prefer proto when installing development tools

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to `DECISIONS.yml`.
- This discussion continues the Node.js route work recorded in `records/dev-tools-009-node-tool-installation.md`.

## Entry List

### Entry 0001 (2026-08-09)
- Why now: The user clarified that the previous explicit-mapping and no-remote-probe policy was an implementation assumption, not a requested constraint. Proto should be the preferred manager where it supports a target, while unsupported targets may fall back to mise or another available route.
- Findings / trade-offs:
  - `mise registry <identifier>` and `nix eval --read-only` already perform manager-side capability checks, so remote or manager-specific resolution is not uniquely a proto concern. Identifier aliases remain necessary for all managers, but aliases should not be treated as proof of support.
  - `proto versions <identifier> --json` returns success and a version manifest for supported built-in targets (`python`, `ruby`, `node`, and `uv`) and returns `proto::tool::unknown_id` for unsupported targets in the current proto 0.59.0 environment. This is a name-based capability probe, but it may access the remote release manifest and a transient failure is indistinguishable from unsupported support.
  - Proto's build mode is a separate installation contract. The current known modes are Python, Node.js, and uv as prebuilt (`--no-build`) and Ruby as source build (`--build`). The capability probe must not infer the build mode from support success.
  - The current helper orders `nix` before `proto`, configures `system` or `official` as defaults for most tools, and does not fall back to the first available route when the configured default is unavailable. That prevents proto from being the practical first choice and can make an unavailable default become `skip` even when another manager is available.
  - `proto plugin list <identifier>` exits successfully with `{}` for unknown identifiers in the current CLI, so plugin-list exit status alone is not a sufficient support probe. `proto versions` has the required supported/unknown distinction.
- Focus areas:
  - Replace proto's tool allowlist in route availability with manager-side name probing plus a static build-mode table and alias normalization.
  - Put proto first in the displayed route order and make the default selection choose proto when available, then the next available route when it is not.
  - Preserve `--global` route filtering, no manager/plugin installation during probing, process-scoped post-install activation, dry-run command fidelity, and fallback behavior for unsupported proto targets.
- Explicit exclusions: Do not infer build mode from a successful capability probe, run an installation as a probe, add automatic plugin registration, add npm/pnpm package installation, change project initialization, change first-setup dependencies, or change install.sh distribution.
- Current conclusion: The candidate direction is to use `proto versions` as the proto capability probe, retain explicit alias and build-mode data only where installation semantics require it, and make route/default priority prefer proto while preserving fallback to other available managers.
- Promotion to DECISIONS.yml: pending
- Evidence / references: `templates/dev-tools.sh`; `tests/dev-tools.test.sh`; `DECISIONS.yml`; `records/dev-tools-009-node-tool-installation.md`; proto 0.59.0; `proto versions <tool> --json`; `proto plugin list <tool> --json`; commit `55b1f32`

### Entry 0002 (2026-08-09)
- Discussion-validation: PASS. The bounded scan covered the manager capability functions, proto command semantics, build-mode dispatch, route ordering, default-route fallback, global filtering, dry-run behavior, focused tests, the original manager-probe commit, and the active decision contracts.
- Directional fit: Manager-side name probing and proto-first selection directly address the user's stated goal. The change removes an implementation-only proto allowlist without broadening installation scope or silently installing unsupported tools.
- Contract fit: The candidate preserves read-only probing, no plugin registration, no installation during detection, process-scoped activation, route-specific build modes, dry-run command fidelity, and `--global` exclusion of proto. A failed or unsupported proto probe falls through to the next available route rather than becoming an unconditional skip.
- Hidden bindings: `proto versions` must be treated as a capability result only; its success must not choose `--build` or `--no-build`. The build-mode table must remain explicit, and proto capability results should be cached within one helper process to avoid repeated remote probes while listing, defaulting, and previewing routes.
- Promotion targets: Update `installer-011-2-installation-backends`, `installer-011-2-1-proto-prebuilt`, `installer-011-2-4-node-installation-mapping`, and `installer-011-8-install-method-selection`. Add a small proto capability/default-priority sub-decision if needed to keep the active contract concise; update prior Node proto wording through the new linked record rather than rewriting immutable history.
- Validation result: PASS. The candidate serves the original objective, the narrowed focus is justified by the existing helper boundaries, and focused tests can disprove unsupported-target leakage, repeated probing, wrong build-mode selection, route-order drift, default fallback failure, and global proto exposure.
- Promotion to DECISIONS.yml: ready -> `installer-011-2-installation-backends`, `installer-011-2-1-proto-prebuilt`, `installer-011-2-4-node-installation-mapping`, `installer-011-8-install-method-selection`
- Evidence / references: `templates/dev-tools.sh`; `tests/dev-tools.test.sh`; proto 0.59.0 read-only probe results

### Entry 0003 (2026-08-09)
- Implementation result: `templates/dev-tools.sh` now probes proto support with `proto versions <identifier> --json`, caches positive and negative results in a process-local temporary file, keeps build mode explicit per tool, lists proto before other routes, and falls back to the first available route when proto is unavailable. Python, Node.js, and uv use `--no-build`; Ruby uses `--build`.
- Test result: `bash tests/dev-tools.test.sh` passed 22 focused tests, including proto capability success/failure, cache reuse across Bash substitution boundaries, proto-first ordering, default fallback, Node planned/executed commands, and uv prebuilt command planning. `bash tests/first-setup.test.sh` passed 1 test and `bash tests/install.test.sh` passed 18 tests.
- Implementation-validation result: PASS. A real non-interactive `install --dry-run` showed `node` as `planned proto: proto install node latest --no-build --yes` with proto as the default route. Shell syntax, `git diff --check`, diagnostics, and decision YAML/ID validation passed.
- Scope preserved: Capability probing does not install tools, register plugins, change manager configuration, update shell profiles, or modify project initialization. `--global` continues to exclude proto. The remaining operational risk is that proto's capability probe resolves a remote version manifest, so transient network failure causes proto to be treated as unavailable for that run and triggers fallback.
- Evidence / references: `templates/dev-tools.sh`; `tests/dev-tools.test.sh`; `tests/first-setup.test.sh`; `tests/install.test.sh`; `DECISIONS.yml`; real `install --dry-run`; proto 0.59.0

### Entry 0004 (2026-08-09)
- Clarification: Serena is known to be installable only through the existing `uv tool install -p 3.13 serena-agent` route. The proto-first rule applies to other supported targets and does not broaden Serena to proto, nix, mise, asdf, brew, system, or official routes.
- Implementation correction: `templates/dev-tools.sh` now excludes Serena from proto build-mode and capability handling, limits Serena's route list to `uv-tool` and `skip`, and restores `uv-tool` as Serena's configured default. This explicit route boundary also prevents generic manager probes from surfacing Serena as an unsupported alternative.
- Contract alignment: `installer-011-1-tool-order-and-prompt`, `installer-011-2-installation-backends`, `installer-011-2-1-proto-prebuilt`, `installer-011-8-install-method-selection`, and `installer-011-21-dry-run-preview` now state the Serena-only-uv exception alongside the proto-first contract.
- Validation result: `bash tests/dev-tools.test.sh` passed 22 focused tests, including manager fixtures that report Serena as available while the helper still exposes only `uv-tool` or `skip` and selects `uv-tool` by default.
- Evidence / references: `templates/dev-tools.sh`; `tests/dev-tools.test.sh`; `DECISIONS.yml`; existing `installer-011-18-uv-and-serena-installation` contract
