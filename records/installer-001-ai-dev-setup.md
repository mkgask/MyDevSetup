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

### Entry 0026 (2026-08-01T00:00:00Z)
- Why now: DODKit の `install.sh` が `--force` から `--overwrite yes|no` へ移行し、省略時を `ask` としているため、MyDevSetup の同じ委譲入口とローカルアセット上書き契約を揃えるか確認する。
- Findings / trade-offs:
  - **DODKit の現行契約**: `OVERWRITE_POLICY=ask` を初期値とし、`--overwrite` の値は `yes|no` のみ受け付け、値の欠落・不正値・旧 `--force` は拒否する。省略時の対話プロンプトは `Overwrite this file? [Y/n/a] (a = all remaining files):` とし、Enter は現在のファイルだけ、`n` は現在のファイルだけを保持、`a` は現在のインストール中だけ以降を `yes` 相当にする。利用可能な端末がない `ask` は自動更新し、明示的な `yes|no` は端末検出より優先する。
  - **MyDevSetup の現状**: `FORCE_OVERWRITE` と `--force` をローカルの `AGENTS.md` / `.docs/PRINCIPLES.md` 上書き判定に使い、対話時は `[y/N]`、非対話時は既存ファイルを保持する。受け取った引数列は DODKit へそのまま透過しているため、ローカル判定だけを更新しても委譲先との CLI 契約がずれる。
  - **既存の例外**: `installer-011-9-helper-destination` は `.dev/dev-tools.sh` を配置先へ上書きすることを明示している。この helper の無条件更新は今回のオプション形状変更の対象に含めず、既存の `dev-tools` 責務を維持する。
  - **影響する周辺領域**: `install.sh` のパーサー、ヘルプ、AGENTS.md / PRINCIPLES.md の競合処理、DODKit 引数透過、focused shell tests、`DECISIONS.yml` の `--force` 表記が対象になる。DODKit 自体の実装やターゲット集合、dev-tools.sh の導入ロジックは変更しない。
  - **候補方針**: MyDevSetup も `OVERWRITE_POLICY=ask` を既定値とし、`--overwrite yes|no` をローカルの管理対象テンプレートへ適用する。`AGENTS.md` と `.docs/PRINCIPLES.md` は DODKit と同じ `ask/yes/no` の意味論と対話プロンプトを使い、受領した `--overwrite` 引数は変更せず DODKit へ渡す。旧 `--force` は拒否する。
- Focus areas: (1) `--overwrite` の検証とローカル上書き判定、(2) DODKit への引数透過とヘルプ／テストの用語同期、(3) helper の既存無条件更新境界を保ったままの回帰確認。
- Explicit exclusions: DODKit `install.sh` の再変更、`.dev/dev-tools.sh` の上書き契約変更、DODKit 以外のターゲット追加、dev-tools helper の内部ロジック変更。
- Current conclusion: DODKit との CLI 契約を一致させる候補方向は、既存のテンプレート配布・DODKit 委譲・helper 境界を維持しながら実装可能である。`DECISIONS.yml` の `installer-005-2`、`installer-009-2`、DODKit 引数透過契約、`installer-011-6` の旧用語を更新対象として、discussion-validation で方向性と契約完全性を確認する。
- Promotion to DECISIONS.yml: pending（discussion-validation 後）
- Evidence / references (optional): `DODKit/install.sh`、`DODKit/DECISIONS.yml`、`DODKit/records/agent-002-installer-delivery.md`、`MyDevSetup/install.sh`、`MyDevSetup/tests/install.test.sh`

### Entry 0027 (2026-08-01T00:00:01Z)
- Why now: Gate A step 2（discussion-validation）として、Entry 0026 の候補方針を元の目的、既存契約、隣接する helper 境界へ照合する。
- Findings / trade-offs:
  - **Landscape coverage**: DODKit の実装・決定・README・既存記録、MyDevSetup の install.sh・focused shell tests・決定・関連記録を確認し、パーサー、ローカル配布、DODKit 委譲、helper の例外、用語同期の主要領域をカバーした。
  - **Focus justification**: 変更要求に直接関係する `--overwrite` の検証、`AGENTS.md` / `PRINCIPLES.md` の競合処理、DODKit への引数透過、テストとヘルプに絞った。helper の無条件更新、DODKit 実装、ターゲット集合、dev-tools 内部ロジックは既存の明示契約により除外できる。
  - **Directional fit**: DODKit と MyDevSetup の入口を同じ明示的な上書き指定へ揃えるため、ユーザー要求と標準汎用インストーラーの目的に合う。MyDevSetup は DODKit を bundled installer として呼び出すため、同じ引数を透過することも維持される。
  - **Contract fit**: テンプレート由来、workspace-only、冪等性、fail-fast、既存本文を保護する add-only 追記の契約と衝突しない。`AGENTS.md` / `PRINCIPLES.md` の旧 `--force` 契約は更新が必要だが、`.dev/dev-tools.sh` の上書きは `installer-011-9` の独立した既存契約として維持する。
  - **Hidden bindings**: `ask` の exact prompt、Enter / `n` / `a` の適用範囲、非対話時の自動更新、明示値の端末優先、旧 `--force` の拒否、helper の無条件更新例外を active decisions に明記する必要がある。`installer-011-6` の「--force なし」表記も add-only の責務境界を表す用語へ更新する。
  - **Validation result**: PASS — 候補方向は元の目的と active constraints に適合し、実装前に昇格可能である。
