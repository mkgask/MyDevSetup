# Decision Record: dev-tools-001-optional-tool-installation

## Metadata
- Created At: 2026-07-18
- Scope: Optional development-tool installation and dev-tools helper distribution

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to DECISIONS.yml.
- Keep each entry as short as the discussion allows.
- Evidence and detailed promotion metadata are optional; omit them when the entry stays clear without them.

Append rules:
- Append at EOF only; do not edit earlier sections.
- Do not add status tracking or remaining-work items.

## Entry List

### Entry 0001 (2026-07-18T00:00:00Z)
  - **既存方針の継承**: 不足時の対象は `python`、`ruby`、`rg`、`rtk`、`codegraph` の順とし、未導入のものだけを既定Yの `[Y/n]` で確認する。Linux/WSL限定、既存パッケージマネージャ優先、既存 `mise` / `asdf` のみ利用、`python3` の受入れ、公式インストーラー利用、CLI本体だけの導入、非対話時スキップ、個別失敗後の継続、最後の結果集計、AGENTS.mdのadd-only追記は維持する。
  - **責務境界**: ツール検出・対話・導入・結果集計・AGENTS.md管理ブロック追記は `templates/dev-tools.sh` に分離する。`install.sh` はアセット配布と処理順序の制御を担当し、補助スクリプトの詳細ロジックを持たない。
  - **配布と実行**: `install.sh` は `templates/dev-tools.sh` を対象プロジェクトへ配布し、`bash` で補助スクリプトを実行する。補助スクリプトは単独でも `--help` を表示でき、`rtk init`、`codegraph install`、`codegraph init` は自動実行しない。
  - **AGENTS.mdの順序**: DODKitと通常アセットの処理後に補助スクリプトを実行し、ツール導入結果の管理ブロック追記を全体処理の最後に行う。既存本文と既存記載は変更しない。
  - **記録の分離**: 既存 `records/installer-001-ai-dev-setup.md` は初期インストーラーの不変履歴として残し、開発用ツールの追加・変更履歴は本ファイルへ追記する。決定IDは既存の `installer-011-optional-tool-installation` を維持してリンク先だけを本ファイルへ更新する。

### Entry 0002 (2026-07-18T12:55:00Z)
- Why now: `dev-tools.sh` の実装順序と配置先、導入マネージャー選択の対話回数を具体化する必要がある。
- Findings / trade-offs:
  - `install.sh` は `dev-tools.sh` の実装と単体検証が完了した後に更新する。先に補助スクリプト単体の責務と挙動を確定する。
  - 標準配置先は `.dev/dev-tools.sh` とし、既存の `.dev/` ディレクトリがある場合だけ配置先ディレクトリを1回尋ねる。空入力は `.dev/` と解釈し、配置先の `dev-tools.sh` を上書きする。
  - 不足ツールごとの確認は1回だけとし、利用可能で対象ツールを扱える `nix`、`proto`、`mise`、`asdf` と「導入しない」を同じ選択で提示する。マネージャを選んだ後に別の導入確認は行わない。
  - マネージャ本体は自動導入せず、選択肢には実行可能なコマンドだけを出す。追加のプラグイン登録や初期化も自動化しない。`python`、`ruby`、`rg`、`rtk`、`codegraph` のうち選択マネージャで扱えないものは既存の公式導入経路へフォールバックし、利用可能な経路がなければそのツールをスキップする。
  - 公式資料の確認結果として、`proto` は Python/Ruby を組み込み対応し、`mise` は Python/Ruby/ripgrep/rtk をレジストリで扱える。`asdf` はツールごとのプラグインが必要で、`nix` はパッケージ導入方式のため、実装ではツール別の対応表を持ち、未確認の組み合わせを推測しない。
- Focus areas: `templates/dev-tools.sh` の対話契約、マネージャー対応表、`.dev/` 配置と既存ファイル上書き、公式導入フォールバック。
- Explicit exclusions: この段階では `install.sh` の配布アセット追加、マネージャ本体の導入、シェル設定ファイルの変更、`rtk init`、`codegraph install`、`codegraph init`、各マネージャーの初期化を行わない。
- Current conclusion: `dev-tools.sh` を単独で検証可能な `.dev/dev-tools.sh` として先に実装し、各不足ツールを1回の選択で処理する。`install.sh` の変更はその後に行う。
- Next validation target: 選択肢が利用可能なマネージャーだけに制限され、各ツールの質問が1回で完了し、`.dev/` の既存・未存在・空入力・別ディレクトリ指定を決定契約どおりに扱えることを確認する。
- Promotion to DECISIONS.yml: pending（manager selection、`.dev/` destination、helper-first integration order）
- Evidence / references (optional): Nix公式ダウンロード、proto公式Supported tools、mise公式tool registry、asdf公式plugin documentation

### Entry 0003 (2026-07-18T13:00:00Z)
- Why now: Gate A step 2（discussion-validation）として、Entry 0002 の候補方向を既存契約と公式資料へ照合する。
- Findings / trade-offs:
  - **Coverage**: `install.sh` のアセット配布・DODKit委譲・処理順序、`templates/AGENTS.md` の配置制約、`installer-011` の既存契約、Nix/proto/mise/asdf の公式導入・ツール対応モデルを確認した。
  - **Directional fit**: `dev-tools.sh` を先に単体検証し、`install.sh` を後から接続する順序、1ツール1回の選択、`.dev/` 配置は当初の責務分離と利用者の要求に適合する。
  - **Contract gap**: `installer-011-2` の「既存システムパッケージマネージャ優先・既存 mise/asdf のみ利用」と、Entry 0002 の4候補マネージャー選択は置き換え関係にある。また `installer-011-3` の rtk/codegraph 公式インストーラー固定を、選択マネージャー利用とどう併存させるかを明示する必要がある。
  - **Hidden binding**: マネージャー本体・asdf/protoプラグインの自動導入可否、マネージャーを使わない選択の意味（スキップのみか、公式／システム経路へのフォールバックか）は、実装前に決める独立した制約である。
- Validation result: RETURN — 配置先と実装順序は昇格可能だが、上記の導入経路契約が未確定のため、manager selection の決定昇格は保留する。
- Next validation target: 「未導入マネージャーを選択肢に出さずスキップする」か「選択時にマネージャー本体も導入する」か、および「マネージャーなし」をスキップまたは公式／システム経路として扱うかを確定する。
- Promotion to DECISIONS.yml: none（契約の衝突と未確定事項を解消してから昇格する）
- Evidence / references (optional): Nix公式ダウンロード、proto公式Supported tools、mise公式tool registry、asdf公式plugin documentation、`DECISIONS.yml` の installer-011-2/3

### Entry 0004 (2026-07-18T13:09:18Z)
- Why now: Entry 0003 で保留した導入経路の意味を利用者の回答で確定し、決定昇格の条件を満たす。
- Resolved constraints:
  - `nix`、`proto`、`mise`、`asdf` の本体が未導入の場合は選択肢に出さず、これらの本体や不足プラグインを自動導入しない。
  - マネージャーが導入済みでも対象ツールを扱えない場合は選択肢から除外する。選択肢はツールごとの対応表と、その環境での実行可能性から生成する。
  - `system` は対応する既存のシステムパッケージマネージャーが検出でき、対象ツールを扱える場合だけ候補にする。`official` は対象ツールに公式インストーラーがある場合だけ候補にする。`skip` は常に候補にする。
  - 不足ツールごとの確認は1回だけとし、導入方法の選択後に別の導入確認を行わない。導入済みツールは質問しない。
  - 標準配置先は `.dev/dev-tools.sh` とする。既存の `.dev/` ディレクトリがある場合だけ配置先ディレクトリを尋ね、空入力は `.dev/` と解釈して `dev-tools.sh` を上書きする。
  - `dev-tools.sh` の単体実装と検証を先に完了し、その後 `install.sh` へ配布アセットと実行委譲を追加する。
