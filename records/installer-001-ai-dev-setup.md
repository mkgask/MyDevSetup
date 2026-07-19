# Decision Record: installer-001-ai-dev-setup

## Metadata
- Created At: 2026-06-24
- Scope: AI 利用開発環境向け標準汎用インストーラーの初期設計

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

### Entry 0001 (2026-06-24T00:00:00Z)
- Why now: 本リポジトリ（MyDevSetup）で AI 利用開発環境の標準汎用インストーラーを新規作成する。実装前に Gate A 議論フェーズとして方針を確定する。
- Findings / trade-offs:
  - **目的**: 対象プロジェクトのルートへ AI 開発環境アセットを配布する汎用インストーラーを提供する。
  - **テンプレート配置**: `templates/` ディレクトリを作成し、コピー元として `templates/AGENTS.md` を置く。初期内容は空ファイルでよい。
  - **配布方式**: リポジトリルートに `install.sh` を置き、`curl -fsSL https://raw.githubusercontent.com/<org>/<repo>/<ref>/install.sh | bash` 形式で直接実行可能にする（DODKit と同パターン）。
  - **対象 AI ツール**: GitHub Copilot と Cursor の 2 種のみ。
  - **AGENTS.md の扱い**: Copilot / Cursor いずれもプロジェクトルートへ `AGENTS.md` を配置するだけで足りる。ターゲット別の追加配置や内容分岐は初期スコープ外。
  - **DODKit 連携**: インストール処理に DODKit のインストールも含める。DODKit 側はターゲット指定が必須（例: `curl -fsSL https://raw.githubusercontent.com/mkgask/DODKit/main/install.sh | bash -s -- cursor --force`）。DODKit `install.sh` は `copilot|cursor` 引数と `--force` を受け付ける。`DECISIONS.yml` は DODKit 側で上書き保護対象。
  - **既存状態**: 本リポジトリには DODKit（cursor ターゲット）が既に導入済み（`.cursor/rules/*.mdc`, `.dodkit/templates/`, `DECISIONS.yml`）。`DECISIONS.yml` はプレースホルダーのみ。
  - **広域スキャンで触れた隣接領域**: リモート raw URL（org/repo/ref）、install.sh の CLI 形状、AGENTS.md 上書きポリシー、DODKit 呼び出し順序、エラー時ロールバック、CI/テスト、README 記載 — いずれも初期議論では束ねず、実装前に必要分のみ決定する。
  - **意図的にスコープ外（現時点）**: AGENTS.md の中身定義、Copilot/Cursor 向け DODKit 以外のアセット、自動ターゲット検出、install.sh 自身の `--force` 意味論の詳細、テスト戦略。
  - **未確定事項**: 本リポジトリの raw.githubusercontent.com URL（org/repo/branch）、install.sh がターゲット引数を必須とするか DODKit と同様にデフォルト copilot とするか、AGENTS.md への `--force` 適用範囲。
- Current conclusion: 上記を初期バインディング方針とする。`templates/AGENTS.md`（空）＋ルート `install.sh`（curl|bash 配布）＋ Copilot/Cursor 向けルート `AGENTS.md` 配置 ＋ 選択ターゲット向け DODKit インストール（`bash -s -- <target> --force`）で構成する。実装は Gate A 完了後に着手する。
- Promotion to DECISIONS.yml: pending（Entry 0002 検証後）
- Evidence / references (optional):
  - DODKit install.sh: `https://raw.githubusercontent.com/mkgask/DODKit/main/install.sh`（`copilot|cursor`, `--force`, `DECISIONS.yml` 保護を確認）
  - ユーザー要求: templates/AGENTS.md、ルート install.sh、DODKit 連携、Copilot/Cursor ターゲット

### Entry 0002 (2026-06-24T00:00:01Z)
- Why now: Gate A step 2（discussion-validation）— Entry 0001 の候補方針を実装前監査する。
- Findings / trade-offs:
  - **Landscape coverage**: インストーラー配布（curl|bash）、テンプレート配置、ターゲット AI（Copilot/Cursor）、AGENTS.md 配置、DODKit 委譲 — 主要ドメインはカバー済み。raw URL・CLI 詳細・上書きポリシーは未確定だが初期バインディングを阻害しない。
  - **Focus justification**: 初期 MVP は「AGENTS.md 配置 + DODKit 委譲」の 2 本柱に絞る判断は妥当。AGENTS.md 内容や追加アセットは後続議論でよい。
  - **Directional fit**: ユーザー目的（標準汎用インストーラー、curl|bash、DODKit 同梱）と一致。
  - **Contract fit**: 非目標（AGENTS.md 内容未定義、他 AI ツール非対応）を明示。DODKit の DECISIONS.yml 保護は既存プロジェクトデータ保全と整合。
  - **Hidden bindings として昇格**: (1) templates/AGENTS.md はコピー元、(2) 配布先 AGENTS.md はルートのみ、(3) DODKit は mkgask/DODKit main の install.sh を `-s -- <target> --force` で呼ぶ、(4) 対象は copilot/cursor のみ — いずれも DECISIONS.yml へ昇格対象。
  - **Validation result**: PASS — 昇格可能。
