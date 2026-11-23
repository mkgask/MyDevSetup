# Decision Record: dev-tools-016-shellcheck-helper-ignore-implementation

## Metadata
- Created At: 2026-11-23
- Scope: `installer-011-26-3-shellcheck-gitignore` の helper-local `.gitignore` 実装結果

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

### Entry 0001 (2026-11-23T00:45:09+09:00)
- Why now: `dev-tools-015-shellcheck-ignore-location` promoted the helper-local ignore approach, and its record reached the reviewability threshold before implementation closeout.
- Findings / trade-offs:
  - The active `installer-011-26-3-shellcheck-gitignore` contract now requires `<helper-directory>/.gitignore` to contain `bin/` after successful in-project local install/reuse.
  - Existing `.gitignore` content and permissions must be preserved; unsafe targets fail explicitly without rolling back the installed binary.
  - The project-root `.gitignore` entry from the prior approach is no longer needed.
- Focus areas: Update the helper, its focused tests, the root ignore file, and README wording while retaining global-fallback, failed-install, external-helper, and AGENTS.md ordering behavior.
- Explicit exclusions: No change to release selection, installer deployment, automatic linting, or PATH/profile behavior.
- Current conclusion: The helper now creates or updates its own `.gitignore` with `bin/`, and the repository root `.gitignore` no longer carries `.dev/bin/`. The focused and installer validations pass.
- Promotion to DECISIONS.yml: none; the binding contract was promoted in `dev-tools-015-shellcheck-ignore-location`
- Evidence / references: `DECISIONS.yml` (`installer-011-26-3-shellcheck-gitignore`); `records/dev-tools-015-shellcheck-ignore-location.md`; `templates/language-tools.sh`; `tests/language-tools.test.sh`; `tests/install.test.sh`; `README.md`; root `.gitignore`

### Entry 0002 (2026-11-23T00:45:09+09:00)
- Implementation-validation: PASS. The focused test initializes a Git repository and confirms `git check-ignore` excludes `.dev/bin/shellcheck` through `.dev/.gitignore`; custom helper paths use the same local `bin/` rule.
- Validation result: PASS — 14 language-tools tests, 18 installer tests, Bash syntax, ShellCheck at warning severity, `git diff --check`, decision YAML and links.
- Artifact alignment: README.md now describes the helper-local ignore file; the root `.gitignore` no longer has the old `.dev/bin/` rule. The decision remains linked to the approved discussion record `dev-tools-015`.
- Remaining non-binding risk: The new ignore behavior was exercised on Linux; the macOS ShellCheck release path remains mock-tested rather than live-tested.
- Evidence / references: Entry 0001 in this record; `DECISIONS.yml`; `tests/language-tools.test.sh`; `tests/install.test.sh`; `README.md`; root `.gitignore`
