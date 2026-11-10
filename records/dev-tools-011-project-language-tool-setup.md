# Decision Record: dev-tools-011-project-language-tool-setup

## Metadata
- Created At: 2026-11-08
- Scope: 引数で指定したプロジェクト用言語ツールを導入・設定し、利用可能な状態まで整える独立フローの検討

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

### Entry 0001 (2026-11-08T16:37:26+09:00)
- Why now: 既存の `first-setup.sh`、`dev-tools.sh install`、`dev-tools.sh init`、`install.sh` に役割がある一方、プロジェクトが必要とする言語環境と依存関係を整える独立した流れがない。
- Broad-scan findings:
  - `first-setup.sh` はOS初期準備としてapt依存とproto/mise本体を扱い、言語ランタイム、plugin、開発ツールは導入しない。`installer-011-22-6-side-effect-boundary` もこの境界を明示している。
  - `.dev/dev-tools.sh install` はPython、Ruby、Node.jsを含む汎用CLI/ランタイムを利用者環境へ任意導入する。ユーザーの説明では、これらはAI開発でよく使う共有ツールであり、プロジェクト固有の言語指定を表すものではない。
  - `dev-tools.sh init` は導入済みのRTK、CodeGraph、Serenaなどのプロジェクト初期化を行う。`installer-011-16-project-init-scope` は不足バイナリを導入せず、`uv sync`、virtualenv作成などの言語依存セットアップを行わない契約である。
  - `install.sh` はAI向けアセットを配置してDODKitと開発ツールhelperを実行する。現状、プロジェクト言語の依存関係を明示的に扱う専用の入口はなく、READMEにもその操作例はない。
  - 適用する意思決定の基準はルートの `DECISIONS.yml` のみで、スコープ付きの別decisionファイルはない。既存の開発ツール、first-setup、README関連の決定は実装承認済みである。
- Focus areas:
  - 共有の汎用CLI導入と、プロジェクト指定の言語環境・依存セットアップを区別する。
  - 指定されたツールだけを対象とし、導入・設定・プロジェクト依存の準備を経て、利用可能かを確認する独立フローの責務を定める。
  - OSパッケージ、対応言語・ツール、依存の宣言元、runtime manager、配布先、動作確認方法は既存契約と照合し、どこまでを今回の決定に含めるかを見極める。
- Explicit exclusions: 今回はコード実装、既存の `first-setup.sh`・`dev-tools.sh install`・`dev-tools.sh init`・`install.sh` の動作変更、AI初期化への統合、OSパッケージ導入方式の追加を行わない。依存範囲はプロジェクトに宣言された言語・package依存とし、OSパッケージは既存のOSセットアップ境界に残す。
- Candidate direction:
  - プロジェクト用言語ツールの導入・セットアップは、既存の `dev-tools.sh` の `install` や `init` に混在させず、独立スクリプトとして設ける。
  - スクリプトは引数で選ばれたツールだけを対象にし、必要なruntime/toolの導入・プロジェクト依存のセットアップを行い、対象ツールが動作する状態か確認する。
  - `dev-tools.sh install` の共有ツール選定や `init` のAI向けプロジェクト初期化とは責務を分ける。`install.sh` や `init` からは自動実行しない。
  - 対応言語、依存マニフェストの扱い、利用するmanager、スクリプトの配置・配布、検証コマンドは未確定であり、実装前に別途絞り込む。
- Current conclusion: ユーザーは、引数で指定したツールについて導入・セットアップを行い、プロジェクト依存も準備して実際に利用できるところまでを対象とする独立スクリプトを希望している。依存の対象はOSパッケージではなく、プロジェクトに宣言された言語・package依存である。候補方向は既存のOSセットアップ、共有CLI導入、AIプロジェクト初期化から責務を分けること。対応対象や配布・実行方式は引き続き検討が必要である。
- Next validation target: 候補方向が `installer-011-22` のOS bootstrap境界、`installer-011-15` / `installer-011-16` の `dev-tools.sh` モードとinit責務、`installer-011-7` / `installer-011-10` のhelper配布境界、`installer-003-4` のREADME範囲と衝突しないかを確認する。特に、独立スクリプトの手動実行と配布場所、引数と依存宣言の対応、成功・失敗時の検証契約が昇格可能な粒度かを判定する。
- Promotion to DECISIONS.yml: pending
- Evidence / references: `DECISIONS.yml` (`installer-011-optional-tool-installation`, `installer-011-7-dev-tools-helper-boundary`, `installer-011-10-helper-first-integration`, `installer-011-15-mode-selection`, `installer-011-16-project-init-scope`, `installer-011-22-first-setup-dependencies`, `installer-003-4-readme-scope`); `first-setup.sh`; `templates/dev-tools.sh`; `install.sh`; `README.md`; user clarification in this discussion