- Current conclusion: Entry 0001 の方向性を検証済み。DECISIONS.yml へ全バインディング制約を昇格する。
- Promotion to DECISIONS.yml: promoted -> installer-001-project-scope, installer-002-templates-agents-md, installer-003-install-sh-distribution, installer-004-supported-targets, installer-005-agents-md-deploy, installer-006-dodkit-bundled, installer-007-dodkit-invocation（および各 sub_decisions）
- Evidence / references (optional): discussion-validation 手順（`.cursor/rules/discussion-validation.mdc`）

### Entry 0003 (2026-06-28T00:00:00Z)
- Why now: install.sh 初期実装着手前に、Entry 0001 で残した未確定事項（raw URL、ターゲット既定値、AGENTS.md 上書き範囲）を解消する必要がある。
- Findings / trade-offs:
  - **広域スキャン結果（今回スコープ内）**:
    - 現在のリポジトリには `install.sh` と `templates/AGENTS.md` が未配置で、インストーラー実体は未実装。
    - 実行入口は `raw.githubusercontent.com/mkgask/MyDevSetup/main/install.sh` を前提にできる（現リポジトリ owner/name/default branch と一致）。
    - DODKit 公式 install.sh（`mkgask/DODKit/main`）の CLI 契約は `copilot|cursor` + `--force`、かつ引数省略時は `copilot` 既定。
    - DODKit 側は非対話時に既存ファイルを保護する実装だが、本リポジトリ決定（installer-007）では DODKit 呼び出し時は `--force` を渡す。
  - **フォーカス領域**: (1) MyDevSetup install.sh 自身の CLI 形状、(2) AGENTS.md の上書きポリシー、(3) DODKit 委譲時の引数境界。
  - **意図的な非スコープ**: AGENTS.md 内容定義、Copilot/Cursor 以外の分岐、ロールバック機構、自動ターゲット推定。
  - **候補方針**:
    - MyDevSetup install.sh も DODKit と同じくターゲット省略時 `copilot` 既定とする。
    - MyDevSetup の `--force` は `AGENTS.md` コピーの上書き可否にのみ適用する。
    - DODKit 呼び出しは既存決定どおり `bash -s -- <target> --force` を維持する。
- Current conclusion: 未確定3点は今回の実装スコープでバインディング制約として確定可能。discussion-validation へ進める。
- Promotion to DECISIONS.yml: pending（Entry 0004 の検証通過後）
- Evidence / references (optional):
  - DODKit install.sh（`https://raw.githubusercontent.com/mkgask/DODKit/main/install.sh`）
  - リポジトリ情報（owner: mkgask / repo: MyDevSetup / default branch: main）

### Entry 0004 (2026-06-28T00:00:01Z)
- Why now: Gate A step 2（discussion-validation）— Entry 0003 の候補方針を実装前監査する。
- Findings / trade-offs:
  - **Landscape coverage**: 配布 URL、CLI 契約、上書き境界、DODKit 委譲契約の主要ドメインを再確認済み。
  - **Focus justification**: 実装直前に必要な未確定事項だけに絞っており、過不足ない。
  - **Directional fit**: 目的（標準汎用インストーラー、curl|bash、Copilot/Cursor、DODKit 同梱）と整合。
  - **Contract fit**: 既存非目標を維持しつつ、実装時に解釈ぶれが出る点（デフォルト引数、上書きポリシー）を顕在化できる。
  - **Hidden bindings として昇格対象**:
    - MyDevSetup install.sh の source repository/ref（`mkgask/MyDevSetup@main`）
    - ターゲット省略時 `copilot` 既定
    - MyDevSetup の `--force` 適用対象は AGENTS.md のみ
    - DODKit 呼び出しは引き続き `--force` 固定
  - **Validation result**: PASS — 昇格可能。
- Current conclusion: Entry 0003 の方向性は妥当。上記バインディング制約を DECISIONS.yml へ昇格する。
- Promotion to DECISIONS.yml: promoted -> installer-003-2-installer-source, installer-003-3-default-target, installer-005-2-agents-overwrite, installer-007-4-dodkit-force-fixed
- Evidence / references (optional): discussion-validation 手順（`.github/skills/discussion-validation/SKILL.md`）