- Validation result: PASS — Entry 0002 の候補方向は回答内容で具体化され、既存の AGENTS.md 保護、Linux/WSL限定、CLI本体のみ、初期化なし、失敗後継続、最後のAGENTS.md追記という既存制約とも整合する。
- Promotion to DECISIONS.yml: pending（installer-011-2/3 の更新、および manager selection、`.dev/` destination、helper-first integration order の追加）
- Evidence / references (optional): 利用者回答、Entry 0003 の公式資料確認、`install.sh` の既存アセット配布・DODKit委譲実装

### Entry 0005 (2026-07-18T13:10:37Z)
- Why now: Gate A step 3（decision-promotion）として、Entry 0004 の検証済み契約を `DECISIONS.yml` の active decision set へ反映する。
- Promoted decisions:
  - `installer-011-1` を1ツール1回の導入方法選択へ更新し、空入力時のツール別既定方法を明示した。
  - `installer-011-2` を既存 `system`、`nix`、`proto`、`mise`、`asdf`、`official` の対応経路選択へ更新し、マネージャー本体と不足プラグインの自動導入を禁止した。
  - `installer-011-3` を選択経路の最新安定版と `official` 候補、実行コマンド検証の契約へ更新した。
  - `installer-011-8-install-method-selection` を追加し、未導入・未対応経路の除外、`skip` の常設、選択後の追加確認なし、経路なし時のskipを明示した。
  - `installer-011-9-helper-destination` を追加し、標準配置先 `.dev/dev-tools.sh`、既存 `.dev/` 時の配置先確認、空入力時の `.dev/` 上書きを明示した。
  - `installer-011-10-helper-first-integration` を追加し、`templates/dev-tools.sh` の実装・検証後に `install.sh` を更新する順序を明示した。
- Current conclusion: manager selection、配置先、helper-first integration order の契約を昇格し、`dev-tools.sh` 実装へ進める条件が整った。既存の `install.sh` は未変更である。
- Promotion to DECISIONS.yml: promoted -> `installer-011-1`、`installer-011-2`、`installer-011-3`、`installer-011-8`、`installer-011-9`、`installer-011-10`
- Evidence / references (optional): `DECISIONS.yml` diagnosticsなし、decision contract重複なし、`git diff --check` PASS

### Entry 0006 (2026-07-18T13:30:00Z)
- Implementation finding: protoの `--pin global` は `~/.proto/.prototools` を永続変更するため、ツール導入後に `proto bin` で実体パスを取得し、PATHへ現在のプロセス内だけ追加する。miseは `mise install` 後に `mise bin-paths` で実体パスを取得する。
- Implementation finding: HomebrewのPython標準式は `python` であり、導入後の実行コマンド `python3` と分離して対応表へ反映する。
- Validation evidence: `bash -n templates/dev-tools.sh`、`bash -n tests/dev-tools.sh`、モックによる4ケースの集中テストが通過した。
- Promotion to DECISIONS.yml: `installer-011-11-process-scoped-manager-activation` を追加し、空入力の既定経路選択を `installer-011-5` に反映した。

### Entry 0007 (2026-07-18T14:00:00Z)
- Implementation result: `templates/dev-tools.sh` を `install.sh` から `.dev/dev-tools.sh` へ配布し、通常アセットとDODKitの処理後に `bash` で実行する。既存の通常アセット保護、DODKit引数透過、AGENTS.md本文保護は維持する。
- Validation result: ヘルパー5ケース、インストーラー3ケース、各ファイルの `bash -n`、`git diff --check`、エディター診断が通過した。
- Artifact alignment: 空入力の既定経路、利用可能経路だけの選択肢、失敗後継続、管理ブロックの冪等更新、既存 `.dev/` の配置先選択をコードとテストで確認した。

### Entry 0008 (2026-07-18T14:41:18Z)
- Why now: テストファイル名、ログ出力、`printf` の使い分け、`--global`、`install`/`init` モードを次の変更候補として整理する必要がある。
- Broad-scan findings:
  - `tests/` には `dev-tools.sh` と `install.sh` があり、`*.test.sh` への変更はテスト実行名と参照箇所を確認する機械的な整理である。テスト内の `printf` は失敗診断、モック・fixture生成、ファイル内容の直列化、合格表示に分かれており、すべてを本番用 `log_*` に置き換えると生成内容や標準出力の契約を壊す。
  - `install.sh` の `log_warning`、`log_error`、`log_success` はそれぞれ `[⚠️WARNING]`、`[❌️ERROR]`、`[✅️SUCCESS]` のラベル、TTYと `NO_COLOR` に応じた色、warning/successは標準出力、errorは標準エラーという契約を持つ。`templates/dev-tools.sh` はwarning/errorのラベル・色・出力先が異なり、success loggerを持たない。
  - 本番ヘルパーの `printf` もログだけではない。コマンド名・経路名・URLをコマンド置換へ返す出力、プロンプト、サマリー、AGENTS.md管理ブロックのMarkdown生成は、ログラベルを付けないデータまたは表示の契約である。
  - 公式資料では、RTKの `rtk init` はAIツールのhookや設定を構成し、CodeGraphの `codegraph install` はagent設定を、`codegraph init` はプロジェクトごとの `.codegraph/` 索引を扱う。したがって `init` はCLI本体の導入後に必ず行う共通後処理ではなく、別の永続的・プロジェクト依存の責務である。
  - `--global` も単一の意味ではない。system/official/nixの配置スコープ、proto/mise/asdfのバージョン選択や設定の永続化、RTK/CodeGraphのagent設定スコープは相互に異なる。特に既存契約のプロセス内PATH調整と、protoのグローバルpinを作らない方針は、単純な全経路へのフラグ転送とは両立しない。
- Focus areas:
  - テストファイルの命名と、テスト実行コマンド・ドキュメント・CI参照の同期。
  - `install.sh` とヘルパー間の warning/error/success の表示契約。ログとプロンプト・サマリー・データ生成の出力チャネルを分離する。
  - `--global` を「現在ユーザーが全プロジェクトから利用できる導入先」、「manager設定の永続化」、「agent設定のglobal適用」のどれとして定義するか、および経路ごとの対応表。
  - `install` を現在のCLI本体導入に、`init` を明示的なagent連携またはプロジェクト索引作成に分離する場合の対象、スコープ、非対話時挙動、冪等性、既存の初期化禁止契約の改訂範囲。
