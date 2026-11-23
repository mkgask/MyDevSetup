# Decision Record: dev-tools-015-shellcheck-ignore-location

## Metadata
- Created At: 2026-11-23
- Scope: Generated helper-local binariesをrootまたはhelper配下の `.gitignore` のどちらで管理するか

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

### Entry 0001 (2026-11-23T00:16:28+09:00)
- Why now: After implementing root `.gitignore` maintenance for `.dev/bin/`, the user asked whether a `.gitignore` inside the helper installation directory, containing `bin/`, would be more generic.
- Broad-scan findings:
  - `installer-011-26-3-shellcheck-gitignore` currently requires a project-root `.gitignore` entry for the helper-relative `bin/` directory, defaulting to `.dev/bin/`.
  - `install.sh` defaults to `.dev` but permits a custom helper directory; `language-tools.sh` installs its local binary beside the helper.
  - A root `.gitignore` centralizes project ignore policy but needs a path-specific entry for each helper directory. A helper-local `.gitignore` with `bin/` is independent of the helper directory name and keeps the rule next to the generated directory.
  - A nested ignore file is itself an additional project file and may interact with an existing user-owned `.gitignore` in the helper directory. Git does not read ignore files inside a directory that is already excluded by a parent rule; in that case, the helper directory's contents are already excluded by the parent.
  - The current root-level approach is documented and tested for default and custom in-project helper paths.
- Focus areas: Compare location-independence, ownership/discoverability, interactions with existing helper-directory ignore rules, and the number of files/entries added. No installation or fallback behavior is under reconsideration.
- Explicit exclusions: No code or decision change is requested in this turn; do not silently replace the approved root-level behavior.
- Candidate direction: A helper-local `.gitignore` with `bin/` is more location-independent when helper directories may vary, while root `.gitignore` is more centralized and conventional for a fixed project-level policy such as `.dev/bin/`. The right choice depends on whether the helper directory is intended to own all generated local binaries or whether ignore rules should remain centralized.
- Current conclusion: The nested option is more generic with respect to the helper's installation path; the current root option remains valid and has a clearer central project-policy surface. Keep the approved root-level implementation until the user chooses whether helper-local ownership is preferred.
- Next validation target: Before changing the active contract, confirm whether custom helper directories should be self-contained and whether creating/updating a `.gitignore` beside the helper is acceptable when that directory already contains user-owned configuration.
- Promotion to DECISIONS.yml: none; comparison requested, no direction approved
- Evidence / references: `DECISIONS.yml` (`installer-011-26-3-shellcheck-gitignore`); `records/dev-tools-014-shellcheck-gitignore.md`; `install.sh`; `templates/language-tools.sh`; `tests/language-tools.test.sh`; `README.md`; root `.gitignore`

### Entry 0002 (2026-11-23T00:16:28+09:00)
- Discussion-validation: PASS for the requested comparison; no binding direction was approved.
- Landscape and focus validation: PASS. The comparison covered the fixed `.dev` default, custom helper directories, the helper-local `bin/` ownership boundary, root policy visibility, existing-file collision risk, and Git's nested-ignore behavior.
- Directional fit: Both options prevent the local binary from being added when their ignore rules apply. A helper-local `.gitignore` is more location-independent; root `.gitignore` remains more centralized and discoverable.
- Contract fit: Switching to a nested file would change the approved `installer-011-26-3-shellcheck-gitignore` contract and require new tests for existing helper-local ignore files. No such change is justified without the user's direction.
- Document ownership: Keep the current binding behavior in `DECISIONS.yml`; this record contains only the comparison rationale. No implementation or README changes are required for an unapproved alternative.
- Promotion target: None. Keep `installer-011-26-3-shellcheck-gitignore` unchanged.
- Promotion to DECISIONS.yml: none
- Evidence / references: Entry 0001 in this record; `DECISIONS.yml`; `install.sh`; `templates/language-tools.sh`; root `.gitignore`

### Entry 0003 (2026-11-23T00:45:09+09:00)
- Why now: The user selected the helper-local `.gitignore` alternative and requested that the implementation switch to it.
- Findings / trade-offs:
  - The active `installer-011-26-3-shellcheck-gitignore` contract currently writes the helper-relative binary directory into the project-root `.gitignore`; the implementation derives and escapes that path.
  - ShellCheck is installed under `<helper-directory>/bin/`, and `install.sh` supports both the default `.dev` directory and a custom helper directory.
  - A `.gitignore` next to the helper can use the fixed relative entry `bin/`, so it naturally follows any in-project helper location. If the helper is outside the project root, no project Git metadata needs updating.
  - The existing root `.gitignore` entry, README wording, and focused tests encode the old location and must be updated together. Existing user content in a helper-local `.gitignore` must be preserved.
- Focus areas: Replace only the ignore-file location and entry representation; retain local install/reuse gating, global fallback behavior, safe/idempotent updates, explicit errors, and ordering before AGENTS.md guidance.
- Explicit exclusions: No changes to ShellCheck release selection, helper deployment, automatic linting, PATH/profile behavior, or the project-root invocation convention.
- Current conclusion: For successful local install/reuse within the project, ensure `<helper-directory>/.gitignore` contains `bin/`. Create it if absent; otherwise preserve its contents and permissions while adding the entry only when missing. Fail explicitly on unsafe/unwritable files without rolling back the installed binary. Do not update ignore files on local setup failure, global fallback, or when the helper is outside the project root. Remove the now-redundant `.dev/bin/` entry from the repository root `.gitignore` and document the new behavior.
- Next validation target: Confirm this contract preserves user-owned helper-local ignore content, is idempotent for default and custom directories, leaves the root `.gitignore` untouched, and retains the existing no-change behavior for global fallback and failed setup before promotion.
- Promotion to DECISIONS.yml: pending discussion-validation
- Evidence / references: User approval in chat; `DECISIONS.yml` (`installer-011-26-3-shellcheck-gitignore`); Entries 0001-0002 in this record; `templates/language-tools.sh`; `tests/language-tools.test.sh`; `install.sh`; `README.md`; root `.gitignore`

### Entry 0004 (2026-11-23T00:45:09+09:00)
- Discussion-validation: PASS. The scan covered the approved ignore contract, default and custom helper deployment, helper-local binary placement, existing root and helper-local ignore ownership, affected documentation/tests, and local/global failure boundaries.
- Focus and direction: PASS. A fixed `bin/` entry beside the helper is more location-independent than deriving a root-relative path, while preserving the original goal of excluding only the generated local binary directory.
- Contract fit: PASS. Keep updates limited to successful local install/reuse; preserve safe/idempotent file handling and update before AGENTS.md. Global fallback, failed setup, and helper paths outside the project root remain unchanged.
- Omission check: If a parent rule already excludes the helper directory, Git may not read its nested `.gitignore`, but the binary is already excluded by that parent. Existing helper-local `.gitignore` content must still be preserved.
- Document ownership: Update only `installer-011-26-3-shellcheck-gitignore` as the binding contract. README.md describes the user-visible file location; this record keeps the comparison and rationale.
- Promotion target: Update `installer-011-26-3-shellcheck-gitignore` to require `<helper-directory>/.gitignore` with `bin/`, linked to this record; remove the now-redundant root `.dev/bin/` rule and update its tests/documentation during implementation.
- Promotion to DECISIONS.yml: ready -> `installer-011-26-3-shellcheck-gitignore`
- Evidence / references: Entry 0003 in this record; `DECISIONS.yml`; `install.sh`; `templates/language-tools.sh`; `tests/language-tools.test.sh`; `README.md`; root `.gitignore`