### Entry 0005 (2026-06-28T00:00:02Z)
- Why now: Gate B（implementation）として、promoted 済み決定に従い最初期 `install.sh` と `templates/AGENTS.md` を実装する。
- Findings / trade-offs:
  - **実装内容**:
    - ルート `install.sh` を新規追加（`copilot|cursor`、既定 `copilot`、`--force`、`--help`）。
    - `templates/AGENTS.md`（空ファイル）を追加。
    - `AGENTS.md` 配置は `templates/AGENTS.md` から行い、既存時は比較して差分がある場合のみ上書き判定。
    - `--force` は MyDevSetup 側 `AGENTS.md` 上書き判定にのみ適用。
    - DODKit は `bash -s -- <target> --force` で委譲。
  - **実装中に発見した事実（binding）**:
    - `https://raw.githubusercontent.com/mkgask/DODKit/main/install.sh` はこの実行環境で HTTP 400。
    - `https://raw.githubusercontent.com/mkgask/dodkit/main/install.sh` は HTTP 200。
    - 再現性確保のため DODKit 取得 URL は小文字 repo path（`mkgask/dodkit`）へ更新した。
  - **実装中に発見した事実（non-binding）**:
    - 公開前にローカル実行できるよう、`install.sh` 実体の近傍に `templates/AGENTS.md` があればローカルコピーを優先し、無ければ raw 取得へフォールバックする。
- Current conclusion: 初期 install.sh のターゲット形状とアセット配置は実装完了。implementation-validation へ進める。
- Promotion to DECISIONS.yml: promoted update -> installer-007-1-dodkit-source（URL を `mkgask/dodkit` へ更新）
- Evidence / references (optional): 一時ディレクトリ実行ログ（copilot/cursor 両ターゲット）

### Entry 0006 (2026-06-28T00:00:03Z)
- Why now: Gate B step 3 / Gate C（implementation-validation と closeout）として、変更スコープを実行検証し決定整合を確認する。
- Findings / trade-offs:
  - **Deterministic checks**:
    - `bash -n install.sh` PASS
    - `./install.sh --help` PASS
    - `./install.sh invalid-target` で期待どおりエラー終了
    - 一時ディレクトリで `install.sh copilot` 実行 PASS（`AGENTS.md`, `.github/agents/dod.agent.md`, `DECISIONS.yml`, `.dodkit/templates/discussion-record.md` を確認）
    - 一時ディレクトリで `install.sh cursor` 実行 PASS（`AGENTS.md`, `.cursor/rules/dod-implementation-agent.mdc`, `DECISIONS.yml`, `.dodkit/templates/discussion-record.md` を確認）
  - **Artifact alignment**:
    - `install.sh` 実装は installer-003/004/005/006/007 系 decision と整合。
    - `templates/AGENTS.md` は空テンプレート decision と整合。
    - DODKit URL の小文字化は実測に基づく binding として `DECISIONS.yml` に反映済み。
  - **Decision hygiene**: 対象 decision/sub-decision の status を `✅️Implementation Approved` に更新済み。
  - **Remaining risk**:
    - raw 配布URL（`mkgask/MyDevSetup/main/install.sh`）はリモート反映前に 404 となる。この期間の挙動は設計どおり（公開後に解消）。
- Current conclusion: 初期 install.sh スコープの closeout 条件を満たした。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): implementation-validation 手順（`.github/skills/implementation-validation/SKILL.md`）

### Entry 0007 (2026-06-28T00:01:00Z)
- Why now: 運用後フィードバックにより、配布URLの表記と DODKit への引数委譲方針を再確認する必要がある。
- Findings / trade-offs:
  - **広域スキャン結果（今回スコープ内）**:
    - MyDevSetup の raw URL は `mkgask/MyDevSetup` と `mkgask/mydevsetup` の双方で現時点 HTTP 200。
    - 「小文字でなければ動かない」は現時点で確認できない。
    - 一方で DODKit 側は `mkgask/DODKit` で HTTP 400、`mkgask/dodkit` で HTTP 200 を観測済み。
  - **候補方針**:
    - MyDevSetup 取得元URLは「必須条件」ではなく「運用上の正規表記」として小文字 `mkgask/mydevsetup` を採用する。
    - MyDevSetup install.sh から DODKit install.sh へ渡す引数は固定化せず、受け取った引数をそのまま透過委譲する。
    - MyDevSetup 側の `--force` 解釈は AGENTS.md 上書き判定にのみ使い、DODKit 側にも同じ引数列をそのまま渡す。
  - **意図的な非スコープ**: DODKit 側CLI仕様の再定義、追加オプションの独自実装。
- Current conclusion: 上記方針で discussion-validation に進める。
- Promotion to DECISIONS.yml: pending（Entry 0008 検証後）
- Evidence / references (optional): raw URL HEAD 応答確認（2026-06-28）

