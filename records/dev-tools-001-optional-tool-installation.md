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

### Entry 0031 (2026-07-19T00:00:03Z)
- Why now: `install` と `init` に加えて、各ツールの現在状態だけを確認し、install時と同じsummary形式で表示するモードが必要になった。導入や初期化を伴わない問い合わせ操作として、モード名を `status` とするか、出力名に近い `summary` とするかを整理する必要がある。
- Active baseline: 対象は `installer-011-7-dev-tools-helper-boundary`、`installer-011-13-logging-and-data-output`、`installer-011-15-mode-selection`、`installer-011-17-failure-diagnostics`。`templates/dev-tools.sh` は `DEV_TOOLS_MODE` に `install` と `init` だけを受け付け、`find_tool_command` は各対象を `--version` で検証し、`print_summary` は処理結果を対象順に表示する。`main` はinstall時だけAGENTS.mdを更新する。
- Broad-scan findings:
  - 新モードの主な変更点は `parse_args`、モード別dispatch、結果状態の設定、終了status、使用方法、focused testであり、`install.sh`の配布・実行委譲や既存のinstall/init処理は直接変更する必要がない。
  - 現在の `find_tool_command` はPATH準備後に外部導入を行わず、利用可能な実行コマンドと `--version` の結果だけを返せるため、statusの読み取り処理に再利用できる。statusではprompt、installer、project initialization、AGENTS.md更新を行わない必要がある。
  - `print_summary` は表示フォーマットの責務であり、statusを `summary` と命名すると出力関数名と操作名が混同しやすい。CLI利用者の意図は「現在の状態を問い合わせる」ため、候補としては `status` の方が既存の `install`、`init` と並ぶ操作名として明確である。
  - statusの結果状態は、導入処理の `installed`、`initialized`、`skipped`、`failed` をそのまま流用すると、何も実行していない問い合わせ結果を誤って表す可能性がある。少なくとも検証成功の `present` と、未検出・検証失敗を区別する表示語が必要になる。
  - `--global` は導入スコープを表すためstatusには意味がなく、statusと組み合わせた場合は引数エラーにする候補が既存の `init --global` 拒否と整合する。`--debug` はstatusの `--version` 検証traceを必要時だけ出す用途に再利用できる。
- Focus areas:
  - canonical mode nameを `status` とし、`summary` を正式な別名として追加するかどうか。候補方向はAPIを増やさず `status` のみを正式名にし、`print_summary` は内部表示関数として維持する。
  - statusの各対象を `find_tool_command` で検証し、install/initを一切実行せず、AGENTS.mdやproject filesを変更しない読み取り専用境界。
  - 未導入、実行ファイル存在だが `--version` 検証失敗、検証成功をsummaryへどう表示するか、および全対象が利用可能でない場合にstatusを非0にするか。
  - `--global`、`--debug`、非Linux環境、uv/Serenaを含む対象順、status時の後続処理継続を既存契約へどう接続するか。
- Explicit exclusions: 今回の議論ではコード、テスト、`DECISIONS.yml`、`install.sh`を変更しない。`summary`をstatusの別名として受け付けること、JSON等の新しい出力形式、watch/daemon化、導入経路やinit処理の変更、AGENTS.mdのstatus記録は対象外とする。
- Candidate direction: 正式な操作名は `status` とし、実装時は現在の対象順で全ツールを検証してから既存summary形式を表示する。statusはprompt、導入、初期化、AGENTS.md更新を行わず、PATH準備は現在プロセス内の検出に必要な範囲だけ許可する。表示状態は少なくとも `present` と未利用状態を区別し、`summary`は内部関数名として残す。`status --global` は拒否し、`--debug` は任意に許可する。
- Current conclusion: ユーザーが求めているのは出力形式ではなく現在状態の問い合わせなので、`status` の方が `summary` よりCLIの操作名として適切である。既存の `find_tool_command` と `print_summary` を活用でき、実装範囲もhelper内のモード分岐とテストに限定できる。ただし、欠落時の表示語とstatus全体の終了コードはbinding contractにする前に確認が必要である。
- Next validation target: discussion-validationでは、statusの読み取り専用性、`status --global` の拒否、status時のdebug trace、欠落・検証失敗・検証成功の表示状態、全対象不在時の終了コードが元の「表示だけ見たい」という目的に適合するかを確認する。特に終了コードを「常に表示成功で0」または「ツール不足を反映して非0」のどちらにするかを決定する。
- Promotion to DECISIONS.yml: pending（このentryでは候補方向と未確定論点だけを記録し、コード・decision契約は変更しない）。

### Entry 0032 (2026-07-19T00:00:04Z)
- Discussion update: ユーザーは正式なモード名を `status` とし、いずれかのツールが不足または検証失敗した場合の終了statusを `1` とする方向を承認した。install時のsummary表示とstatus時の状態表示は共通処理にできるかを確認し、モードごとのタイトル表示と、summary描画後の終了status処理を分離する案を提示した。
- Discussion-validation: broad scanで確認した `templates/dev-tools.sh` の検出、結果集計、引数解析、mainの終了処理、`tests/dev-tools.test.sh` の既存契約、および `installer-011-7`、`installer-011-13`、`installer-011-15`、`installer-011-17` の境界に対して、候補方向は適合する。`install.sh`の配布責務、既存install/init処理、AGENTS.md記録はstatusの読み取り専用追加によって変更されない。
- Validated direction:
  - canonical modeは `status` とする。モード省略時は既存どおり `install` とし、`summary` は新しい公開aliasとして追加しない。
  - statusは全対象を既存の `find_tool_command` で検証し、prompt、install、init、project設定、AGENTS.md更新を行わない。検出成功は `present`、検出または `--version`検証が完了しない場合は `unavailable` として、`LAST_VERIFICATION_DETAILS` 相当の詳細をsummaryへ残す。
  - statusは対象を最後まで処理し、1件でも `unavailable` があればsummary表示後に `1` を返す。検出処理そのものが完了して表示できたことだけを理由に成功扱いにはしない。
  - summaryはモードに依存しない結果行描画関数へ分離する。install/statusはそれぞれ必要なタイトルを表示し、各モードの処理・固有の失敗集計を終えた後に共通の結果行描画を呼び、描画後に各自の終了statusを返す。既存のsummary形式、対象順、結果詳細の表示契約は維持する。
  - `status --global` は引き続き引数エラーとし、`--debug` はstatusの `--version` 検証traceに利用できる。既存のLinux/WSL判定とプロセス内PATH準備の境界は変更しない。
- Contract audit: 状態問い合わせと導入・初期化を分離するため、read-only境界、全対象継続、非0終了、共通描画、global拒否、debug許可は実装に必要なbinding constraintである。新しい出力形式、永続PATH設定、AGENTS.mdへのstatus記録、installer.shの引数透過は引き続き非対象である。
- Promotion target: `installer-011-15-mode-selection` にstatusの引数・global/debug制約を追加し、`installer-011-13-logging-and-data-output` にモード非依存のsummary行描画を追加し、`installer-011-17-failure-diagnostics` にstatusの検証失敗・終了status・継続を追加する。既存decisionを過度に膨らませないため、status専用の表示状態・read-only境界は新しい `installer-011-20-status-mode` として独立させる。
- Remaining non-binding detail: statusタイトルの文言と、`unavailable` の詳細文面は既存のsummaryレイアウトを壊さない範囲で実装時に決める。いずれも終了status、読み取り専用境界、対象順、診断情報の契約は変更しない。

### Entry 0033 (2026-07-19T00:00:05Z)
- Implementation outcome: `templates/dev-tools.sh` に `status` モードを追加し、対象順に `find_tool_command` を実行して検証成功を `present`、検出または `--version` 検証不能を `unavailable` として集計するようにした。statusは全対象を継続処理し、検証詳細を結果行へ残す。
- Summary integration outcome: 既存のinstall/init用 `Development-tool summary:` タイトルと、status用 `Development-tool status:` タイトルをモード側に分離し、対象結果行の描画は `print_summary_rows` へ共通化した。summary表示後にinstall/initは既存failureとAGENTS.md更新結果を、statusは `STATUS_UNAVAILABLE_COUNT` をそれぞれ判定して終了する。
- Read-only outcome: statusではprompt、install、init、project設定、AGENTS.md更新を実行せず、`--global` は引数エラー、明示的な `--debug` はversion検証traceだけを許可した。`install.sh`、既存のinstall/init処理、対象順、現在プロセス内PATH準備は変更していない。
- Test outcome: `bash tests/dev-tools.test.sh` は10件、`bash tests/install.test.sh` は5件がpassした。statusの混在状態・version失敗・全対象継続・summary後の終了1、全対象利用可能時の終了0、AGENTS.md非変更、install/initコマンド非実行、`--debug` trace、`status --global`拒否をfocused fixtureで確認した。
- Validation outcome: `bash -n templates/dev-tools.sh tests/dev-tools.test.sh tests/install.test.sh install.sh`、editor diagnostics、`ruby`による`DECISIONS.yml` YAML検証（49 unique ids）、`git diff --check` がpassした。配布テストもstatus追加によるinstall.shの退行なしを確認した。
- Decision alignment: `installer-011-13`、`installer-011-15`、`installer-011-17`、`installer-011-20` の実装契約を満たしたため、これらのstatusを `✅️Implementation Approved` へ更新する。今回の実装で新しいbinding constraintは発生していない。
- Remaining non-binding risk: 非Linux環境では既存のLinux/WSL warning-and-skipを維持するためstatusのツール検証は行われず、対応環境での「unavailableなら1」という契約とは別に既存の非対応環境動作が適用される。