- Candidate direction:
  - テスト名は `tests/dev-tools.test.sh` と `tests/install.test.sh` に揃え、参照する実行コマンドも同時に更新する。
  - 本番のユーザー向け状態通知だけを `log_info`/`log_warning`/`log_error`/`log_success` に寄せ、warning/error/successは `install.sh` と同じラベル、色、標準出力・標準エラー規則にする。コマンド置換の戻り値、プロンプト、サマリー、Markdownやfixtureの生成はログではないため、`printf`を残すか専用のデータ出力関数へ分離する。テスト診断も本番ログAPIとは分けて扱う。
  - `--global` は全経路へ無条件に渡さず、導入スコープ、manager設定の永続化、agent設定スコープ、shell起動ファイル変更を分離した明示的な契約として検討する。少なくとも既存のプロセス内PATH限定とshell設定ファイル非変更は、別途明示的に変更されない限り維持する。
  - 既定モードは現行の `install` 相当とし、`init` は明示指定時だけ実行する別モードとする。RTK/CodeGraphの初期化を対象に含める場合は、対象ツールごとのコマンド、global/local scope、確認、失敗時の継続、冪等性を新しい決定として定義してから、`installer-011-4` を改訂する。
- Explicit exclusions: この議論ではテストのrename、ログ関数、`printf`、`--global`、`install`/`init` の実装、`DECISIONS.yml` の変更を行わない。既存の `rtk init`、`codegraph install`、`codegraph init` を自動実行しない契約、shell起動ファイルを変更しない契約、プロセス内PATH限定を暗黙に緩めない。
- Current conclusion: `printf` の全面置換と、全managerへ共通の `--global` 転送は責務またはスコープの違いを隠すため不適切である。まず命名とログ契約を独立して整理し、global scopeとinit scopeは既存契約を改訂する候補として明示的に定義する必要がある。
- Next validation target: `install.sh` のログ契約をヘルパーにも適用した場合の標準出力・標準エラー・`NO_COLOR`・TTYなしの期待値、全テスト参照のrename漏れ、各導入経路のglobal/local意味、`install`/`init` の対象と既存の初期化禁止契約との整合性を確認する。
- Promotion to DECISIONS.yml: pending（候補方向の検証と、`--global` および `init` の意味に関する利用者確認が必要）

### Entry 0009 (2026-07-18T14:41:18Z)
- Discussion-validation: broad scanは `install.sh`、`templates/dev-tools.sh`、両テスト、既存決定・記録、RTK/CodeGraph公式CLI資料を含み、命名、表示契約、データ出力、manager導入スコープ、agent連携、プロジェクト索引の主要境界を確認できている。焦点の絞り込みも、`printf` の用途分離とglobal/initの責務分離という実際の破壊点に基づいている。
- Directional fit: `*.test.sh` への命名整理と、ログ関数だけを `install.sh` の表示契約へ揃える方向は、既存のCLI導入・AGENTS.md記録・責務分離を維持したまま要求に適合する。`printf` のデータ出力を維持または専用出力関数へ分離する方針も、コマンド置換、プロンプト、サマリー、Markdown生成の契約と整合する。
- Contract fit: `--global` をmanagerの永続設定や全経路への共通フラグとして直ちに扱うことは、`installer-011-11` のプロセス内PATH限定・protoのグローバルpin禁止と衝突し得る。`init` でRTKまたはCodeGraphの設定を実行することは、`installer-011-4` の初期化なし・CLI本体のみの契約を改訂しない限り許可できない。
- Hidden bindings: 承認する場合は、ログ出力契約、テスト命名、導入スコープとagent設定スコープの分離、`install`/`init` の対象と非対話・冪等性を、それぞれ独立した決定またはサブ決定として昇格する必要がある。特に `--global` は「バイナリを全プロジェクトから利用可能にする」「managerの選択を永続化する」「agent設定をglobal適用する」を同じ語で表さない契約が必要である。
- Validation result: RETURN — 命名とログの候補は妥当だが、`--global` の導入スコープ、`init` の対象、既存の初期化禁止契約を変更するかどうかが未確定であり、現時点で `DECISIONS.yml` の更新や実装へ進む条件は満たさない。
- Required clarification before promotion: `--global` の意味を導入先スコープだけに限定するか、manager設定・agent設定まで含めるかを分けて確定し、`init` で実行する対象ツールとlocal/global scopeを確定する。その後、ログ契約とテスト命名を含む最小のdecision setを再検証する。

### Entry 0010 (2026-07-19T00:00:00Z)
- Clarification: テストファイル名を `*.test.sh` にする方針、ユーザー向けログだけを `log_*` に揃えてデータ生成用の `printf` は維持または分離する方針は承認された。
- Global scope: `--global` は「導入したバイナリを全プロジェクトから利用可能にする」ための明示的な導入スコープを表す。通常の `install` ではプロセス内PATH限定とprotoのグローバルpin禁止を維持し、`--global` のときだけ、そのスコープを実現するために必要な一時的PATH・manager activationの拡張を許容する。`--global` をmanager設定全体の永続化やagent設定のglobal適用を意味するものとはしない。
- Install/init boundary: 既定モードは `install` とし、バイナリのダウンロード・インストールだけを行い、既存の「自動初期化なし」「CLI本体のみ」の契約を維持する。明示的な `init` モードでは、導入済みの各ツールについて、プロジェクトで利用可能にするために必要な初期設定をツールごとに実行してよい。初期設定が不要なツールは処理せず、実際のCLIが `init` 以外の名称を使う場合も、プロジェクト利用に必要な同等の設定処理を対象にする。これにより、利用者が各ツールの初期設定を個別に手入力しなくてよい状態を目指す。
- Scope and safety: `init` の対象はツールごとに定義し、不要な初期化や無関係なagent設定・プロジェクト索引作成を一括実行しない。global/localの適用範囲、非対話時挙動、冪等性、失敗後継続は実装前に各ツールの契約として確認する。
- Discussion conclusion: 前回のRETURN理由だった `--global` と `init` の意味は利用者回答で解消された。次の段階では、テストrename・ログ契約・`printf`分類・`--global`の経路別一時拡張・install/initのツール別初期設定を、既存 `installer-011` の改訂候補として検証する。今回は `DECISIONS.yml`、コード、テストファイル名を変更しない。
- Promotion to DECISIONS.yml: pending（利用者回答を反映した候補方向の記録まで。実装または決定昇格は次段階で行う）

### Entry 0011 (2026-07-18T15:21:40Z)
- Final clarifications:
  - モードは `dev-tools.sh [install|init] [--global]` の位置引数で指定し、モード省略時は `install` とする。
  - `init` は明示指定時だけ実行し、不足バイナリの導入は行わない。現在のプロジェクトで利用可能かつ初期設定が必要なツールだけを対象とし、初期設定不要または未導入のツールはスキップする。
  - 明示的な `init` 自体を同意とみなし、ツールごとの追加確認は行わない。個別の初期設定失敗では後続ツールを継続する。
  - `--global` は `install` モードのバイナリ導入スコープだけに適用し、`init` の適用範囲やagent設定のglobal化には使わない。全プロジェクトから利用可能な導入先を持つ経路だけを候補にし、該当経路がなければskipとする。通常モードのプロセス内PATH限定とprotoのグローバルpin禁止は維持し、`--global` 時だけ必要な一時的PATH・manager activationの拡張を許容する。shell起動ファイル、manager設定全体、agent設定の永続変更はこの意味に含めない。
  - `*.test.sh` へのrename、ユーザー向け `log_*` とデータ生成用 `printf` の分離、`install.sh` と同じwarning/error/success表示契約を実装対象とする。
