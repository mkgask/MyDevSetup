# Decision Record: dev-tools-014-shellcheck-gitignore

## Metadata
- Created At: 2026-11-23
- Scope: `language-tools.sh shell` が導入するプロジェクト内 ShellCheck binary の Git ignore

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

### Entry 0001 (2026-11-23T00:01:13+09:00)
- Why now: `language-tools.sh shell` installs ShellCheck into `.dev/bin/` by default, but the root `.gitignore` does not currently exclude that generated binary directory, so it could be committed with project changes.
- Broad-scan findings:
  - `installer-011-26-1-shellcheck-installation` installs or reuses `bin/shellcheck` beside the helper; `.dev` is the default helper directory, while the installer also permits a custom directory.
  - The helper's global fallback has no project-local binary. Local install/reuse succeeds before ShellCheck guidance is updated in `AGENTS.md`.
  - `README.md` directs users to run project setup from the project root. `tests/language-tools.test.sh` uses per-fixture project roots and currently verifies the local binary and AGENTS guidance, but not `.gitignore`.
  - The repository root `.gitignore` excludes logs and VS Code files, but not `.dev/bin/`. No existing helper manages this ignore entry.
  - `install.sh` deploys the helper without running it, so the ignore update belongs to the explicit language-tool setup operation, not deployment.
- Focus areas:
  - After a successful local install or reuse, ensure the project-root `.gitignore` excludes the local binary directory; the default entry is `.dev/bin/`.
  - Keep the operation idempotent, preserve existing ignore content, and avoid changing `.gitignore` when setup fails or uses the global fallback.
  - Align the root ignore rule, user documentation, and focused tests with the implementation.
- Explicit exclusions: No changes to ShellCheck version/platform selection, global package-manager fallback, helper deployment, automatic linting, PATH/profile behavior, or unrelated ignore rules.
- Candidate direction:
  - For a local install/reuse, derive the binary directory relative to the project root from the helper location and ensure that exact directory entry appears once in root `.gitignore` (normally `.dev/bin/`).
  - Create `.gitignore` with the entry if it is absent; otherwise append only when the entry is missing, preserving existing contents. Fail explicitly if the file cannot be safely updated; do not roll back an already installed binary.
  - Update `.gitignore` before the AGENTS.md guidance step. Leave it untouched for global fallback or failed local setup.
- Current conclusion: Explicitly ignoring the local binary directory is the smallest change that prevents accidental commits while preserving the existing local/global installation boundary. The default helper path must produce the requested `.dev/bin/` entry; custom in-project helper paths should protect their actual local binary directory too.
- Next validation target: Confirm that the entry is updated only after local install/reuse, remains unique on repeated setup, preserves existing `.gitignore` content, and reports unsafe update failures without changing AGENTS.md. Confirm that global fallback and failed installation leave `.gitignore` unchanged, and that the proposed rule does not alter existing decision boundaries.
- Promotion to DECISIONS.yml: pending discussion-validation
- Evidence / references: `DECISIONS.yml` (`installer-011-26-project-language-tool-setup`, `installer-011-26-1-shellcheck-installation`, `installer-011-26-2-shellcheck-agents-guidance`); `records/dev-tools-012-shellcheck-project-tool-setup.md`; `records/dev-tools-013-shellcheck-agents-guidance.md`; `templates/language-tools.sh`; `tests/language-tools.test.sh`; `install.sh`; `README.md`; root `.gitignore`

### Entry 0002 (2026-11-23T00:01:13+09:00)
- Discussion-validation: PASS. The broad scan covered the active language-tool and ShellCheck contracts, helper deployment/default and custom paths, local reuse versus global fallback, project-root invocation guidance, root `.gitignore`, focused tests, and current documentation.
- Focus and direction: PASS. Updating only the local binary directory after local install/reuse addresses accidental commits without changing the global fallback, deployment, or automatic-lint boundaries. Deriving an in-project custom helper path preserves the existing helper-local installation contract; the default remains `.dev/bin/`.
- Contract fit: PASS. The update is gated by successful local setup, leaves failed installs and global fallback untouched, and reports `.gitignore` update failures explicitly. An installed binary is not rolled back if metadata update fails, consistent with the existing AGENTS.md update behavior.
- Document ownership: PASS. The ignore behavior belongs in a dedicated ShellCheck sub-decision. README.md will describe the user-visible setup effect, while the record retains rationale and validation history.
- Promotion target: Add `installer-011-26-3-shellcheck-gitignore` under `installer-011-26-project-language-tool-setup`; keep the existing installation and AGENTS guidance contracts unchanged.
- Promotion to DECISIONS.yml: ready -> `installer-011-26-3-shellcheck-gitignore`
- Evidence / references: `DECISIONS.yml`; Entry 0001 in this record; `templates/language-tools.sh`; `tests/language-tools.test.sh`; `README.md`; root `.gitignore`

### Entry 0003 (2026-11-23T00:01:13+09:00)
- Implementation result: Successful local ShellCheck install/reuse now adds the helper-relative binary directory to the project-root `.gitignore` before updating AGENTS.md. Existing ignore content and permissions are preserved, missing files are created, and unsafe targets fail explicitly without rolling back the binary. Global fallback, failed local installs, and helper paths outside the project root do not change `.gitignore`. The repository ignore file now excludes `.dev/bin/`, and README.md documents the behavior.
- Validation result: PASS — 13 focused language-tools tests, 18 installer regressions, Bash syntax checks, ShellCheck at warning severity, `git diff --check`, `git check-ignore -v .dev/bin/shellcheck`, and YAML parsing with 97 unique decision IDs and 46 valid links.
- Artifact alignment: Tests cover creation, preserving existing contents without a final newline, idempotent reuse, custom helper paths, global fallback, failed installation, and unsafe symlink handling before AGENTS.md is updated.
- Remaining non-binding risk: The new `.gitignore` update path was exercised on Linux; the macOS ShellCheck asset route remains mock-tested rather than live-tested.
- Evidence / references: `DECISIONS.yml` (`installer-011-26-3-shellcheck-gitignore`); `templates/language-tools.sh`; `tests/language-tools.test.sh`; `tests/install.test.sh`; `README.md`; `.gitignore`