### Entry 0034 (2026-08-01T15:11:13Z)
- Why now: `*_tool_for_tool` の静的な対応表は、manager側が新しいツールを扱えるようになったときに MyDevSetup 側の更新を要求する。対応可否の判断を各managerの読み取り問い合わせへ移せるかを確認する。
- Active baseline: 対象は `installer-011-2-installation-backends`、`installer-011-8-install-method-selection`、`installer-011-11-process-scoped-manager-activation`、および既存の「manager本体・不足pluginを自動導入しない」契約である。`templates/dev-tools.sh` では `*_for_tool` が識別子変換と対応表を兼ね、`*_route_available` が候補表示前の環境判定を行う。
- Broad-scan findings:
  - `mise registry NAME` は公式に read-only とされ、指定名のregistry解決結果を返す。未知名の終了statusを候補判定に使えるため、`mise` は manager側の問い合わせを利用できる。ただし `rg` などの実行名とregistry名が異なる場合のalias変換は残す必要がある。
  - Nixは `nix search` の曖昧な検索ではなく、`nix eval --read-only --raw nixpkgs#<attribute>.name` のような完全な属性評価を候補にできる。検索結果の説明文や広いregex検索は、候補列挙の判定として不安定または高コストなので採用しない。
  - asdfの `asdf plugin list` は現在登録済みのpluginだけを返す。一方 `asdf plugin list all` はremote short-name repositoryを参照・同期し得る。remoteで存在するだけのpluginは現行の「不足pluginを自動導入しない」契約では install route として実行可能とは言えないため、installed-only判定を維持する。
  - protoの `proto install` は導入を開始し、`proto versions` はremote release manifestを解決する。`proto plugin search` はcommunity registryへ問い合わせ、`proto plugin list` と `proto plugin info` もtoolをloadして設定・version・inventoryを解決するため、反復する軽量な capability predicate としての安定した契約を確認できない。protoは今回、静的な対応対象と識別子変換を残す。
  - system package manager は apt/dnf/pacman等で問い合わせコマンドとパッケージ名・権限・repository semanticsが異なり、今回の対象に共通する読み取りpredicateを確認できていない。systemの既存package identifier mappingは維持し、manager別の安全な問い合わせを確認できた場合に別途拡張する。
- Focus areas:
  - capability detectionとidentifier normalizationを分離し、`mise` と Nix はmanager側のread-only問い合わせへ置き換える。
  - asdfは既存pluginだけを候補にする安全境界を維持しつつ、tool名または必要なaliasに一致するinstalled pluginを直接判定する。
  - proto、system、official、uv-toolの既存ルート実行契約、route order、`skip` 常設、process-local activation、manager/pluginの自動導入禁止を変更しない。
  - route predicateのstdoutは候補リストへ流さず、stderrも通常実行で表示しない。問い合わせは候補列挙から繰り返し呼ばれるため、インストール・初期化・永続設定変更を行わない。
- Explicit exclusions: protoの`versions`・`plugin search`・`plugin info`を候補判定には使わない。asdfのremote plugin一覧を使った新規plugin登録や自動導入、system package managerの横断的なremote検索、manager本体の導入、shell起動ファイル・manager設定の永続変更、install実行分岐の再設計は今回の対象外とする。
- Candidate direction: `mise registry NAME` とNixの完全属性評価をroute availabilityへ追加し、現在の対応表は必要なmanager identifierのalias normalizationとして縮小する。asdfはinstalled plugin listを基に候補を解決し、インストール時にも同じplugin identifierを使う。protoとsystemは安全な共通問い合わせが確認できるまで現行の明示対応を保つ。
- Current conclusion: 全managerを一つの問い合わせ方式へ揃えるのは不適切だが、managerごとに安全なread-only契約がある範囲では静的な対応可否を削減できる。今回の実装候補は `mise`、Nix、installed-only asdfであり、protoは保留、systemは別議論とする。
- Next validation target: `mise registry` の既知名・未知名の終了status、Nix exact attribute probeの引数と終了status、asdf installed pluginの候補解決をmockで確認する。既存route order、alias、候補出力の純粋性、install時のidentifier再利用、no-plugin-install契約も同時に検証する。
- Promotion to DECISIONS.yml: pending（discussion-validationで、`installer-011-2` と `installer-011-8` にmanager-specific read-only probing、alias保持、asdf installed-only、proto/systemの明示的保留を追加する必要性を確認する）。
- Evidence / references (optional): mise CLI registry documentation、Nix `search`/`eval` documentation、asdf plugin command documentation、proto CLI source (`crates/cli/src/app.rs`、`crates/cli/src/commands/plugin/{list,info,search}.rs`)。

### Entry 0035 (2026-08-01T15:11:14Z)
- Discussion-validation: broad scanは `templates/dev-tools.sh` の対応表・route predicate・install分岐、mock test、`DECISIONS.yml` の既存契約、mise/Nix/asdfの公式CLI仕様、protoのCLI sourceを含み、候補判定の副作用と不足plugin policyを比較するのに必要な範囲を覆っている。
- Focus validation: `mise`、Nix、installed-only asdfへ絞ることは、read-only問い合わせが確認できたmanagerだけを採用するという調査結果から導かれる。protoのremote/plugin解決とsystem package managerの異なるrepository semanticsを保留した理由も明示されており、prematureな全体置換にはなっていない。
- Directional fit: manager更新への追従性を高める目的に対し、`*_for_tool` のalias変換を維持しながら対応可否をmanager側へ寄せる方向は適合する。静的対応を完全に削除せず、確認できないmanagerの既存挙動を保つため、今回の変更が動的問い合わせのない環境を不必要に壊すことも避けられる。
- Contract fit: 問い合わせは導入・初期化・plugin登録・永続設定変更を行わず、manager本体と不足pluginの自動導入禁止、`skip` 常設、global候補制限、process-local activation、既存route orderを維持する。probeの非0や未知名はroute非表示として扱い、通常ログや候補stdoutへ診断出力を混入させない。
- Hidden bindings: identifier normalizationとcapability detectionを別責務として保持する必要がある。asdfはinstalled pluginだけを有効なrouteとし、remote一覧だけでは候補にしない。protoとsystemは今回の実装で動的対応を主張せず、将来安全な問い合わせ契約が確認された場合に別途議論する。
- Validation result: PASS。候補方向は元の目的、現在の不変条件、非ゴール、失敗時の安全側挙動に適合し、実装対象と保留対象の境界も明確である。
- Promotion targets: `installer-011-2-installation-backends` にmanager-specific read-only capability probing、probe失敗時のroute非表示、asdf installed-only、proto/system保留を追加する。`installer-011-8-install-method-selection` にmanager queryで確認された候補だけを表示する条件とalias normalizationの分離を追加する。必要なroute predicateのquiet/non-mutating契約は同じdecisionのsub-decisionとして保持する。
- Promotion to DECISIONS.yml: ready（上記2 decisionの契約更新後に実装へ進む）。

### Entry 0036 (2026-08-01T15:24:00Z)
- Implementation result: `templates/dev-tools.sh` のNix routeは候補identifierを `nix eval --read-only --raw nixpkgs#<identifier>.name` で確認し、mise routeは `mise registry NAME` でregistryを確認するよう更新した。どちらも未知のtool名を直接問い合わせ、`python` と `rg` だけmanager固有のalias候補を持つ。
- Implementation result: asdf routeは `asdf plugin list` のinstalled inventoryだけを読み、tool名または `rg -> ripgrep` のaliasに一致するpluginをinstall identifierとして再利用する。remote plugin一覧、plugin登録、install、設定変更は行わない。proto/systemの既存明示mappingとinstall実行は変更していない。
- Test result: `tests/dev-tools.test.sh` は11件、`tests/install.test.sh` は15件がpassした。新しいfixtureはmanagerが新しい `codegraph` を対応した場合のroute追加、alias解決、probe stdoutの抑制、asdf remote plugin queryの不在を確認する。
- Validation evidence: helper／installerのfocused suite、4ファイルの `bash -n`、変更ファイルのeditor diagnostics、`git diff --check` がpassした。Ruby YAML parserは環境に存在せず実行できなかったが、DECISIONS.ymlのeditor diagnosticsと既存のdecision-id構造検査は通過した。
- Promotion to DECISIONS.yml: `installer-011-2-installation-backends` と `installer-011-8-install-method-selection` を `⚠️Implementing` として実装中へ更新した。

### Entry 0037 (2026-08-01T15:24:01Z)
- Implementation-validation: executable checksはdynamic capability fixtureを含むhelper 11件、installer 15件、Bash syntax、editor diagnostics、空白差分でPASSだった。変更されたコード、テスト、decision contractは、mise/Nixのread-only probe、asdf installed-only、alias normalization、proto/system保留の境界で一致している。
- Terminology and record hygiene: `capability probe`、`read-only`、`installed-only`、`alias normalization` の表現を `DECISIONS.yml`、record、test期待値で揃えた。`installer-011` のlinkは本記録を指し、binding ruleはrecordだけに残っていない。
- Status result: `installer-011-2-installation-backends` と `installer-011-8-install-method-selection` を `✅️Implementation Approved` へ更新する。今回の実装で新しいbinding constraintは発生していない。
- Remaining non-binding risk: 実際のNix/mise/asdf managerを使うlive installは実行していない。proto/systemの動的capability queryは安全な共通契約が確認できるまで対象外であり、将来対応する場合は別議論とする。ShellCheckとRuby YAML parserは環境にないため実行していない。

