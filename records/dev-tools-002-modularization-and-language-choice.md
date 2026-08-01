# Decision Record: dev-tools-002-modularization-and-language-choice

## Metadata
- Created At: 2026-08-01
- Scope: `templates/dev-tools.sh` のモジュール分割と実装言語の継続判断

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to DECISIONS.yml.
- Keep each entry as short as the discussion allows.

Append rules:
- Append at EOF only; do not edit earlier sections.
- Do not add status tracking or remaining-work items.

## Entry List

### Entry 0001 (2026-08-01T00:00:00Z)
- Why now: `templates/dev-tools.sh` が 1,161 行、関数定義が 64 個まで増え、ドメイン境界ごとのファイル分割と、Bash を継続するか他言語へ移行するかを実装前に検討する必要がある。
- Broad-scan findings:
  - 現在の責務は、CLI とログ・外部コマンド記録、ツール検出と `--version` 検証、導入経路の対応表と利用可能性判定、system/nix/proto/mise/asdf/official/uv-tool の導入、install/init/status のツール処理、AGENTS.md 管理ブロック更新、summary・引数解析・main に分かれている。関数群としては境界候補が明確である。
  - ただし各領域はグローバル状態を介して接続している。`find_tool_command` は検証結果を `FOUND_TOOL_COMMAND` と `LAST_VERIFICATION_DETAILS` に書き込み、導入処理は `LAST_OPERATION_COMMAND` とプロセス内 `PATH` を更新し、`process_*` は結果配列と失敗カウンターを更新し、AGENTS.md 更新は `NEW_TOOL_COMMANDS` を読む。単純な関数単位の移動だけでは依存関係が隠れたままになる。
  - 外部配布契約は、`install.sh` が `templates/dev-tools.sh` という単一アセットを対象プロジェクトの `.dev/dev-tools.sh` へコピーし、`bash` で実行する形である。ローカルテンプレートと raw GitHub URL のフォールバック、helper の無条件更新、DODKit 実行後の委譲、テストでの単一ファイル比較がこの形に依存している。
  - 現在の検証は `bash -n`、`tests/dev-tools.test.sh` の 10 件、`tests/install.test.sh` の 15 件が通過している。ヘルパーのテストは関数を source して直接検証するものと、単一ファイルを `bash` で実行するものが混在しており、分割時には公開入口とテスト用内部境界の両方を保つ必要がある。
  - Bash は、sudo、TTY、PATH、各種パッケージマネージャー、`curl | sh`、終了ステータスを直接扱う現在の責務には自然である。一方、対象ツール・導入経路・モード・結果詳細・失敗継続の組み合わせは、共有状態と暗黙の実行順序が増えるほど型や構造化された結果を持たないことの負担が大きくなる。
  - Python へ移行すると Python 自体を導入対象にしている現在のブートストラップと循環し、実行環境の前提が増える。Go や Rust のような静的バイナリはランタイム前提を減らせるが、OS/CPU別配布、リリース成果物、raw installer からの取得、更新・署名・テストの運用を新たに持つことになる。言語を変えても外部CLI呼び出し、パッケージマネージャー差異、TTY、PATH、権限の複雑さは消えない。
- Focus areas:
  - モジュール境界ごとに公開関数、共有状態、初期化順序、エラーと終了ステータスの契約を明示できるか。
  - 分割後も `.dev/dev-tools.sh` の単一入口、raw 配布、原子的な更新、単体テストのモック境界を維持できる配布方式を選べるか。候補は、複数モジュールを同時配布する方式と、リポジトリ内モジュールをリリース時に単一ファイルへ束ねる方式である。
  - Bash 継続と他言語移行を、行数ではなく、型付きデータ・構造化設定・対象OS拡大・テスト可能性・配布可能なランタイムまたは静的成果物の必要性で比較できるか。
