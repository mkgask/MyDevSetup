# Decision Record: first-setup-002-installer-deployment

## Metadata
- Created At: 2026-08-03
- Scope: install.sh による first-setup.sh 配布

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to DECISIONS.yml.
- Keep each entry as short as the discussion allows.

## Entry List

### Entry 0001 (2026-08-03T16:24:17Z)
- Why now: `templates/first-setup.sh` も `install.sh` で配布し、`dev-tools.sh` と同じ配置先で利用できるようにしたい。現在の `installer-011-22-first-setup-dependencies` には「初期スコープでは install.sh の配布アセットへ追加しない」という制約があり、今回の要求と衝突する。
- Findings / trade-offs: `install.sh` は `DEPLOYMENT_ASSET_SPECS` の source path / destination path / asset name の3要素をループして配布する。`select_dev_tools_destination` は既定の `.dev/` を使い、既存時だけ利用者が別ディレクトリを選べるが、現在は `dev-tools.sh` の配置先だけを動的に更新する。`templates/first-setup.sh` は既にローカルテンプレート解決と raw GitHub fallback の対象にでき、単独の `tests/first-setup.test.sh` で実行契約を検証している。`installer-011-9-helper-destination` は既定の `.dev/dev-tools.sh`、選択時の同一ディレクトリ、helper の上書きを定め、`installer-012-3-helper-overwrite-exception` は `dev-tools.sh` の無条件更新を定めている。新しい companion を `.dev/` 配下へ追加する場合、別の配置先 prompt や自動実行を導入すると既存の責務境界を広げるため、同じ選択済みディレクトリへコピーするだけに留めるのが小さい。`tests/install.test.sh` の fixture と比較検証は現状 `dev-tools.sh` だけを対象としているため、配布・カスタム配置・上書きの omission risk がある。
- Current conclusion: `install.sh` の配布アセットへ `templates/first-setup.sh` を追加し、既定の配置先を `.dev/first-setup.sh` とする。既存 `.dev/` で別ディレクトリが選ばれた場合も `dev-tools.sh` と同じ選択済みディレクトリへ配置する。`first-setup.sh` はコピー後に自動実行せず、既存 helper と同じ配布処理の上書き例外として更新する。`install.sh` の配布リスト・動的配置更新・focused installer test を変更対象とし、`templates/first-setup.sh` の apt 動作や `tests/first-setup.test.sh` の実行契約は変更しない。README の操作例追加は今回のコピー契約に必須ではないため、公開利用手順の別要求がない限り変更しない。
- Promotion to DECISIONS.yml: pending
- Evidence / references (optional): `install.sh` の `DEPLOYMENT_ASSET_SPECS`、`select_dev_tools_destination`、`install_template_asset`、`tests/install.test.sh` の fixture と配布テスト、`DECISIONS.yml` の `installer-011-9-helper-destination`、`installer-011-22-first-setup-dependencies`、`installer-012-3-helper-overwrite-exception`

## Append Template (Copy and Append at EOF)

### Entry {next-sequence} ({timestamp})
- Why now:
- Findings / trade-offs:
- Current conclusion:
- Promotion to DECISIONS.yml:
- Evidence / references (optional):