### Entry 0038 (2026-08-02T00:00:00Z)
- Implementation refinement: `status` の `present` 詳細を、`--version` 出力から抽出したversion valueと `command -v` で得た実行ファイルの絶対pathを、キー名なしで `version path` の順に表示する形式へ更新した。例: `python present 3.14.4 /usr/bin/python3`。
- Output behavior: version出力はstdout/stderrを結合し、先頭の非空行から数値version部分を表示する。versionを返さないCLIでも、検出できたpathは表示する。`unavailable` の既存診断、statusの終了status、install/initの処理境界は変更していない。
- Test result: status mockでPython、Ruby、uvのversionとmock executable pathを検証し、helper 11件がpassした。実環境でも `python present 3.14.4 /usr/bin/python3` の出力を確認した。
- Validation evidence: helper suite、Bash syntax、editor diagnosticsをpassした。この表示改善は既存 `installer-011-20-status-mode` の検証詳細表示契約内であり、新しいbinding constraintは発生していない。

### Entry 0039 (2026-08-02T00:00:00Z)
- Why now: 実際の導入を開始する前に、各不足ツールがどのmanager/routeと予定コマンドで導入されるかを確認できる `install --dry-run` が必要になった。既存の `install` は `has_install_route`、`prompt_for_route`、`install_with_route` の順で選択と実行を分けているため、選択結果を表示して実行を止める境界を明示する必要がある。
- Broad-scan findings:
  - route候補は `available_routes_for_tool` がsystem、nix、proto、mise、asdf、official、uv-toolの順でcapability probeを行い、`--global` の候補制限と `skip` を適用する。dry-runでもこの既存判定を再利用し、未導入manager、不足plugin、未対応toolを候補へ戻さない。
  - 実際の導入コマンドは `install_with_system`、`install_with_nix`、`install_with_proto`、`install_with_mise`、`install_with_asdf`、`install_with_official`、`install_with_uv_tool` に分散している。systemのsudo/package manager差、officialのcurl pipeline、manager導入後のPATH refreshや検証用queryがあるため、route名だけでなく予定する主要コマンドを表示できる形が必要である。
  - install時の既存ツールは質問せずpresentとして処理し、未導入ツールだけを一回のroute選択で扱う。dry-runはこの対象境界を維持し、既存ツールを再導入候補にしない。
  - 現行の非対話installは不足ツールをskipする。dry-runは導入を実行しないpreviewであるため、TTYがなくても候補routeと既定routeを表示できる方が「どのmanagerで導入されるかを確認する」という目的に適する。ただし対話環境では既存のroute選択を使い、選択したrouteを予定として表示する候補がある。
  - `prepare_known_tool_paths` による現在プロセス内のPATH準備とmanager capability probeは読み取り・検出に必要だが、install関数に含まれる導入、plugin操作、official pipeline、PATH refresh、AGENTS.md追記はdry-runで実行してはならない。
- Focus areas:
  - `--dry-run` の引数契約をinstall専用の一回限りflagとして定義し、`init`/`status`との併用、`--global`との併用、flag位置、help表示、既存 `--debug` との組み合わせを確定する。
  - route選択と予定コマンドの生成を実行関数から分離し、各routeのmanager名、tool/package/plugin identifier、主要install commandを安全に表示する。予定表示はshell commandとして実行せず、officialのURLやsudo有無も明示する。
  - interactive dry-runでは既存の選択肢から選んだrouteをpreviewし、non-interactive dry-runでは利用可能なconfigured default routeをpreviewする。default routeが利用できない場合は候補routeとskipを表示し、暗黙に別routeを実行しない方向を検証する。
  - dry-runの結果集計、終了status、AGENTS.md、PATH、manager/plugin設定、ネットワークアクセスの境界を既存install/status契約と整合させる。
- Explicit exclusions: dry-runの実行中にsystem package manager、nix、proto、mise、asdf、official installer、uv tool installを実行しない。manager本体・plugin導入、shell起動ファイル・manager設定・AGENTS.md・project設定の変更、install.shの責務変更、JSON等の新しい出力形式、dry-runで選んだrouteの永続化は今回の対象外とする。
- Candidate direction: `install --dry-run` をinstall専用の読み取りpreviewとして追加し、既存ツールはpresent、不足ツールはroute選択またはnon-interactive時のconfigured default routeを `dry-run`/`planned` の結果と予定コマンド付きで表示する。capability probeとalias normalization、route order、`--global`候補制限、`skip`常設は既存どおり維持する。dry-runはpreview上の引数エラーや内部生成失敗を除き、導入結果の成功/失敗を実行したかのようには扱わず、選択・表示が完了すれば終了status 0とする候補である。
- Current conclusion: routeの選択とinstallの副作用を分離する専用preview層が必要であり、install関数をdry-run条件分岐で部分実行するより、予定コマンド生成を共通化してdry-runから呼ぶ方が安全である。`--global`は既存のinstall scopeに従い併用可能とし、init/statusとの併用は引数エラーにする方向が既存mode契約と整合する。
- Next validation target: discussion-validationでは、予定コマンド生成が全routeの実際のinstall commandと一致するか、interactive/non-interactiveのroute選択が既存の一回選択・非対話ポリシーと両立するか、dry-runがmanager probe以外の副作用とネットワークアクセスを避けるか、終了status 0と結果語が既存のfailure/summary契約から逸脱しないかを確認する。特に「non-interactiveでdefaultをpreviewする」ことをactive install policyの例外として明示する必要がある。
- Promotion to DECISIONS.yml: pending（`installer-011-15-mode-selection`、`installer-011-5-failure-and-noninteractive-policy`、`installer-011-8-install-method-selection`、`installer-011-11-process-scoped-manager-activation`、`installer-011-17-failure-diagnostics`に関係する候補をdiscussion-validation後に更新または新規sub-decision化する）。

### Entry 0040 (2026-08-02T00:00:01Z)
- Discussion-validation: broad scanはhelperの引数parser/help、route availabilityとmanager-specific probe、各routeのinstall command、install時のPATH/AGENTS.md更新、mock tests、関連decisionを確認しており、dry-runの選択・予定表示・副作用境界を判断するために必要な範囲を覆っている。
- Directional fit: `install --dry-run` をhelper内のpreviewとして追加し、実際の導入前にmanager/routeと主要コマンドを確認する方向は、ユーザーの目的と `installer-011-7` の責務境界に適合する。install.shの配布・DODKit委譲や、実際のinstall/init処理を広げる必要はない。
- Contract fit: capability probe、alias normalization、route order、`--global`候補制限、`skip`常設を維持し、manager本体・plugin・package・official installer・uv toolの導入、shell/manager/AGENTS.md/project設定の変更、install後PATH refreshをdry-runから除外する。manager-specific probe自体が行う既存のread-only問い合わせは許可するが、導入を開始するnetwork pipelineは実行しない。
- Hidden bindings resolved: 通常installのTTYなしskipは副作用を持つ導入処理の安全策として維持し、`--dry-run`だけは導入を実行しないpreviewであるためnon-interactive時にconfigured default routeを表示する明示例外とする。interactive時は既存の一回だけのroute選択を再利用し、選択したrouteを予定として表示する。既存ツールはpresentとして扱い、missing toolのpreviewだけを作る。
- Result and exit contract: 予定された導入を `planned` としてsummaryへ表示し、previewが最後まで表示できた場合は導入成功・失敗とは扱わず終了status 0とする。利用可能routeがない、またはskipが選ばれた場合はskipとして表示する。引数エラー、予定コマンド生成の不整合などpreview自体の失敗は既存の非0エラー契約に従う。
- Promotion targets: `installer-011-15-mode-selection` に `--dry-run` のinstall限定・flag位置・`--global`併用・init/status拒否を追加する。`installer-011-5-failure-and-noninteractive-policy` にdry-runのnon-interactive default preview例外を追加する。新規 `installer-011-21-dry-run-preview` に、capability probeのみの選択、route-specific planned command、`planned`/`skip`結果、status 0、副作用禁止、既存install処理の非変更をまとめる。
- Validation result: PASS — candidate directionは元の目的、既存のread-only、manager/plugin自動導入禁止、process-scoped activation、AGENTS.md記録、failure diagnostics、mode境界と整合する。実装時は予定コマンドと実行コマンドの一致をrouteごとのmockで検証し、manager/package/installerのログが発生しないこと、interactive/non-interactiveの選択、flag組み合わせ、既存install/init/status回帰を確認する。
- Promotion to DECISIONS.yml: ready（`installer-011-15-mode-selection`、`installer-011-5-failure-and-noninteractive-policy`を更新し、`installer-011-21-dry-run-preview`を追加する）。

