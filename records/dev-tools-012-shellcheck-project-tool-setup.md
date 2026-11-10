# Decision Record: dev-tools-012-shellcheck-project-tool-setup

## Metadata
- Created At: 2026-11-09
- Scope: `language-tools.sh shell` によるプロジェクト内ShellCheck導入の方法と境界の決定

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to DECISIONS.yml.
- Keep each entry as short as the discussion allows.
- Evidence and detailed promotion metadata are optional; omit them when the entry stays clear without them.

Record boundary guidance:
- Keep one record focused on one cohesive decision theme. If an independent question, component, or follow-up appears, start a new record with a new `discussion-id` instead of extending unrelated history. Mention the prior record in `Evidence / references` when the new discussion continues from it.
- Use a practical reviewability signal: when a record reaches roughly 10 entries or 1,000 words, close it at a natural boundary and continue in a new record with a new `discussion-id`. This is a heuristic, not a hard parser-enforced limit; stay in the current record only when the next same-theme entry remains concise and reviewable.

Append rules:
- Append at EOF only; do not edit earlier sections.
- Do not add status tracking or remaining-work items.

## Entry List

### Entry 0001 (2026-11-09T01:27:36+09:00)
- Why now: The first concrete language-tool request maps the `shell` argument to ShellCheck. The parent decision `installer-011-26-project-language-tool-setup` is active, but its supported tools, installation source, target path, and failure behavior were intentionally left open. The linked `dev-tools-011` record already has eight entries and 846 words, so this focused tool decision starts a new record.
- Broad-scan findings:
  - `templates/language-tools.sh` is a scaffold with no-argument Usage and an explicit not-implemented response for arguments. `install.sh` deploys it beside `dev-tools.sh` and does not execute it.
  - `installer-011-26-project-language-tool-setup` keeps OS packages outside this helper, requires explicit tool arguments, and does not require separate runtime checks or project-wide tests/builds.
  - `templates/dev-tools.sh` installs shared/general tools through system managers and other routes; ShellCheck is not in its tool catalog. Adding ShellCheck there would mix project-selected tools into the shared tool flow.
  - The official ShellCheck README supports package-manager installation or precompiled release archives. GitHub has a pinned v0.11.0 release with Linux and macOS archives, including `.tar.gz` assets. The release API does not expose an asset digest, so an independent checksum is unavailable.
  - The npm `shellcheck` package is a third-party wrapper, requires Node.js 20.9 or later, and downloads the ShellCheck binary on first execution. This repository has no package manifest, so that route would introduce an unrelated Node dependency.
  - Existing tests are shell scripts with mock-command helpers; there is not yet a focused language-tools test file.
- Focus areas:
  - Map the explicit `shell` argument to ShellCheck and reject unsupported tool names before side effects.
  - Prefer a project-local binary beside the installed helper, honoring a custom helper directory as well as the default `.dev`.
  - Choose an upstream source/version and define supported OS/architecture and failure behavior without crossing the OS-package boundary.
  - Document how the project-local binary is used; do not run it against project files during installation.
- Explicit exclusions: No `apt`/`brew`/other OS package installation, global PATH or shell-profile changes, npm manifest creation, `.shellcheckrc` generation, automatic linting of project scripts, or setup for other language arguments in this first tool increment.
- Candidate direction:
  - `language-tools.sh shell` installs the official precompiled ShellCheck v0.11.0 into `bin/shellcheck` under the helper's directory (`.dev/bin/shellcheck` by default).
  - Support the Linux and macOS architectures with official v0.11.0 release archives; use HTTPS and a pinned release. Fail explicitly for unsupported platforms or failed download/extraction rather than silently falling back to an OS package manager.
  - Reuse a local installation only when its executable reports the pinned version. Do not modify PATH or run ShellCheck on project sources automatically.
