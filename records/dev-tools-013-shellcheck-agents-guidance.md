# Decision Record: dev-tools-013-shellcheck-agents-guidance

## Metadata
- Created At: 2026-11-10
- Scope: `language-tools.sh shell` 成功時の ShellCheck 利用案内を AGENTS.md に登録する方法と境界

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

### Entry 0001 (2026-11-10T01:19:48+09:00)
- Why now: `language-tools.sh shell` now installs ShellCheck, but it does not tell project agents that the tool is available or how to invoke it. The active `installer-011-26-1-shellcheck-installation` decision covers installation and explicitly excludes automatic linting; it does not define AGENTS.md guidance.
- Findings / trade-offs:
  - `templates/dev-tools.sh` already manages an `AGENTS.md` block delimited by `<!-- BEGIN MYDEVSETUP DEV TOOLS -->` and `<!-- END MYDEVSETUP DEV TOOLS -->`, preserving content outside it and keeping entries idempotent.
  - ShellCheck may be project-local beside the helper or global through the approved fallback, so the invocation shown to agents must match the successful installation route.
  - `install_shellcheck_locally` reuses a matching existing binary, so registration must follow any successful `shell` setup, not only a new download.
  - Adding a permanent ShellCheck claim to `templates/AGENTS.md` would be inaccurate for projects that have not installed it.
- Focus areas: Record one ShellCheck usage entry in the target project's managed AGENTS.md block after local installation/reuse or successful global fallback; do not record it when setup fails. Keep the operation repeatable and preserve user-owned content.
- Explicit exclusions: No automatic ShellCheck execution, PATH/profile edits, shared `dev-tools.sh install` changes, install-time helper execution, or unconditional ShellCheck entry in the AGENTS template.
- Current conclusion: After successful `language-tools.sh shell`, upsert managed AGENTS.md guidance identifying the working ShellCheck command (project-local path or `shellcheck` for global installation). Use the existing `DEV_TOOLS_AGENTS_PATH` / `AGENTS.md` target convention, preserve content outside the managed block, and fail explicitly if the managed document cannot be updated safely. A failed ShellCheck setup must not change AGENTS.md.
- Promotion to DECISIONS.yml: pending discussion-validation -> `installer-011-26-2-shellcheck-agents-guidance`
- Evidence / references: `DECISIONS.yml` (`installer-011-26-1-shellcheck-installation`, `installer-011-6-agents-tool-record`, `installer-011-6-2-installed-tool-sync`); `templates/language-tools.sh`; `templates/dev-tools.sh`; `templates/AGENTS.md`; `tests/language-tools.test.sh`; `records/dev-tools-012-shellcheck-project-tool-setup.md`

### Append Template (Copy and Append at EOF)

### Entry {next-sequence} ({timestamp})
- Why now:
- Findings / trade-offs:
- Current conclusion:
- Promotion to DECISIONS.yml:
- Evidence / references (optional):

### Entry 0002 (2026-11-10T01:20:20+09:00)
- Discussion-validation: PASS. The bounded scan covered the active ShellCheck install contract, the language helper's local/reuse/global paths, the existing AGENTS.md managed-block updater and its preservation rules, template behavior, and focused tests.
- Focus and direction: PASS. Recording operational availability in AGENTS.md addresses the user's request without changing installation ownership or adding unconditional guidance to projects that have not installed ShellCheck. The update applies after successful local installation/reuse or global fallback, but not after setup failure.
- Contract fit: PASS. The proposal does not conflict with the language-tool boundary, ShellCheck's no-auto-lint/no-PATH-change constraints, or dev-tools' managed-block ownership. Guidance is limited to the block and names the actual invocation; malformed or unsafe AGENTS.md updates fail explicitly.
- Document ownership: The new decision owns the behavior contract; the generated AGENTS.md line is distinct operational guidance for project agents. No static ShellCheck claim is added to `templates/AGENTS.md`.
- Promotion target: Add `installer-011-26-2-shellcheck-agents-guidance` under `installer-011-26-project-language-tool-setup`, linked to this record. Keep the existing ShellCheck installation decision approved and the broader language-tool parent implementing.
- Evidence / references: `DECISIONS.yml`; Entries 0001-0002 in this record; `templates/dev-tools.sh` managed-block behavior; `templates/language-tools.sh`; `templates/AGENTS.md`; `tests/language-tools.test.sh`

### Entry 0003 (2026-11-10T01:27:34+09:00)
- Implementation result: Successful `shell` setup now idempotently adds or updates a ShellCheck usage entry in the managed AGENTS.md block. It records the project-relative local command where possible, or `shellcheck` for the global fallback; it also updates on local-version reuse. User content outside the block is preserved, and failed setup does not change AGENTS.md.
- Failure behavior: Unsafe or malformed managed blocks fail explicitly after installation without rolling back the installed binary. The focused test covers incomplete markers, as well as local/global paths, existing blocks, duplicate cleanup, custom helper paths, the `DEV_TOOLS_AGENTS_PATH` override, and missing AGENTS.md creation.
- Validation result: PASS — 11 language-tools tests, 18 installer regressions, Bash syntax checks, `git diff --check`, YAML parsing with 96 unique decision IDs and current links/statuses, live official Linux x86_64 ShellCheck v0.11.0 install and version check, and ShellCheck v0.11.0 at warning severity for the changed helper and tests.
- Artifact alignment: `README.md` documents the managed-block update and its failure behavior. `templates/AGENTS.md` was not given an unconditional ShellCheck entry.
- Remaining non-binding risk: The live install and lint ran on Linux x86_64; macOS release selection and global package-manager fallback are mock-tested, not exercised on those environments.
- Evidence / references: `DECISIONS.yml`; `README.md`; `tests/language-tools.test.sh`; `tests/install.test.sh`; official ShellCheck v0.11.0 release