### Entry 0041 (2026-08-02T00:00:02Z)
- Implementation result: `templates/dev-tools.sh` に `--dry-run` を追加し、install専用flagとしてparser/helpへ反映した。`init --dry-run` と `status --dry-run` は引数エラーとし、`--global` と `--debug` は既存のinstall flag契約どおり併用できる。top-level `install.sh` の引数透過と配布責務は変更していない。
- Preview result: 既存ツールは `present` として再導入せず、不足ツールはinteractive時に既存の一回のroute選択、non-interactive時にconfigured default routeを使って `planned` として表示する。system、nix、proto、mise、asdf、official、uv-toolそれぞれのmanager/package/plugin/identifierと主要install commandを表示し、利用可能routeなし・skip選択は `skip` とする。
- Side-effect boundary: dry-runはmanager capability probeと現在の実行可能性検証だけを行い、package manager、nix profile install、proto/mise/asdf install、official curl pipeline、uv tool install、manager/plugin操作、install後PATH refresh、AGENTS.md・project・shell・manager設定変更を実行しない。dry-runのsummary表示後は、preview自体が完了すればstatus 0を返す。
- Test result: dry-runのparser、help、init/status拒否、non-interactive default preview、interactive route selection、副作用なし、global preview、全routeのplanned commandをfocused fixtureで確認した。`bash tests/dev-tools.test.sh` は13件、`bash tests/install.test.sh` は15件がpassした。
- Validation evidence: helper／installer suite、Bash syntax、editor diagnostics、`git diff --check`、実環境の `./templates/dev-tools.sh install --dry-run </dev/null | cat` と `install --dry-run --global` を確認した。実環境では既存pythonを `present`、ruby/rgを `system` planned、routeのない対象を `skip` と表示し、global previewもstatus 0だった。ShellCheckは環境に存在しないため未実行である。
- Decision result: `installer-011-5-failure-and-noninteractive-policy`、`installer-011-15-mode-selection`、`installer-011-21-dry-run-preview` を `✅️Implementation Approved` とした。実装により新たなbinding constraintは発生していない。

### Entry 0042 (2026-08-02T00:00:03Z)
- Why now: Homebrewが導入済みの環境でも、現在の候補表示は `system` routeの内部managerとしてしかbrewを扱わず、利用者が `brew` を選択肢として確認できない。ユーザー要望により、route順を `asdf`、`brew`、`official` とし、Homebrewを明示的なパッケージマネージャ候補として表示する必要がある。
- Broad-scan findings:
  - `find_system_package_manager` は現在 apt-get、dnf、yum、pacman、zypper、apk、brewを同じsystem manager探索に含め、`system_package_for_tool` はPython・Ruby・rgのbrew package名も既に持っている。`install_with_system` と `planned_install_command_for_route` にもbrew分岐があるため、package identifierとcommandの知識は既存実装に存在する。
  - `available_routes_for_tool` はsystem、nix、proto、mise、asdf、official、uv-toolだけを候補として出すため、brew-only fixtureでは現在 `system` と `skip` しか表示されない。brewを別routeとして追加する場合、systemがbrewを内部選択し続けると同一導入操作が二重表示になる。
  - route-specificな実装を追加する対象はbrewのavailability、global scope、install dispatch、dry-run planned command、候補順、focused testである。Homebrewのremote package検索、tap追加、brew本体の導入、shell設定変更は既存の「manager本体や不足pluginを自動導入しない」境界により対象外である。
  - Homebrewはユーザーまたはシステムのprefixへ導入したCLIを複数プロジェクトから利用できるため、既存のglobal route契約に従って `--global` 候補にできる。候補の可否は `command -v brew` と既存の明示的なtool-to-package mappingだけで判定し、package availabilityのnetwork queryは行わない。
- Focus areas:
  - system routeからbrewを除外し、brew routeだけが `brew install <package>` を実行・表示する責務境界。
  - `available_routes_for_tool` の `asdf` と `official` の間へのbrew追加、`--global`での候補制限、通常installと `install --dry-run` のidentifier・command一致。
  - Python、Ruby、rgの既存brew package mappingを再利用し、rtk、codegraph、uv、SerenaへHomebrew対応を推測で追加しないこと。
- Explicit exclusions: Homebrewのtapやformula検索、brew本体のインストール、未確認formulaの自動追加、default routeをsystemからbrewへ変更すること、top-level `install.sh` の変更、既存のnix/proto/mise/asdf/official/uv-tool routeの順序変更は今回の対象外とする。
- Candidate direction: `find_system_package_manager` のsystem候補からbrewを外し、`brew_route_available`、`install_with_brew`、brewのplanned command生成とroute dispatchを追加する。候補列はsystem、nix、proto、mise、asdf、brew、official、uv-tool、skipとし、brewはglobal scopeをサポートする。brew routeの既定選択は新設せず、既存のtoolごとのconfigured defaultを維持する。
- Current conclusion: brewは既存system implementationの別名ではなく、ユーザーがmanagerを比較・選択できる独立routeとして追加するのが適切である。systemからbrewを分離すればbrew-only環境で `brew` と表示でき、複数manager環境でも同じ操作を重複表示しない。dry-runの主要commandと実installのcommandは `brew install` で一致させる。
- Next validation target: discussion-validationでは、systemからのbrew分離が既存のLinux package manager契約とdefault routeを壊さないこと、brewのglobal候補が既存scope契約に適合すること、brew-only・複数manager・dry-run・実install dispatchをfocused testで検証可能なこと、Homebrew対応範囲を既存mappingに限定することを確認する。
- Promotion to DECISIONS.yml: pending（`installer-011-2-installation-backends`、`installer-011-8-install-method-selection`、`installer-011-14-global-install-scope`、`installer-011-21-dry-run-preview` のbrew route契約をdiscussion-validation後に更新する）。

### Entry 0043 (2026-08-02T00:00:04Z)
- Discussion-validation: broad scanはsystem manager探索、既存brew package mapping、route availability、通常install、planned command、global候補制限、既存focused test、関連decisionを確認しており、brewを独立routeへ分離するための主要な境界と重複表示のリスクを覆っている。
- Focus validation: `asdf` と `official` の間へbrewを置く候補順、systemからbrewを除外する重複回避、Python・Ruby・rgだけの明示mapping再利用、brew-onlyと複数managerの候補表示、通常installとdry-runのcommand一致に絞ることは、 broad scanから直接導かれている。formula検索やtap管理を対象外にした理由も既存のmanager/plugin自動導入禁止と整合する。
- Directional fit: brewを利用者が選択可能なmanagerとして表示することは、導入前にrouteを確認する目的と既存helperの責務に適合する。top-level `install.sh`、既存manager route、toolごとのconfigured defaultを変更せず、helper内のroute表現だけを拡張するためprematureなscope growthはない。
- Contract fit: systemの既定route、常時 `skip`、manager本体・不足pluginの自動導入禁止、`--global`の全プロジェクト利用可能性、dry-runのcapability probe-only・副作用禁止を維持できる。brewは既に利用可能な `brew` commandと既存package mappingだけで判定し、remote formula queryや永続設定変更を行わない。
- Hidden bindings: brew routeをglobal候補にすること、system routeからbrewを除外して同一commandの二重表示を防ぐこと、brew対応対象を既存mappingのPython・Ruby・rgに限定することは実装を誤ると選択結果へ影響するためactive decisionへ昇格する必要がある。新しい独立decision objectは不要で、関連する4 decisionへ分散して保持する。
- Validation result: PASS。候補方向は元の要求、既存の不変条件、非ゴール、dry-run契約に適合し、必要な実装面とfocused validationも明確である。
- Promotion targets: `installer-011-2-installation-backends` にbrew routeの明示mapping・systemからの分離・manager本体非導入、`installer-011-8-install-method-selection` にroute orderとbrew対象、`installer-011-14-global-install-scope` にbrewのglobal候補、`installer-011-21-dry-run-preview` にbrew planned commandと副作用禁止を追加し、4件を `⚠️Implementing` に更新する。

### Entry 0044 (2026-08-02T00:00:05Z)
- Implementation result: `templates/dev-tools.sh` のsystem manager探索からbrewを分離し、`brew_package_for_tool` と `brew_route_available` を追加した。brew routeはPython、Ruby、rgの既存package mappingだけを利用し、Homebrew formula検索やtap操作は行わない。
- Route integration: 候補順を system、nix、proto、mise、asdf、brew、official、uv-tool、skip とし、brewをglobal候補へ追加した。`install_with_brew` は `brew install <package>` を実行し、`planned_install_command_for_route` と `install_with_route` も同じbrew commandへ接続した。system routeからbrew実行分岐を除去したため、brew-only環境で同一操作がsystemとbrewへ重複表示されない。
- Dry-run result: interactiveな `install --dry-run` でbrewを選択すると `brew: brew install python` のplanned detailを表示し、non-interactiveのconfigured default、既存route、AGENTS.md非変更、manager command非実行の既存契約を維持した。
- Test result: brew-only route、`asdf` の後にbrewが現れる順序、global filtering、Python・Ruby・rg package mapping、通常install dispatch、planned command、interactive dry-run summary、副作用なしをfocused fixtureで確認した。`bash tests/dev-tools.test.sh` は14件、`bash tests/install.test.sh` は15件がpassした。
- Validation evidence: 4ファイルのeditor diagnostics、全Bash対象の `bash -n`、`git diff --check`、decision ID uniquenessを確認した。top-level `install.sh` は変更していない。ShellCheckは環境に存在しないため未実行である。
- Decision result: `installer-011-2-installation-backends`、`installer-011-8-install-method-selection`、`installer-011-14-global-install-scope`、`installer-011-21-dry-run-preview` を `✅️Implementation Approved` とした。実装により新たなbinding constraintは発生していない。

### Entry 0045 (2026-08-02T00:00:06Z)
- Why now: `status` currently reports each development tool's verified version and executable path, but it does not show whether the package-manager commands used by the installation routes are available, what versions they provide, or where they are installed. The user requested the package-manager side to be visible in the same status view.
- Active baseline: The relevant contracts are `installer-011-2-installation-backends`, `installer-011-8-install-method-selection`, `installer-011-11-process-scoped-manager-activation`, `installer-011-13-logging-and-data-output`, `installer-011-17-failure-diagnostics`, and `installer-011-20-status-mode`. The current focused helper suite passes 14 tests.
- Broad-scan findings:
  - The route layer already names the concrete manager commands: system package-manager alternatives (`apt-get`, `dnf`, `yum`, `pacman`, `zypper`, `apk`), `nix`, `proto`, `mise`, `asdf`, `brew`, and `uv`.
  - The existing tool status path already provides the required read-only primitives: `command -v` for the executable path and `--version` output parsing for the displayed version. Reusing that verification contract avoids package-database-specific behavior that would differ across distributions and managers.
  - `official` is an installer route backed by `curl`, not a package manager, so it should not be represented as a package-manager row. `uv` is both a tracked development tool and the manager used for Serena; showing it in the package-manager section makes that dual role explicit even though its tool row remains unchanged.
  - Package-manager availability is environmental information, not a required dependency for every run. Missing package managers must be displayed but must not change the existing status exit rule, which reflects unavailable development tools.