- Current conclusion: `installer-012-overwrite-policy` と必要な sub_decisions を追加し、`installer-005-2`、`installer-009-2`、`installer-007-4`、`installer-011-6` の active wording / status を更新してから、実装へ進める。
- Promotion to DECISIONS.yml: promoted -> `installer-012-overwrite-policy`（および必要な sub_decisions）、updated -> `installer-005-2`、`installer-009-2`、`installer-007-4`、`installer-011-6`
- Evidence / references (optional): `DODKit/install.sh` の `parse_args` / `confirm_overwrite` / `should_overwrite`、`bash tests/install.test.sh` の overwrite-policy tests

### Entry 0028 (2026-08-01T00:00:02Z)
- Why now: Gate B（implementation）として、promoted 済みの `installer-012-overwrite-policy` を MyDevSetup の install.sh と focused tests へ反映する。
- Findings / trade-offs:
  - `FORCE_OVERWRITE` を `OVERWRITE_POLICY="ask"` へ置き換え、`--overwrite yes|no` の値検証、欠落・不正値・旧 `--force` の拒否、受領引数列の DODKit への透過を実装した。
  - AGENTS.md と .docs/PRINCIPLES.md は DODKit と同じ `ask/yes/no` の意味論、exact prompt、`a` のセッション限定切替、非対話時の自動更新を使う。`.dev/dev-tools.sh` は既存契約どおり `--overwrite no` でも無条件更新する。
  - ヘルプを `--overwrite yes|no` に同期し、parser、既定値、明示 yes/no、interactive `a`、default 非対話更新、旧 option 拒否、DODKit 引数透過、helper 例外の focused tests を追加・更新した。
  - `bash -n install.sh` と `bash tests/install.test.sh` は PASS。focused suite は 14 tests passed。`get_errors` は install.sh、tests/install.test.sh、DECISIONS.yml ともに diagnostics なし。
- Current conclusion: promoted decision contract に従う実装と検証が完了した。DODKit 側の実装・決定・ドキュメントは変更せず、MyDevSetup 側の入口とローカル管理対象だけを同期した。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): `MyDevSetup/install.sh`、`MyDevSetup/tests/install.test.sh`、`bash -n install.sh`、`bash tests/install.test.sh`

### Entry 0029 (2026-08-01T00:00:03Z)
- Why now: Gate B step 3 / Gate C（implementation-validation と closeout）として、overwrite-policy 実装、active decisions、記録、用語、変更範囲の整合を確認する。
- Findings / trade-offs:
  - **Executable validation**: `python3` の YAML parse、`bash -n install.sh`、`bash tests/install.test.sh` は PASS。focused suite は 14 tests passedし、parser、既定 ask、明示 yes/no、対話 `a`、非対話更新、旧 option 拒否、DODKit 引数透過、helper 例外を検証した。
  - **Artifact alignment**: `install.sh` の実装と `installer-012-overwrite-policy`、`installer-005-2`、`installer-009-2`、`installer-007-4`、`installer-011-6` の active constraints が一致する。`DECISIONS.yml` の変更済み status は `✅️Implementation Approved` で、link は本記録を指す。
  - **Terminology alignment**: user-facing help と実装の主契約は `--overwrite yes|no`。active decision に残る `--force` は旧 option を拒否する契約だけであり、過去の discussion history は append-only のため書き換えていない。
  - **Scope and hygiene**: `get_errors` は対象4ファイルで diagnostics なし、`git diff --check` は PASS。MyDevSetup の4ファイルだけを変更し、DODKit の実装・決定・README は変更していない。
- Current conclusion: implementation-validation の executable、artifact、terminology、decision-record hygiene の確認を満たし、本スコープを closeout できる。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): `python3` YAML parse、`bash -n install.sh`、`bash tests/install.test.sh`、`git diff --check`、`get_errors`

### Entry 0030 (2026-08-01T00:00:04Z)
- Why now: ユーザー確認により、旧 `--force` は MyDevSetup 側で特別に拒否せず、DODKit と同じく未対応引数として通常の委譲境界で扱う方針を確認する。
- Findings / trade-offs:
  - **DODKit の現行処理**: `parse_args` は `--overwrite` と既知ターゲット／help だけを解釈し、それ以外は共通の `*` 分岐で `Unknown argument` として拒否する。`--force` 専用分岐は存在しない。
  - **MyDevSetup の現状**: `parse_args` は受領引数を DODKit へ透過する設計だが、`--force` だけは専用分岐でローカル拒否している。そのため旧 option の拒否責任が委譲先と重複している。
  - **候補方針**: `--overwrite` の値検証（欠落・不正値）は MyDevSetup が引き続き担当し、それ以外の引数は特別扱いせず `PASSTHROUGH_ARGS` のまま DODKit へ渡す。`--force` は実際の DODKit 実行時に DODKit の一般的な unsupported-argument 処理で拒否される。