### Entry 0002 (2026-11-08T16:45:00+09:00)
- Clarification: 独立スクリプトは `install.sh` の配布アセットとして対象プロジェクトへ配置するが、`install.sh` から自動実行しない。利用者が明示的に手動実行する。
- Findings / trade-offs: 配布先はAI向けアセットと同じ導入時に利用可能になる一方、プロジェクト依存の導入はAI環境の配置・DODKit実行から分離される。既存の配布アセット一覧、READMEの記載範囲、helper permissionの契約との整合が必要になる。
- Current conclusion: 「独立した手動実行スクリプトをinstall.shが配置するが実行しない」を候補方向へ追加する。配置先、実行permission、対応対象、依存宣言の読み方、動作確認方法は未決定とし、今回の議論で実装しない。
- Promotion to DECISIONS.yml: pending
- Evidence / references: user clarification in this discussion; `DECISIONS.yml` (`installer-001-project-scope`, `installer-010-asset-list-loop`, `installer-011-24-executable-helper-deployment`, `installer-003-4-readme-scope`); `install.sh`

### Entry 0003 (2026-11-08T16:47:00+09:00)
- Clarification: 成功条件は対象runtime/toolとプロジェクト依存の導入コマンドが成功することまでとする。別途の起動確認、プロジェクト全体のtest/build実行は要求しない。
- Current conclusion: Entry 0001の「利用可能か確認」は独立した動作チェックを意味しない。導入コマンドの成功を今回の完了条件とする。
- Promotion to DECISIONS.yml: pending
- Evidence / references: user clarification in this discussion

### Entry 0004 (2026-11-08T16:50:00+09:00)
- Discussion-validation: PASS. The bounded scan covered the OS bootstrap, shared CLI installation, AI-specific project initialization, installer asset deployment and invocation, README scope, relevant active decisions, and focused helper/installer test surfaces.
- Focus validation: 引数で対象を指定する独立スクリプト、プロジェクト宣言の依存のみを扱う範囲、install.shが配置するが実行しない境界へ絞ることは、ユーザーの回答と既存責務から妥当である。first-setupのOSパッケージ、dev-tools installの共有CLI、initのAIツール初期化は変更しない。
- Directional fit: PASS — 候補はプロジェクト固有の言語環境・依存セットアップという欠落を補い、利用者の明示操作を保つ。成功条件は導入コマンドの成功であり、別の動作チェックやプロジェクト全体のtest/buildを行わないという解釈も確認済みである。
- Contract fit: install.shのasset-list配布方式は新しいファイルを配置でき、明示実行に留めればDODKit/helperの既存実行順序と `dev-tools.sh init` の非依存導入契約を変えない。OSパッケージを対象外とすることで `first-setup.sh` の範囲も維持できる。
- Hidden bindings and ownership: 配布する資産の追加に伴い、installerの対象範囲とREADMEの許可記載範囲を明示する必要がある。配布元・配置先、直接実行permission、対応言語/ツール、manifestと引数の対応、runtime manager、コマンド失敗時の詳細は、実装前に追加決定が必要である。プロジェクト固有の制約は `DECISIONS.yml` を所有者とし、READMEには利用者向けの操作方法だけを記す。
- Promotion targets: 新規 `installer-011-26-project-language-tool-setup` を `dev-tools` 領域へ追加し、`installer-001-project-scope` と `installer-003-4-readme-scope` を今回の手動実行helper配布に合わせて更新する。`installer-010-asset-list-loop` は既存の配布方式として維持し、`installer-011-15-mode-selection` と `installer-011-16-project-init-scope` は変更しない。
- Validation result: PASS — broad scan、焦点の妥当性、元の目的、first-setup/dev-tools/installの既存契約、および文書の所有範囲に適合する。上記の実装詳細は未確定だが、今回合意したアーキテクチャと成功範囲の昇格を妨げない。実装には着手しない。
- Promotion to DECISIONS.yml: ready -> `installer-011-26-project-language-tool-setup`, `installer-001-project-scope`, `installer-003-4-readme-scope`
- Evidence / references: `DECISIONS.yml`; `records/installer-002-executable-helper-assets.md`; `tests/install.test.sh`; `tests/dev-tools.test.sh`; `install.sh`; `README.md`; user clarifications in this discussion

