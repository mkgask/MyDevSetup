# Decision Record: dev-tools-003-proto-prebuilt-installation

## Metadata
- Created At: 2026-08-02
- Scope: Prebuilt binary selection for the proto installation route

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to DECISIONS.yml.
- Keep each entry as short as the discussion allows.

## Entry List

### Entry 0001 (2026-08-02T00:00:50Z)
- Why now: `templates/dev-tools.sh` で proto route の Ruby 導入を選ぶと、proto 0.59.0 が `apt update` を current user で実行する source-build workflow に入り、first-setup.sh で依存を導入済みでも apt lock の権限で失敗した。ユーザーは proto が Ruby の prebuilt binary を扱えるか、現在の helper が source build を強制しているかを確認した。
- Broad-scan findings: `install_with_proto` は `proto install <tool> latest --yes` を実行しており、`--build` は指定していないが、prebuilt を要求する `--no-build` も指定していない。インストール済み proto 0.59.0 の help は `--build` を source build、`--no-build` を prebuilt download と明記している。Ruby の実行ログは `ruby-build` と apt system dependency の source workflow を示している。proto の `bin` による導入後PATH検証と、current user の proto環境を維持する既存境界は変更不要である。
- Focus areas: proto route の実行引数、mock test の command contract、既存の process-local PATH と非sudo manager境界を確認する。Rubyだけの例外ではなく proto route 全体の Python/Ruby に prebuilt 要求を適用するかを決める。
- Explicit exclusions: proto の導入、Ruby version の固定、system routeや他manager routeの変更、sudo proto、source-build fallback、shell/PATH/manager設定の永続変更、third-party live install のテスト、install.sh の配布契約変更は対象外とする。
- Current conclusion: proto route は `proto install <tool> latest --no-build --yes` を実行し、prebuilt binary を明示的に要求する。prebuilt が利用できない場合は proto の失敗をそのまま結果へ反映し、helper が sudo や source buildへ暗黙に切り替えない。これにより first-setup は source build の前提ではなく、ほかの開発ツールの依存準備にも使える。
- Next validation target: discussion-validation は、`--no-build` が proto の公式CLI契約に基づくこと、Python/Rubyのproto routeへ一貫して適用できること、既存のPATH・失敗継続・manager非永続化・dry-run command表示契約と整合することを確認する。
- Promotion to DECISIONS.yml: pending

### Entry 0002 (2026-08-02T00:00:51Z)
- Discussion-validation: broad scan は `templates/dev-tools.sh` の proto capability probe、proto install dispatch、導入後の `proto bin` PATH更新、dry-run planned command生成、focused mock test、`DECISIONS.yml` の installation backend・command contract・failure contract、および実測した proto 0.59.0 help/log を確認している。binary/source selection とその失敗境界に必要な landscape を覆っている。
- Focus validation: `install_with_proto` の引数と同じ route の planned command、Python/Ruby 共通 mapping、既存の current-process PATH 更新に絞ることは、実際の source-build失敗を制御する最小の境界から導かれる。system route、first-setup、manager導入、永続設定を除外しても、今回の問題を取りこぼさない。
- Directional fit: `--no-build` の明示により、proto route を source build に暗黙依存しない prebuilt route として利用でき、ユーザーが確認した proto の binary 対応を helper の導入コマンドへ反映できる。
- Contract fit: `latest`、proto自身の失敗を非0として集計する既存 failure contract、後続ツール継続、`proto bin` による process-local PATH 更新、sudoをmanagerへ付けない境界、dry-runで実行しない境界を維持する。prebuilt不存在時に sourceへ切り替えないため、sudo aptの隠れた副作用も増えない。
- Hidden bindings: proto route の実行コマンドと planned command の双方へ `--no-build` を含め、Python/Rubyの両方に同じ binary preference を適用する必要がある。これは `installer-011-2` の sub-decision として明示し、新しい独立 top-level decision は追加しない。
- Validation result: PASS — candidate direction は proto CLIの実測契約、元の要求、既存の不変条件、非ゴール、失敗時の境界に適合する。
- Promotion targets: `installer-011-2-installation-backends` に proto route の `--no-build`、source fallbackなし、Python/Ruby共通適用、planned command整合の sub-decision を追加する。

### Entry 0003 (2026-08-02T00:00:52Z)
- Promotion result: `installer-011-2-1-proto-prebuilt` を `installer-011-2-installation-backends` の sub-decision として追加し、proto route の Python/Ruby共通 `--no-build`、source fallbackなし、sudo protoなし、dry-run command整合を active contract にした。
- Status result: 新しい sub-decision は `⚠️Discussion Approved` とし、実装前の Gate A を完了した。親 decision と他の route 契約は変更していない。
- Implementation boundary: `templates/dev-tools.sh` の proto install command、planned command、focused test のみを更新対象とし、proto本体・first-setup・install.sh・他routeは変更しない。