- Focus areas: MyDevSetup parser の `--force` 専用分岐、legacy option の passthrough test、`installer-012-2-overwrite-argument-validation` の wording。
- Explicit exclusions: DODKit の実装・決定・ドキュメント変更、`--overwrite` の検証ルール変更、他の未知引数の仕様変更。
- Current conclusion: `--force` を MyDevSetup で特別扱いしない候補は、既存の引数透過契約と DODKit の validation ownership に一致する。discussion-validation で、`--overwrite` の fail-fast を保ちつつ legacy option だけを generic passthrough にできることを確認する。
- Promotion to DECISIONS.yml: pending（discussion-validation 後）
- Evidence / references (optional): `DODKit/install.sh` の `parse_args`、`MyDevSetup/install.sh` の `parse_args`、`installer-012-2-overwrite-argument-validation`

### Entry 0031 (2026-08-01T00:00:05Z)
- Why now: Gate A step 2（discussion-validation）として、Entry 0030 の候補方針を DODKit の parser、既存の引数透過契約、`--overwrite` validation と照合する。
- Findings / trade-offs:
  - **Landscape coverage**: DODKit / MyDevSetup 両方の `parse_args`、MyDevSetup の `installer-012-2`、引数透過を定める `installer-007-4`、focused tests と discussion record を確認した。
  - **Focus justification**: 変更対象は MyDevSetup の `--force` 専用分岐とそのテスト・decision wording に限定できる。DODKit の実装・決定・ドキュメント、`--overwrite` の検証、他の未知引数の扱いは対象外のまま維持する。
  - **Directional fit**: unsupported argument の validation ownership を DODKit に揃え、MyDevSetup の既存 passthrough 設計と一致する。MyDevSetup がローカルで同じエラーを重複生成する必要はない。
  - **Contract fit**: `--overwrite` の値欠落・不正値は引き続き MyDevSetup が fail-fast し、有効な引数列は変更せず DODKit へ渡す。`--force` は DODKit 到達後に一般の unknown-argument 処理で拒否されるため、拒否責任の変更は legacy option に限定される。
  - **Validation result**: PASS — DODKit の `parse_args --force` が `Unknown argument: --force` を返すことを確認し、候補方向は元の目的と active constraints に適合する。
- Current conclusion: `installer-012-2-overwrite-argument-validation` の旧 `--force` 専用拒否を削除し、unsupported argument は DODKit へ透過する契約へ更新してから実装する。
- Promotion to DECISIONS.yml: promoted -> `installer-012-2-overwrite-argument-validation`
- Evidence / references (optional): `DODKit/install.sh` `parse_args --force` の generic rejection check

### Entry 0032 (2026-08-01T00:00:06Z)
- Why now: Gate B（implementation）として、promoted 済みの parser-boundary 契約を MyDevSetup の install.sh と focused tests へ反映する。
- Findings / trade-offs:
  - MyDevSetup `parse_args` から `--force` 専用の拒否分岐を削除し、`--overwrite` の欠落・不正値検証以外は既存どおり受領引数列を保持して DODKit へ渡す形にした。
  - focused tests を、local parser が `--force` を拒否せず passthrough することと、installer が DODKit へ同引数を渡すことの検証へ更新した。
  - `bash -n install.sh` と `bash tests/install.test.sh` は PASS。focused suite は 15 tests passed。DODKit の generic `Unknown argument` 処理と DODKit 側のファイルは変更していない。
- Current conclusion: `installer-012-2-overwrite-argument-validation` の更新内容に沿う実装が完了した。MyDevSetup は unsupported argument の所有権を DODKit に委譲し、`--overwrite` の local validation は維持している。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): `MyDevSetup/install.sh`、`MyDevSetup/tests/install.test.sh`、`DODKit/install.sh` `parse_args --force`、`bash tests/install.test.sh`

### Entry 0033 (2026-08-01T00:00:07Z)
- Why now: Gate B step 3 / Gate C（implementation-validation と closeout）として、unsupported argument の責務移譲、active decision、テスト、用語、変更範囲の整合を確認する。
- Findings / trade-offs:
  - **Executable validation**: `DECISIONS.yml` の YAML parse、`bash -n install.sh`、`bash tests/install.test.sh`、`git diff --check` は PASS。focused suite は 15 tests passedし、`--force` の parser passthrough と DODKit 委譲を含む。
  - **Artifact alignment**: `installer-012-2-overwrite-argument-validation` は `✅️Implementation Approved` で、`--overwrite` の local validation と unsupported argument の DODKit 委譲を明示している。実装は `--force` 専用分岐を持たない。
  - **Terminology and ownership**: MyDevSetup の現行コードに `--force` の特別処理はなく、DODKit 側の一般的な `Unknown argument` 処理へ到達する。過去の discussion history にある旧方針は append-only のため保持した。
  - **Scope and hygiene**: 対象ファイルの diagnostics はすべてなし。DODKit の実装・決定・ドキュメントは変更していない。
