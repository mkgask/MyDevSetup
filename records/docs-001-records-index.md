# Decision Record: docs-001-records-index

## Metadata
- Created At: 2026-11-07
- Scope: Keep the complete records index out of AGENTS.md.

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to DECISIONS.yml.
- Keep each entry as short as the discussion allows.
- Evidence and detailed promotion metadata are optional; omit them when the entry stays clear without them.

Record boundary guidance:
- Keep one record focused on one cohesive decision theme. If an independent question, component, or follow-up appears, start a new record with a new `discussion-id` instead of extending unrelated history. Mention the prior record in `Evidence / references` when the new discussion continues from it.
- Use a practical reviewability signal: when a record reaches roughly 10 entries or 1,000 words, close it at a natural boundary and continue in a new record with a new `discussion-id`. This is a heuristic, not a hard parser-enforced limit; stay in the current record only when the next same-theme entry remains concise and reviewable.

Append rules:
- Append at EOF only; do not edit earlier sections.
- Do not add status tracking or remaining-work items.

## Entry List

### Entry 0001 (2026-11-07T00:34:34+09:00)
- Why now: The user noted that maintaining a growing records table of contents in AGENTS.md would make the agent instructions grow without bound, and suggested moving the full index to records/index.md.
- Findings / trade-offs: DECISIONS.yml fixes templates/AGENTS.md as the distributed source and permits an initially empty template, but has no records-index rule. AGENTS.md and templates/AGENTS.md each currently have a short records directory link, with a Japanese mirror under .docs/ja; the records directory contains 18 entries across installer, dev-tools, and first-setup. No README or test code depends on the current records link. .docs/PRINCIPLES.md requires Japanese mirrors for English development documentation. A curated index adds a small maintenance step but keeps the complete list out of the agent instructions.
- Focus / exclusions / uncertainty: Focus on records navigation, the project and template AGENTS.md files, their Japanese mirror, and the applicable decision contract. Installer behavior, README content, and test code are out of scope. Interpret "all contents in the index" as one complete list of record links in records/index.md, grouped by the existing record areas; AGENTS.md keeps only a short pointer and says where new records belong. Maintain the index when records are added or removed.
- Current conclusion: Candidate direction is to create records/index.md as the complete records table of contents, link to it from AGENTS.md and its template, and keep the Japanese documentation synchronized under .docs/ja.
- Promotion to DECISIONS.yml: pending discussion-validation.
- Evidence / references (optional): DECISIONS.yml (installer-002-templates-agents-md); AGENTS.md; templates/AGENTS.md; .docs/ja/templates/AGENTS.md; .docs/PRINCIPLES.md; current records/*.md inventory.

### Entry 0002 (2026-11-07)
- Why now: The user clarified the meaning of the existing Japanese-documentation note in AGENTS.md after a possible conflict with .docs/PRINCIPLES.md was identified.
- Findings / trade-offs: "You do not need to add Japanese documentation" means Japanese documents do not need separate entries in the AGENTS.md index; it does not waive the requirement in .docs/PRINCIPLES.md to maintain Japanese mirrors.
- Current conclusion: Keep records/index.md as the complete English records list and link to it from AGENTS.md. Maintain its Japanese mirror under .docs/ja, but do not add translated documents as separate entries in the AGENTS.md index.
- Promotion to DECISIONS.yml: pending discussion-validation.
- Evidence / references (optional): User clarification; AGENTS.md; templates/AGENTS.md; .docs/PRINCIPLES.md.

### Entry 0003 (2026-11-07)
- Why now: Validate the candidate direction before promoting it into the active decision list.
- Findings / trade-offs: The broad scan covered the project decision baseline, root and distributed AGENTS.md files, the Japanese template mirror, all current records, and possible README or test references. The focus is justified: there is no existing records index or nested decision file, and the affected docs are the only navigation surfaces. installer-002 fixes the distributed template source and allows an initially empty template without constraining this documentation update; installer-005 keeps deployment at the project root and is unaffected. The user clarified that Japanese documents need not be listed separately in the AGENTS.md index, while .docs/PRINCIPLES.md still requires Japanese mirrors.
- Current conclusion: Validation passed. Promote one Documentation decision, docs-001-records-index: records/index.md is the complete, categorized index of every records/*.md file and is updated when records are added or removed; AGENTS.md and templates/AGENTS.md point to it without enumerating records. The Japanese template points to the translated index, and Japanese mirrors are not separate AGENTS.md index entries. Acceptance is that every current record appears once in the index and no per-record list remains in AGENTS.md.
- Promotion to DECISIONS.yml: validated; promotion pending -> docs-001-records-index.
- Evidence / references (optional): DECISIONS.yml (installer-002-templates-agents-md and installer-005-agents-md-deploy); AGENTS.md; templates/AGENTS.md; .docs/ja/templates/AGENTS.md; .docs/PRINCIPLES.md; records/*.md inventory; user clarification.

### Entry 0004 (2026-11-07)
- Why now: While deriving the index contents, the acceptance wording was checked against the actual records directory.
- Findings / trade-offs: A literal records/*.md glob also matches records/index.md, which is the index rather than a decision record. The index must enumerate the record documents only and must not list itself.
- Current conclusion: Clarify the candidate contract to require every record document under records/ other than index.md exactly once. This narrows the acceptance check without changing the user-requested scope.
- Promotion to DECISIONS.yml: discussion revalidation pending -> docs-001-records-index.
- Evidence / references (optional): records/ file inventory; proposed records/index.md path.

### Entry 0005 (2026-11-07)
- Why now: Revalidate the clarified acceptance contract before implementation.
- Findings / trade-offs: Excluding index.md makes the target set unambiguous: decision-record documents in the repository's records directory, not the navigation document or its Japanese mirror under .docs/ja. The adjustment does not change the original scope or conflict with active installer decisions.
- Current conclusion: Revalidation passed. Promote the clarified docs-001-records-index contract and proceed with the records index and concise AGENTS.md pointers.
- Promotion to DECISIONS.yml: validated; docs-001-records-index approved for implementation.
- Evidence / references (optional): DECISIONS.yml (docs-001-records-index; installer-002-templates-agents-md; installer-005-agents-md-deploy); records/ inventory; .docs/PRINCIPLES.md.

### Entry 0006 (2026-11-07)
- Why now: Integration review checked the link behavior of the distributed AGENTS.md template.
- Findings / trade-offs: install.sh deploys templates/AGENTS.md but does not deploy records/. A relative records/index.md link in the template would therefore be broken in target projects. The repository root AGENTS.md can link to the repository-local index, but the distributable template cannot.
- Current conclusion: Keep the records/index.md pointer only in the repository root AGENTS.md. Keep templates/AGENTS.md and its Japanese mirror free of links to this repository-local index; do not expand installer assets to distribute records/.
- Promotion to DECISIONS.yml: promoted -> docs-001-records-index.
- Evidence / references (optional): install.sh DEPLOYMENT_ASSET_SPECS; DECISIONS.yml (installer-005-agents-md-deploy and installer-009-principles-md-deploy); user request.

### Entry 0007 (2026-11-07)
- Why now: Record the implementation outcome and focused verification results.
- Findings / trade-offs: records/index.md lists all 19 record documents exactly once, excluding itself, and all links resolve. The Japanese index has the same source-record set and its links resolve. Only the repository root AGENTS.md links to the repository-local index; the deployed template and its Japanese mirror do not. DECISIONS.yml parses as YAML, git diff --check is clean, and all 18 installer tests pass. The indexes remain manually maintained when records change.
- Current conclusion: The implementation matches docs-001-records-index without changing installer behavior or deployed assets.
- Promotion to DECISIONS.yml: docs-001-records-index remains Implementing pending implementation-validation.
- Evidence / references (optional): focused index/link check; Ruby YAML parse; git diff --check; bash tests/install.test.sh (18 passed).

### Entry 0008 (2026-11-07)
- Why now: Implementation-validation completed the closeout checks for docs-001-records-index.
- Findings / trade-offs: The record set is complete in both indexes, links resolve, the repository-only pointer is not present in the deployed template, the decision link and status are current, and all focused checks pass. Index synchronization remains a manual maintenance requirement.
- Current conclusion: Implementation is approved with no remaining blocker.
- Promotion to DECISIONS.yml: docs-001-records-index -> ✅️Implementation Approved.
- Evidence / references (optional): focused index/link check; DECISIONS.yml parse and contract check; git diff --check; bash tests/install.test.sh (18 passed).

### Entry 0009 (2026-11-07)
- Why now: The user noted that removing the instruction to index new documents was undesirable.
- Findings / trade-offs: The maintenance instruction should remain, but "here" could send every record entry back into AGENTS.md and recreate the growth problem. Direct new documents to their relevant index instead: the repository root AGENTS.md points to records/index.md, while the distributable template must remain free of this repository-local link.
- Current conclusion: Candidate wording is "Whenever you create a new document, be sure to add it to the relevant index." Keep it in the root AGENTS.md, distributed template, and Japanese template mirror; retain the existing records-index pointer only in the repository root AGENTS.md.
- Promotion to DECISIONS.yml: pending discussion-validation.
- Evidence / references (optional): User follow-up; docs-001-records-index; AGENTS.md; templates/AGENTS.md; .docs/ja/templates/AGENTS.md.

### Entry 0010 (2026-11-07)
- Why now: Validate the user's follow-up before updating the active contract.
- Findings / trade-offs: Replacing "here" with "the relevant index" preserves the indexing instruction without directing every record entry into AGENTS.md. It works for both the repository instructions and the distributed template; the template remains free of a link to the repository-only records index.
- Current conclusion: Validation passed. Promote docs-001-1-new-document-indexing-guidance: keep a concise instruction in the root AGENTS.md and distributed template to add new documents to the relevant index, while keeping the record list itself in records/index.md.
- Promotion to DECISIONS.yml: validated; promotion pending -> docs-001-1-new-document-indexing-guidance.
- Evidence / references (optional): User follow-up; current docs-001-records-index contract; AGENTS.md; templates/AGENTS.md; .docs/ja/templates/AGENTS.md; installer deployment scope.

### Entry 0011 (2026-11-07)
- Why now: Record the implementation and focused checks for the follow-up.
- Findings / trade-offs: The concise maintenance instruction is present in the repository AGENTS.md, distributed template, and Japanese template mirror. The repository-only records index link remains only in the root AGENTS.md. All 18 installer tests pass, the focused wording/scope check passes, DECISIONS.yml parses with the expected parent and child statuses, and git diff --check is clean.
- Current conclusion: The instruction to index new documents has been restored with "relevant index" wording, without moving the records list back into AGENTS.md.
- Promotion to DECISIONS.yml: docs-001-records-index and docs-001-1-new-document-indexing-guidance remain Implementing pending implementation-validation.
- Evidence / references (optional): focused wording/scope check; Ruby YAML decision check; git diff --check; bash tests/install.test.sh (18 passed).

### Entry 0012 (2026-11-07)
- Why now: Implementation-validation confirmed the follow-up matches the active decision contract.
- Findings / trade-offs: The instruction is present in both English AGENTS files and the Japanese template mirror; only the repository root AGENTS.md links to records/index.md. The focused installer and documentation checks pass, and the decision link/status are current.
- Current conclusion: The indexing instruction is retained without reintroducing a growing records list in AGENTS.md.
- Promotion to DECISIONS.yml: docs-001-records-index and docs-001-1-new-document-indexing-guidance -> ✅️Implementation Approved.
- Evidence / references (optional): bash tests/install.test.sh (18 passed); focused wording and deployment-scope checks; YAML decision/link check; git diff --check.