### Entry 0002 (2026-08-03T16:25:00Z)
- Why now: Gate A step 2 として、Entry 0001 の候補方向を現在の意思決定契約と実装境界へ照合した。
- Findings / trade-offs: Broad scan は `install.sh` の配布リスト、source URL fallback、既定・カスタム配置先の選択、asset 上書き判定、DODKit と helper の実行順、`tests/install.test.sh` の fixture、`templates/first-setup.sh` の単体責務、README の最小公開範囲、関連する `installer-011-9`、`installer-011-10`、`installer-011-22`、`installer-012-3` を確認している。候補は既存の3要素 asset loop とローカル/raw 配布経路を再利用でき、first-setup を自動実行しないことで apt 操作を install.sh の実行責務へ持ち込まない。既存 `.dev/` 時の一回の配置先 prompt を共有し、選択されたディレクトリだけを配布先にするため、別 prompt、別 destination policy、別の実行順を増やさない。`--overwrite no` でも companion を更新する契約は既存 helper の無条件更新例外を拡張するため、`DECISIONS.yml` に明示する必要がある。
- Current conclusion: PASS — 候補方向は要求に適合し、asset loop、既定・カスタム配置、helper の上書き、DODKit 引数透過、first-setup の手動実行境界、既存テンプレート保護と衝突しない。Promotion では `installer-011-22-first-setup-dependencies` の古い「install.sh へ追加しない」文言を除去し、`first-setup` 配下に `installer-011-23-first-setup-deployment` を追加して default/custom destination、非自動実行、配布対象としての受け入れ条件を明示する。共有上書き例外は `installer-012-3-helper-overwrite-exception` を `dev-tools.sh` と `first-setup.sh` の両方へ更新する。README と first-setup 自体の実行契約は今回の配布変更では変更しない。
- Promotion to DECISIONS.yml: validated -> installer-011-22-first-setup-dependencies, installer-011-23-first-setup-deployment, installer-012-3-helper-overwrite-exception
- Evidence / references (optional): `install.sh` の `DEPLOYMENT_ASSET_SPECS`、`select_dev_tools_destination`、`install_template_asset`、`tests/install.test.sh`、`templates/first-setup.sh`、`README.md`、関連 decision entries

### Entry 0003 (2026-08-03T16:32:00Z)
- Why now: Gate A 完了後、promoted contract に従って配布実装と focused test を統合した。
- Findings / trade-offs: `install.sh` の asset list に `templates/first-setup.sh|.dev/first-setup.sh|first-setup.sh` を追加し、既存の配置先選択後に companion の destination も同じディレクトリへ更新した。`install_template_asset` の無条件上書き例外を `dev-tools.sh` と `first-setup.sh` に共有させた。`tests/install.test.sh` の fixture は first-setup のコピーと、自動実行されると marker を残して失敗する mock を用意したため、配布だけで自動実行しない境界も検証できる。
- Current conclusion: `first-setup.sh` は既定の `.dev/first-setup.sh` と、既存 `.dev/` から選択したカスタム配置先の両方へ `dev-tools.sh` と同じ経路でコピーされる。`--overwrite no` でも companion は更新され、DODKit 実行後に自動実行されることはない。
- Promotion to DECISIONS.yml: implementation -> installer-011-22-first-setup-dependencies, installer-011-23-first-setup-deployment, installer-012-3-helper-overwrite-exception
- Evidence / references (optional): `bash tests/install.test.sh` は 15 focused tests passed。変更対象は `install.sh` と `tests/install.test.sh`。

### Entry 0004 (2026-08-03T16:33:00Z)
- Why now: Gate B の実装結果を closeout 前の deterministic checks と decision contract に照合した。
- Findings / trade-offs: `bash tests/first-setup.test.sh` は 1件、`bash tests/dev-tools.test.sh` は 20件、`bash tests/install.test.sh` は 15件すべて PASS。`bash -n install.sh templates/first-setup.sh templates/dev-tools.sh tests/install.test.sh tests/first-setup.test.sh tests/dev-tools.test.sh`、対象ファイルの editor diagnostics、`git diff --check` も PASS した。first-setup template の apt 動作と focused test は変更しておらず、README の既存 `.dev/dev-tools.sh` 操作例とも用語上の衝突はない。
- Current conclusion: PASS — 実装、focused tests、decision contract は、first-setup.sh を dev-tools.sh と同じ選択済み配置先へコピーし、自動実行せず、helper と同じ上書き扱いにする要求へ整合している。新しい binding constraint や未解決 blocker は発生していない。
- Promotion to DECISIONS.yml: implementation validation -> installer-011-22-first-setup-dependencies, installer-011-23-first-setup-deployment, installer-012-3-helper-overwrite-exception
- Evidence / references (optional): `DECISIONS.yml` は YAML parse と 61 unique decision IDs を通過。対象ファイルの editor diagnostics は errors なし。
