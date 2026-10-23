# Decision Record: first-setup-005-bootstrap-distribution

## Metadata
- Created At: 2026-10-22
- Scope: Standalone bootstrap invocation versus per-project distribution

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to `DECISIONS.yml`.
- Keep each entry as short as the discussion allows.

## Entry List

### Entry 0001 (2026-10-22)
- Why now: The user questioned whether `first-setup.sh`, which is intended for one-time OS preparation rather than repeated project-local use, should remain in `templates/` and be copied into every project, or instead be invoked directly with `curl | bash` like `install.sh`.
- Findings / trade-offs:
  - `first-setup.sh` installs apt dependencies and the current user's HackGen fonts. Its active lifecycle decision places it after OS setup and before `dev-tools.sh`; it does not configure a target project.
  - `install.sh` currently copies it to `.dev/first-setup.sh`, adjusts its destination with the `dev-tools.sh` destination prompt, makes it executable, and unconditionally updates it. The current README does not document this helper.
  - `install.sh` runs the deployed `dev-tools.sh` helper before it exits. A standalone first-setup command therefore belongs before `install.sh` if its dependencies are prerequisites for tool installation.
  - `tests/install.test.sh` has deployment, custom-directory, executable-permission, overwrite, and no-auto-execution assertions for first-setup. `tests/first-setup.test.sh` independently verifies its behavior. Removing project deployment must update the installer tests and contracts while retaining focused tests for the standalone script.
  - `first-setup.sh` does not depend on its own path, so piping its source to Bash is technically compatible. A direct raw-GitHub command still requires `curl` and executes the current remote script; using `main` has the same mutable-source trust model as the existing `install.sh` command.
  - Active decisions `installer-011-22-first-setup-dependencies`, `installer-011-23-first-setup-deployment`, `installer-011-24-executable-helper-deployment`, `installer-011-25-hackgen-font-installation`, and `installer-012-3-helper-overwrite-exception` are implementation-approved. The prior deployment decision was promoted in `records/first-setup-002-installer-deployment.md`; the latest header examples in `records/first-setup-004-usage-examples.md` also assume `.dev/first-setup.sh`.
- Focus areas: Decide whether to retain the current `.dev` deployment or make first-setup a standalone bootstrap; if standalone, choose its source location and public URL, document its order relative to `install.sh`, and identify the deployment tests and decision contracts that must change. Keep the apt and font behavior unchanged.
- Explicit exclusions: No implementation or decision promotion before the user confirms a direction. Do not change the dependency set, HackGen behavior, `dev-tools.sh` deployment, or `install.sh`'s project-install purpose.
- Current conclusion: Preliminary recommendation is to move the script to the repository root as `first-setup.sh`, invoke it directly with a raw-GitHub `curl | bash` command, and remove it from `install.sh`'s project asset list. This better matches one-time host setup and avoids adding an unused helper to each project. The README should show first-setup before `install.sh`, because the latter invokes `dev-tools.sh`. Whether to pin the source URL to a release rather than `main` remains a choice; no direction has been promoted.
- Next validation target: Discussion-validation should verify the proposed location and run order against the active lifecycle, confirm no project-local use case is lost, account for the `curl` prerequisite and mutable remote-source risk, and name the exact decisions to update if the user approves.
- Promotion to DECISIONS.yml: pending user direction
- Evidence / references: `README.md`; `install.sh`; `templates/first-setup.sh`; `tests/install.test.sh`; `tests/first-setup.test.sh`; `DECISIONS.yml`; `records/first-setup-002-installer-deployment.md`; `records/first-setup-003-hackgen-font-installation.md`; `records/first-setup-004-usage-examples.md`

### Entry 0002 (2026-10-22)
- Discussion-validation: PASS for the standalone-bootstrap candidate. The scan covered the public README flow, installer execution order and asset machinery, both relevant test suites, all active first-setup/helper contracts, and the earlier distribution and font-installation records.
- Directional fit: A standalone bootstrap matches the one-time host-level responsibility better than a helper copied into a project. Running it before `install.sh` preserves the existing requirement to prepare dependencies before `dev-tools.sh`, which `install.sh` invokes automatically. The script has no dependency on its own on-disk path, so a streamed source is technically viable.
- Contract fit: The candidate retains manual execution, apt-get-only Linux/WSL support, apt-only sudo escalation, and user-local font installation; it does not add first-setup execution to `install.sh`. `curl | bash` requires curl to already exist and executes the remote script. Following the existing `main` URL convention is simplest, while a pinned release would provide more reproducibility. The whole script must continue to run as the ordinary user so fonts are not installed under root.
- Focus validation: Removing distribution is the substantive decision; moving the source to the repository root is the clearer public layout but is not technically required for a raw URL. If approved, the focused change includes the README order, first-setup source/test paths, install asset and special-case removal, installer test updates, and the deployment/executable/overwrite decision contracts. Apt and font behavior remain out of scope.
- Promotion targets if approved: Update `installer-011-22-first-setup-dependencies` and `installer-011-22-8-header-usage-examples` for the standalone path; replace `installer-011-23-first-setup-deployment`'s project-copy contract; remove first-setup from `installer-011-24-executable-helper-deployment` and `installer-012-3-helper-overwrite-exception`; align `installer-011-25-hackgen-font-installation` with the new source path.
- Current conclusion: The recommendation to stop copying first-setup into target projects is validated. No decision was promoted because the user asked for an assessment, not implementation approval; whether to move the source to the repository root and whether to use `main` or a pinned release remain for confirmation.
- Promotion to DECISIONS.yml: pending user direction
- Evidence / references: `README.md`; `install.sh`; `tests/install.test.sh`; `tests/first-setup.test.sh`; `DECISIONS.yml`; records `first-setup-002`, `first-setup-003`, and `first-setup-004`