- Discussion result: 追加の実装前質問はない。位置引数、既定モード、initの対象・確認・失敗継続、globalの適用範囲・候補経路という実装判断に必要な契約が確定した。
- Promotion to DECISIONS.yml: pending（このEntryをdiscussion-validationで確認後、`installer-011` の既存契約と新規サブ決定へ昇格する）

### Entry 0012 (2026-07-18T15:31:19Z)
- Discussion-validation: broad scanは本番インストーラー、補助スクリプト、テスト、既存決定、append-only記録、RTK/CodeGraphの公式CLI境界を確認しており、今回の変更に関係する出力、導入スコープ、初期設定、manager activation、テスト参照の主要領域を網羅している。
- Directional fit: 利用者回答により、テスト命名・ログとデータ出力の分離、`install`/`init` の位置引数、`--global` のinstall限定、プロジェクト単位の明示的initが具体化された。これらは既定のCLI本体導入と自動初期化なしを維持したまま、明示指定時だけ拡張するため、元の目的と整合する。
- Contract fit: `install` は従来どおり不足ツールの導入・確認・AGENTS.md記録を行い、TTYなしでは任意導入をスキップする。`init` は不足バイナリを導入せず、利用可能で初期設定が必要なツールだけを追加確認なしで処理し、不要なツールを変更しない。`--global` はmanager設定・agent設定・shell起動ファイルの永続変更を意味せず、protoのグローバルpin禁止も維持する。
- Hidden bindings resolved: `init --global` はglobalの意味がinstallスコープに限定されるため不許可とし、明示的エラーにする。global installでは全プロジェクトから利用可能な導入経路だけを候補にし、該当経路がなければskipとする。初期設定コマンドが内部で確認を出す場合は、実装時にツール別の非対話・冪等性契約を確認する。
- Promotion targets: `installer-011` の既定install/init境界を更新し、`installer-011-2`、`installer-011-4`、`installer-011-5`、`installer-011-11` を拡張する。新規サブ決定としてテストファイル命名、ログ出力とデータ出力の境界、global install scope、mode selection、project init scopeを追加する。
- Validation result: PASS — candidate directionは元の目的、既存の不変条件、非ゴール、失敗時継続、非対話方針に適合し、実装判断に必要な契約が明示された。
- Promotion to DECISIONS.yml: ready（上記の親決定更新、既存サブ決定更新、新規サブ決定追加を実施する）

### Entry 0013 (2026-07-18T15:33:44Z)
- Final clarification: 明示的な `init` では、公式ツールが現在プロジェクトで通常行う設定へ委譲する。必要であれば現在プロジェクトの `AGENTS.md` やagent設定の変更も許可する。これは `install` のCLI本体導入・AGENTS.md add-only記録とは別の明示的initの例外であり、globalなagent設定や他プロジェクトへの設定適用を意味しない。
- Contract adjustment: `installer-011-6` の既存AGENTS.md保護は通常の `install` に維持し、`init` では公式ツール所有のプロジェクト設定変更を許可する境界を明記する。公式initが不要なツールは処理せず、利用可能な公式のプロジェクト設定手順がない場合はskipまたは失敗として後続処理を継続する。
- Validation result: PASS — 最後の設定ファイル境界を含めても、既定installの自動初期化なし、global installのスコープ限定、プロセス内PATH・proto global pin禁止、失敗後継続という既存契約と、明示initの拡張が衝突しない。
- Promotion to DECISIONS.yml: ready（`installer-011-6` の通常install/init例外を更新し、`installer-011-16-project-init-scope` に公式プロジェクト設定委譲を含める）

### Entry 0014 (2026-07-18T15:40:53Z)
- Promotion result: `installer-011` の既定install/init境界を更新し、`installer-011-2`、`installer-011-4`、`installer-011-5`、`installer-011-6`、`installer-011-11` を `⚠️Discussion Approved` として更新した。
- New decision contracts: `installer-011-12-test-file-naming`、`installer-011-13-logging-and-data-output`、`installer-011-14-global-install-scope`、`installer-011-15-mode-selection`、`installer-011-16-project-init-scope` を追加した。
- Promotion coverage: `install` の既定CLI導入・非対話・AGENTS.md記録、明示 `init` のプロジェクト設定委譲、`--global` のinstall限定スコープ、ログとデータ出力の分離、テスト命名が `DECISIONS.yml` の実装契約として明示された。
- Validation evidence: エディター診断は `DECISIONS.yml` と本記録の両方でエラーなし、決定ID重複なし、`git diff --check` 通過。環境にRubyとPython YAMLライブラリがなく専用YAMLパーサーは実行できなかったが、編集後の診断検証は通過した。
- Scope boundary: 今回は議論・検証・決定昇格のみを行い、実装、テストファイルrename、テスト実行、`install.sh` または `templates/dev-tools.sh` の変更は行っていない。

### Entry 0015 (2026-07-18T16:17:54Z)
- Wording clarification: `installer-011-1-tool-order-and-prompt` の「未導入のツールだけを1回の導入方法選択で確認する」を「未導入のツールだけを各一回ずつの導入方法選択で確認する」へ修正した。
- Intended meaning: 未導入ツール全体に対して導入方法を一度だけ選ぶのではなく、対象ツールごとに導入方法を一回だけ選択する。導入方法の選択肢は各ツールの対応表から生成し、既存の `skip` とツール別の既定方法を維持する。
- Scope boundary: 実装、テスト、その他の決定契約は変更していない。

### Entry 0016 (2026-07-19T05:56:53Z)
- Implementation result: `templates/dev-tools.sh` に `install`／`init` モード、ツール別の利用可能な導入経路選択、`--global` の経路制限、プロセス内だけのmanager PATH更新、RTK／CodeGraphの明示的なプロジェクト初期化、結果集計、install時だけのAGENTS.md管理ブロック更新を実装した。`install.sh` は補助スクリプトを `.dev/dev-tools.sh` へ配布し、DODKit実行後に `bash` で委譲する。
- Artifact result: テストを `tests/dev-tools.test.sh` と `tests/install.test.sh` へ改名し、ログ契約、`init --global` の拒否、initの失敗後継続、CodeGraphの二段階コマンド、AGENTS.md記録のinstall/init分離をmockで検証した。Nix導入後のユーザープロファイルPATHも同一プロセス内で再評価する。
- Validation evidence: mock-onlyのヘルパー7件とインストーラー3件、4ファイルの `bash -n`、エディター診断、`git diff --check`、旧テスト名参照なし、`Discussion In Progress` なしの確認が通過した。ShellCheckは環境に存在しなかったため実行していない。
- Execution boundary: 実際のsystem／nix／proto／mise／asdf／officialによる第三者CLIのinstallおよびRTK／CodeGraphのinitは実行せず、コマンド引数・順序・失敗継続だけをmockで検証した。

### Entry 0017 (2026-07-19T06:52:26Z)
- Implementation refinement: 実働時の失敗診断性を上げるため、外部install/initコマンドの実行前traceを `DEV_TOOLS_DEBUG=1` で stderr に出し、失敗時のsummaryとerrorへ実行コマンドおよび終了コードを含める。個別失敗の後続処理は維持し、helperとinstall.shは最終的に非0を返す。
- Validation evidence: mock-onlyのヘルパー7件とインストーラー5件、helper／installerの `bash -n`、エディター診断が通過した。失敗mockでinstallとinitの後続継続、status伝播、debug trace、installer最上位のstatus表示を確認した。
- Execution boundary: 実際の第三者CLIのinstallおよびRTK／CodeGraphのinitは今回も実行していない。