- Current conclusion: implementation-validation の executable、artifact、ownership、terminology、decision-record hygiene の確認を満たし、本変更を closeout できる。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): `DODKit/install.sh` の generic argument rejection check、`bash tests/install.test.sh`、`git diff --check`、`get_errors`

### Entry 0034 (2026-08-01T00:00:08Z)
- Why now: `install.sh` の一部 warning が `[⚠️WARNING]` を直接 `printf` しており、既存の `log_warning` 契約へ統一できるか確認する。
- Findings / trade-offs:
  - **Bounded landscape scan**: `install.sh` の `log_warning`、`confirm_overwrite`、`select_dev_tools_destination`、配布失敗・skip 通知と、`DECISIONS.yml` の `installer-008-console-log-format` を確認した。warning の直接 `printf` は `confirm_overwrite` の対話時表示に限定され、他の本番 warning はすでに `log_warning` を使っている。
  - **TTY boundary**: `/dev/tty` は warning のラベル生成に必須ではなく、対話 warning と overwrite prompt を端末へ固定するために使われている。`log_warning "File exists: ..." >/dev/tty` とすれば既存の出力先を維持できる。prompt 本体と `read` は対話制御のため `printf` / `read` を残す。
  - **Focus areas**: `confirm_overwrite` の warning 出力を `log_warning` へ置換し、stdout へ出す非対話系 warning と `[⚠️WARNING]` の色・ラベル契約を回帰確認する。
  - **Explicit exclusions**: prompt 文、`/dev/tty` の入出力判定、`log_warning` の出力先・色判定、DODKit、`templates/dev-tools.sh` の logging 実装は変更しない。
- Current conclusion: 既存の `installer-008` 契約に沿って、warning 表示だけを `log_warning` に統一できる。`/dev/tty` は対話 UX のために残し、prompt の直接 `printf` までログ API として扱わない。
- Promotion to DECISIONS.yml: none（既存 decision の実装整合化のみ）
- Evidence / references (optional): `MyDevSetup/install.sh` の `log_warning` / `confirm_overwrite`、`MyDevSetup/DECISIONS.yml` の `installer-008-console-log-format`、`records/dev-tools-001-optional-tool-installation.md` の logging boundary

### Entry 0035 (2026-08-01T00:00:09Z)
- Why now: Gate A step 2（discussion-validation）として、Entry 0034 の logging 統一方針を既存 decision、TTY境界、ログと prompt の責務分離へ照合する。
- Findings / trade-offs:
  - **Landscape coverage**: `install.sh` の共通 logger、上書き確認、helper 配置先選択、アセット skip、既存の logging boundary と `installer-008-console-log-format` を確認した。warning の直接 `printf` と prompt の直接 `printf` を区別できている。
  - **Focus justification**: 変更対象を `confirm_overwrite` の warning 本体に限定し、`/dev/tty` の prompt 入出力、非対話時の helper directory warning、helper 内部 logging、DODKit は除外できる。
  - **Directional fit**: 本番状態通知を共通 logger へ寄せる既存方針と一致し、warning のラベル・色・出力先を `log_warning` に一元化できる。`>/dev/tty` を logger 呼び出しに付けることで対話時の表示先は維持される。
  - **Contract fit**: `installer-008` の `[⚠️WARNING]` と黄色表示を維持し、prompt の exact text、TTY 判定、`NO_COLOR`、非対話時の自動更新も変更しない。新しい independently active rule は発生していない。
  - **Validation result**: PASS — 候補方向は元の logging objective と active constraints に適合し、decision promotion は不要。実装は `confirm_overwrite` の warning 分岐を logger 呼び出しへ置換するだけで足りる。
- Current conclusion: logging 統一方針を実装へ進める。対象 decision は既存の `installer-008-console-log-format` で、`DECISIONS.yml` の更新は行わない。
- Promotion to DECISIONS.yml: none（discussion-validation PASS、既存 decision の適用のみ）
- Evidence / references (optional): `MyDevSetup/install.sh`、`MyDevSetup/DECISIONS.yml` の `installer-008-console-log-format`、`records/dev-tools-001-optional-tool-installation.md` Entry 0008

### Entry 0036 (2026-08-01T00:00:10Z)
- Why now: Gate A step 3（decision-promotion）として、validation 済みの logging 統一方針を active decision set と照合する。
- Findings / trade-offs:
  - 適用対象は既存の `installer-008-console-log-format` と、そこから導かれる「本番 warning は `log_warning` を使う」という実装上の整合性である。
  - `log_warning` のラベル・色・出力先、TTY prompt の exact text と入出力、`NO_COLOR`、非対話時挙動は既存契約として明示済みで、追加の sub_decision は不要である。
  - `DECISIONS.yml` の status、link、decision wording を変更する必要はない。prompt の直接 `printf` をログ API として扱わない境界も今回の実装スコープ内で明確になっている。
