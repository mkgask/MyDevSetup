# Decision Record: dev-tools-004-proto-source-dependencies

## Metadata
- Created At: 2026-08-03
- Scope: Ubuntu/Debian system dependency recognition for proto Ruby source builds

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to DECISIONS.yml.
- Keep each entry as short as the discussion allows.
- Evidence and detailed promotion metadata are optional; omit them when the entry stays clear without them.

## Entry List

### Entry 0001 (2026-08-03T00:00:00Z)
- Why now: proto Ruby の source build は許可してよいが、`first-setup.sh` で依存を導入した後も `libreadline6-dev`、`libncurses5-dev`、`libgdbm6` が `is not installed` と判定され、proto が非rootで `apt update` を実行して失敗した。
- Findings / trade-offs: Ubuntu 26.04 の apt はそれぞれ `libreadline-dev`、`libncurses-dev`、`libgdbm6t64` を選択している。proto 0.59.0 は `apt list --installed` のパッケージ名を完全一致で比較するため、代替パッケージを旧名の導入済みとして認識しない。Ruby plugin の Apt dependency list には上記旧名に加えて `bison` があり、現行 `first-setup.sh` は `bison` を含んでいない。proto には system dependency を無効化する install option はないが、`PROTO_BUILD_EXCLUDE_PACKAGES` で依存名を一時的に除外できる。
- Focus areas: `templates/first-setup.sh` の Ruby build dependency list、`templates/dev-tools.sh` の proto Ruby command と alias detection、実行時だけの `PROTO_BUILD_EXCLUDE_PACKAGES`、planned command と focused mock test を対象にする。
- Explicit exclusions: proto 本体・Ruby plugin の修正、Ubuntu package manager の永続設定、`sudo proto` の導入、source build から別routeへの暗黙 fallback、prebuilt route、Ruby version の固定は対象外とする。
- Current conclusion: Ruby は proto の候補へ戻し、`proto install ruby latest --build --yes` で source build を実行する。first-setup は `bison` を追加する。代替パッケージが `dpkg-query` で導入済みと確認できた場合だけ、対応する proto 旧依存名を `PROTO_BUILD_EXCLUDE_PACKAGES` に追加し、proto の完全一致判定による誤検出と不要な `apt update` を回避する。代替が確認できない旧名は除外せず、実際の不足として proto に扱わせる。
- Promotion to DECISIONS.yml: pending
- Evidence / references: `proto 0.59.0` help, `moonrepo/proto` `crates/core/src/flow/build.rs`, `moonrepo/proto` `crates/core/src/settings/settings.rs`, `moonrepo/plugins` `tools/ruby/src/proto.rs`, `proto-ruby-install.log`

### Entry 0002 (2026-08-03T00:00:01Z)
- Why now: Discussion-validation is required before changing the active route contract.
- Findings / trade-offs: The bounded scan covers the first-setup package list, the proto install dispatch and dry-run command, the existing Ruby route filtering, the exact Ubuntu log, proto's apt package parser, and the official exclusion environment variable. The focus follows the failure boundary: package identity resolution and the command that triggers proto's dependency workflow. Keeping alias exclusions conditional preserves failure visibility when a replacement is not actually installed; keeping them process-local avoids persistent proto configuration drift.
- Current conclusion: PASS — the candidate direction serves the user's source-build objective, preserves the existing no-helper-sudo and failure propagation boundaries, adds the missing `bison` dependency, restores Ruby proto selection, and avoids masking genuinely missing packages. The active source-only Ruby plugin fact remains explicit, while route availability is no longer suppressed.
- Promotion to DECISIONS.yml: installer-011-2-2-proto-ruby-source-only (updated to allow its source-build route), installer-011-2-3-proto-apt-aliases (new conditional alias handling contract)
- Evidence / references: `proto install --help` has no dependency-skip option; proto source uses exact installed-name lookup and supports `PROTO_BUILD_EXCLUDE_PACKAGES`.

### Entry 0003 (2026-08-03T00:00:02Z)
- Implementation result: `proto_tool_for_tool` now exposes Python and Ruby. Python uses `--no-build`; Ruby uses explicit `--build`. Ruby source-build installs conditionally pass the process-local `PROTO_BUILD_EXCLUDE_PACKAGES` value generated from installed Ubuntu replacements, while planned commands show the same environment assignment.
- Dependency result: `templates/first-setup.sh` now includes `bison`; existing package names remain compatible with apt resolution, and the helper recognizes `libreadline-dev`, `libncurses-dev`, and `libgdbm6t64` as replacements for the names used by the proto Ruby plugin.
- Test result: focused `tests/dev-tools.test.sh` passes 16 tests, including Ruby route restoration, source-build command selection, all-installed alias exclusions, and conditional exclusion when only one replacement is present. `tests/first-setup.test.sh` passes 1 test and `tests/install.test.sh` passes 15 tests.
- Environment result: the current machine reports all three replacement packages as `install ok installed`, so the helper produces `libreadline6-dev,libncurses5-dev,libgdbm6`. `bison` is currently not installed because first-setup was run before this change; rerunning first-setup is required before a complete live Ruby build.
- Promotion to DECISIONS.yml: none

### Entry 0004 (2026-08-03T00:00:03Z)
- Executable validation: PASS — `bash tests/dev-tools.test.sh` passes 16 tests, `bash tests/first-setup.test.sh` passes 1 test, and `bash tests/install.test.sh` passes 15 tests. The focused suite verifies Ruby route restoration, explicit `--build`, conditional alias exclusion, and matching dry-run output.
- Static and artifact validation: PASS — Bash syntax, YAML parse with 59 unique decision IDs, editor diagnostics, and `git diff --check` all pass. The current machine's route probe lists `proto` for Ruby and its planned command contains the installed replacement aliases and `--build`.
- Alignment: `templates/first-setup.sh`, `templates/dev-tools.sh`, tests, `DECISIONS.yml`, and this record agree that Ruby source build is allowed, `bison` is a first-setup dependency, and replacement aliases are excluded only after `dpkg-query` confirms them.
- Risk boundary: a complete live Ruby build after installing the newly added `bison` was not run because the current machine still lacks `bison` and running first-setup requires privileged package installation. The remaining user action is to rerun first-setup, after which proto should no longer attempt `apt update` for the three already-installed replacement packages. No implementation blocker remains.
- Closeout result: implementation-validation confirms executable results, artifact and terminology alignment, decision-record hygiene, and the remaining live-validation boundary. `installer-011-2-2-proto-ruby-source-only` and `installer-011-2-3-proto-apt-aliases` are implementation approved.