### Entry 0018 (2026-07-19T07:00:00Z)
- Why now: 初回実行では `DEV_TOOLS_DEBUG=1` を付けない想定のため、失敗時のコマンドと終了コードが通常ログだけで追跡できるかを再確認し、debug traceの識別ラベルを改善する。
- Broad-scan findings:
  - `templates/dev-tools.sh` のinstall失敗とinit失敗は、`DEV_TOOLS_DEBUG` の有無に関係なく error と最終summaryへ実行コマンドおよび終了コードを含める。`DEV_TOOLS_DEBUG=1` は実行前traceを追加するだけで、失敗詳細の表示条件ではない。
  - `install.sh` もhelperおよびDODKitの終了コードをエラーへ含め、子プロセスが出したstderrを保持する。したがって初回実行で詳細取得のために再実行する必要はない。
  - 現行の失敗テストは `DEV_TOOLS_DEBUG=1` を設定しているため、通常経路の詳細表示自体は実装済みでも、debug環境なしの回帰条件がテストで明示されていない。
  - 現行debug traceのラベルは `[DEBUG]` であり、ユーザー提案の `[🔵DEBUG]` と異なる。これはstderrのdebug表示ラベルだけを変更する候補で、error／warning／successの既存ラベル契約や出力先とは別である。
- Focus areas:
  - `DEV_TOOLS_DEBUG` 未設定時のinstall/init失敗ログとsummaryに、コマンド・終了コードが残ること。
  - `DEV_TOOLS_DEBUG=1` 時のtraceラベルを `[🔵DEBUG]` とする表示契約。
  - 実CLIを実行せず、mockで通常経路とdebug経路を分けて検証するテスト境界。
- Explicit exclusions: 第三者CLIの実install／init、エラーの継続処理・終了status・stderr保持の意味変更、既存のwarning／error／successラベル変更、今回の議論中のコード実装とDECISIONS.yml更新。
- Candidate direction: 失敗詳細の常時表示は現行実装を維持し、通常経路での表示をmockテストへ追加する。debug traceの見出しだけを `[🔵DEBUG]` に変更し、`DEV_TOOLS_DEBUG=1` のopt-in性、stderr出力、通常ログとの分離を維持する。
- Current conclusion: 第一の懸念である「初回実行では詳細が取れない」は現行コードで解消済み。追加実装が必要な候補はdebugラベルの変更と、通常経路の回帰テスト明示であり、いずれも既存のfailure-diagnostics決定から逸脱しない。
- Next validation target: 上記candidate directionが、初回実行の診断性、既存ログ契約、失敗後継続、debug出力のopt-in性を同時に満たすことをdiscussion-validationで確認する。
- Promotion to DECISIONS.yml: pending（discussion-validation後、必要なら `installer-011-17-failure-diagnostics` のdebugラベルと通常経路テスト要件を更新する）。

### Entry 0019 (2026-07-19T09:18:31Z)
- Follow-up finding: 導入コマンドが成功した後の実行コマンド検証（`--version`）に失敗する経路では、現行のerrorとsummaryが「command verification failed」とだけ表示し、検証対象コマンドと終了コードを表示しない。これは `installer-011-17-failure-diagnostics` の「外部コマンド失敗は終了コードと実行コマンドを記録する」という契約に対する実装上の残存ギャップである。
- Refined candidate direction: install／initの実行コマンド失敗だけでなく、導入後検証の各候補コマンドについても、実行コマンドと終了コードを通常の失敗ログとsummaryへ残す。`DEV_TOOLS_DEBUG=1` は実行前traceの追加表示に限定し、debugラベルを `[🔵DEBUG]` へ変更する。通常経路での失敗詳細をmockテストで明示する。
- Scope boundary: 第三者CLIの実行、失敗処理の継続方針、既存のerror／warning／success出力契約、`install`／`init`の責務は変更しない。今回の議論ではコードとDECISIONS.ymlを変更しない。

### Entry 0020 (2026-07-19T09:18:31Z)
- Discussion-validation: broad scanは `templates/dev-tools.sh` の実行・検証失敗経路とログ関数、`install.sh` のhelper／DODKit委譲、helper／installerのmockテスト、`DECISIONS.yml` のfailure-diagnostics・logging・failure-continuation契約、AGENTS.mdの編集制約を確認した。実行前trace、通常error、summary、終了status、stderr保持の境界を対象に含めており、今回の診断性の論点に対して十分な範囲である。
- Directional fit: 通常の初回実行で失敗コマンドと終了コードを見られる状態を維持し、`[🔵DEBUG]`は明示指定時の追加traceに限定する方向は、再実行なしの診断という目的に適合する。検証失敗のコマンド・終了コードを追加することで、導入成功後のPATHや実行ファイル問題も同じ契約で追跡できる。
- Contract fit: `installer-011-5` の失敗後継続、`installer-011-13` のログとデータ出力の分離、`installer-011-16` のinit境界、`installer-011-17` の非0終了とstderr保持を維持する。実CLIをテストで実行しない制約、既存warning／error／successラベル、AGENTS.mdのinstall／init分離にも抵触しない。
- Hidden binding: `find_tool_command` の検証試行は候補コマンドと終了コードを構造化して返せるようにし、導入実行失敗と検証失敗をsummary上で区別する必要がある。これは新しい目的ではなく `installer-011-17-failure-diagnostics` の適用範囲を明文化する更新として扱う。
- Validation result: PASS — candidate directionは元の目的、既存の不変条件、非ゴール、失敗基準に適合する。実装時は通常経路の失敗テスト、検証失敗テスト、`[🔵DEBUG]`表示テストを追加し、既存mock-only suiteを維持する。
- Promotion to DECISIONS.yml: ready（`installer-011-17-failure-diagnostics` を、導入後検証失敗の詳細表示と `[🔵DEBUG]` ラベルを含む契約へ更新する）。

### Entry 0021 (2026-07-19T09:22:37Z)
- Why now: `DEV_TOOLS_DEBUG=1` は毎回の設定値ではなく、その実行だけ一時的に有効にしたい診断指定であるため、環境変数より明示的な `--debug` flag の方が呼び出し意図を表すかを再検討する。
- Active baseline: 対象は `installer-011-15-mode-selection` と `installer-011-17-failure-diagnostics`。いずれも `✅️Implementation Approved` で、現在の補助スクリプト仕様は `dev-tools.sh [install|init] [--global]`、debug traceは `DEV_TOOLS_DEBUG=1` のときだけ有効としている。
- Broad-scan findings:
  - `templates/dev-tools.sh` は `DEV_TOOLS_DEBUG` を `log_debug` の条件としてのみ参照し、永続設定や複数回実行にまたがる状態は持たない。用途は一回限りのCLI診断flagに近い。
  - `parse_args` は `install`／`init`／`--global`／`--help`を処理し、引数の順序を固定していない。現状の `--debug` は未知引数としてstatus 2になり、helpにも環境変数だけが記載されている。
  - `tests/dev-tools.test.sh` は環境変数を設定して `[DEBUG] Running:` を検証しているため、flag移行時には引数解析、debug有効時のtrace、debug未指定時のtrace不在、通常の失敗詳細を分けて固定する必要がある。
  - `install.sh` は受け取った引数をDODKitへそのまま渡し、helper起動時には引数を渡していない。したがってトップレベルの `install.sh --debug` まで同じ意味にすると、DODKit引数透過との境界を新たに設計する必要がある。
  - `.docs/PRINCIPLES.md` は一般的なdebug log levelに絵文字を付ける方針を持つが、今回の `[🔵DEBUG]` は補助スクリプトのstderr trace表示に限定する。既存の `[✅️SUCCESS]`／`[❌️ERROR]`／`[⚠️WARNING]`契約は変更しない。