- Current conclusion: Gate A を完了し、`DECISIONS.yml` を変更せずに実装へ進む。実装対象は `confirm_overwrite` の warning 出力のみとする。
- Promotion to DECISIONS.yml: none（既存 decision を適用）
- Evidence / references (optional): `MyDevSetup/DECISIONS.yml` の `installer-008-console-log-format`、Entry 0035 の discussion-validation PASS

### Entry 0037 (2026-08-01T00:00:11Z)
- Why now: Gate B（implementation）として、`confirm_overwrite` の warning 表示を既存の `log_warning` 契約へ統一する。
- Findings / trade-offs:
  - `has_tty` 分岐では `log_warning "File exists: ..." >/dev/tty` とし、warning の出力先を従来どおり端末へ固定した。
  - `[[ -t 0 ]]` 分岐では同じ warning を通常の `log_warning` で表示する。
  - overwrite prompt の `printf` と回答の `read` は対話制御そのものなので、`/dev/tty` 入出力を維持した。
  - `bash tests/install.test.sh` は PASS（15 tests）。
- Current conclusion: `installer-008-console-log-format` の logger 境界に沿う実装を完了した。新しい binding constraint は発生していない。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): `MyDevSetup/install.sh` の `confirm_overwrite`、`bash tests/install.test.sh`

### Entry 0038 (2026-08-01T00:00:12Z)
- Why now: Gate B step 3 / Gate C（implementation-validation と closeout）として、warning logger 統一後の実装、active decision、記録、変更範囲を最終確認する。
- Findings / trade-offs:
  - **Executable validation**: `bash tests/install.test.sh` は 15 tests passed、`bash -n install.sh`、`DECISIONS.yml` の YAML parse、`git diff --check` も PASS。
  - **Logger alignment**: `install.sh` の `[⚠️WARNING]` 直書きは `log_warning` 関数本体だけに残り、`confirm_overwrite` の warning 表示は対話時も非対話時も `log_warning` を使う。prompt の `printf` / `read` と `/dev/tty` は対話制御として維持した。
  - **Artifact and terminology alignment**: `installer-008-console-log-format` の warning label/color 契約、Entry 0034〜0037 の logging boundary、現行の `log_warning` 名称と整合している。`DECISIONS.yml` の status/link は変更不要のままである。
  - **Scope and hygiene**: 対象4ファイルの diagnostics はすべてなし。今回の実装で DODKit、helper 内部、prompt 契約、overwrite policy の意味論は変更していない。
- Current conclusion: implementation-validation の executable、artifact、terminology、decision-record hygiene、scope の確認を満たし、本変更を closeout できる。残存する `printf` は logger 実装または prompt/data output であり、warning の共通化対象ではない。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): `bash tests/install.test.sh`、`bash -n install.sh`、`python3` YAML parse、`git diff --check`、`get_errors`

### Entry 0039 (2026-08-02T00:00:00Z)
- Why now: ルートに README.md がなく、利用者がこのリポジトリの目的と正規の導入方法を確認できない。ユーザー要望により、自分で作って自分で使うためのリポジトリであることを明記し、一般利用者向けの最小導入案内を追加する。
- Findings / trade-offs:
  - 既存の `installer-003-install-sh-distribution` は、対象プロジェクトへ移動した利用者が raw GitHub の `install.sh` を `curl -fsSL ... | bash` で実行する公開導線を定めている。
  - `install.sh` は実行時の current working directory を導入先として扱い、引数なしでは Copilot を既定ターゲットにする。Cursor は一般利用者向けの引数例として案内できる。
  - README は自作・自用の性格と一般利用者向けの curl 導線だけを扱い、ローカル checkout、開発・検証手順、内部実装の説明は意図的に含めない。
- Current conclusion: ルート README.md に、自分で作って自分で使うリポジトリであること、対象プロジェクトのルートで実行すること、Copilot既定の curl 導入コマンド、Cursor指定の任意コマンドだけを最小限記載する。
- Promotion to DECISIONS.yml: pending（discussion-validation 後）
- Evidence / references (optional): `DECISIONS.yml` の `installer-003-install-sh-distribution`、`install.sh` の `SOURCE_REPOSITORY`・`SOURCE_REF`・`parse_args`・`main`

### Entry 0040 (2026-08-02T00:00:01Z)
- Why now: Gate A step 2（discussion-validation）として、Entry 0039 の README 方針を既存の配布契約と利用者スコープへ照合する。
- Findings / trade-offs:
  - **Landscape coverage**: ルート構成、README の有無、`install.sh` の raw URL・current working directory・既定ターゲット、`installer-003`、既存 installer tests を確認した。README の追加以外の配布実装変更は不要である。
  - **Focus justification**: README の目的、導入先、一般利用者向け command、対象ターゲットの案内に絞り、ローカル checkout・開発手順・内部実装・オフライン導入は除外する。
  - **Directional fit**: 自作・自用のリポジトリであることを明記しつつ、公開利用者が current working directory で raw installer を実行する既存導線をそのまま説明できる。
  - **Contract fit**: `curl -fsSL ... | bash`、`mkgask/mydevsetup/main`、引数なしの Copilot 既定、Copilot/Cursor 限定を維持し、新しい installer route や CLI semantics を追加しない。
  - **Hidden bindings**: README に開発者向け手順を載せないことは今回の user-facing documentation scope として明示的に decision 化する。実装上の新規制約はない。
  - **Validation result**: PASS — 方針は元の配布目的と active constraints に適合し、README の内容だけを実装すればよい。