### Entry 0008 (2026-06-28T00:01:01Z)
- Why now: Gate A step 2（discussion-validation）— Entry 0007 の候補方針を実装前監査する。
- Findings / trade-offs:
  - **Landscape coverage**: 配布URL表記、DODKit URLの大小文字差、引数委譲境界（MyDevSetup vs DODKit）を確認済み。
  - **Focus justification**: 変更要求に直結する2点（URL正規化、引数透過）のみを対象としており過不足ない。
  - **Directional fit**: ユーザー要望（引数固定よりユーザー指定優先）と一致。
  - **Contract fit**:
    - 既存の `installer-007-4-dodkit-force-fixed` は新方針と衝突するため更新が必要。
    - `installer-003-2-installer-source` は小文字表記へ更新対象。
  - **Validation result**: PASS — 昇格可能。
- Current conclusion: URL正規化と引数透過委譲を DECISIONS.yml へ昇格してから実装へ進む。
- Promotion to DECISIONS.yml: promoted update -> installer-003-2-installer-source, installer-007-dodkit-invocation, installer-007-4-dodkit-force-fixed
- Evidence / references (optional): discussion-validation 手順（`.github/skills/discussion-validation/SKILL.md`）

### Entry 0009 (2026-06-28T00:01:02Z)
- Why now: Gate B（implementation）として、引数透過委譲と配布URL正規表記の実装反映を行う。
- Findings / trade-offs:
  - **実装内容**:
    - `SOURCE_REPOSITORY` を `mkgask/mydevsetup` に更新。
    - 引数パースを「拒否/正規化」から「透過委譲」へ変更し、受領した引数列を `bash -s -- "$@"` 相当で DODKit に渡す形へ変更。
    - MyDevSetup 側では `--force` の有無だけを局所利用し、AGENTS.md 上書き判定に反映。
    - `-h|--help` は MyDevSetup の使用方法表示に加えて、同じ引数で DODKit help を表示。
  - **設計上の境界**:
    - 引数妥当性の最終責任は DODKit 側に委譲。
    - MyDevSetup 側は AGENTS 配置責務の範囲だけを維持。
- Current conclusion: 実装は決定更新内容に整合。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): install.sh 変更差分

### Entry 0010 (2026-06-28T00:01:03Z)
- Why now: Gate B step 3 / Gate C（implementation-validation と closeout）として変更スコープの実行検証を行う。
- Findings / trade-offs:
  - **Deterministic checks**:
    - `bash -n install.sh` PASS
    - `./install.sh --help` で MyDevSetup help + DODKit help を表示 PASS
    - `./install.sh not-a-valid-target` で MyDevSetup 側は拒否せず、DODKit 側エラーとして失敗することを確認
    - 一時ディレクトリで `install.sh cursor --force` 実行 PASS
  - **Artifact alignment**:
    - `DECISIONS.yml` の更新内容（URL正規表記、引数透過委譲）と実装が一致。
  - **Remaining risk**:
    - MyDevSetup の raw URL は大小文字どちらも現時点で到達可能。小文字採用は互換性要件ではなく運用ポリシー。
- Current conclusion: 本スコープの closeout 条件を満たした。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): implementation-validation 手順（`.github/skills/implementation-validation/SKILL.md`）

### Entry 0011 (2026-06-28T00:02:00Z)
- Why now: ユーザー要求により、install.sh のコンソール出力に絵文字ラベルと色分けを導入する必要がある。
- Findings / trade-offs:
  - **広域スキャン結果（今回スコープ内）**:
    - 現在の `install.sh` は `[SUCCESS]`/`[ERROR]`/`[WARNING]` の無色ラベルを使用している。
    - `confirm_overwrite` 内では `printf` 直書きの WARNING ラベルがあり、ロガー関数とは別経路で出力される。
  - **候補方針**:
    - 成功は `[✅️SUCCESS]` を緑（ANSI 32）で表示。
    - エラーは `[❌️ERROR]` を赤（ANSI 31）で表示。
    - 警告は `[⚠️WARNING]` を黄（ANSI 33）で表示。
    - 色付けは TTY 接続時のみ有効化し、`NO_COLOR` が設定されている場合は無色にフォールバックする。
    - 直書き WARNING も同じラベル規約に合わせる。
  - **意図的な非スコープ**: INFO ログの色付け、ログ収集用JSON化。
- Current conclusion: 上記方針を binding として昇格し、実装へ進める。
- Promotion to DECISIONS.yml: pending（Entry 0012 検証後）
- Evidence / references (optional): ユーザー要求（成功/エラー/警告のラベルと色指定）

### Entry 0012 (2026-06-28T00:02:01Z)
- Why now: Gate A step 2（discussion-validation）— Entry 0011 の候補方針を実装前監査する。
- Findings / trade-offs:
  - **Landscape coverage**: ロガー関数経路と `confirm_overwrite` 直書き経路の両方を確認済み。
  - **Focus justification**: 変更要求に直接関係する出力ラベルと色制御のみに限定しており妥当。
  - **Directional fit**: ユーザー指定（成功=緑、エラー=赤、警告=黄）と一致。
  - **Contract fit**: TTY/NO_COLOR 分岐を明示しても既存機能契約（処理結果）には影響しない。
  - **Validation result**: PASS — 昇格可能。
