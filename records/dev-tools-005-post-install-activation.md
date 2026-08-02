# Decision Record: dev-tools-005-post-install-activation

## Metadata
- Created At: 2026-08-03
- Scope: Post-install activation and shell profile setup for manager-installed tools

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to DECISIONS.yml.
- Evidence and detailed promotion metadata are optional; omit them when the entry stays clear without them.

## Entry List

### Entry 0001 (2026-08-03T00:00:10Z)
- Why now: `install` の summary では proto/mise 経由のツールが `installed` になる一方、新しい shell から `status` を実行すると Ruby、rg、rtk、uv が `unavailable` になった。現在の helper は install 後に現在プロセスの PATH だけを調整し、shell profile や manager の active version を変更しないため、導入直後に必要な作業が次の prompt に埋もれている。
- Findings / trade-offs: proto Ruby は実体が `~/.proto/tools/ruby/4.0.6/bin/ruby` にあり、shim は version pin がないと失敗する。mise の rg/rtk/uv は `mise ls --installed --json` で installed だが active false で、`mise activate bash` だけでは version 未選択の shim が失敗する。proto は `proto pin <tool> <version> --to user`、mise は `mise use --global <tool>@<version>` で active selection を永続化できる。現在の `~/.bashrc` には既存の mise activation があるが、proto activation はなく、追記は idempotent に行う必要がある。
- Focus areas: `templates/dev-tools.sh` の install 成功直後の hook、proto/mise の exact installed version lookup、現在 shell の activation、`~/.bashrc` への重複しない追記、post-install 状態の表示、mock test と profile fixture を対象にする。
- Explicit exclusions: 既存ツールの再設定、status/init/dry-run での profile・manager変更、system/brew/nix/asdf/official/uv-tool route の一般的な shell 設定、proto/mise manager 本体の導入、プロジェクト初期化、既存 profile の他行の書き換え、`--global` route scope の変更は対象外とする。
- Current conclusion: `install` の今回の実行で route install と command verification に成功した対象だけ、proto route では exact version を user config へ pin して current shell に proto activation を適用し、mise route では exact version を global config へ use して current shell に mise activation を適用する。対応する `eval "$(proto activate bash)"` または `eval "$(mise activate bash)"` を `DEV_TOOLS_SHELL_PROFILE`（既定 `~/.bashrc`）へ一度だけ追記する。post-install setup が失敗した場合は導入済みバイナリを削除せず、その対象を setup failure として表示し、後続対象を継続する。各処理は次の route prompt の前に明示的な info/success log を出す。
- Promotion to DECISIONS.yml: pending
- Evidence / references: `DECISIONS.yml` の installer-011-4 / installer-011-11 / installer-011-20、`~/.bashrc`、`proto activate bash --export`、`mise activate bash`、`proto pin --help`、`mise use --help`、`mise ls --installed --json`

### Entry 0002 (2026-08-03T00:00:11Z)
- Why now: Discussion-validation is required before relaxing the existing no-persistent-activation contract.
- Findings / trade-offs: The bounded scan covers install dispatch and verification order, route-specific PATH refresh, current status semantics, existing profile contents, manager activation commands, global install candidate restrictions, and test fixture boundaries. The requested persistence is limited to successful proto/mise installs from this invocation, so existing tools and non-install modes remain untouched. Idempotent profile writes avoid duplicate activation lines, while failed setup remains visible without rolling back the installed binary.
- Current conclusion: PASS — the candidate direction directly addresses the user's post-install usability problem, preserves dry-run/status/init read-only behavior and `--global` route restrictions, and makes persistent side effects explicit and immediately visible. The previous process-only decision must be narrowed to an exception for successful normal-install proto/mise routes.
- Promotion to DECISIONS.yml: installer-011-4 (clarify manager activation is separate from CLI/project initialization), installer-011-11 (replace blanket process-only rule), installer-011-11-1-post-install-manager-activation (new detailed contract)
- Evidence / references: direct binary version checks succeeded for Ruby 4.0.6, ripgrep 15.2.0, rtk 0.44.1, and uv 0.12.1; shim checks failed until manager activation/version selection was configured.