### Entry 0004 (2026-08-02T00:00:53Z)
- Implementation result: `install_with_proto` と `planned_install_command_for_route` の Python/Ruby proto command に `--no-build --yes` を追加した。既存の `proto bin` による current-process PATH 更新、protoをsudoで実行しない境界、他routeの挙動は維持した。
- Test result: `tests/dev-tools.test.sh` の実行 command と dry-run planned command の期待値を更新し、先行失敗後に focused suite 15件が PASS した。
- Live validation boundary: ユーザーの `~/.proto` を変更しない一時 HOME で `proto install ruby latest --no-build --yes` を実行し、Ruby prebuilt route の実動確認を行っている。結果と終了状態を closeout entry に追記する。
- Promotion to DECISIONS.yml: none

### Entry 0005 (2026-08-02T00:00:54Z)
- Validation correction: proto CLI の `--no-build` 自体は Ruby 対応だが、公式 `moonrepo/plugins` の現行 Ruby plugin は `default_install_strategy: InstallStrategy::BuildFromSource` を返し、`download_url` や prebuilt download handler を実装していない。`build_instructions` は `ruby-build` と OS package manager の source-build 手順だけを定義している。したがって Ruby に `--no-build` を付けても prebuilt route を作ることはできない。
- Direction correction: Python の proto route には `--no-build --yes` を残し、Ruby は proto route の候補から除外する。Ruby は system、mise、brew、nix、asdf の利用可能な既存経路から選択し、proto の source build や sudo proto へ暗黙に切り替えない。
- Contract fit: これは proto の process-local PATH、manager本体を自動導入しない境界、失敗後継続、dry-runの実行禁止を維持し、source-build時の権限エラーを選択肢の段階で回避する。Python の prebuilt command と Ruby の route exclusion は別々の active rule として保持する。
- Promotion targets: `installer-011-2-1-proto-prebuilt` を prebuilt 対応tool（現行Python）へ限定し、`installer-011-2-2-proto-ruby-source-only` を追加して Ruby plugin の source-only 性質と proto route 非表示を明記する。

### Entry 0006 (2026-08-02T00:00:55Z)
- Implementation correction: `proto_tool_for_tool` を Python のみに限定し、Ruby の proto route 候補を除外した。Python の `install_with_proto` と planned command には `--no-build --yes` を維持した。
- Test result: `tests/dev-tools.test.sh` は Ruby の route list に proto が含まれないことと、Python の prebuilt command を確認し、15件が PASS した。
- Evidence correction: 隔離 HOME での Ruby `--no-build` 実行は `Preparing install` で停止し、導入成功は確認できなかった。一方、公式 Ruby plugin source の `BuildFromSource`、source-only `build_instructions`、prebuilt handler不在が route exclusion の根拠となる。Ruby prebuilt の実動成功は主張しない。
- Implementation-validation handoff: 全関連 suite、Bash構文、YAMLの親子decision ID一意性、差分空白、active status/link整合を確認する。新たな binding constraint はない。
- Promotion to DECISIONS.yml: none

### Entry 0007 (2026-08-02T00:00:56Z)
- Executable validation: PASS — `bash tests/dev-tools.test.sh` は 15件、`bash tests/install.test.sh` は 15件、`bash tests/first-setup.test.sh` は 1件を通過した。focused suite は Python の proto prebuilt command と Ruby の proto route exclusion を確認している。
- Static and artifact validation: PASS — `bash -n templates/dev-tools.sh tests/dev-tools.test.sh`、YAML parse と親子 decision ID の一意性確認（58件）、`git diff --check`、対象ファイルの editor diagnostics を通過した。
- Alignment: `templates/dev-tools.sh`、`tests/dev-tools.test.sh`、`DECISIONS.yml` は、Python の `--no-build --yes` と Ruby の proto route 非表示という分離した契約に一致している。両 sub-decision の record link と実装承認済み status は canonical decision list に存在する。
- Risk boundary: Ruby prebuilt artifact の実動成功は確認していない。公式 plugin の source-only 実装を根拠に proto route を除外しており、prebuilt artifact のネットワーク取得可否は今回の closeout の主張に含めない。今回の変更を阻む未解決事項はない。
- Closeout result: implementation-validation の executable result、artifact alignment、terminology alignment、decision-record hygiene、remaining-risk boundary を確認した。