- Current conclusion: ログラベルと色制約を DECISIONS.yml に昇格し、実装へ進める。
- Promotion to DECISIONS.yml: promoted -> installer-008-console-log-format
- Evidence / references (optional): discussion-validation 手順（`.github/skills/discussion-validation/SKILL.md`）

### Entry 0013 (2026-06-28T00:02:02Z)
- Why now: Gate B（implementation）として、コンソール出力の絵文字ラベルと色制約を install.sh に実装する。
- Findings / trade-offs:
  - **実装内容**:
    - `supports_stdout_color` と `supports_stderr_color` を追加し、TTY かつ `NO_COLOR` 未設定時のみ色付けするようにした。
    - `log_success` を `[✅️SUCCESS]` + 緑に変更。
    - `log_error` を `[❌️ERROR]` + 赤に変更（stderr 出力維持）。
    - `log_warning` を `[⚠️WARNING]` + 黄に変更。
    - `confirm_overwrite` 内の直書き WARNING 表示も同ラベル/同色規約に合わせた。
  - **設計上の境界**:
    - INFO ログは無変更。
    - 色表現は表示層のみであり、制御フロー・終了コードには影響しない。
- Current conclusion: 実装は decision contract（installer-008）と整合。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): install.sh 変更差分

### Entry 0014 (2026-06-28T00:02:03Z)
- Why now: Gate B step 3 / Gate C（implementation-validation と closeout）として出力仕様変更を検証する。
- Findings / trade-offs:
  - **Deterministic checks**:
    - `bash -n install.sh` PASS
    - `source ./install.sh; log_success/log_warning/log_error` 実行でラベルがそれぞれ `[✅️SUCCESS]` / `[⚠️WARNING]` / `[❌️ERROR]` になることを確認
    - ファイル内実装確認で ANSI 色コード（緑32/黄33/赤31）が対応ログに適用されることを確認
  - **Artifact alignment**:
    - `DECISIONS.yml` の installer-008 と `install.sh` 実装が一致。
  - **Remaining risk**:
    - 出力が非TTYまたは `NO_COLOR` 指定時は無色表示となる（意図したフォールバック）。
- Current conclusion: 本スコープの closeout 条件を満たした。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): implementation-validation 手順（`.github/skills/implementation-validation/SKILL.md`）

### Entry 0015 (2026-06-29T00:00:00Z)
- Why now: ユーザー要求により、AGENTS.md 配布に加えて `templates/.docs/PRINCIPLES.md` を `.docs/PRINCIPLES.md` へ配布する必要がある。
- Findings / trade-offs:
  - **広域スキャン結果（今回スコープ内）**:
    - 現在の `install.sh` は `templates/AGENTS.md -> AGENTS.md` のみを扱い、`PRINCIPLES.md` の配布処理は未実装。
    - 配布元ファイルは `templates/.docs/PRINCIPLES.md` に存在する。
    - 既存の上書きポリシー（既定保護、`--force` 指定時のみ上書き）を AGENTS.md だけに適用している。
  - **候補方針**:
    - `PRINCIPLES.md` も MyDevSetup アセットとして install.sh で配布対象に追加する。
    - コピー元を `templates/.docs/PRINCIPLES.md`、配置先を `.docs/PRINCIPLES.md` に固定する。
    - 競合時ポリシーは AGENTS.md と統一し、既定保護＋`--force` 指定時のみ上書きを許可する。
    - 配置先ディレクトリ `.docs/` が未存在の場合は install.sh 側で作成する。
  - **discussion-validation 結果**:
    - Coverage: 配布元/配布先パス、上書き境界、既存 `--force` 契約との整合を確認済み。
    - Directional fit: ユーザー要求（PRINCIPLES の同梱配布）と一致。
    - Contract fit: 既存のファイル保護契約を維持しつつ対象ファイルを拡張するのみで、既存 decision と衝突しない。
    - Validation result: PASS — DECISIONS.yml へ昇格可能。
- Current conclusion: `PRINCIPLES.md` 配布制約を DECISIONS.yml に昇格後、install.sh 実装へ進む。
- Promotion to DECISIONS.yml: pending（本エントリに基づき昇格）
- Evidence / references (optional): ユーザー要求（PRINCIPLES.md 配布追加）