- Explicit exclusions: 今回はコード分割、ビルド・bundle機構、`install.sh` の配布アセット変更、`DECISIONS.yml` の変更、実装言語の決定、Python/Go/Rust などの移行実験、第三者CLIの実行を行わない。既存の install/init/status、AGENTS.md、DODKit引数透過、非対話・失敗継続の契約も変更しない。
- Candidate direction:
  - 1,000 行超という規模から、ドメイン境界に沿ったモジュール化は前向きに検討する価値がある。ただし `templates/dev-tools.sh` を単純に複数ファイルへ切るのではなく、薄い公開入口、明示的な共有状態またはコンテキスト、モジュールの読み込み順、失敗時の返却契約を先に定義する。
  - 外部契約は当面 `.dev/dev-tools.sh` という単一の実行入口に固定する。複数ファイルを対象へ配布する場合は全モジュールの版ずれと部分更新を防ぐ原子的な配布が必要であり、単一ファイルを維持する場合は決定的な bundle と生成物検証が必要になる。現行の raw コピーと単一ファイル比較への変更が小さいのは後者だが、bundle のビルド・デバッグ運用を別途設計する必要がある。
  - 言語は現時点では Bash を継続する。まずモジュール化で共有状態、外部コマンド実行、結果集計、テストの境界を可視化し、その後に、Bash の制約が実際に障害になったかを評価する。移行の再検討条件は、対象OSや導入経路の拡大で状態・分岐が構造化データとして扱えなくなること、同種の quoting/終了status/TTY 回帰が繰り返されること、型付き設定や堅牢な subprocess/JSON/API 処理が必要になること、またはランタイムを確実に配布できる静的成果物の運用基盤が整うことである。
  - 分割と言語移行は同じ変更で行わない。分割後の契約とテストを先に安定させることで、将来移行する場合にも比較対象となる Bash 実装と回帰基準を残す。
- Current conclusion: ファイル分割は妥当な次段階候補だが、まず配布形態と共有状態の境界を設計する必要がある。行数だけを理由に他言語へ移行する必要はなく、現在のインストール・環境設定・外部CLI委譲という性質では Bash 継続が合理的である。今回の議論では候補方向の整理までとし、決定昇格と実装は行わない。
- Next validation target: モジュール方式または bundle 方式で、単一入口・raw 配布・部分更新防止・既存テストを同時に満たせるかを確認する。あわせて、共有状態をモジュール間インターフェースへ変換できるか、Bash 継続／静的バイナリ／ランタイム依存言語を配布・テスト・保守の観点で比較し、再評価条件を実装可能な基準へ絞る。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): `templates/dev-tools.sh` 1,161 行、関数境界一覧、`install.sh` の `DEPLOYMENT_ASSET_SPECS` と `run_dev_tools_helper`、`tests/dev-tools.test.sh` 10 件、`tests/install.test.sh` 15 件、`bash -n` の通過結果。

### Entry 0002 (2026-08-01T00:10:00Z)
- Discussion-validation: `templates/dev-tools.sh` 本体、`install.sh` の単一アセット配布とhelper委譲、helper/installerのmockテスト、既存の `installer-011` 契約を確認しており、分割で影響する実行・配布・テスト・決定記録の主要領域をカバーしている。言語移行についても、現行のBashブートストラップ、外部CLI委譲、ランタイムまたは静的成果物の配布条件を確認しており、行数だけで判断しないための比較軸を含めている。
- Focus validation: モジュール境界と共有状態、単一入口を保つ配布方式、言語移行の再評価条件へ絞ったことは、広域確認から直接導かれている。実装・bundle機構・複数ファイル配布・言語選定を今回の範囲から外した理由も、既存の単一アセット配布とユーザーの「議論のみ」という要請に基づき明確である。
- Directional fit: ドメイン分割を前向きに検討しつつ `.dev/dev-tools.sh` の公開入口と既存のinstall/init/status契約を維持し、言語移行を保留する方向は、保守性を高めながら現在の配布UXとLinux/WSL向けの責務を守る。分割と言語移行を同時に行わないため、将来の比較基準も失わない。
- Contract fit: `installer-011-7` の補助スクリプト境界、`installer-011-9` の配置先、`installer-011-10` のhelper先行統合、DODKit引数透過、プロセス内PATH、非対話・失敗継続の契約と衝突しない。複数ファイルを配布する方式またはbundleを導入する方式を binding にする場合は、版ずれ防止・部分更新・生成物検証を追加契約として明示する必要がある。
- Hidden bindings: 実装前に、モジュールが公開する関数・共有状態・初期化順序、配布方式と原子性、bundleを採用する場合の生成元と検証、言語移行の評価表と再評価条件を暗黙のまま残してはならない。これらは現在の議論の候補であり、今回の段階では active decision へ追加しない。
- Validation result: PASS — broad scan、focus、元の保守性向上という目的、既存の不変条件・非ゴール・失敗基準との整合を確認した。ただしユーザー要請どおり、決定昇格と実装は行わない。
- Promotion to DECISIONS.yml: none