- Focus areas:
  - Add a status-only package-manager inventory using the same `present`/`unavailable`, version, path, and verification-detail format as tool rows.
  - Keep the inventory read-only: no package queries, route selection, installation, manager activation, PATH mutation, AGENTS.md update, or project initialization.
  - Render manager rows after the existing tool rows, preserve tool order and status exit semantics, and cover present, version-failed, and missing manager cases with focused mocks.
- Explicit exclusions: Package database inspection (for example, whether a specific formula or distro package is installed), package ownership/path resolution, new manager routes, official installer status, live third-party manager commands, and changes to install/init/dry-run behavior are out of scope. The requested package-manager status means the manager executable's availability, version, and executable path.
- Candidate direction: Add a concrete package-manager command list and a shared verified-command lookup so status can display each manager command in a separate `Package-manager status:` section. Keep manager failures informational and preserve `STATUS_UNAVAILABLE_COUNT` for development-tool rows only.
- Current conclusion: The candidate direction satisfies the requested visibility with the smallest ownership change: status gains an additional read-only inventory while route selection and installation behavior remain unchanged. The manager list should use the same concrete command names as the existing route layer so displayed status and selectable routes cannot drift.
- Next validation target: discussion-validation should confirm that manager-command inventory is the correct interpretation of package-manager-side status, that every listed command is safe to probe with `--version`, that manager absence does not alter the established status exit contract, and that the shared verification path preserves tool diagnostics.
- Promotion to DECISIONS.yml: pending (update `installer-011-20-status-mode` and, if needed, `installer-011-17-failure-diagnostics` with the package-manager inventory and informational-failure boundary after validation).

### Entry 0046 (2026-08-02T00:00:07Z)
- Discussion-validation: The bounded scan covered the status verifier, route-specific manager names, install/dry-run dispatch, focused status tests, and the active read-only, failure-diagnostics, and exit-status contracts. It included the main omission risk: conflating manager executable status with distro-specific package database inspection.
- Focus validation: A separate manager inventory section is justified because the route layer has concrete manager commands while a tool may have multiple possible routes. Using the same verified-command path keeps version/path semantics consistent and avoids making route selection or package metadata the responsibility of status.
- Directional fit: Reporting manager executable availability, version, and path directly serves the request without changing the existing tool rows, route ordering, install/init behavior, or distribution boundary. Excluding `official`/`curl` is correct because it is an installer transport rather than a package manager.
- Contract fit: Probing each manager with `command -v` and `--version` is read-only and does not perform manager capability queries that could mutate state. Manager rows may be `unavailable` without incrementing the development-tool unavailable count, so the existing status exit contract remains limited to tool availability. Existing command, exit-code, and verification-detail reporting remains applicable to both inventories.
- Hidden bindings: The concrete manager list must remain synchronized with route-layer names, the manager section must not be treated as a second install target set, and package-manager absence must remain informational. These are implementation constraints and will be promoted into `installer-011-20-status-mode`; no separate decision object is needed.
- Validation result: PASS. The candidate direction fits the original request and active invariants, and the focused implementation/test surface is clear.
- Promotion targets: Update `installer-011-20-status-mode` with the read-only package-manager inventory, concrete route-manager list, shared version/path display, and informational manager failures. Keep `installer-011-17-failure-diagnostics` unchanged because its existing command and exit-code contract already covers the shared verifier.

### Entry 0047 (2026-08-02T00:00:08Z)
- Implementation result: `templates/dev-tools.sh` now shares the verified-command implementation between development tools and package-manager commands. In `status` mode it renders a separate `Package-manager status:` section for `apt-get`, `dnf`, `yum`, `pacman`, `zypper`, `apk`, `nix`, `proto`, `mise`, `asdf`, `brew`, and `uv`, showing `present` or `unavailable`, the parsed version, the executable path, and verification details.
- Boundary result: Package-manager probing runs only in `status`, uses `command -v` and `--version`, and does not run package queries, route selection, installation, activation, PATH changes, AGENTS.md updates, or project initialization. Manager failures remain informational and do not change the existing development-tool status exit count.
- Test result: The focused helper suite passes 14 tests, including manager present/version/path, version failure diagnostics, missing manager display, and successful status with an unavailable manager. The installer suite passes 15 tests, confirming distribution and delegation remain unchanged.
- Validation evidence: Bash syntax checks, editor diagnostics for the changed helper/tests/decision/record, `git diff --check`, and a live Linux `status` run passed. The live output confirmed `python present 3.14.4 /usr/bin/python3` and `apt-get present 3.2.0 /usr/bin/apt-get`.
- Decision result: `installer-011-20-status-mode` is ready to return to `✅️Implementation Approved`. No new binding constraint was discovered beyond the promoted manager inventory contract.

### Entry 0048 (2026-08-02T00:00:09Z)
- Implementation-validation: Executable validation, artifact alignment, and terminology alignment all pass. The manager names match the concrete route-layer commands, the display uses the existing `present`/`unavailable` and version/path format, and status still processes all tools before returning the established tool-based exit status.
- Decision-record hygiene: `installer-011-20-status-mode` retains the link to this record and now contains the manager inventory, read-only boundary, display contract, and informational failure rule. `installer-011-17-failure-diagnostics` remains unchanged because the shared verifier already covers manager command and exit-code details.
- Closeout result: PASS. No implementation blocker remains. Live third-party installation and package-database inspection were intentionally not performed because they are outside this status-only scope.

### Entry 0049 (2026-08-02T00:00:10Z)
- User refinement: In `status` output, show `Package-manager status:` before `Development-tool status:` so the available installation backends are visible before the tool results they support.
- Implementation result: `print_status_summary` now renders the package-manager rows first. The focused status test asserts the heading order while preserving the existing row content and exit-status behavior.
- Validation: `bash tests/dev-tools.test.sh` passes all 14 focused tests. The ordering refinement introduces no new side effects or decision scope.

### Entry 0050 (2026-08-02T00:00:11Z)
- User refinement: `uv` appears in both status sections because it is both a development tool and Serena's installation manager. The duplicate row is less clear than the role distinction it represents.
- Decision: Do not add a third status layer for this case. Keep the manager inventory limited to manager-only commands and treat the `uv` tool row as the canonical availability/version/path status. Serena's `uv-tool` installation route remains unchanged.
- Implementation result: Removed `uv` from `PACKAGE_MANAGER_NAMES` and added a focused assertion that the status output contains exactly one `uv` row.
- Validation target: Re-run the helper status suite, syntax/diagnostic checks, and installer regression suite. Package metadata inspection and a manager-to-tool relationship section remain out of scope unless a later request needs that information.

### Entry 0051 (2026-08-02T00:00:12Z)
- Implementation-validation: `uv` is now displayed once in `Development-tool status:` while the manager-only inventory remains in `Package-manager status:`. No third status layer was introduced.
- Validation result: The helper suite passes 14 tests, the installer suite passes 15 tests, Bash syntax checks pass, editor diagnostics report no errors, and the live status output contains exactly one `uv` row.
- Closeout result: PASS. The `uv-tool` installation route and existing status exit semantics are unchanged. A manager-to-tool relationship section remains a future scope only if route provenance or package metadata needs to become user-facing.

### Entry 0052 (2026-08-02T00:00:13Z)
- Why now: In the current environment `curl` is not on `PATH`, so `./templates/dev-tools.sh --dry-run` reports `rtk`, `codegraph`, and `uv` as having no installation method even though their official installer URLs are embedded in the helper. The preview should show that URL-backed official route as the planned installation.
- Active baseline: The relevant contracts are `installer-011-2-installation-backends`, `installer-011-5-failure-and-noninteractive-policy`, `installer-011-15-mode-selection`, and `installer-011-21-dry-run-preview`. `official_route_available` currently requires both a mapped installer URL and an executable `curl`; `planned_install_command_for_route` already renders the complete `curl ... | sh` pipeline without executing it.
- Broad-scan findings:
  - Official route identity comes from `official_installer_url_for_tool`, while `curl` is the execution transport. The preview only needs the former to describe the planned command; it performs no network or installer action.
  - Normal install should continue requiring `curl` before exposing `official`, otherwise an interactive install could offer a route that cannot execute in the current environment and then fail with a missing transport.
  - The non-interactive dry-run rule already permits configured default routes to be shown without performing installation. Treating URL-backed official routes as previewable is a narrow extension of that existing exception.
- Focus areas:
  - Make official route availability mode-aware: URL mapping is sufficient in `install --dry-run`, while normal install retains the `curl` prerequisite.
  - Preserve the existing planned command, route order, `--global` behavior, no-network boundary, and actual install dispatch.
  - Add a focused no-`curl` dry-run fixture that verifies `official` is planned for `rtk`, `codegraph`, and `uv`, while non-dry-run route filtering still excludes it.