### Entry 0016 (2026-06-29T00:00:01Z)
- Why now: Gate B（implementation）として、promoted 済み decision（installer-009）に従い install.sh へ PRINCIPLES.md 配布処理を追加する。
- Findings / trade-offs:
  - **実装内容**:
    - `templates/.docs/PRINCIPLES.md` を扱う source path と `.docs/PRINCIPLES.md` を扱う destination path を追加。
    - テンプレート取得処理を汎用化し、`install_template_asset` を導入して AGENTS.md と PRINCIPLES.md の配布処理を共通化。
    - `.docs/` が未存在でも配布できるように `mkdir -p` で親ディレクトリを作成。
    - 既存ファイル競合時は既存契約を踏襲し、`--force` 指定時のみ上書きを許可。
    - `--help` の説明文を AGENTS + PRINCIPLES 配布契約に合わせて更新。
  - **設計上の境界**:
    - DODKit 呼び出し契約（引数透過、実行順）は変更なし。
    - AGENTS/PRINCIPLES 配布層の責務拡張に限定し、ターゲット判定ロジックには手を入れていない。
- Current conclusion: 実装は installer-009 系 decision contract と整合。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): install.sh 変更差分

### Entry 0017 (2026-06-29T00:00:02Z)
- Why now: Gate B step 3 / Gate C（implementation-validation と closeout）として、PRINCIPLES 配布追加の実行検証と artifact 整合を確認する。
- Findings / trade-offs:
  - **Deterministic checks**:
    - `bash -n install.sh` PASS
    - 一時ディレクトリで `source ./install.sh; FORCE_OVERWRITE=1; install_agents_template; install_principles_template` 実行 PASS（`AGENTS.md` と `.docs/PRINCIPLES.md` の生成を確認）
    - 一時ディレクトリで既存ファイルを作成後、TTY なし実行（`setsid`）かつ `FORCE_OVERWRITE=0` で両ファイルが保持されることを確認 PASS
  - **Artifact alignment**:
    - `DECISIONS.yml` の installer-009 / sub-decisions と install.sh 実装が一致。
  - **Remaining risk**:
    - `main` フローで DODKit まで含めた end-to-end 実行はネットワーク依存のため今回未実施（ローカル関数単位で対象スコープを検証）。
- Current conclusion: 本スコープの closeout 条件を満たした。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): implementation-validation 手順（`.github/skills/implementation-validation/SKILL.md`）

### Entry 0018 (2026-06-30T00:00:00Z)
- Why now: 配布ファイル増加に備え、配布元/配置先を定数リストで管理し、install.sh の配布処理をループ化する必要がある。
- Findings / trade-offs:
  - **広域スキャン結果（今回スコープ内）**:
    - 現在の実装は `install_template_asset` までは共通化できているが、`install_agents_template` と `install_principles_template` の呼び分けが個別で増える。
    - 新規配布ファイルを追加するたびに、定数追加 + 関数追加 + `main` への呼び出し追加が必要となり変更点が散らばる。
  - **候補方針**:
    - 配布契約を `source|destination|asset-name` のリストとして1箇所に集約する。
    - `main` は個別呼び出しをやめ、リストをループして `install_template_asset` を実行する。
    - 既存の上書き契約（既定保護、`--force` 指定時のみ上書き）は変更しない。
  - **discussion-validation 結果**:
    - Coverage: 変更対象は配布制御層のみで、DODKit 委譲やログ契約には影響しないことを確認。
    - Directional fit: ユーザー要望（効率的で管理しやすい構成）と一致。
    - Contract fit: installer-005 / installer-009 の配布パス契約を維持したまま実装方式だけを改善するため、既存 decision と衝突しない。
    - Validation result: PASS — DECISIONS.yml へ昇格可能。
- Current conclusion: 配布アセットリスト + ループ実行の実装方式を DECISIONS.yml に昇格後、install.sh を更新する。
- Promotion to DECISIONS.yml: pending（本エントリに基づき昇格）
- Evidence / references (optional): ユーザー要求（配布元とコピー先のリスト管理）

### Entry 0019 (2026-06-30T00:00:01Z)
- Why now: Gate B（implementation）として、配布管理をリスト化し loop 実行へ置き換える。
- Findings / trade-offs:
  - **実装内容**:
    - `DEPLOYMENT_ASSET_SPECS` を追加し、`source|destination|asset-name` の3要素で配布定義を集約。
    - `install_template_assets` を追加し、配布定義をループして `install_template_asset` を実行。
    - 既存の `install_agents_template` / `install_principles_template` を削除して `main` からはループ関数のみ呼び出す構成へ変更。
    - spec 破損時の早期失敗（3要素不足検出）を追加。
  - **設計上の境界**:
    - 実配布ロジック本体（`install_template_asset`）は維持し、配布制御の入口だけを置換。
    - DODKit 実行契約、上書き契約、ログ契約は変更なし。
- Current conclusion: 実装は installer-010 の decision contract と整合。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): install.sh 変更差分

