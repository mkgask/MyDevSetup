# Decision Record: dev-tools-008-installed-agents-sync

## Metadata
- Created At: 2026-08-09
- Scope: Synchronize installed development-tool entries in the AGENTS.md managed block

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to DECISIONS.yml.
- Keep each entry as short as the discussion allows.

## Entry List

### Entry 0001 (2026-08-09)
- Why now: `templates/dev-tools.sh` currently adds AGENTS.md entries only for tools newly installed during the current install. Existing installed tools are skipped, except for the narrow migration of managed `ripgrep`, `rtk`, and `codegraph` description lines.
- Findings / trade-offs: The controlling path is `process_install_tool` followed by `update_agents_managed_block`. The tool result state already distinguishes verified `present` and `installed` tools from skipped or failed tools. The managed block parser can update existing canonical lines and append missing lines without changing user content outside the block.
- Focus areas: During non-dry-run install, synchronize every tool whose command was verified as present or newly installed. If its canonical entry exists in the helper-managed block, rewrite it with the current verified command and fixed description format; if absent, append it to that block. Keep unavailable, skipped, and failed tools out of the block.
- Explicit exclusions: Do not update AGENTS.md during init, status, or dry-run. Do not modify user-owned text or entries outside the managed block, change tool installation or verification, alter DODKit/helper ordering, or change the existing compact descriptions and command-only format for other tools.
- Current conclusion: Extend the existing AGENTS.md recording rule from newly installed tools to all verified installed tools while retaining managed-block ownership and add/update idempotence.
- Promotion to DECISIONS.yml: pending
- Evidence / references: `templates/dev-tools.sh` (`process_install_tool`, `build_new_agents_entries`, `build_managed_agents_replacements`, `update_agents_managed_block`); `tests/dev-tools.test.sh`; `DECISIONS.yml` `installer-011-6-agents-tool-record`; `records/dev-tools-007-agents-tool-descriptions.md`; user request

### Entry 0002 (2026-08-09)
- Discussion-validation: PASS。bounded scan は install tool result state、AGENTS.md managed block の追加・置換・冪等性、既存の compact description migration、init/status/dry-run の side-effect boundary、ユーザー本文保護を確認した。verified `present`／`installed` の区別は既存状態で表現でき、独立した新しい tool installation mechanism は不要である。
- Contract fit: 現行の「新規導入成功のみ」制約だけを「現在の install で command verification に成功した `present`／`installed` 全対象」へ拡張する。未導入・skip・failure は記載せず、managed block 外の同名記載と user-owned 本文は変更しない。既存 managed line の command token 保持、三つの compact description、command-only tool の形式は維持する。
- Disconfirming check: 既存 installed tool の managed entry を旧形式で用意し、同じ tool を `present` として処理した後に canonical description／format が適用され、未記載の present tool が一度だけ追加され、skip／failed tool が追加されないことを focused test で確認する。二回目の同期結果は同一でなければならない。
- Promotion target: `installer-011-6-agents-tool-record` の対象を verified `present`／`installed` tools へ更新し、`installer-011-6-2-installed-tool-sync` sub-decision を追加する。status は実装中へ移行する。
- Evidence / references: `templates/dev-tools.sh` (`TOOL_RESULTS`, `TOOL_RESULT_DETAILS`, `NEW_TOOL_COMMANDS`); `tests/dev-tools.test.sh`; existing `installer-011-6-1-compact-tool-descriptions` contract

### Entry 0003 (2026-08-09)
- Implementation result: `agents_tool_is_verified()` が install 処理結果の `present`／`installed` を同期対象とし、`build_missing_agents_entries()` と `build_managed_agents_replacements()` が全 verified tool を扱うようにした。既存 managed line は command token を保持して表示形式を更新し、未記載行は検証済み command で追加する。command-only tool の置換も command-only のまま維持する。
- Test result: `tests/dev-tools.test.sh` の managed-block fixture を `TOOL_RESULTS`／`TOOL_RESULT_DETAILS` の present tool で検証する形へ更新し、既存 installed tool の更新、未記載 tool の追加、skip／failure の除外、冪等性、user-owned content 保護をカバーした。
- Scope boundary: init、status、dry-run、tool installation／verification、DODKit/helper の順序、managed block 外の AGENTS.md 本文は変更していない。

### Entry 0004 (2026-08-09)
- Implementation-validation: dev-tools focused suite 20件、installer suite 18件、first-setup suite 1件、Bash syntax、editor diagnostics、`git diff --check` が PASS した。Decision YAML の parse と decision ID 66件の一意性も PASS した。
- Artifact alignment: `installer-011-6-agents-tool-record` と `installer-011-6-2-installed-tool-sync` は verified `present`／`installed` 全件の managed-block 同期、既存 command token 保持、managed block 外の保護、skip／failure 除外、init/status/dry-run 非変更を明示し、実装と tests が一致している。statuses は `✅️Implementation Approved` へ更新する。
- Remaining risk: ShellCheck は環境に存在しないため実行していない。第三者 CLI の実 install／init は従来どおり mock-only の検証範囲である。