- Current conclusion: 既存 `installer-003-install-sh-distribution` に README の対象読者・内容境界を sub-decision として追加し、その後 README.md を作成する。
- Promotion to DECISIONS.yml: ready -> `installer-003-install-sh-distribution`
- Evidence / references (optional): `DECISIONS.yml` の `installer-003-*`、`install.sh`、`tests/install.test.sh`

### Entry 0041 (2026-08-02T00:00:02Z)
- Why now: Gate B（implementation）として、promoted 済みの README scope をルートの user-facing documentation に反映する。
- Findings / trade-offs:
  - `README.md` を新規追加し、自作・自用のリポジトリであること、対象プロジェクトのルートで実行すること、既定の Copilot 導入、Cursor 指定の公開 command だけを記載した。
  - ローカル checkout、開発・検証手順、内部実装、別の導入 transport は追加していない。
  - `bash tests/install.test.sh` は 15 tests passed、`bash -n install.sh`、README command の文字列確認、`git diff --check` は PASS。
- Current conclusion: `installer-003-4-readme-scope` に沿う README 実装が完了した。新しい binding constraint は発生していない。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): `README.md`、`install.sh`、`bash tests/install.test.sh`

### Entry 0042 (2026-08-02T00:00:03Z)
- Why now: Gate B step 3 / Gate C（implementation-validation と closeout）として、README 実装、active decision、記録、変更範囲の整合を確認する。
- Findings / trade-offs:
  - **Executable validation**: `bash tests/install.test.sh` は 15 tests passed、`bash -n install.sh`、README の導入 command 確認、`git diff --check` は PASS。
  - **Artifact alignment**: `README.md` は自作・自用の目的、対象プロジェクトのルート実行、Copilot既定、Cursor指定だけを含み、`installer-003-4-readme-scope` の非目標を守っている。
  - **Terminology and contract**: README の URL、`curl -fsSL ... | bash`、`cursor` 引数は `installer-003-1`、`installer-003-2`、`installer-003-3`、`installer-004` と整合している。
  - **Decision-record hygiene**: `installer-003-install-sh-distribution` の link は `records/installer-001-ai-dev-setup.md` を指し、Entry 0039〜0042 に今回の discussion、validation、implementation、closeout が append-only で記録されている。
  - **Scope and risk**: `install.sh`、helper、tests の動作は変更していない。README の導入例が実際の公開ブランチに存在することは、今回のローカル検証範囲外として残る運用上のリスクである。
- Current conclusion: implementation-validation の executable、artifact、terminology、decision-record hygiene、scope の確認を満たし、本変更を closeout できる。`installer-003-install-sh-distribution` と `installer-003-4-readme-scope` を `✅️Implementation Approved` とする。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): `README.md`、`DECISIONS.yml`、`bash tests/install.test.sh`、`bash -n install.sh`、`git diff --check`、`get_errors`

### Entry 0043 (2026-08-02T00:01:00Z)
- Why now: README の導入案内だけでは、配布された `.dev/dev-tools.sh` を利用者がどう呼び出すか確認できない。ユーザー要望により、一般利用者向けの簡単な helper 操作例を README に追加する。
- Findings / trade-offs:
  - `templates/dev-tools.sh` の公開 usage は `install`、`init`、`status` であり、`install --dry-run` は導入前の確認用として既存契約に定義されている。
  - `install` は不足している開発用CLIを導入し、`install --dry-run` は予定 route と command を表示し、`status` は現在のツールと package-manager 状態を検証し、`init` は現在プロジェクト向けの明示的な初期設定を行う。
  - README には `.dev/dev-tools.sh` の呼び出し例と短い用途説明だけを追加し、helper の内部実装、route詳細、manager導入手順、開発者向けローカル checkout は記載しない。
- Current conclusion: 既存 README の Install セクションに続けて、対象プロジェクトのルートから実行する `status`、`install --dry-run`、`install`、`init` の最小例を記載する。
- Promotion to DECISIONS.yml: pending（discussion-validation 後）
- Evidence / references (optional): `templates/dev-tools.sh` の `print_usage`、`DECISIONS.yml` の `installer-011-15-mode-selection`・`installer-011-20-status-mode`・`installer-011-21-dry-run-preview`