### Entry 0003 (2026-10-23)
- Why now: The user approved implementing the standalone-bootstrap recommendation.
- User-confirmed direction: Move the script to the repository root as `first-setup.sh`, expose it through a direct raw-GitHub `curl | bash` command using the existing `main` branch convention, remove it from `install.sh` project deployment, and update documentation and tests.
- Scope boundary: Preserve apt package installation, user-local HackGen behavior, and existing error handling. Document and test the standalone invocation before `install.sh`; do not add first-setup execution to `install.sh`.
- Promotion to DECISIONS.yml: approved by user; promotion in progress
- Evidence / references: User confirmation on 2026-10-23; validated candidate in Entries 0001-0002

### Entry 0004 (2026-10-23)
- Promotion result: Updated the active first-setup source, lifecycle, header, deployment, executable-helper, HackGen-path, and overwrite contracts to describe a root-level standalone bootstrap that `install.sh` neither deploys nor executes.
- Decision shape: Removed obsolete destination and deployment-asset-loop sub-decisions; retained the manual-execution boundary and added the standalone raw-GitHub entrypoint contract.
- Status and linkage: Affected parent and sub-decisions are in `⚠️Discussion Approved` and link through the parents to this record.
- Promotion to DECISIONS.yml: promoted -> `installer-011-22-first-setup-dependencies`, `installer-011-22-3-first-setup-lifecycle`, `installer-011-22-8-header-usage-examples`, `installer-011-23-first-setup-deployment`, `installer-011-23-2-manual-execution-boundary`, `installer-011-23-4-standalone-bootstrap-entrypoint`, `installer-011-24-executable-helper-deployment`, `installer-011-25-hackgen-font-installation`, `installer-012-3-helper-overwrite-exception`
- Evidence / references: `DECISIONS.yml`; user approval on 2026-10-23

### Entry 0005 (2026-10-23)
- Implementation finding: Existing projects may already contain `.dev/first-setup.sh` from previous installs. Removing it from the asset list stops future copies and updates but does not remove those files.
- Current conclusion: Preserve existing project copies without modifying or deleting them. This avoids an unrequested destructive migration; users may continue to run an existing copy, while new installs use the standalone root script.
- Promotion to DECISIONS.yml: promoted -> `installer-011-23-5-existing-copy-preservation`
- Evidence / references: `install.sh` deployment flow; existing-copy assertions in `tests/install.test.sh`

### Entry 0006 (2026-10-23)
- Implementation result: Moved the script to repository-root `first-setup.sh`, updated its header with direct run/help commands, removed its project asset and helper permission/overwrite special cases from `install.sh`, updated its focused-test path, and documented the command before `install.sh` in README. Existing `.dev/first-setup.sh` files are left untouched.
- Validation result: Bash syntax check passed; `tests/first-setup.test.sh` passed 2 tests; `tests/install.test.sh` passed 18 tests; piped stdin help execution passed; header/README order checks, YAML parsing with 88 unique decision IDs, decision status/link checks, and `git diff --check` passed.
- Artifact alignment: `DECISIONS.yml` records the standalone URL, manual-before-install lifecycle, no project deployment, and legacy-copy preservation. The prior header and font behavior remains in the root script.
- Implementation-validation: PASS — local script behavior and installer deployment boundaries match the approved contract. The raw-GitHub command itself cannot resolve this uncommitted script until the branch is published; its local stdin equivalent passed.
- Promotion to DECISIONS.yml: implementation approved -> `installer-011-22-first-setup-dependencies`, `installer-011-22-3-first-setup-lifecycle`, `installer-011-22-8-header-usage-examples`, `installer-011-23-first-setup-deployment`, `installer-011-23-2-manual-execution-boundary`, `installer-011-23-4-standalone-bootstrap-entrypoint`, `installer-011-23-5-existing-copy-preservation`, `installer-011-24-executable-helper-deployment`, `installer-011-25-hackgen-font-installation`, `installer-012-3-helper-overwrite-exception`
- Evidence / references: `bash -n install.sh first-setup.sh tests/first-setup.test.sh tests/install.test.sh`; `bash tests/first-setup.test.sh`; `bash tests/install.test.sh`; `bash -s -- --help < first-setup.sh`; `DECISIONS.yml`; `README.md`