- Explicit exclusions: Automatically installing `curl`, executing official installers, changing official URLs, adding a new transport fallback, changing normal install prompts, and changing `Serena`'s `uv-tool` dependency are out of scope.
- Candidate direction: When `DRY_RUN=1`, let `official_route_available` succeed from the existing URL mapping alone. Keep the current `curl` check for normal install. The existing planned command will expose the URL and pipeline as the preview detail.
- Current conclusion: This is the smallest change that makes dry-run accurately describe the official route already encoded in the helper without claiming that the current environment can execute it. No extra status or relationship layer is needed.
- Next validation target: discussion-validation should confirm that the mode-aware predicate preserves normal install safety, that no-`curl` dry-run previews all three URL-backed tools, and that preview remains side-effect-free and status 0.
- Promotion to DECISIONS.yml: pending (update `installer-011-5-failure-and-noninteractive-policy` and `installer-011-21-dry-run-preview` with the URL-mapping-only official preview rule).

### Entry 0053 (2026-08-02T00:00:14Z)
- Discussion-validation: The bounded scan covered the official URL mapping, route availability predicate, dry-run planned-command generation, normal install dispatch, non-interactive policy, existing focused fixtures, and the active dry-run contract. It identified the key distinction between previewing an official command and being able to execute its `curl` transport.
- Focus validation: A mode-aware official predicate is justified because the two modes have different obligations: dry-run describes a non-executing command, while normal install must offer only an executable route. The existing URL mapping and planned command provide a stable preview source without any additional network probe.
- Directional fit: Previewing `official` for `rtk`, `codegraph`, and `uv` directly addresses the requested output and keeps the implementation inside `templates/dev-tools.sh`. The change does not alter route order, installer URLs, normal install behavior, or the `uv-tool` route for Serena.
- Contract fit: The candidate preserves the dry-run no-install/no-network boundary, configured-default preview behavior, `--global` filtering, and preview status 0. It also preserves normal install's `curl` prerequisite, manager/plugin non-installation, and failure diagnostics.
- Hidden bindings: The official route must remain URL-backed, the dry-run preview must not imply that `curl` is installed, and normal install must not expose an unusable official route. These are implementation constraints for the two existing decisions; no new decision object is needed.
- Validation result: PASS. The candidate direction fits the request and active invariants, and the focused no-`curl` fixture can falsify both accidental normal-install relaxation and missing dry-run previews.
- Promotion targets: Update `installer-011-5-failure-and-noninteractive-policy` and `installer-011-21-dry-run-preview` with the mode-aware official route rule, then implement and test the helper-only change.

### Entry 0054 (2026-08-02T00:00:15Z)
- Implementation result: `official_route_available` now treats the existing installer URL mapping as sufficient during `install --dry-run`, while normal install continues to require an executable `curl`. The existing `planned_install_command_for_route` output exposes the full official `curl ... | sh` command and URL without executing it.
- Test result: Added a no-`curl` fixture covering `rtk`, `codegraph`, and `uv` official routes, their planned URLs, and normal-install exclusion. The helper suite passes 15 focused tests.
- Live result: In the current environment, `./templates/dev-tools.sh --dry-run </dev/null` displays all three tools as `planned official` with their embedded URLs and returns status 0. No installer or network command ran.
- Decision result: `installer-011-5-failure-and-noninteractive-policy` and `installer-011-21-dry-run-preview` are ready to return to `✅️Implementation Approved`.

### Entry 0055 (2026-08-02T00:00:16Z)
- Implementation-validation: The mode-aware predicate preserves normal installation safety and expands only the non-executing preview. Route order, `--global` filtering, official URL constants, planned command generation, no-network behavior, and existing install/init/status boundaries remain aligned.
- Executable validation: Helper 15 tests, installer 15 tests, Bash syntax checks, editor diagnostics, and live no-`curl` dry-run verification all pass. The live preview returns 0 and shows URL-backed official plans for `rtk`, `codegraph`, and `uv`.
- Decision-record hygiene: The active contracts now state the URL-mapping-only official preview rule, while the record retains the rationale and validation evidence. No new binding constraint remains.
- Closeout result: PASS. Automatically installing `curl` or adding a transport fallback remains out of scope.

### Entry 0056 (2026-08-02T00:00:17Z)
- Why now: Interactive `install --dry-run` currently prints each route list before the question that asks which route to choose, so the tool and the question are visually separated. When `uv` is planned but not installed during the preview, Serena is reported with a generic no-installation-method warning even though its fixed dependency route is `uv-tool`.
- Findings / trade-offs:
  - `prompt_for_route` owns the display order. It can print the question heading first, then the route choices, and finally a short selection prompt without changing route ordering, default selection, or one-prompt-per-tool behavior.
  - Serena must continue to use `uv tool install -p 3.13 serena-agent` only when `uv` is available; a dry-run must not pretend that a planned `uv` route has already installed or activated `uv`.
  - The no-route branch can use an informational dependency message for Serena while retaining the existing `skipped` result and non-zero behavior for actual install failures. Other tools keep the generic warning.
- Focus areas: interactive prompt readability, Serena's uv dependency message in dry-run and normal install, existing route order/defaults, and focused output assertions.
- Explicit exclusions: no route reorder, no implicit uv installation, no new Serena route, no change to dry-run result semantics, and no changes to `install.sh` distribution.
- Current conclusion: Show the route-selection question before its choices and finish with `Selection:` for input. When Serena has no currently available route, report that Serena is installed via uv and is skipped until uv is available, using an informational message rather than the generic warning.
- Next validation target: discussion-validation should confirm that the prompt remains one selection per missing tool, that the route list and default remain unchanged, and that Serena's message preserves the uv-only dependency and existing skipped result.
- Promotion to DECISIONS.yml: pending (`installer-011-1-tool-order-and-prompt`, `installer-011-2-installation-backends`, and `installer-011-8-install-method-selection` may only need wording clarification if the validation finds a binding contract change).

### Entry 0057 (2026-08-02T00:00:18Z)
- Discussion-validation: The bounded scan covered `prompt_for_route`, route availability/default selection, install and dry-run processing, the existing focused prompt tests, and the active uv/Serena decisions. It found no need to change route order, capability probes, dependency sequencing, or dry-run side-effect boundaries.
- Focus validation: Moving the question heading before the route list and adding a final `Selection:` input line preserves the existing one-read interaction and makes the tool being configured visible before its choices. The route list, numbering, default route, and string/number selection behavior remain unchanged.
- Directional fit: Replacing only Serena's generic no-route warning with an informational uv dependency message directly addresses the confusing output while preserving the fact that Serena cannot be installed until `uv` is available. The actual `uv-tool` route and `skipped` result remain unchanged.
- Contract fit: The candidate preserves `installer-011-1`'s tool order and one prompt per missing tool, `installer-011-2`/`installer-011-8`'s uv-only Serena route, `installer-011-5`'s dry-run and failure behavior, and `installer-011-13`'s user-facing log levels.
- Hidden bindings: None. This is a presentation and diagnostic-message refinement over existing contracts, not a new route or dependency behavior.
- Validation result: PASS. Existing decisions are sufficient; implementation can proceed without changing `DECISIONS.yml`.
- Promotion targets: none; apply the helper and focused test changes, then record implementation and closeout results.

### Entry 0058 (2026-08-02T00:00:19Z)
- Implementation result: `prompt_for_route` now emits the tool-specific question first, then the unchanged route list, and finally `Selection:` before the existing single input read. The configured default, route order, numeric/string parsing, `/dev/tty` fallback, and one-prompt-per-missing-tool behavior are unchanged.
- Serena result: Both dry-run and install no-route branches retain the `skipped` result and now use an informational message stating that Serena is installed via uv and is skipped because uv is unavailable. Serena remains available only through the existing `uv-tool` route.
- Test result: The helper tests assert question-before-options ordering, the final selection label, and the Serena uv dependency message.
- Implementation scope: Only `templates/dev-tools.sh` and `tests/dev-tools.test.sh` changed for this request; `install.sh`, README content, route semantics, and distribution behavior were not changed.

### Entry 0059 (2026-08-02T00:00:20Z)
- Implementation-validation: The changed helper behavior matches `installer-011-1`'s tool order and one-prompt contract, `installer-011-2`'s uv-only Serena route, the existing dry-run boundary, and the user-facing log-level contract. No terminology drift or new binding constraint was found.
- Executable validation: `bash tests/dev-tools.test.sh` passes all 15 focused helper tests; `bash tests/install.test.sh` passes all 15 installer tests; Bash syntax checks, editor diagnostics, and `git diff --check` pass.
- Decision-record hygiene: The applicable decisions remain `✅️Implementation Approved`, their link still points to this record, and no decision promotion is required because the implementation changes presentation and diagnostics without changing an active constraint.
- Closeout result: PASS. The remaining limitation is unchanged: Serena is skipped when uv is unavailable in the current execution; no implicit uv installation was added.

### Entry 0060 (2026-08-02T00:00:21Z)
- Why now: The user requested that installation methods be displayed in the preference order `nix`, `proto`, `mise`, `asdf`, `brew`, `system`, `official`, `skip`. The active helper currently emits `system` first, which makes the system route appear preferred over manager-backed routes.
- Active baseline: The relevant contracts are `installer-011-1-tool-order-and-prompt`, `installer-011-2-installation-backends`, `installer-011-8-install-method-selection`, and `installer-011-21-dry-run-preview`, all currently `✅️Implementation Approved`. `available_routes_for_tool` owns candidate order, while `default_route_for_tool` separately owns the configured blank-input default.
- Broad-scan findings:
  - The route order is shared by normal install and dry-run, so one change to `available_routes_for_tool` updates both interactive displays and numeric selection indexes.
  - `system` is now separate from `brew`; moving the route in the shared list must not reintroduce brew as a system-manager alias or change the existing package mapping.
  - `uv-tool` is a dependency-specific route for Serena and is not part of the user's general manager sequence. It must remain available before `skip` when `uv` is executable, otherwise Serena's existing installation contract would be lost.
  - Configured defaults are intentionally separate from display order. Keeping them fixed preserves the established blank-input behavior while changing the visible route preference order requested by the user.
