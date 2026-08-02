# Decision Record: first-setup-001-generic-dependencies

## Metadata
- Created At: 2026-08-02
- Scope: Generic first-setup dependency messaging

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to DECISIONS.yml.
- Keep each entry as short as the discussion allows.

## Entry List

### Entry 0001 (2026-08-02T00:00:40Z)
- Why now: `templates/first-setup.sh` の usage、info、success メッセージが `proto` と `Ruby` に限定されている。現在のパッケージ配列には開発用CLIの導入に使う `curl`、`git`、`gh`、アーカイブ・圧縮ユーティリティも含まれており、将来ほかのツールに必要なライブラリを追加する際にも表示が特定ツールへ寄りすぎる。
- Broad-scan findings: `first-setup.sh` は依存パッケージを単一の `APT_PACKAGES` 配列から渡す構造で、追加パッケージを同じ経路へ拡張できる。proto/Ruby 固有の参照は usage と install 完了メッセージ、および focused test の期待値・説明に限られる。`DECISIONS.yml` の `installer-011-22-first-setup-dependencies` も現在は proto の Ruby source build を主語にしている。apt の root/sudo 境界、update-before-install 順、proto を実行しない境界、手動実行テンプレートという既存契約は今回の目的に直接関係し、維持する必要がある。
- Focus areas: `templates/first-setup.sh` の usage/info/success 文言、`tests/first-setup.test.sh` のユーザー向け出力検証、`installer-011-22-first-setup-dependencies` の依存パッケージ記述を、開発ツール全体を示す表現へ同期する。将来の追加は `APT_PACKAGES` の明示リストへ行い、メッセージは個別ツール名を列挙しない。
- Explicit exclusions: パッケージの追加・削除、apt 以外の導入経路、root/sudo や update-before-install の挙動、proto/Ruby/他CLIの実際の導入、shell/PATH/manager設定、`install.sh` への配布アセット追加は変更しない。
- Current conclusion: usage は「development tools に必要な apt packages」、info/success は「development tool dependencies」を示す汎用文言へ変更する。対象のパッケージ集合は今後も `APT_PACKAGES` へ追加でき、first-setup の実行は依然として依存パッケージ導入だけに限定する。
- Next validation target: discussion-validation は、汎用文言が現在のパッケージ集合と将来の追加方針を正しく表し、既存の apt/root/sudo、非proto実行、手動テンプレート配布の契約および focused test の責務を壊さないことを確認する。
- Promotion to DECISIONS.yml: pending

### Entry 0002 (2026-08-02T00:00:41Z)
- Discussion-validation: broad scan は `templates/first-setup.sh`、`tests/first-setup.test.sh`、`DECISIONS.yml` の既存契約、直近の first-setup 実装記録、README の導入対象範囲を確認しており、表示文言、パッケージ配列、apt 権限境界、テスト所有権、手動実行スコープの主要な関係を覆っている。
- Focus validation: usage/info/success と focused test の期待値、既存 decision の主語に絞ることは、現在の実装で proto/Ruby 固有性が現れる箇所から直接導かれる。パッケージ集合・導入経路・配布処理を除外することで、表示の一般化を実際の責務拡張へ誤って広げない。
- Directional fit: 個別ツール名を含まないメッセージと、`APT_PACKAGES` へ将来の依存を追加できる契約は、first-setup を開発ツール依存の準備入口として使う目的に適合する。
- Contract fit: apt-only、root/sudo の適用範囲、update-before-install、proto/Ruby/CLI 自体を導入しない境界、shell/PATH/manager設定を変更しない境界、`install.sh` へ配布しない初期スコープを維持する。focused test は実際のapt操作ではなく、コマンド列と表示契約だけを検証する。
- Hidden bindings: `installer-011-22-first-setup-dependencies` の decision 本文を、固定された proto/Ruby 用途ではなく、明示された開発ツール依存パッケージ集合と汎用メッセージ契約として更新する必要がある。新しい独立 decision は不要である。
- Validation result: PASS — candidate direction は元の要求、既存の不変条件、非ゴール、失敗時の境界に適合し、実装判断に必要な制約が明確になった。
- Promotion targets: `installer-011-22-first-setup-dependencies` の package purpose、将来の `APT_PACKAGES` 拡張、usage/info/success の汎用文言、個別ツール名をメッセージへ戻さない境界を更新する。

### Entry 0003 (2026-08-02T00:00:42Z)
- Implementation result: `templates/first-setup.sh` の usage、インストール中、成功時の表示を `development tools` / `development tool dependencies` へ一般化し、`proto` と `Ruby` の固有名をスクリプトのユーザー向けメッセージから除去した。APTパッケージ配列、apt update/install 順、root/sudo 境界、protoを実行しない境界は変更していない。
- Test result: `tests/first-setup.test.sh` は help、info、success の汎用文言と proto/Ruby 非表示を検証するよう更新し、focused suite は 1 test pass した。
- Implementation-validation handoff: Bash 構文、関連 suite、決定IDの一意性、差分空白、決定と実装・テストの用語整合を確認して closeout する。新しい binding constraint は発生していない。
- Promotion to DECISIONS.yml: none

### Entry 0004 (2026-08-02T00:00:43Z)
- Implementation-validation: first-setup の focused suite 1件、dev-tools suite 15件、installer suite 15件、変更対象の Bash 構文、エディター診断が PASS した。Python YAML パーサーで `DECISIONS.yml` を読み込み、13件の decision ID が一意であることも確認した。
- Artifact alignment: `templates/first-setup.sh`、`tests/first-setup.test.sh`、`DECISIONS.yml` は、明示的な依存パッケージ集合を将来拡張できること、usage/info/success が個別ツール名に依存しないこと、apt/root/sudo と手動実行の境界を同じ契約として表している。
- Terminology alignment: first-setup template のユーザー向けメッセージと focused assertions は `development tools` / `development tool dependencies` に統一され、template 内に proto/Ruby の参照は残っていない。`git diff --check` も通過した。
- Closeout result: PASS — 表示文言の一般化は完了し、実際の apt 操作、パッケージ集合、導入経路、配布範囲には変更がない。Ruby YAML パーサーと ShellCheck は環境にないため未実行だが、利用可能な YAML 診断・構文・focused suite で変更範囲を検証できている。
- Promotion to DECISIONS.yml: none