- Focus areas:
  - `dev-tools.sh`の一回限りの診断指定を `--debug` として解析し、mode／`--global`と任意順序で併用できるか。
  - debug未指定時のtrace不在と、通常失敗ログ・summaryにおけるコマンド／終了コード表示の分離。
  - helper単体のflag契約と、DODKit引数を透過するトップレベル `install.sh` の責務境界。
- Explicit exclusions: 今回はコード、テスト、`DECISIONS.yml`、トップレベル`install.sh`の引数透過契約、DODKitの受け付ける引数、第三者CLIのinstall／initを変更しない。`DEV_TOOLS_DEBUG`を環境変数として残す互換aliasも候補から外し、制御経路を二重化しない。
- Candidate direction: `dev-tools.sh [install|init] [--global] [--debug]` を正式な一回限りの診断指定とし、既存parserと同じくflagの位置は問わず、複数指定は冪等に扱う。`--debug`なしではtraceを出さず、失敗の詳細ログは従来どおり常時表示する。トップレベル`install.sh --debug`は別議論で明示的にhelperへ渡す契約を定めるまでサポート対象にしない。
- Current conclusion: 用途と実行単位の一致、呼び出し時の可視性、環境継承による意図しないdebug有効化の回避という点で、`DEV_TOOLS_DEBUG=1`より`--debug`への一本化が妥当である。ただしトップレベルinstallerからhelperを診断したい場合は別の引数設計が必要であり、今回の候補に暗黙に含めない。
- Next validation target: `--debug`一本化が `installer-011-15` のmode／global契約、`installer-011-17` のtrace・失敗詳細契約、DODKit引数透過、非対話・mock-onlyテスト方針と両立するかを確認する。
- Promotion to DECISIONS.yml: pending（discussion-validation後、必要なら `installer-011-15` と `installer-011-17` のdebug指定を更新する）。

### Entry 0022 (2026-07-19T09:22:37Z)
- Discussion-validation: broad scanは補助スクリプトのparser／help／trace関数、helperのmockテスト、トップレベルinstallerのDODKit引数透過とhelper委譲、関連するログ原則、対象決定の契約を確認しており、flag移行で影響する主要境界を網羅している。特に、helper引数とトップレベルinstaller引数を同一視しない omission risk を明示できている。
- Focus validation: 一回限りのdebug指定、通常失敗詳細との分離、mode／`--global`との併用、テストでのmock-only検証に絞ることは、広い調査結果から直接導かれている。`install.sh --debug`の意味付けとDODKitの対応可否を今回の焦点から外した理由も、既存の引数透過契約に基づき明確である。
- Directional fit: `dev-tools.sh`のdebug指定を `--debug`へ一本化する方向は、ユーザーの「毎回ではない診断」を明示的な呼び出しにする目的に適合する。環境変数の継承による意図しないtraceを避け、通常実行の失敗コマンド・終了コード表示は維持できる。
- Contract fit: `installer-011-15` のmode省略・`install`既定・`init --global`拒否、`installer-011-17` のstderr trace・失敗後継続・非0終了、`installer-011-13` のログ出力契約、DODKit引数の透過、第三者CLIを実行しないテスト方針と衝突しない。既存のwarning／error／successラベルも変更しない。
- Hidden binding: `--debug`はhelper単体の正式な一回限りflagとして `installer-011-15` と `installer-011-17` に昇格し、`DEV_TOOLS_DEBUG`を通常契約から削除する必要がある。トップレベル`install.sh --debug`を将来サポートする場合は、DODKitへ渡す引数とhelperへ渡す診断指定の分離を別decisionで定義する。
- Validation result: PASS — candidate directionは元の目的、現在の決定、不変条件、非ゴール、失敗基準に適合する。今回の段階では決定昇格と実装を行わず、次段階で契約更新後にhelperのparser／help／trace／通常失敗テストを実装する。
- Promotion to DECISIONS.yml: ready（`installer-011-15-mode-selection` と `installer-011-17-failure-diagnostics` を `--debug`一本化へ更新する。トップレベルinstallerへのdebug転送は含めない）。

### Entry 0023 (2026-07-19T09:30:00Z)
- Promotion result: `installer-011-15-mode-selection` を更新し、`dev-tools.sh`の正式な引数へ `--debug` を追加した。flagの任意順序・重複指定の冪等性、環境変数代替を提供しないこと、トップレベル`install.sh`の引数透過とhelper委譲を変更しない境界を明記した。
- Promotion result: `installer-011-17-failure-diagnostics` を更新し、install／init実行失敗だけでなく導入後検証失敗にもコマンドと終了コードの記録を要求した。`--debug`指定時のみ `[🔵DEBUG]` traceをstderrへ出し、`DEV_TOOLS_DEBUG`だけではtraceを有効化しない契約へ変更した。
- Decision-shape assessment: 新しい独立decisionは追加していない。mode／責務境界とfailure diagnosticsの既存decisionへ分割して保持することで、debug flag、ログ出力、検証失敗、トップレベルinstaller非対応の各ルールを過度に一つへ集約していない。
- Implementation obligations: parser／help、debug状態、traceラベルとstderr、環境変数単独時のtrace不在、flag組み合わせ、通常失敗詳細、導入後検証失敗詳細をmock-onlyテストで固定する。実CLIのinstall／initは実行しない。
- Status result: 対象2件を `⚠️Discussion Approved` とし、今回の契約変更は未実装であることを明示した。親decisionと他の既存契約は変更していない。
- Remaining non-binding question: トップレベル`install.sh --debug`を将来サポートする場合は、DODKitへの引数透過とhelperへの診断指定を分離する別議論が必要である。現時点では実装対象外とする。

### Entry 0024 (2026-07-19T09:37:47Z)
- Implementation result: `templates/dev-tools.sh` に `--debug` の引数解析と一回限りのdebug状態を追加し、`DEV_TOOLS_DEBUG`環境変数には依存しないようにした。helpの使用方法を更新し、traceを `[🔵DEBUG]` ラベルでstderrへ出力する。
- Implementation result: 導入後の `--version` 検証を実行記録経路へ統合し、検証候補ごとのcommand・exit status・失敗理由を集約して、errorとsummaryへ表示する。既存のinstall／init失敗の後続継続、非0終了、通常ログ契約は維持した。
- Test result: `tests/dev-tools.test.sh` にhelper引数の受け渡し、環境変数だけではtraceを出さないこと、`--debug`時の `[🔵DEBUG]`、検証失敗のcommand/status、helpとflag組み合わせを追加した。mock-onlyのhelper 8件とinstaller 5件が通過した。
- Implementation boundary: `install.sh` は変更せず、DODKit引数透過とトップレベルinstallerからhelperへdebugを渡さない境界を維持した。実際の第三者CLIのinstall／initは実行していない。
- Validation evidence: 変更対象と関連artifactのエディター診断、4ファイルの `bash -n`、`DECISIONS.yml` のRuby YAMLパース、決定ID重複確認、`git diff --check` が通過した。実装中に検証status取得位置の不具合を修正し、同じhelper suiteを再実行して通過を確認した。

