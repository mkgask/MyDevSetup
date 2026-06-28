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