- Current conclusion: The project-local official binary is the best fit for the user's preferred target and preserves the existing OS-bootstrap boundary. The release has no published asset digest in the inspected API response; pinned HTTPS download is the available integrity boundary for this increment.
- Next validation target: Confirm that the proposed local install path and pinned official release satisfy the user's request; confirm the OS-package boundary remains intact; ensure unknown arguments fail before installation, installation does not lint project files, and README/test changes reflect the exact supported-platform and failure behavior. Only then promote the tool-specific constraints.
- Promotion to DECISIONS.yml: pending
- Evidence / references: `DECISIONS.yml` (`installer-011-26-project-language-tool-setup`); `records/dev-tools-011-project-language-tool-setup.md`; `templates/language-tools.sh`; `templates/dev-tools.sh`; `install.sh`; `tests/install.test.sh`; official ShellCheck [installation instructions](https://github.com/koalaman/shellcheck#installing) and [v0.11.0 release](https://github.com/koalaman/shellcheck/releases/tag/v0.11.0); [npm package documentation](https://www.npmjs.com/package/shellcheck)

### Entry 0002 (2026-11-09T01:34:25+09:00)
- Clarification: The user approved global OS-package installation as a ShellCheck-only fallback when no official project-local release is available for the current platform.
- Contract interaction: This is a narrow exception to `installer-011-26-project-language-tool-setup`'s OS-package exclusion; it does not change `first-setup.sh` or authorize OS-package installation for other language-tool arguments.
- Updated candidate direction: Prefer the official pinned v0.11.0 project-local binary where an upstream asset exists. Only when the platform has no such asset may a supported, available global package manager install ShellCheck. A download/extraction failure where a local asset exists remains an explicit failure, not a reason to fall back globally.
- Next validation target: Confirm the exception is limited to ShellCheck and unsupported local-release platforms, and promote both the parent-boundary clarification and the tool-specific installation contract before implementation.
- Promotion to DECISIONS.yml: pending
- Evidence / references: User clarification via the structured choice in this discussion

### Entry 0003 (2026-11-09T01:34:53+09:00)
- Discussion-validation: PASS. The broad scan covered the active project-language and OS-package decisions, the existing helper deployment/CLI boundary, shared-tool installation routes, project documentation, test conventions, official ShellCheck installation options, and the alternative npm wrapper.
- Focus validation: The local-first route follows the user's stated preference and the official release artifacts cover the project's Linux/WSL use case; the global package-manager fallback is limited to platforms without a local official asset, as explicitly approved by the user.
- Directional fit: PASS — `shell` selects ShellCheck without merging it into `dev-tools.sh install`, and setup remains a manual project-helper action.
- Contract fit: The parent decision's OS-package exclusion needs a narrow explicit exception for this tool only. No `first-setup.sh`, automatic helper invocation, project-wide test/build, or other language-tool behavior changes.
- Hidden bindings and ownership: Promote the ShellCheck version/source, project-local target, supported release platforms, global package-manager fallback boundary, and explicit failure behavior to `DECISIONS.yml`. Keep research trade-offs in this record and user operation examples in `README.md`.
- Promotion targets: Update `installer-011-26-project-language-tool-setup` to permit only an explicitly authorized per-tool global fallback; add `installer-011-26-1-shellcheck-installation` for the `shell` mapping and its local-first/fallback contract.
- Validation result: PASS — no broader OS-package policy change is justified; the exception is bounded to ShellCheck where no official local release asset exists. No other tool or workflow scope is promoted.
- Promotion to DECISIONS.yml: ready -> `installer-011-26-project-language-tool-setup`, `installer-011-26-1-shellcheck-installation`
- Evidence / references: `DECISIONS.yml`; Entries 0001-0002 in this record; user fallback clarification; official ShellCheck README and v0.11.0 release assets

### Entry 0004 (2026-11-09T01:35:50+09:00)
- Promotion result: Updated `installer-011-26-project-language-tool-setup` with the explicit-per-tool global fallback exception and added `installer-011-26-1-shellcheck-installation`.
- Promoted contract: ShellCheck v0.11.0 is installed locally beside the helper when an official release asset exists; the bounded global-manager fallback applies only when no local asset exists. Local download/extraction failures remain failures, and automatic project lint/configuration is excluded.
- Status and linkage: Both affected decisions are `⚠️Implementing`; the child links to this record. The high-level language-tool decision remains active while actual setup logic is implemented.
- Remaining non-binding risk: GitHub's release API exposed no asset digest for the inspected artifacts; the selected source is pinned and fetched over HTTPS.
- Evidence / references: `DECISIONS.yml`; user fallback clarification; official ShellCheck v0.11.0 release assets

### Entry 0005 (2026-11-09T01:45:15+09:00)
- Implementation result: `templates/language-tools.sh` maps `shell` to the official ShellCheck v0.11.0 release. Supported local assets install beside the helper as `bin/shellcheck`; platforms without a local asset use the approved global package-manager fallback. Unsupported arguments and installation failures are reported explicitly.
- Validation result: PASS — 7 focused language-tools tests, 18 installer regressions, Bash syntax checks, a live Linux x86_64 install from the official release archive with the installed binary reporting v0.11.0, and ShellCheck v0.11.0 at warning severity for the helper and related tests.
- Artifact alignment: `README.md` documents the manual install and local/global invocation paths. `install.sh` still copies the helper without running it; no PATH or shell-profile changes, `.shellcheckrc`, or automatic project linting were added.
- Remaining non-binding risk: The pinned HTTPS download is not checked against an archive checksum. The live install covered Linux x86_64; mocked tests cover macOS asset selection and the global fallback.
- Evidence / references: `DECISIONS.yml`; `README.md`; `tests/language-tools.test.sh`; `tests/install.test.sh`; official ShellCheck v0.11.0 release