### Entry 0020 (2026-06-30T00:00:02Z)
- Why now: Gate B step 3 / Gate C（implementation-validation と closeout）として、ループ化後の挙動と契約整合を検証する。
- Findings / trade-offs:
  - **Deterministic checks**:
    - `bash -n install.sh` PASS
    - 一時ディレクトリで `source ./install.sh; FORCE_OVERWRITE=1; install_template_assets` 実行 PASS（`AGENTS.md` と `.docs/PRINCIPLES.md` の生成を確認）
    - 一時ディレクトリで既存ファイルを作成後、TTY なし実行（`setsid`）かつ `FORCE_OVERWRITE=0` で両ファイル保持を確認 PASS
    - `get_errors` で install.sh に diagnostics がないことを確認
  - **Artifact alignment**:
    - installer-005 / installer-009 の配布パス契約と installer-010 の方式契約が install.sh 実装と一致。
  - **Remaining risk**:
    - DODKit を含むネットワーク依存の end-to-end 実行は今回スコープ外（配布制御層のみ検証）。
- Current conclusion: 本スコープの closeout 条件を満たした。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): implementation-validation 手順（`.github/skills/implementation-validation/SKILL.md`）

### Entry 0021 (2026-07-18T12:19:55Z)
- Why now: 開発環境に不足している汎用CLIとAI開発支援CLIを、利用者の確認付きで任意導入できるようにする次期スコープを議論する。
- Findings / trade-offs:
  - **対象と順序**: 不足時に `python`、`ruby`、`rg`、`rtk`、`codegraph` の順で確認し、存在するツールは質問せず、未導入のツールだけを1件ずつ `[Y/n]` で確認する。
  - **対応環境**: シェル版インストーラーの対象は Linux/WSL とする。Python・Ruby・rg は既存のシステムパッケージマネージャを優先し、`mise` または `asdf` が既に存在する場合だけランタイム導入の候補として利用する。パッケージマネージャやバージョン管理ツール自体は自動導入しない。
  - **コマンド判定**: `python3` を Python の導入済みコマンドとして受け入れ、AGENTS.md には実際に確認できたコマンド名を記載する。
  - **サードパーティCLI**: `rtk` と `codegraph` は各公式インストーラーの最新安定版を使い、公式に用意された環境変数等によるバージョン固定の余地は維持する。`~/.local/bin` のためにシェル設定ファイルは変更せず、今回の実行中に限り導入先を検証できるようにする。
  - **AI連携の境界**: 初期スコープではCLI本体の導入だけを行い、`rtk init`、`codegraph install`、`codegraph init` は自動実行しない。したがって、導入だけではRTKのフックによる透過的な出力圧縮やCodeGraphの索引利用は有効化されない。
  - **失敗と対話**: 空入力を導入扱いとする既定Yの `[Y/n]` を使い、TTYがない場合は任意ツールをスキップする。個別の導入失敗では後続ツールを継続し、処理末尾に成功・失敗・スキップをまとめて表示する。
  - **AGENTS.md追記**: 導入に成功した新規ツールのうち、AGENTS.mdに未記載のものだけを収集し、全ツール処理の最後に管理ブロックとして冪等に追記する。既存のAGENTS.md本文や既存のツール記載は上書きしない。細かな説明は追加せず、各CLIの詳細は各コマンドの `--help` に委ねる。
- Current conclusion: CLI導入とAGENTS.md追記を任意の個別確認で行う方向は確定した。discussion-validation では、Linux/WSL上のパッケージマネージャ選択、既存 `mise` / `asdf` の利用条件、公式インストーラー後の実行ファイル検証、非対話時の終了コード、既存AGENTS.mdへの管理ブロック追記が既存決定と衝突しないことを確認する。
- Promotion to DECISIONS.yml: pending（discussion-validation 後）
- Evidence / references (optional):
  - RTK公式README・インストーラー: `https://github.com/rtk-ai/rtk`, `https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh`
  - CodeGraph公式README・インストーラー: `https://github.com/colbymchenry/codegraph`, `https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh`
  - ripgrep公式README: `https://github.com/BurntSushi/ripgrep/blob/master/README.md`
  - Ruby公式インストール案内: `https://www.ruby-lang.org/en/documentation/installation/`