### Entry 0005 (2026-11-08T17:32:52+09:00)
- Promotion result: The validated high-level contract is now active in `DECISIONS.yml` as `installer-011-26-project-language-tool-setup`; `installer-001-project-scope` has a new manual-helper deployment sub-decision, and `installer-003-4-readme-scope` now includes the helper's user-facing usage.
- Current boundary: No implementation, README content, script asset, or test behavior was changed. Supported tools, dependency manifest mapping, manager, destination/permission, and command-failure details still require a focused implementation discussion.
- Promotion to DECISIONS.yml: promoted -> `installer-011-26-project-language-tool-setup`, `installer-001-1-project-language-tool-helper`, `installer-003-4-readme-scope`
- Evidence / references: `DECISIONS.yml`; discussion-validation PASS in Entry 0004

### Entry 0006 (2026-11-09T01:04:22+09:00)
- Implementation-scope clarification: The final script name remains undecided; `language-tools.sh` is a provisional name for this scaffold. The requested source location is `templates/language-tools.sh`. `install.sh` should copy the helper beside `dev-tools.sh` in the selected helper directory (default `.dev`) without executing it.
- CLI boundary: Accept one or more positional tool arguments. With no arguments, show Usage only and do not start setup. This request is for a scaffold before the actual installation logic.
- Current conclusion: The temporary scaffold can display Usage plus an explicit not-implemented error for supplied arguments and return nonzero, avoiding any appearance that setup succeeded. No tool or dependency installation is part of this step.
- Promotion to DECISIONS.yml: updated -> `installer-001-1-project-language-tool-helper`, `installer-011-26-project-language-tool-setup`
- Evidence / references: user clarification in this discussion

### Entry 0007 (2026-11-09T01:16:34+09:00)
- Scaffold result: Added `templates/language-tools.sh`. No arguments print Usage only; one or more arguments print Usage and an explicit not-implemented error with a nonzero exit. No installation side effects were added.
- Installer and documentation: `install.sh` deploys the provisional helper beside `dev-tools.sh` in the selected helper directory without invoking it. `README.md` describes the provisional name, current stub behavior, manual invocation, and intended scope.
- Scope boundary: No supported tools, runtimes, dependency managers, or project dependency installation logic were implemented.
- Verification: `bash tests/install.test.sh` passed all 18 tests; Bash syntax checks, decision YAML parsing, unique decision IDs (94), and `git diff --check` passed.
- Evidence / references: `templates/language-tools.sh`; `install.sh`; `README.md`; `tests/install.test.sh`; `DECISIONS.yml`

### Entry 0008 (2026-11-09T01:18:02+09:00)
- Implementation-validation: PASS for this scaffold request. The deployment target, manual-only invocation, no-argument Usage output, multi-argument explicit nonzero stub behavior, README scope, and provisional naming align with the approved scope.
- Decision status update: `installer-001-1-project-language-tool-helper` and `installer-003-4-readme-scope` are Implementation Approved. `installer-011-26-project-language-tool-setup` remains Implementing because actual tool setup and project dependency installation are intentionally deferred.
- Remaining limitation: The helper does not install or configure tools; this is the intended boundary of the current scaffold, not a blocker to this request.
- Evidence / references: focused installer tests, Bash syntax checks, decision YAML/ID validation, and whitespace checks