- Focus areas: shared route candidate order, normal and dry-run prompt numbering, preservation of configured defaults, Serena's `uv-tool` placement, and regression assertions for manager filtering and planned command selection.
- Explicit exclusions: no change to route availability probes, package mappings, `--global` scope, manager installation policy, official installer URLs, Serena dependency semantics, or top-level `install.sh` distribution.
- Current conclusion: Change the shared candidate order to `nix`, `proto`, `mise`, `asdf`, `brew`, `system`, `official`, `uv-tool`, `skip`. Keep per-tool configured defaults unchanged; the requested ordering controls display and numeric selection, not blank-input fallback.
- Next validation target: discussion-validation should confirm that the new order is reflected in normal and dry-run candidates, that `system` and `brew` remain distinct, that `uv-tool` remains Serena-only, and that configured defaults and global filtering remain unchanged.
- Promotion to DECISIONS.yml: pending (`installer-011-8-install-method-selection` and `installer-011-21-dry-run-preview` should be updated with the shared route order and preserved configured-default rule).

### Entry 0061 (2026-08-02T00:00:22Z)
- Discussion-validation: The bounded scan covered the shared route candidate generator, route-specific availability and install dispatch, dry-run planned-command reuse, default-route selection, brew/system separation, Serena's uv dependency, global filtering, and the existing focused tests. This covers the main omission risk: changing only visible text while leaving numeric selection or dry-run order inconsistent.
- Focus validation: The narrowed focus on the shared candidate list and the separate configured-default function is justified because both normal prompts and dry-run reuse the candidate list, while blank input is resolved independently. Keeping `uv-tool` as a specialized entry before `skip` preserves its existing dependency contract without changing the requested general manager sequence.
- Directional fit: The candidate order `nix`, `proto`, `mise`, `asdf`, `brew`, `system`, `official`, `uv-tool`, `skip` directly serves the user's requested display preference. Preserving configured defaults avoids an unrelated change to blank-input behavior.
- Contract fit: Capability probes, alias normalization, manager/plugin non-installation, global route filtering, dry-run side-effect boundaries, one prompt per missing tool, and official/uv-tool semantics remain unchanged. The route order is the only binding behavior being revised.
- Hidden bindings: The same order must be represented in `available_routes_for_tool`, the dry-run decision contract, and focused route-order assertions. No new decision object is needed; the existing route-selection and dry-run decisions are the correct owners.
- Validation result: PASS. The candidate direction fits the original request and active invariants, and the focused implementation/test surface is clear.
- Promotion targets: Update `installer-011-8-install-method-selection` and `installer-011-21-dry-run-preview` with the shared route order and explicit preservation of per-tool configured defaults. Set both to `⚠️Implementing` before the helper/test change.

### Entry 0062 (2026-08-02T00:00:23Z)
- Implementation result: `available_routes_for_tool` now emits routes in the promoted order `nix`, `proto`, `mise`, `asdf`, `brew`, `system`, `official`, `uv-tool`, `skip`. The same shared list drives normal install prompts, numeric selection, and dry-run previews.
- Compatibility result: Per-tool configured defaults remain unchanged: `system` for Python/Ruby/rg, `official` for RTK/CodeGraph/uv, and `uv-tool` for Serena. `brew` remains a separate route from `system`, and the Serena route remains gated by executable `uv`.
- Test result: The helper suite passes all 15 focused tests, including route filtering, global filtering, preserved defaults, and dry-run prompt ordering. The installer suite passes all 15 tests. Bash syntax, editor diagnostics, and `git diff --check` also pass.
- Implementation scope: Only `templates/dev-tools.sh` and `tests/dev-tools.test.sh` changed for the implementation. `install.sh`, route probes, install commands, and distribution behavior were not changed.

### Entry 0063 (2026-08-02T00:00:24Z)
- Implementation-validation: The shared route order is aligned across the helper implementation, normal prompt behavior, dry-run behavior, and the two active decision contracts. The requested general sequence is visible while the specialized `uv-tool` route remains before `skip` for Serena.
- Artifact alignment: Focused assertions cover the new manager order, `--global` filtering order, default-route preservation, and the first displayed dry-run option. Existing tests continue to cover brew/system separation, planned command generation, and helper distribution.
- Terminology and record hygiene: `DECISIONS.yml` and this record use the same route names and order. No new binding constraint was discovered, and no implementation rule remains only in the record.
- Validation result: PASS. The two promoted decisions can return to `✅️Implementation Approved`; live third-party installation was not performed because this change only controls display and selection order.

### Entry 0064 (2026-08-02T00:00:25Z)
- Why now: The dry-run summary currently reports a user-selected skip as `dry-run selected skip`, while normal install reports the equivalent choice as `user selected skip`. The user requested the common `selected skip` wording because the mode distinction is not useful in this result detail.
- Findings / trade-offs: Both branches represent the same explicit route selection and already use the `skipped` result state. The dry-run contract requires skipped selections to be displayed but does not require mode-specific detail text. This is a presentation-only change; route selection, installation, side-effect boundaries, and exit status remain unchanged.
- Focus areas: Normalize the selected-skip result detail in `process_dry_run_tool` and `process_install_tool`, then add a focused assertion that dry-run output uses the common wording.
- Explicit exclusions: No change to non-interactive skip wording, no-route diagnostics, route order, default selection, dry-run semantics, or installation behavior.
- Current conclusion: Use exactly `selected skip` as the result detail for an explicit skip in both normal install and dry-run.
- Next validation target: discussion-validation should confirm that the wording change stays within the existing skip-result contract and does not conflate explicit selection with non-interactive or unavailable-route skips.
- Promotion to DECISIONS.yml: none; this is a user-facing wording refinement within the existing decision contract.

### Entry 0065 (2026-08-02T00:00:26Z)
- Discussion-validation: The bounded scan covered both explicit-skip branches, the no-route and non-interactive skip branches, dry-run summary rendering, focused test fixtures, and the active failure/non-interactive and dry-run decisions. It distinguishes explicit selection from other skip reasons, so the proposed wording does not erase meaningful diagnostics.
- Directional fit: Reusing `selected skip` for explicit choices directly matches the user's requested output while preserving the existing `skipped` result state and all mode behavior.
- Contract fit: No-route messages, non-interactive skip behavior, route selection, dry-run side-effect boundaries, and exit-status rules remain unchanged. No new binding rule is needed.
- Validation result: PASS. The helper and focused test can be updated without decision promotion.
- Promotion to DECISIONS.yml: none.

### Entry 0066 (2026-08-02T00:00:27Z)
- Implementation result: Explicit skip selections now use the common result detail `selected skip` in both `process_install_tool` and `process_dry_run_tool`. Non-interactive skips and unavailable-route diagnostics retain their existing details and messages.
- Test result: The helper tests now assert `selected skip` for both normal install and interactive dry-run. The focused helper suite passes all 15 tests.
- Implementation scope: Only `templates/dev-tools.sh` and `tests/dev-tools.test.sh` changed for this wording refinement; route behavior, installation, and distribution contracts were not changed.

### Entry 0067 (2026-08-02T00:00:28Z)
- Implementation-validation: Explicit skip output is aligned across normal install and dry-run without conflating it with non-interactive or unavailable-route skips. The existing `skipped` result state and summary format remain unchanged.
- Artifact alignment: Focused assertions cover both execution modes, while the active dry-run and failure/non-interactive decisions remain sufficient and approved.
- Terminology and record hygiene: The user-facing phrase is consistently `selected skip`; no decision promotion or status change is required.
- Validation result: PASS. Remaining risk is limited to the existing untested live third-party installation paths, which this presentation-only change does not affect.

### Entry 0068 (2026-08-02T00:00:29Z)
- Why now: Selecting the proto route for Ruby failed when proto's source-build workflow tried to run `apt update` without permission. The user requested a neighboring `first-setup.sh` that installs the required libraries before using the development-tool helper.
- Active baseline: `templates/dev-tools.sh` currently runs `proto install ruby latest --yes` as the current user, while the system route separately uses `sudo` for system package installation. Proto 0.59.0's install help exposes no sudo or dependency-install option, and proto is installed under the user's `~/.proto`.
- Findings / trade-offs:
  - The preparation script should elevate only the `apt-get` commands. Running `sudo proto` could move proto's configuration and Ruby installation into root's environment, after which the helper's user-side command verification would not find the result.
  - The required package set is the Ruby build dependency list reported by proto: `patch`, `libdb-dev`, `build-essential`, `libyaml-dev`, `libssl-dev`, `libreadline6-dev`, `libffi-dev`, `autoconf`, `libgdbm-dev`, `zlib1g-dev`, `rustc`, `libncurses5-dev`, `libgdbm6`, and `libgmp-dev`.
  - The requested artifact is a standalone apt-specific preparation helper beside `templates/dev-tools.sh`. It should not modify shell profiles, proto configuration, manager settings, or run proto/tool installation itself. Top-level `install.sh` distribution is outside this request because the user asked for the neighboring template file only.
