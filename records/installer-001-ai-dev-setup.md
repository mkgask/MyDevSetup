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