### Entry 0003 (2026-08-01T00:20:00Z)
- Bundler candidates reviewed:
  - `malscent/bash_bundler` は Go 製で、Bash の構文解析を使い `source` を再帰的に展開して単一ファイルを生成するため、候補の中では現在の目的に最も近い。Apache-2.0 だが、リリースは v1.0.2、主要更新は約2年前で、生成ヘッダーに現在時刻を含めるため出力はそのままでは決定的でない。`source` の検出も一般的な Bash の import 言語全体を保証するものではなく、採用時は対象構文を限定した上で実行比較が必要である。
  - `rynkowsg/sosh` はローカル・リモートの `source`、変数を含むパス、再帰依存、重複依存を扱える。MIT だが ALPHA 表記で、Babashka が必須であり、`source` が関数内にあるケースを未対応としている。ビルド環境に別ランタイムを追加し、パス評価のためにスクリプトを実行する方式は、現行の単純なローカルモジュール接続には過剰である。
  - `eiedouno/shuttle` は Bash 単体の bundler で、release build と未使用関数の除去を持つ。ただし独自のプロジェクト構造・`shuttle.json`・`jq`・`rg`・`realpath` などを前提とし、関数単位の再構成や dead-code cleanup は、グローバル初期化・副作用・トップレベル処理を含む現行 helper の意味論を変えるリスクがある。直近更新はあるが、リリース成果物は公開されていない。
  - `kamaranl/bunsh` は source tree をコマンド／ライブラリ bundle にする別の設計で、decorator と設定ファイルを中心にしている。現行 helper の `source` 依存グラフをそのまま解決する道具ではなく、更新も約2年前である。
- Fit assessment:
  - どの候補も、リポジトリ内で分割ソースを直接実行すること自体は妨げないが、既存の `.dev/dev-tools.sh` 単一アセット配布、追加ランタイムなしの raw installer、生成物の決定性、現行テストとの同一挙動を同時に満たす完成済みの drop-in tool は確認できなかった。
  - 外部ツールを使うなら `bash_bundler` を release/build 環境だけに固定導入し、対象とする `source` 構文を限定し、生成日時を含む出力を禁止またはパッチし、split entrypoint と生成 bundle の両方へ既存テストを実行する必要がある。インストール先で bundler を実行する方式は採らない。
  - 現行の接続がリポジトリ内ローカルファイルだけなら、明示的な manifest または限定した import marker を読む小さなプロジェクト内 bundler の方が、依存ランタイム・隠れたコード変換・更新停止した第三者実装への依存を減らし、決定的な出力と失敗検出を設計しやすい。これは外部ツールを直ちに排除する決定ではなく、採用候補を比較するための現在の方向である。
- Discussion conclusion: 現時点の第一候補は `bash_bundler` の直接導入ではなく、明示的なモジュール接続を持つプロジェクト内 bundler である。外部ツールを採用する場合も、開発時の split 実行と release 時の bundle 生成を分離し、生成物を単一配布アセットとして検証する構成に限定する。
- Promotion to DECISIONS.yml: none

### Entry 0004 (2026-08-01T00:25:00Z)
- Discussion-validation: 候補ツールの依存解決方式、実行ランタイム、生成物の決定性、保守状況、現行helperとの意味論上の衝突を確認した。比較対象は単純な `source` 展開、変数・遠隔依存を含むresolver、Bash単体のrelease bundler、設定駆動の別形式bundlerを含んでおり、今回の単一ローカルhelperという目的に対する主要な選択肢をカバーしている。
- Focus validation: 現行の単一raw配布と、リポジトリ内split実行を同時に満たすことを中心に絞ったのは、`installer-011-7`、`installer-011-9`、`installer-011-10` と既存テストが直接この境界を決めているためである。遠隔依存の取得、未使用コード除去、別ランタイムでの実行、install時のbundle生成は対象外として明示できている。
- Directional fit: 明示的なローカルmodule接続とrelease/build時だけのbundle生成を第一候補とする方向は、保守性向上という元の目的に適合し、ユーザーの「リポジトリでは分割したまま動かす」という要件も保つ。外部bundlerを使う場合も、インストール先での追加依存を避けるためbuild側へ限定する条件が必要である。
- Contract fit: 単一入口、`bash`実行、install/init/statusの公開契約、DODKit引数透過、プロセス内PATH、失敗継続、AGENTS.md管理、非対話ポリシーとは衝突しない。bundleの導入で新たに必要になる、import構文の許可範囲、循環・重複検出、生成物の決定性、atomic publication、split/bundle双方への回帰テストは未昇格の実装契約である。
- Drift and hidden bindings: 第三者bundlerの採用を決定したり、`install.sh` の取得元を変更したり、生成ファイルを正規ソースとして扱ったりする根拠はまだない。これらを暗黙に決めず、実装議論で候補を比較した後に必要なものだけ新しいdecisionまたはsub-decisionへ昇格する。
- Validation result: PASS — broad scan、候補比較、focus、元の目的、既存の不変条件・非ゴール・失敗リスクを確認した。現段階では議論の結論として「外部bundlerのdrop-in採用は保留し、明示的な接続を持つproject-local bundlerを第一候補にする」と整理できる。
- Promotion to DECISIONS.yml: none; user requested discussion only and no new binding implementation rule is being introduced.
