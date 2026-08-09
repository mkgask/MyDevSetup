# Decision Record: installer-002-executable-helper-assets

## Metadata
- Created At: 2026-08-09
- Scope: Executable permissions for installed dev-tools and first-setup helpers

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to DECISIONS.yml.
- Keep each entry as short as the discussion allows.

## Entry List

### Entry 0001 (2026-08-09)
- Why now: `install.sh` currently copies all deployment assets and applies `chmod 0644`. This leaves the installed `dev-tools.sh` and `first-setup.sh` non-executable even though both are shell scripts intended for direct manual use after installation.
- Findings / trade-offs: The controlling path is `install_template_asset` in `install.sh`. It also returns early when content is already identical, so an existing non-executable helper would remain unchanged unless permission normalization runs on that path too. `run_dev_tools_helper` currently invokes the helper through `bash`, and `first-setup.sh` is intentionally not auto-run; making both files executable adds direct-execution capability without changing invocation order or automation boundaries. Other assets must remain regular `0644` files.
- Focus areas: Apply `chmod +x` to the deployed `templates/dev-tools.sh` and `templates/first-setup.sh` on both new-copy and content-already-current paths; keep AGENTS.md and PRINCIPLES.md at `0644`; test default and selected helper destinations, including stale or already-current files.
- Explicit exclusions: Do not auto-run `first-setup.sh`, change shell profiles or PATH, change DODKit/helper ordering, alter source template modes, or make documentation assets executable.
- Current conclusion: Use the existing asset classification in `install_template_asset` to normalize helper permissions after a successful copy and after an identical-content early return. Add a focused installer assertion for both installed scripts being executable while regular documentation assets remain non-executable.
- Promotion to DECISIONS.yml: pending
- Evidence / references: `install.sh` (`install_template_asset`, `DEPLOYMENT_ASSET_SPECS`); `tests/install.test.sh`; `DECISIONS.yml` `installer-011-9-helper-destination` and `installer-011-23-first-setup-deployment`; user request

### Entry 0002 (2026-08-09)
- Discussion-validation: The bounded scan covered the shared asset installer, default and user-selected destinations, overwrite/no-overwrite paths, same-content early return, helper invocation, manual first-setup boundaries, and existing installer tests. The narrowed focus is justified because mode normalization belongs to the shared copy function and does not require changes to script behavior or orchestration.
- Directional fit: PASS — making only the two shell helper assets executable supports direct post-install use while preserving the existing DODKit-first order, bash-based helper invocation, non-automatic first-setup behavior, and documentation asset permissions.
- Contract fit: The candidate preserves symlink refusal, overwrite policy for non-helper assets, content comparison, selected destination handling, and no shell-profile/PATH changes. The only new binding is explicit executable permission for both helper paths, including already-current files.
- Promotion targets: Add `installer-011-24-executable-helper-deployment` with `chmod +x` for deployed `dev-tools.sh` and `first-setup.sh`, `0644` for other assets, and focused mode assertions in `tests/install.test.sh`.
- Validation result: PASS — no unresolved scope ambiguity remains.
- Promotion to DECISIONS.yml: ready -> `installer-011-24-executable-helper-deployment`

### Entry 0003 (2026-08-09)
- Implementation result: `install.sh` にアセット種別ごとの permission normalization を追加し、`dev-tools.sh` と `first-setup.sh` は新規コピー時と同一内容の早期完了時の両方で `chmod +x` を適用する。AGENTS.md と PRINCIPLES.md は `0644` とし、`chmod` を必須コマンド検証へ追加した。
- Test result: `tests/install.test.sh` に新規配置、既存内容の再インストール、選択配置先、通常ドキュメントアセットの mode を検証するケースを追加した。
- Scope boundary: first-setup の自動実行、helper/DODKitの順序、PATH・shell profile、source template の mode は変更していない。

### Entry 0004 (2026-08-09)
- Implementation-validation: installer suite 18件、helper suite 20件、first-setup suite 1件、Bash syntax、editor diagnostics、YAML parse、decision ID uniqueness（65件）、`git diff --check` が PASS した。
- Artifact alignment: `installer-011-24-executable-helper-deployment` の両 helper `chmod +x`、通常 asset `0644`、同一内容 early return の正規化、非自動実行の境界が `install.sh`、tests、record に揃っている。link は本 record を指している。
- Status result: `installer-011-24-executable-helper-deployment` を `✅️Implementation Approved` へ更新する。closeout を阻む問題はない。
- Remaining risk: ShellCheck は環境に存在しないため実行していない。実際のネットワーク経由アセット取得は mock fixture の範囲で検証している。