### Entry 0044 (2026-08-02T00:01:01Z)
- Why now: Gate A step 2（discussion-validation）として、Entry 0043 の helper usage 方針を README の既存 scope と `dev-tools.sh` の active contract へ照合する。
- Findings / trade-offs:
  - **Landscape coverage**: README の現行 Install 案内、helper の `print_usage`、mode selection、status、dry-run の decision と配布先 `.dev/dev-tools.sh` を確認した。追加の code path やテスト契約は影響を受けない。
  - **Focus justification**: 対象を一般利用者向けの4コマンド例と用途説明に限定し、内部 route、manager、debug、global scope、ローカル開発手順を除外できる。
  - **Directional fit**: 導入後に利用者が状態確認、予定確認、導入、現在プロジェクトの初期設定へ進める最小の入口を README に提供する。
  - **Contract fit**: `status` の読み取り専用、`install --dry-run` の副作用なし、`install` の不足CLI導入、`init` の明示的な project initialization という既存意味論を変更しない。
  - **Hidden bindings**: README に helper の基本操作例を含めることは既存の user-facing documentation scope の拡張であり、新しい実装上の binding constraint は発生しない。
  - **Validation result**: PASS — 既存の `installer-003-4-readme-scope` を更新すれば、README 追加の範囲を十分に表現できる。
- Current conclusion: `installer-003-4-readme-scope` に、導入後の `.dev/dev-tools.sh` 基本操作例を一般利用者向けに含める契約を追加して実装する。
- Promotion to DECISIONS.yml: ready -> `installer-003-4-readme-scope`
- Evidence / references (optional): `README.md`、`templates/dev-tools.sh`、`DECISIONS.yml` の `installer-011-15/20/21`

### Entry 0045 (2026-08-02T00:01:02Z)
- Why now: Gate B（implementation）として、promoted 済みの helper usage scope を README に反映する。
- Findings / trade-offs:
  - `README.md` に `Development tools` セクションを追加し、対象プロジェクトのルートから `.dev/dev-tools.sh status`、`install --dry-run`、`install`、`init` を実行する例と短い用途説明を記載した。
  - helper の配置先、mode名、dry-runの位置づけは `templates/dev-tools.sh` の usage と active decision に合わせた。helper、install.sh、既存の導入経路は変更していない。
  - helper suite は 15 tests passed、installer suite は 15 tests passed。help文字列、README command、Bash構文、`git diff --check` も PASS。
- Current conclusion: `installer-003-4-readme-scope` に沿う helper usage の README 実装が完了した。新しい binding constraint は発生していない。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): `README.md`、`templates/dev-tools.sh`、`bash tests/dev-tools.test.sh`、`bash tests/install.test.sh`

### Entry 0046 (2026-08-02T00:01:03Z)
- Why now: Gate B step 3 / Gate C（implementation-validation と closeout）として、helper usage の README 追加、active decision、記録、変更範囲の整合を確認する。
- Findings / trade-offs:
  - **Executable validation**: helper suite は 15 tests passed、installer suite は 15 tests passed。`dev-tools.sh --help` の usage、README の4 command、`bash -n`、`git diff --check` は PASS。
  - **Artifact alignment**: README は Install の後に `.dev/dev-tools.sh` の status、dry-run、install、init だけを追加し、helper の内部 route や開発者向け手順を含まない。
  - **Terminology and contract**: README の mode名と説明は `installer-011-15-mode-selection`、`installer-011-20-status-mode`、`installer-011-21-dry-run-preview` と整合している。
  - **Decision-record hygiene**: `installer-003-install-sh-distribution` の link と Entry 0043〜0046 の discussion、validation、implementation、closeout が揃っている。全対象ファイルの diagnostics に問題はない。
  - **Scope and risk**: helper、install.sh、テストの実装は変更していない。README の操作例は公開後に配布された `.dev/dev-tools.sh` と同じ配置契約を前提とする。
- Current conclusion: implementation-validation の executable、artifact、terminology、decision-record hygiene、scope の確認を満たし、本変更を closeout できる。`installer-003-install-sh-distribution` と `installer-003-4-readme-scope` を `✅️Implementation Approved` とする。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): `README.md`、`DECISIONS.yml`、`templates/dev-tools.sh`、`bash tests/dev-tools.test.sh`、`bash tests/install.test.sh`、`git diff --check`、`get_errors`

### Entry 0047 (2026-08-02T00:02:00Z)
- Why now: README に `dev-tools.sh` の簡単な使い方を追加したため、利用者が導入対象ツールと導入経路の前提を確認できるよう、現在の inventory も簡潔に記載する。
- Findings / trade-offs:
  - `templates/dev-tools.sh` の `TOOL_NAMES` は `python`、`ruby`、`rg`、`rtk`、`codegraph`、`uv`、`serena` を対象とし、`TOOL_COMMANDS` が実行コマンドを定義している。
  - `PACKAGE_MANAGER_NAMES` は `apt-get`、`dnf`、`yum`、`pacman`、`zypper`、`apk`、`nix`、`proto`、`mise`、`asdf`、`brew` を status inventory と導入経路候補の検出対象にしている。
  - README には現在の対象リストを説明用に置き、manager はインストール済みで利用可能なものを導入経路として考慮する旨だけを記載する。各managerが全ツールを扱うことや、manager本体を自動導入することは約束しない。
