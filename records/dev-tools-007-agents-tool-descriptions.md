# Decision Record: dev-tools-007-agents-tool-descriptions

## Metadata
- Created At: 2026-08-09
- Scope: Compact AGENTS.md descriptions for selected installed development tools

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to DECISIONS.yml.
- Keep each entry as short as the discussion allows.

## Entry List

### Entry 0001 (2026-08-09)
- Why now: `dev-tools.sh` currently records only `tool: command` in its managed AGENTS.md block. The requested entries for `rg`, `rtk`, and CodeGraph need compact usage descriptions, and a prior install must not leave the old managed line unchanged.
- Findings / trade-offs: The controlling path is `build_new_agents_entries` plus `update_agents_managed_block` in `templates/dev-tools.sh`. New entries can receive a tool-specific description without changing the existing command recording for Python, Ruby, uv, or Serena. The current `agents_contains_tool` check protects user-owned text and makes the helper skip already-recorded tools, so updating only matching lines inside the managed block is needed for migration without rewriting AGENTS.md prose outside that block. The active `installer-011-6-agents-tool-record` contract currently says not to add detailed explanations; this request is a narrow exception for three tools and should be promoted explicitly.
- Focus areas: Define compact English descriptions for `rg`, `rtk`, and `codegraph`; render them beside the verified command in newly added managed entries; replace only their existing lines inside the managed block when the tool is newly installed in the current run; preserve surrounding user content, add-only behavior for other tools, idempotence, and install-only AGENTS.md updates.
- Explicit exclusions: Do not change tool installation, init/status behavior, command verification, AGENTS.md content outside the managed block, descriptions for Python/Ruby/uv/Serena, or the managed block markers.
- Current conclusion: Use these compact descriptions: `rg` as recursive regex search that respects `.gitignore` and skips hidden/binary files by default, with `rg -uuu` to disable filtering; `rtk` as a CLI proxy that filters and compresses command output for LLM context, with `rtk --help` and its subcommands; and CodeGraph as mapping affected flows, tests, breakage, and business-logic risk. Keep the verified command in each entry and update only the helper-owned managed line when migrating an old entry.
- Promotion to DECISIONS.yml: pending
- Evidence / references: `templates/dev-tools.sh` (`build_new_agents_entries`, `update_agents_managed_block`); `tests/dev-tools.test.sh`; `DECISIONS.yml` `installer-011-6-agents-tool-record`; user-requested descriptions

### Entry 0002 (2026-08-09)
- Why now: Gate A の discussion-validation として、固定説明と既存管理ブロックの移行候補を active decision contract に照合した。
- Findings / trade-offs: Broad scan は `build_new_agents_entries`、`update_agents_managed_block`、AGENTS.md管理ブロックのfocused test、`installer-011-6-agents-tool-record`、install/init/statusの境界を確認した。管理ブロック内の該当行だけを置換すれば、既存ユーザー本文を保護したまま旧形式から移行できる。新規追加は従来どおり `NEW_TOOL_COMMANDS` と既存記載チェックに従い、他ツールの形式は維持する。
- Current conclusion: PASS — `rg`、`rtk`、`codegraph` の三つだけに短い固定説明を付け、現在の install 実行で導入成功した対象について、既存の管理ブロック行も同じ説明へ冪等に更新する方向は元の要求と既存契約に適合する。`installer-011-6-agents-tool-record` を更新し、三つの説明、管理ブロック内限定の移行、ユーザー本文保護を binding にする。
- Promotion to DECISIONS.yml: ready -> `installer-011-6-agents-tool-record`
- Evidence / references: `templates/dev-tools.sh`; `tests/dev-tools.test.sh`; `DECISIONS.yml`; user-requested compact descriptions

### Entry 0003 (2026-08-09)
- Clarification: 固定文はユーザー要求の主要語を省略しない。`rg` は Rust の line-oriented recursive regex search、gitignore・hidden・binary filtering、`rg -uuu` escape hatch を表す。`rtk` は high-performance output-filtering/compression proxy for LLM context、`rtk --help`、および useful subcommands を表す。CodeGraph は code-to-tests、breakage、affected flows、business-logic risk を表す。
- Contract adjustment: `installer-011-6-1-compact-tool-descriptions` の説明文を上記の内容へ更新する。説明文は固定であり、他ツールの command-only 形式、managed block 限定更新、install/init 境界は変更しない。
- Promotion to DECISIONS.yml: ready -> `installer-011-6-1-compact-tool-descriptions`

### Entry 0004 (2026-08-09)
- Implementation boundary clarification: 既存の管理ブロックを要求された形式へ収束させるため、三つの managed 行の移行は `NEW_TOOL_COMMANDS` の有無に依存させない。非 dry-run の install で既存行が管理ブロック内にある場合だけ、説明を更新し、既存行の command token は保持する。新規行の追加は従来どおり現在の install で導入に成功したツールだけを対象にする。
- Safety result: ユーザー本文・管理ブロック外の同名記載、他ツールの行、init/status/dry-run は変更しない。管理ブロック内に対象行がなければ新しい三つの行を勝手に追加しない。
- Promotion to DECISIONS.yml: ready -> `installer-011-6-agents-tool-record` / `installer-011-6-1-compact-tool-descriptions`

### Entry 0005 (2026-08-09T08:16:37Z)
- Implementation result: `templates/dev-tools.sh` に `rg`、`rtk`、`codegraph` の固定説明 formatter と、既存 managed block 行だけを説明付きへ同期する awk 更新を追加した。同期時は既存 command token を保持し、新規導入行は従来の `NEW_TOOL_COMMANDS` に基づく add-only 追加を維持した。現在の `AGENTS.md` も managed block の三行を同じ形式へ同期した。
- Test result: `tests/dev-tools.test.sh` は新規説明、command-only ツール、冪等性、管理ブロック内移行、管理ブロック外のユーザー記載保護、既存 command token 保持を検証する。
- Scope boundary: `init`、`status`、`dry-run`、導入経路、他ツールの AGENTS.md 表記は変更していない。

### Entry 0006 (2026-08-09T08:16:37Z)
- Implementation-validation: focused helper suite 20件、installer suite 17件、first-setup suite 1件、Bash syntax、editor diagnostics、YAML parse、decision ID uniqueness、`git diff --check` が PASS した。
- Artifact alignment: `installer-011-6-agents-tool-record` と `installer-011-6-1-compact-tool-descriptions` の固定文、managed block 限定更新、command token 保持、他ツール command-only、install/init/dry-run 境界がコード、tests、現在の `AGENTS.md` に揃っている。link は本 record を指している。
- Status result: 対象 decision を `✅️Implementation Approved` へ更新する。closeout を阻む問題はない。
- Remaining risk: ShellCheck は環境に存在しないため実行していない。第三者 CLI の実 install/init は従来どおり mock-only の検証範囲である。