### Entry 0003 (2026-08-03T00:00:12Z)
- Why now: Gate A step 2（discussion-validation）として、候補方向を元の要求、既存 decision contract、global install の境界、非変更モードへ照合した。
- Findings / trade-offs: broad scan は `templates/dev-tools.sh` の install dispatch・route-specific PATH refresh・verification order、`tests/dev-tools.test.sh` の mock boundary、`~/.bashrc` の既存行、proto/mise の activation と version-selection command、`installer-011-4/11/14/20/21` を対象にしており、主な omission risk を確認できている。`--global` は既存契約が導入先スコープに限定し shell/manager 永続化を禁止しているため、今回の例外を通常 install に限定する。post-install setup failure は導入済み事実を隠さず、既存の個別失敗・後続継続・最終非0契約へ接続する。
- Current conclusion: PASS — 成功した通常 `install` の今回の新規 proto/mise route だけに、manager version selection、current-process activation、idempotent profile append を適用する方向は元の「新しい shell でも使える」要求に適合する。既存ツール、skip、route install failure、setup failure 後の他対象、`--global`、`status`、`init`、`install --dry-run` には persistent side effect を追加しない。post-install の結果は次の route prompt より前に表示する。
- Next validation target: `DECISIONS.yml` に通常 install の例外、proto の user pin と activation、mise の global use と activation、profile の exact-line idempotence、setup failure の結果/終了status、`--global` と非install mode の除外を明示し、implementation ではこれらを mock test と fresh-shell 相当の検証で確認する。
- Promotion to DECISIONS.yml: ready -> `installer-011-4-third-party-cli-scope`, `installer-011-11-process-scoped-manager-activation`, `installer-011-11-1-post-install-manager-activation`
- Evidence / references: `DECISIONS.yml` の installer-011-14/20/21、`templates/dev-tools.sh`、`tests/dev-tools.test.sh`、`proto pin --help`、`mise use --help`、proto/mise の isolated activation checks

### Entry 0004 (2026-08-03T00:00:13Z)
- Implementation result: `templates/dev-tools.sh` に成功した通常 install の route 後 hook を追加した。proto は user pin と current-process activation、mise は global version selection・PATH refresh・current-process activation を行い、対応する Bash activation 行を `DEV_TOOLS_SHELL_PROFILE`（既定 `$HOME/.bashrc`）へ exact-line で冪等追記する。hook は次の route prompt 前に完了し、success/setup failure を表示する。setup failure は導入済み binary を残したまま failed result として記録し、後続対象を継続する。
- Boundary result: 既存ツール、skip、route install failure、`--global`、`status`、`init`、`install --dry-run` では profile・manager state を変更しない。README にも新しい install behavior と非変更モードを追記した。
- Test result: `tests/dev-tools.test.sh` は 20 tests passed。proto/mise の mock activation、profile idempotence、prompt order、setup failure、existing/status/init/global/dry-run boundary を検証した。
- Promotion to DECISIONS.yml: implementation validation pending
- Evidence / references: `templates/dev-tools.sh` の `append_shell_profile_line`、`run_manager_shell_activation`、`post_install_setup`、`process_install_tool`、`README.md`、`tests/dev-tools.test.sh`

### Entry 0005 (2026-08-03T00:00:14Z)
- Implementation-validation: PASS — `bash tests/dev-tools.test.sh` は20件、`bash tests/first-setup.test.sh` は1件、`bash tests/install.test.sh` は15件すべて通過した。変更対象の Bash syntax、editor diagnostics、PyYAML parse・decision ID uniqueness、`git diff --check` も通過した。
- Artifact alignment: `DECISIONS.yml`、`templates/dev-tools.sh`、`tests/dev-tools.test.sh`、`README.md`、この record は、通常 install の新規 proto/mise 成功時だけ manager activation と profile append を行い、非対象モードと境界条件では変更しない契約で一致している。post-install の成功表示は次の prompt より前に出力される。
- Risk boundary: 実機の proto Ruby build や mise install はこの変更では再実行せず、外部 manager の副作用は mock test で検証した。実環境での privileged install と既存 profile への実書込みは未実施だが、profile path override、manager command order、fresh-process相当の helper subprocess、failure propagation は確認済みである。
- Promotion to DECISIONS.yml: `installer-011-4-third-party-cli-scope`、`installer-011-11-process-scoped-manager-activation`、`installer-011-11-1-post-install-manager-activation` を `✅️Implementation Approved` へ更新した。
- Closeout result: implementation-validation confirms executable results, artifact and terminology alignment, decision-record hygiene, and the explicit live-install boundary. No implementation blocker remains.