- Current conclusion: 既存の `Development tools` セクションに対象ツール一覧と、利用可能な package manager を導入経路として考慮する短い説明を追加する。
- Promotion to DECISIONS.yml: pending（discussion-validation 後）
- Evidence / references (optional): `templates/dev-tools.sh` の `TOOL_NAMES`、`TOOL_COMMANDS`、`PACKAGE_MANAGER_NAMES`、`README.md`

### Entry 0048 (2026-08-02T00:02:01Z)
- Why now: Gate A step 2（discussion-validation）として、Entry 0047 の inventory 方針を helper の active contract と README scope へ照合する。
- Findings / trade-offs:
  - **Landscape coverage**: helper の tool/manager inventory、tool command mapping、status の manager inventory、README の既存 usage section を確認した。追加の実装経路やテスト契約は影響を受けない。
  - **Focus justification**: README に現在の7ツールと11 managerを列挙し、managerの利用可能性を導入経路の考慮条件として一文で説明する範囲に限定する。package database query、manager本体の自動導入、toolごとの対応表は除外する。
  - **Directional fit**: 利用者が `dev-tools.sh` の対象範囲を把握でき、導入時に既存managerが候補として使われることも理解できる。既存の簡潔なREADME方針を保つ。
  - **Contract fit**: README のリストはコードの inventory と一致し、managerは検出・導入経路候補として扱うだけで、manager本体導入や新しいrouteを追加しない。
  - **Hidden bindings**: README の対象リストは現在の helper inventory を説明するものであり、全managerと全toolの対応を保証しない。この境界は実装上の新規制約ではなく、既存 scope の明確化である。
  - **Validation result**: PASS — 既存の `installer-003-4-readme-scope` を更新すれば、inventory記載の範囲を十分に表現できる。
- Current conclusion: `installer-003-4-readme-scope` に、対象ツール一覧と利用可能な package manager を導入経路として考慮する説明を含めて実装する。
- Promotion to DECISIONS.yml: ready -> `installer-003-4-readme-scope`
- Evidence / references (optional): `README.md`、`templates/dev-tools.sh`、`DECISIONS.yml` の `installer-011-2/8/15/20/21`

### Entry 0049 (2026-08-02T00:02:02Z)
- Why now: Gate B（implementation）として、promoted 済みの inventory documentation scope を README に反映する。
- Findings / trade-offs:
  - `README.md` に Python、Ruby、ripgrep、RTK、CodeGraph、uv、Serena を実行コマンド付きで列挙した。
  - `apt-get`、`dnf`、`yum`、`pacman`、`zypper`、`apk`、`nix`、`proto`、`mise`、`asdf`、`brew` を、インストール済みなら利用可能な導入経路として考慮する旨を一文で追加した。
  - README の内容は `TOOL_NAMES`、`TOOL_COMMANDS`、`PACKAGE_MANAGER_NAMES` と照合した。helper suite は 15 tests passed、installer suite は 15 tests passed、Bash構文と `git diff --check` も PASS。
- Current conclusion: `installer-003-4-readme-scope` に沿う inventory documentation の実装が完了した。新しい binding constraint は発生していない。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): `README.md`、`templates/dev-tools.sh`、`bash tests/dev-tools.test.sh`、`bash tests/install.test.sh`

### Entry 0050 (2026-08-02T00:02:03Z)
- Why now: Gate B step 3 / Gate C（implementation-validation と closeout）として、inventory documentation の README 追加、active decision、記録、変更範囲の整合を確認する。
- Findings / trade-offs:
  - **Executable validation**: helper suite は 15 tests passed、installer suite は 15 tests passed。helper配列とREADMEの全項目照合、`bash -n`、`git diff --check` は PASS。
  - **Artifact alignment**: README は7つの対象ツールを実行コマンド付きで列挙し、11個の package manager を利用可能な導入経路として考慮する旨だけを記載している。
  - **Terminology and contract**: `python3`、`rg`、`codegraph` などの実行コマンド表記は `TOOL_COMMANDS` と一致し、managerの説明は `PACKAGE_MANAGER_NAMES` と導入経路候補の契約を越えていない。
  - **Decision-record hygiene**: `installer-003-install-sh-distribution` の link と Entry 0047〜0050 の discussion、validation、implementation、closeout が揃っている。対象ファイルの diagnostics に問題はない。
  - **Scope and risk**: helper、install.sh、テストの実装は変更していない。README のinventoryはhelperの現在値を説明するため、将来の対象追加時には更新が必要になる。
- Current conclusion: implementation-validation の executable、artifact、terminology、decision-record hygiene、scope の確認を満たし、本変更を closeout できる。`installer-003-install-sh-distribution` と `installer-003-4-readme-scope` を `✅️Implementation Approved` とする。
- Promotion to DECISIONS.yml: none
- Evidence / references (optional): `README.md`、`DECISIONS.yml`、`templates/dev-tools.sh`、`bash tests/dev-tools.test.sh`、`bash tests/install.test.sh`、`git diff --check`、`get_errors`