### Entry 0005 (2026-08-09)
- Post-validation correction: `mktemp` の `0600` ファイルに `chmod +x` だけを適用すると配置先が `0711` になるため、helper の permission normalization を `chmod 0755` に明示化した。これにより直接実行に必要な所有者・group・other の読み取りと実行を安定して満たす。
- Test refinement: default destination、selected destination、同一内容 reinstall で helper mode が `0755` になることを focused installer test が検証する。
- Contract impact: decision の executable helper、通常 asset `0644`、非自動実行、処理順序の契約は維持される。`0755` は `chmod +x` の意図を一貫して実現する実装上の具体化である。

### Entry 0006 (2026-08-09)
- New discussion trigger: 数値 mode の `0755`／`0644` は rw permission まで決め打ちするため、ユーザー要望に対して過剰である。今回必要なのは helper の実行ビット追加だけで、既存の rw permission は変更しないこと。
- Bounded scan: 影響範囲は `install.sh` の asset permission normalization、installer tests の mode assertion、`installer-011-24-executable-helper-deployment` の decision contract と本 record に限定される。DODKit/helper の順序、first-setup の自動実行、symlink・overwrite、他 asset の配布内容はこの修正の対象外である。
- Focus and candidate: helper の処理を `chmod +x` に戻し、通常 asset への `chmod 0644` を削除して既存 mode を保持する。tests は数値 mode ではなく、独自の rw mode が install 後も保たれ、helper に実行ビットだけが追加されることを検証する。
- Disconfirming check: read/write bits を意図的に異なる mode にした配置先へ再インストールし、`stat` で rw bits の保持と x bit の追加を確認する。新規コピー時の temporary file mode に依存した読み取り権限を期待しない。
- Current conclusion: `chmod +x` only を binding rule とし、`0755`／`0644` の固定を decision、実装、tests から取り除く。discussion-validation は rw preservation、documentation asset の mode 非変更、既存の処理境界が維持されることを確認する。
- Promotion to DECISIONS.yml: pending -> update `installer-011-24-executable-helper-deployment`

### Entry 0007 (2026-08-09)
- Discussion-validation: PASS。bounded scan は permission normalization、default/selected destination、same-content reinstall、通常 asset の既存 mode、既存の処理順序と自動実行境界をカバーしており、`chmod +x` only への narrowing は十分に根拠付けられる。
- Contract fit: helper の直接実行可能化は維持し、rw permission の変更、通常 asset への mode 強制、DODKit/helper の順序変更、first-setup の自動実行、PATH・shell profile の変更は行わない。新たな独立 decision は不要。
- Promotion target: `installer-011-24-executable-helper-deployment` の decision を、helper の新規コピー時と同一内容 early return 時に `chmod +x` のみ適用し、他の permission bits を変更しない契約へ更新する。status は implementation 後も `✅️Implementation Approved` を維持する。

### Entry 0008 (2026-08-09)
- Implementation result: `set_asset_permissions()` は helper source に対してのみ `chmod +x` を実行し、AGENTS.md と PRINCIPLES.md を含むその他の asset には chmod を行わない。新規コピーと同一内容 early return の両経路で helper の x bit 追加を維持する。
- Test result: installer test は default/selected destination と same-content reinstall を対象に、helper が executable になり、helper と documentation の既存 rw bits が保持されることを検証する。固定 `0755`／`0644` の mode assertion は削除した。
- Implementation-validation: installer suite 18件、dev-tools suite 20件、first-setup suite 1件、Bash syntax、editor diagnostics、YAML parse、decision ID uniqueness（65件）、`git diff --check` が PASS した。
- Artifact alignment: `installer-011-24-executable-helper-deployment` は `chmod +x` only、既存 rw permission 非変更、非自動実行、処理順序維持を明示し、実装と tests が一致している。closeout を阻む問題はない。
- Remaining risk: ShellCheck は環境に存在しないため実行していない。実際のネットワーク経由アセット取得は引き続き mock fixture の範囲で検証している。