### Entry 0025 (2026-07-19T09:37:47Z)
- Implementation-validation: executable validationはhelper 8件とinstaller 5件のmock-only suite、Bash構文、エディター診断、YAMLパース、差分空白チェックを含めてPASSだった。旧 `DEV_TOOLS_DEBUG` と `[DEBUG] Running:` は実装ファイル・テスト・installerに残っていない。
- Artifact alignment: `installer-011-15` のhelper限定flag、任意順序・冗等性・env代替なし・top-level非対応と、`installer-011-17` の失敗詳細・`[🔵DEBUG]`・stderr・非0終了・失敗後継続がコードとtestsへ反映されている。`install.sh`のDODKit引数透過は未変更である。
- Terminology and record hygiene: help、テスト期待値、ログラベル、決定契約は `--debug` と `[🔵DEBUG]` に揃っている。`DECISIONS.yml`のlinkは本記録を指し、今回の実装で新たなbinding decisionは発生していない。
- Status result: `installer-011-15-mode-selection` と `installer-011-17-failure-diagnostics` を `✅️Implementation Approved` とした。実装対象の決定契約は満たされており、closeoutを阻む問題はない。
- Remaining risk: ShellCheckは環境に存在しないため実行していない。トップレベル`install.sh --debug`対応は今回の決定・実装範囲外であり、必要になった時点でDODKit引数との分離を別議論する。

### Entry 0026 (2026-07-19T09:37:47Z)
- Validation correction: Entry 0025の旧参照に関する記述を補足する。実装ファイルでは `DEV_TOOLS_DEBUG` と `[DEBUG] Running:` を参照しないが、`tests/dev-tools.test.sh` には環境変数だけではtraceを出さないことを検証する負のfixtureと、旧ラベルが出ないことを検証するassertが意図的に残る。これはactive decisionの「環境変数単独ではtraceを出さない」を固定するテストであり、terminology driftではない。

### Entry 0027 (2026-07-19T00:00:00Z)
- Why now: install対象へ `uv` と Serena を追加する候補が出た。両方のCLI導入は許可する一方、`uv init` のようなPythonプロジェクト生成を一般プロジェクトの `init` で実行しない境界を先に確定する必要がある。
- Active baseline: 対象は `installer-011-1-tool-order-and-prompt`、`installer-011-2-installation-backends`、`installer-011-3-command-and-version-contract`、`installer-011-4-third-party-cli-scope`、`installer-011-6-agents-tool-record`、`installer-011-8-install-method-selection`、`installer-011-15-mode-selection`、`installer-011-16-project-init-scope`、`installer-011-17-failure-diagnostics`。現在の実装は `TOOL_NAMES` がinstall、init、summary、AGENTS.md記録の全対象を兼ね、`process_init_tool` は `rtk` と `codegraph` だけを初期化対象としている。
- Broad-scan findings:
  - `templates/dev-tools.sh` の新規対象追加は、コマンド検出候補、導入経路対応表、既定route、実行順、結果summary、AGENTS.md管理ブロック、init分岐、テストのroute期待値とprompt数へ影響する。Serenaをuvより前に処理すると、同一実行で導入したuvをSerenaの導入依存として使えないため、対象順序にも依存関係がある。
  - uv公式資料はLinux向けstandalone installerを `curl -LsSf https://astral.sh/uv/install.sh | sh` で導入できること、`uv tool install` はPython CLIを分離環境へ永続導入し、実行ファイルをbin directoryへ公開することを示している。既存契約のshell起動ファイル非変更を維持するには、uvの導入後にPATHを現在のプロセスだけで再評価する必要がある。
  - Serena公式Quick Startは `uv tool install -p 3.13 serena-agent` で導入し、実行コマンドは `serena` とする。これは既存のcurlでinstaller scriptを実行する `official` routeとは異なり、uvを前提とする依存付きの導入経路である。uvが未導入または導入失敗の場合、Serenaを同じ実行で導入できるか、skipまたは失敗として扱うかを明示する必要がある。
  - Serena公式資料の `serena init` は初回設定・動作確認として案内されるが、グローバル設定は `~/.serena/serena_config.yml` に保存される。プロジェクト単位の設定は `serena project create` で `.serena/project.yml` を生成し、MCPクライアント接続はVS Code、Cursor等のクライアントごとの設定として別途行う。したがって `serena init`、プロジェクト作成・索引、MCP設定を同じ「init」にまとめることはできない。
  - uvの `uv init` は現在ディレクトリをPythonプロジェクトとして生成する操作であり、既存の `init` 契約が対象プロジェクトで必要な初期設定だけを行う方針であることから、uvを `init` 処理対象に含めない候補は既存の自動初期化なし・不要な変更を行わない契約と整合する。
- Focus areas:
  - install対象へ `uv` と `serena` を追加する際の対象順序と、Serenaのuv依存を既存routeモデルへどう表現するか。
  - `uv` はinstall時だけ処理し、init時は明示的に「初期設定不要」としてskipする契約。`uv init`、`uv sync`、virtualenv作成などのPythonプロジェクト変更は今回のinitに含めない。
  - Serenaのinstall後に実行する初期設定を `serena init`、`serena project create`、MCPクライアント設定のどこまでとするか。特に既存の「initは現在プロジェクトに限定し、global設定や他プロジェクトへ適用しない」契約との整合を確認する。
  - uvのstandalone installerとSerenaの `uv tool install` で、shell起動ファイルやクライアント設定を永続変更せず、実行中PATHだけを更新する方法、および`--global`時の導入スコープを分離する。
- Explicit exclusions: この議論では `uv init`、uvによるPython環境・依存関係の作成、SerenaのMCPクライアント設定、Serenaのプロジェクト索引作成、shell起動ファイルの変更、コード・テスト・`DECISIONS.yml`の更新を行わない。Serenaの導入依存を理由にuvのinstallを暗黙同意扱いにはしない。
- Candidate direction: `TOOL_NAMES`へ `uv` と `serena` を追加する候補を採用し、uvをSerenaより先に処理する。uvはinstall時にCLI本体を導入・検証し、init時は常にskipする。Serenaはuvが利用可能な場合に `uv tool install -p 3.13 serena-agent` で導入し、`serena`を検証する。Serenaのinitは必要性を認めつつ、`serena init`がグローバル設定を作ることと、プロジェクト設定・MCP設定が別操作であることを踏まえ、実行コマンドと許可スコープをvalidationで確定する。
- Current conclusion: uvのinstall対象化とinit非対象化は既存のmode境界に沿う。Serenaはuv依存のinstall対象として追加できるが、既存の独立route・init契約へそのまま押し込むと、依存順序、PATH、global scope、`~/.serena`変更、MCP設定の責務が不明確になるため、専用の導入・初期化契約が必要である。
- Next validation target: uv standalone installerと `uv tool install` のPATH・永続設定挙動、Serena `serena init` と `serena project create` のスコープ差、uv失敗時のSerena処理、`--global`で許可するrouteを公式資料と既存decisionへ照合する。検証後、uv install-only、Serena install/init境界、依存失敗時の結果、AGENTS.md記録対象を独立したdecisionまたはsub-decisionとして昇格できるか判定する。
- Promotion to DECISIONS.yml: pending（今回の議論では記録のみ更新し、uv/Serenaのbinding contract、コード、テストは変更しない）。