- Focus areas: `templates/first-setup.sh` argument handling, apt availability, root-versus-sudo selection, deterministic package list, update-before-install order, and actionable failure behavior.
- Explicit exclusions: no `sudo proto` invocation, no automatic Ruby or other CLI installation, no package-manager fallback, no persistent PATH or manager configuration, and no `install.sh` asset integration.
- Current conclusion: Add an executable Bash helper that requires `apt-get`, runs `apt-get update`, then installs the fixed Ruby/proto build dependency list with `sudo` only when the current user is not root.
- Next validation target: discussion-validation should confirm the root/sudo boundary, package list fidelity to the observed proto failure, update-before-install order, non-Debian failure behavior, and the intentional manual-only distribution boundary.
- Promotion to DECISIONS.yml: pending (add `installer-011-22-first-setup-dependencies` under the dev-tools decisions).

### Entry 0069 (2026-08-02T00:00:30Z)
- Discussion-validation: The bounded scan covered the proto route implementation, proto install help, existing system-route sudo handling, package-manager scope decisions, deployment assets, and the requested neighboring template location. It identified the main safety risk: elevating the manager command instead of only the OS package operation.
- Focus validation: A standalone apt preparation helper is justified because the missing dependencies belong to proto's Ruby source build, while the actual proto install must remain user-owned. The fixed package list and update-before-install ordering are directly grounded in the observed failure output.
- Directional fit: The candidate directly addresses the failed first setup without changing route selection or making proto installation implicit. Keeping it out of `install.sh` avoids expanding the distribution contract beyond the explicit request.
- Contract fit: The helper preserves the existing manager non-configuration boundary, process-scoped PATH policy, and user-owned proto installation model. Non-apt systems fail clearly instead of silently selecting another package manager.
- Hidden bindings: Root/sudo applies only to `apt-get`; the package list must remain explicit and the script must not invoke proto. These are implementation constraints for the new decision.
- Validation result: PASS. The candidate is ready for promotion and implementation.
- Promotion targets: Add `installer-011-22-first-setup-dependencies` with the package list, sudo boundary, command order, no-proto/no-persistent-config boundary, and manual-only template scope.

### Entry 0070 (2026-08-02T00:00:31Z)
- Implementation result: Added executable `templates/first-setup.sh` with the fixed proto Ruby build dependency list. It checks for `apt-get`, uses `sudo apt-get` only for non-root users, runs `update` before `install -y`, supports `--help`, and rejects unsupported arguments.
- Boundary result: The script does not invoke proto or Ruby, change PATH or shell configuration, modify manager state, or alter `install.sh` distribution. It reports clear errors when apt-get or required sudo access is unavailable.
- Validation result: A mocked non-root run confirmed `sudo apt-get update` precedes `sudo apt-get install -y` and that all 14 requested packages are passed. The actual host apt database was not modified.

### Entry 0071 (2026-08-02T00:00:32Z)
- Implementation-validation: The artifact matches `installer-011-22-first-setup-dependencies`: apt-only preparation, root/sudo boundary, explicit package set, no proto invocation, and manual-only template scope.
- Executable validation: The new script passes `bash -n`, `--help`, executable-permission checks, and the mocked apt command test. Existing helper and installer suites pass 15 tests each; related Bash syntax, editor diagnostics, and `git diff --check` also pass.
- Terminology and record hygiene: The package names and sudo boundary are consistent between the decision, implementation, and record. No additional binding constraint was discovered.
- Closeout result: PASS. Live apt installation remains intentionally unexecuted to avoid changing the host system; the user can run the new helper explicitly before selecting proto for Ruby.

### Entry 0072 (2026-08-02T00:00:33Z)
- Validation follow-up: Added the first-setup mock command check to `tests/dev-tools.test.sh`, preserving the project's two-file shell test convention. The test verifies update-before-install ordering, the complete dependency list, non-root sudo routing when applicable, and the absence of proto invocation.
- Updated executable result: The focused helper suite passes 16 tests, including the new first-setup case. No implementation or decision contract changed.

### Entry 0073 (2026-08-02T00:00:34Z)
- Why now: The first-setup dependency bootstrap has a separate executable and lifecycle from the development-tool helper. The user requested that its decision live under a dedicated `first-setup` category and that its focused test not be mixed into `tests/dev-tools.test.sh`.
- Broad-scan findings: `DECISIONS.yml` currently has a top-level `dev-tools` category containing `installer-011-22-first-setup-dependencies`, while `tests/dev-tools.test.sh` contains the only first-setup test case. The general test-naming decision currently names only the dev-tools and installer suites.
- Direction: Move the existing decision object, without changing its ID or dependency/privilege contract, into a new top-level `first-setup` category. Move the mock test into `tests/first-setup.test.sh`, remove its path constant and test registration from the dev-tools suite, and update the shared test-naming contract to include all three focused suites.
- Explicit exclusions: no change to `templates/first-setup.sh` behavior, package list, root/sudo boundary, `install.sh` distribution, or `templates/dev-tools.sh` route behavior.
- Discussion-validation: The split follows the actual ownership boundary and reduces unrelated suite coupling. Preserving the decision ID keeps existing record references stable; the new test path becomes an explicit first-setup contract rather than an implicit dev-tools fixture.
- Validation result: PASS. Promotion targets are the `first-setup` category placement, the shared test-name update, and the new standalone first-setup test file.

### Entry 0074 (2026-08-02T00:00:35Z)
- Implementation result: Moved `installer-011-22-first-setup-dependencies` into the top-level `first-setup` category without changing its ID or apt/root/sudo contract. The decision now names `tests/first-setup.test.sh` as its focused test.
- Test result: Moved the mock apt test into `tests/first-setup.test.sh` and removed the first-setup fixture from `tests/dev-tools.test.sh`. The first-setup suite passes 1 test, the dev-tools suite passes 15 tests, and the installer suite passes 15 tests.
- Implementation-validation: Bash syntax, editor diagnostics, YAML parsing with unique decision IDs, reference checks, executable permission, and `git diff --check` pass. No source behavior, install.sh distribution, or route behavior changed.
- Closeout result: PASS. The category and test ownership now match the separate first-setup responsibility.

### Entry 0075 (2026-08-02T00:00:36Z)
- Why now: `templates/first-setup.sh` uses plain `[ERROR]` and `[SUCCESS]` output, while `install.sh` and `templates/dev-tools.sh` use the shared emoji, color, TTY, and `NO_COLOR` logging convention. The user requested that the first-setup logger match those scripts.
- Findings: Existing conventions are `[INFO]` without color, `[⚠️WARNING]` in yellow on stdout, `[❌️ERROR]` in red on stderr, and `[✅️SUCCESS]` in green on stdout. Color is emitted only for the corresponding TTY when `NO_COLOR` is absent; plain labels are emitted otherwise.
- Direction: Copy the shared stdout/stderr color capability checks and update first-setup error/success logging to the same labels and ANSI colors. Keep first-setup's current info messages and apt behavior unchanged. Extend `tests/first-setup.test.sh` to assert the no-color user-facing labels without requiring a real TTY.
- Explicit exclusions: no warning path is introduced, no apt command or package change, no install.sh distribution change, and no proto/Ruby invocation.
- Discussion-validation: The logger-only change is directly bounded to the existing output contract and does not alter first-setup control flow. The candidate is ready for promotion and implementation.
- Promotion target: Extend `installer-011-22-first-setup-dependencies` with the shared log label, emoji, color, TTY, and `NO_COLOR` contract.

### Entry 0076 (2026-08-02T00:00:37Z)
- Implementation result: Updated `templates/first-setup.sh` to use the same `supports_stdout_color` and `supports_stderr_color` checks as `install.sh` and `templates/dev-tools.sh`. Info remains `[INFO]`; errors now use red `[❌️ERROR]` on stderr and successes use green `[✅️SUCCESS]` on stdout, with plain emoji labels when color is unavailable or `NO_COLOR` is set.
- Test result: Extended `tests/first-setup.test.sh` to verify the shared info/error/success labels and no ANSI output under `NO_COLOR=1`. The focused first-setup test passes, as do the dev-tools and installer suites with 15 tests each.
- Implementation-validation: Bash syntax, editor diagnostics, executable checks, and `git diff --check` pass. No apt command, package list, route behavior, or distribution behavior changed.
- Closeout result: PASS. First-setup logging now matches the existing installer and development-tools logger conventions.

### Entry 0077 (2026-08-02T00:00:38Z)
- Why now: The user requested that first-setup also install `curl`, `git`, `gh`, `unzip`, `gzip`, and `xz-utils`.
- Direction: Extend the explicit apt package list and its focused expected command with those six packages. Keep `apt-get update` before `apt-get install -y`, preserve root-versus-sudo selection, and do not add any tool-manager or proto invocation.
- Discussion-validation: These are ordinary Debian/Ubuntu bootstrap utilities and fit the existing first-setup apt boundary. The change is limited to the package contract and its test; logging, distribution, and route behavior remain unchanged.
- Promotion target: Update `installer-011-22-first-setup-dependencies` with the six additional packages.

### Entry 0078 (2026-08-02T00:00:39Z)
- Implementation result: Added `curl`, `git`, `gh`, `unzip`, `gzip`, and `xz-utils` to `templates/first-setup.sh` in the requested order, and synchronized the focused install-command expectation and `first-setup` decision contract.
- Test result: The first-setup mock test passes with the expanded package command. The dev-tools suite passes 15 tests and the installer suite passes 15 tests.
- Implementation-validation: Bash syntax, editor diagnostics, executable checks, package-reference checks, and `git diff --check` pass. No live apt operation was performed.
- Closeout result: PASS. The first-setup bootstrap now covers the requested CLI, archive, and compression utilities in addition to the proto Ruby build dependencies.