### Entry 0022 (2026-07-18T12:24:44Z)
- Why now: Gate A step 2（discussion-validation）として、Entry 0021 の候補方針を既存の決定契約と実環境へ照合する。
- Findings / trade-offs:
  - **Landscape coverage**: install.sh の既存CLI委譲・テンプレート配置・AGENTS.md保護、候補ツールの検出、Linuxパッケージマネージャ、RTK/CodeGraph公式インストーラー、PATH副作用、AI連携の別工程を確認済み。
  - **Focus justification**: 任意ツールの検出・導入、導入元、対話と失敗、AGENTS.md追記に絞り、DODKitのターゲット契約や既存アセット配布方式は変更対象から除外した。RTK/CodeGraphのフック・索引作成を自動化しない非目標も明示した。
  - **Directional fit**: 不足環境を利用者の確認付きで補完し、導入済みツールをAIへ知らせるという要求と一致する。CLI本体だけではRTKの透過フックやCodeGraphの索引利用が有効にならない点は、初期スコープの残存リスクとして受け入れる。
  - **Contract fit**: Linux/WSL限定、既存のパッケージマネージャまたは既存 `mise` / `asdf` の利用、パッケージマネージャ自体の自動導入禁止、シェル設定ファイル非変更、既存AGENTS.md本文の保護は既存の配布・保護契約と両立する。現在の環境でも `python3` と `rtk` は検出され、`python`・`ruby`・`rg`・`codegraph`・`mise`・`asdf` は未検出、`apt-get` と `brew` は検出された。
  - **Hidden bindings として昇格対象**: `installer-011-optional-tool-installation` と、ツール順序・既定Yの確認・非対話時スキップ・個別失敗後の継続・CLI導入のみ・公式インストーラー利用・AGENTS.mdの冪等な管理ブロック追記を小さな sub_decisions として明示する。
  - **Validation result**: PASS — 候補方向は当初の目的・既存制約・明示した非目標に適合し、実装前に昇格可能。
- Current conclusion: Entry 0021 の方向性を検証済み。実装開始前に `DECISIONS.yml` へ optional tool installation の契約を昇格する。
- Promotion to DECISIONS.yml: pending（`installer-011-optional-tool-installation` と sub_decisions）
- Evidence / references (optional): Linux/WSL上のコマンド検出結果、`bash -n install.sh` PASS、RTK/CodeGraph/ripgrep/Ruby公式インストール資料

### Entry 0023 (2026-07-18T12:25:43Z)
- Why now: discussion-validation 中に、既存のAGENTS.md上書き保護と新規ツール情報の追記境界を明確化する必要が生じた。
- Findings / trade-offs:
  - `AGENTS.md` 全体のテンプレート上書きは既存どおり `--force` を必要とする。
  - 成功した新規ツールの管理ブロックは既存本文・既存記載を変更しない add-only 操作として扱い、`--force` なしでも追加を許可する。
  - 管理ブロックが既に存在する場合は同ブロックだけを冪等更新し、ユーザー管理部分や別のツール記載を編集しない。
- Current conclusion: AGENTS.mdの全体上書き契約と、今回要求された管理ブロックのadd-only追記契約は分離して両立させる。
- Promotion to DECISIONS.yml: pending（`installer-011-optional-tool-installation` と AGENTS.md追記 sub_decision の契約へ反映）
- Evidence / references (optional): 既存 `installer-005-2-agents-overwrite` とユーザー要求の追記範囲を照合

### Entry 0024 (2026-07-18T12:26:29Z)
- Why now: Gate A step 3（decision-promotion）として、discussion-validation を通過した optional tool installation 方針を実装制約へ昇格する。
- Findings / trade-offs:
  - `installer-011-optional-tool-installation` と6つの sub_decisions を `DECISIONS.yml` に追加し、status は実装前の `⚠️Discussion Approved` とした。
  - ツール順序・既定Yの確認・Linux/WSL限定・既存バックエンド利用・`python3` 受入れ・公式インストーラー・CLI導入のみ・非対話時スキップ・個別失敗後の継続・AGENTS.md add-only追記を明示した。
  - 既存 `installer-005-2-agents-overwrite` の全体上書き保護は維持し、今回の管理ブロック追記だけを独立したadd-only契約として定義した。
- Current conclusion: optional tool installation の Gate A は完了し、実装は昇格済み契約に従って開始できる。今回の議論フェーズでは実装を開始しない。
- Promotion to DECISIONS.yml: promoted -> installer-011-optional-tool-installation（および installer-011-1 〜 installer-011-6）
- Evidence / references (optional): `DECISIONS.yml` diagnosticsなし、`git diff --check` PASS

### Entry 0025 (2026-07-18T12:45:12Z)
- Why now: `installer-011-optional-tool-installation` の責務が既存インストーラー配布方針から独立したため、決定カテゴリと議論記録を整理する。
- Findings / trade-offs:
  - 決定IDは互換性のため維持し、`DECISIONS.yml` の `dev-tools` カテゴリへ移動した。
  - Entry 0021〜0024 の既存履歴は変更せず、開発用ツールの今後の議論は `records/dev-tools-001-optional-tool-installation.md` へ分離した。
  - `templates/dev-tools.sh` にツール導入ロジックを置き、`install.sh` は配布と `bash` による実行委譲を担当する境界を `installer-011-7-dev-tools-helper-boundary` として追加した。
- Current conclusion: 初期インストーラーの履歴と開発用ツールの議論を分離し、決定IDの参照互換性を維持したまま、今後の変更責務を `dev-tools` に集約する。
- Promotion to DECISIONS.yml: updated -> `installer-011-optional-tool-installation`（カテゴリ、リンク、installer-011-7）
- Evidence / references (optional): `records/dev-tools-001-optional-tool-installation.md`