### Entry 0028 (2026-07-19T00:00:01Z)
- Clarification: Serenaのクライアント側設定（VS Code、Cursor、Copilot等のMCP設定ファイルや接続登録）は今回の対象外とし、`init`ではSerenaのMCPサーバー側を利用可能な状態まで準備する。
- Official boundary: Serenaの標準stdioモードでは、MCPサーバーはクライアントが子プロセスとして `start-mcp-server` を起動し、stdin/stdoutで通信する。したがって `init`自身がサーバーを常駐起動して「待ち受け続ける」処理は行わない。HTTPモードの常駐サーバーやsystemd等のサービス化は別スコープとする。
- Candidate init behavior: Serenaが利用可能な場合、`init`で `serena init` を一回実行して初期化と動作確認を行い、`serena start-mcp-server --help` 等でMCPサーバー起動CLIの存在も検証する。`serena project create`、`serena project index`、MCPクライアント設定は自動実行しない。後続クライアントは、必要なcontext・project指定を持つ `serena start-mcp-server` の起動コマンドを自身の設定へ登録する。
- Scope finding: 公式資料では `serena init` が `~/.serena/serena_config.yml` のようなユーザー側設定を初回作成し得る一方、プロジェクト設定・索引とクライアント接続は別操作である。よってこの候補を採用する場合、既存の `installer-011-16-project-init-scope` に対し「Serena自身のMCPサーバー実行に必要なユーザー側ランタイム設定は許可するが、MCPクライアント設定・他プロジェクトへの設定適用は行わない」という限定例外を明示する必要がある。
- Validation result: pending — 「クライアント設定なしでサーバー側を初期化する」方向は責務分離に適合するが、`serena init`が作成する設定の実体、`start-mcp-server --help`の検証価値、init失敗時の継続・非0終了、ユーザー側設定変更の許可境界をdiscussion-validationで確認する。
- Promotion to DECISIONS.yml: pending（今回もコード、テスト、`DECISIONS.yml`は変更しない）。

### Entry 0029 (2026-07-19T00:00:02Z)
- Discussion-validation: PASS。Broad scanは、対象registry・実行順、route対応表と既定route、uv導入後のprocess-scoped PATH、`--global`の導入スコープ、AGENTS.md記録、install/initの失敗継続、既存テストfixture、および公式のuv/Serena導入・MCP実行仕様を対象にしており、今回の変更境界を判断するのに必要な隣接領域を含んでいる。
- Directional fit: `uv`とSerenaをinstall対象へ追加することはCLI導入という元の目的に適合する。uvは`uv init`、`uv sync`、virtualenv作成を行わずinstall-onlyとし、Serenaはuvを先に処理してから`uv tool install -p 3.13 serena-agent`を実行することで、同一実行内の依存順序を満たす。
- Contract fit: Serenaのinitは利用可能な`serena`に対する`serena init`と`serena start-mcp-server --help`の検証までに限定する。stdio MCP serverはクライアントが子プロセスとして起動するため、helperは長時間プロセスを起動・常駐させない。`serena project create`、project index、MCPクライアント設定、HTTP daemon/service化、shell起動ファイル変更は実行しない。
- Scope exception: `serena init`がSerena自身のMCP server実行に必要な`~/.serena`等のユーザー側runtime設定を作成することだけを、`installer-011-16-project-init-scope`の限定例外として明示する。クライアント設定や他プロジェクトへの設定適用は引き続き禁止する。
- Failure and scope fit: uvまたはSerenaの導入・検証・initが失敗しても後続対象を処理し、対象結果とsummaryへコマンド・終了コードを残して全体を非0にする。`--global`ではuv standalone/tool binを全プロジェクトから利用できる導入経路として扱い、shell設定・manager設定・agent設定の永続変更は行わない。uv依存のSerenaはuvが利用可能な場合だけ候補にする。
- Promotion targets: `installer-011-1-tool-order-and-prompt`、`installer-011-2-installation-backends`、`installer-011-3-command-and-version-contract`、`installer-011-4-third-party-cli-scope`、`installer-011-6-agents-tool-record`、`installer-011-8-install-method-selection`、`installer-011-11-process-scoped-manager-activation`、`installer-011-14-global-install-scope`、`installer-011-15-mode-selection`、`installer-011-16-project-init-scope`、`installer-011-17-failure-diagnostics`を更新し、必要なuv/Serena固有のbinding ruleは新規sub-decisionとして追加する。
- Remaining non-binding risk: Serenaの将来バージョンが`serena init`で作成する具体的なユーザー側設定ファイルを変更する可能性は、公式CLIに委譲する範囲の実装リスクとして記録する。今回の実装では作成ファイルを直接編集・検査しない。
- Promotion status: ready。Gate Aの方向性、非ゴール、例外スコープ、失敗契約、promotion対象は明確であり、`DECISIONS.yml`更新へ進める。

### Entry 0030 (2026-07-19T13:50:40Z)
- Implementation outcome: `templates/dev-tools.sh`へ `uv` と Serena をこの順で追加し、uvは公式standalone installer、Serenaは利用可能なuvに対する `uv tool install -p 3.13 serena-agent` として実装した。uv導入後は `uv tool dir --bin` の結果だけを現在プロセスのPATHへ追加し、shell起動ファイル、manager設定、agent設定は変更しない。
- Initialization outcome: `init`ではuvをinstall-onlyとして明示的にskipし、Serenaは `serena init` と `serena start-mcp-server --help` だけを実行する。Serenaの常駐起動、HTTP daemon/service化、project create、project index、MCPクライアント設定、uvのPython project/environment操作は実装していない。
- Failure and recording outcome: uv導入失敗時はSerenaのuv-tool候補を出さず、後続対象の処理を継続して全体を非0にする。uvとSerenaの導入成功時は検証済みの `uv` と `serena` を既存のAGENTS.md管理ブロックへ追記する。
- Validation: `bash tests/dev-tools.test.sh` は9件、`bash tests/install.test.sh` は5件がpassした。route候補、uv先行、uv依存失敗、init時のuv skip、Serenaのserver-side init、MCP CLIヘルプ、禁止されたproject/index/client/daemon操作の不在をfocused fixtureで確認した。`bash -n templates/dev-tools.sh tests/dev-tools.test.sh tests/install.test.sh install.sh`、editor diagnostics、`ruby`による`DECISIONS.yml` YAML検証、`git diff --check`もpassした。
- Remaining non-binding risk: Serenaの将来バージョンが `serena init` で作成するユーザー側runtime設定の具体的なファイル構成を変更する可能性は公式CLIへ委譲する。helperはその設定ファイルを直接編集・検査しない。
