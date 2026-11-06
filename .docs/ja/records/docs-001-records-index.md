# 決定記録: docs-001-records-index

## メタデータ
- 作成日: 2026-11-07
- スコープ: AGENTS.md から records の完全な目次を分離する。

## 注記
- このファイルは追記専用の議論履歴である。
- 状態、残作業、未完了の対応事項など、変更を前提とした追跡情報を記載しない。
- 未解決の質問を一覧として残さない。確認が必要な場合はチャットで質問し、解決した内容を追記する。
- 事実が実装上の拘束条件になった場合は、DECISIONS.yml に昇格する。
- 各記録は可能な限り簡潔にする。
- 記述だけで明確な場合、根拠や昇格に関する詳細なメタデータは省略できる。

記録の境界:
- 1つの記録は、まとまりのある1つの決定テーマに限定する。独立した質問、要素、または追加検討が出てきた場合は、無関係な履歴を追加せず、新しい `discussion-id` の記録を作成する。前の記録を引き継ぐ場合は、新しい記録の「根拠 / 参照」に記載する。
- レビューしやすさの目安として、記録が約10件または1,000語に達したら、自然な区切りで閉じ、新しい記録に続ける。これはパーサーで強制する上限ではない。同じテーマの追記が簡潔でレビューしやすい場合に限り、現在の記録を継続する。

追記ルール:
- ファイル末尾にのみ追記し、既存のセクションを編集しない。
- 状態管理や残作業の項目を追加しない。

## 記録一覧

### Entry 0001 (2026-11-07T00:34:34+09:00)
- なぜ今記録するか: ユーザーから、AGENTS.md に records の目次を増やし続けるとエージェント向け指示が際限なく長くなるため、完全な目次を records/index.md に移す案が提示された。
- 調査結果 / トレードオフ: DECISIONS.yml は配布用テンプレートとして templates/AGENTS.md を指定し、初期状態で空のテンプレートを許容しているが、records の目次に関するルールはない。AGENTS.md と templates/AGENTS.md には現在 records ディレクトリへの短いリンクがあり、.docs/ja に日本語版がある。records ディレクトリには installer、dev-tools、first-setup の3領域に分かれた18件の記録がある。README とテストコードは現在の records リンクに依存していない。.docs/PRINCIPLES.md は英語の開発ドキュメントに日本語版を対応させることを求めている。手動で目次を保守する作業は少し増えるが、完全な一覧をエージェント向け指示から分離できる。
- 対象 / 対象外 / 不確実性: records のナビゲーション、プロジェクトおよびテンプレートの AGENTS.md、日本語ミラー、関連する決定契約を対象とする。インストーラーの動作、README、テストコードは対象外。「目次は全部そっちに」は、既存の記録領域ごとに整理した全記録へのリンクを records/index.md に置き、AGENTS.md には短いリンクと新規記録の追加先だけを残す方針として解釈する。記録の追加・削除時に目次を更新する。
- 現時点の結論: records/index.md を records の完全な目次として作成し、AGENTS.md とそのテンプレートからリンクする。日本語ドキュメントも .docs/ja 以下で同期する方向を候補とする。
- DECISIONS.yml への昇格: discussion-validation 待ち。
- 根拠 / 参照 (任意): DECISIONS.yml (installer-002-templates-agents-md); AGENTS.md; templates/AGENTS.md; .docs/ja/templates/AGENTS.md; .docs/PRINCIPLES.md; 現在の records/*.md 一覧。

### Entry 0002 (2026-11-07)
- なぜ今記録するか: AGENTS.md にある日本語ドキュメントに関する記述と .docs/PRINCIPLES.md の間に矛盾がある可能性が見つかったため、ユーザーに意味を確認した。
- 調査結果 / トレードオフ: 「You do not need to add Japanese documentation」は、日本語文書を AGENTS.md の索引に個別項目として追加する必要はないという意味であり、.docs/PRINCIPLES.md の日本語ミラー作成要件を免除するものではない。
- 現時点の結論: records/index.md を英語の全記録目次とし、AGENTS.md からリンクする。.docs/ja に日本語版を維持するが、翻訳文書を AGENTS.md の索引に別項目として追加しない。
- DECISIONS.yml への昇格: discussion-validation 待ち。
- 根拠 / 参照 (任意): ユーザーによる確認; AGENTS.md; templates/AGENTS.md; .docs/PRINCIPLES.md.

### Entry 0003 (2026-11-07)
- なぜ今記録するか: 結論を有効な決定として昇格する前に、候補の方向性を検証する。
- 調査結果 / トレードオフ: 広範囲の調査では、プロジェクトの決定一覧、ルートと配布用の AGENTS.md、日本語テンプレート、現在の全記録、README やテストコードからの参照を確認した。対象の絞り込みは妥当である。既存の records 目次やネストされた決定ファイルはなく、影響を受けるナビゲーション面は関連するドキュメントに限られる。installer-002 は配布用テンプレートのコピー元を定め、初期テンプレートが空であることを許容するが、今回のドキュメント変更を制約しない。installer-005 のルート配置規則にも影響しない。ユーザーから、日本語文書は AGENTS.md の索引に個別項目として記載不要であり、.docs/PRINCIPLES.md の日本語ミラー作成要件は引き続き有効だと確認された。
- 現時点の結論: 検証に合格した。Documentation 領域に docs-001-records-index を1件昇格する。records/index.md を records/*.md 全件のカテゴリ別目次とし、記録の追加・削除時に更新する。AGENTS.md と templates/AGENTS.md には記録一覧を並べず、目次へのリンクを置く。日本語テンプレートは翻訳版目次へリンクし、日本語版文書を AGENTS.md の索引に個別追加しない。受け入れ条件は、存在する各記録が目次に1回ずつ含まれ、AGENTS.md に記録ごとの一覧がないこと。
- DECISIONS.yml への昇格: 検証済み。docs-001-records-index の昇格待ち。
- 根拠 / 参照 (任意): DECISIONS.yml (installer-002-templates-agents-md、installer-005-agents-md-deploy); AGENTS.md; templates/AGENTS.md; .docs/ja/templates/AGENTS.md; .docs/PRINCIPLES.md; records/*.md 一覧; ユーザーによる確認。

### Entry 0004 (2026-11-07)
- なぜ今記録するか: 目次の内容を設計する際に、受け入れ条件を実際の records ディレクトリに照らして確認した。
- 調査結果 / トレードオフ: `records/*.md` をそのまま対象にすると、記録ではなく目次である `records/index.md` 自体も含まれてしまう。目次には記録文書だけを列挙し、自身は含めない必要がある。
- 現時点の結論: 候補となる契約を、records/ 内の文書のうち index.md 以外の各記録を1回ずつ列挙すること、と明確化する。これは受け入れ条件を具体化するもので、ユーザー要求の範囲は変えない。
- DECISIONS.yml への昇格: docs-001-records-index の議論再検証待ち。
- 根拠 / 参照 (任意): records/ ファイル一覧; records/index.md の予定パス。

### Entry 0005 (2026-11-07)
- なぜ今記録するか: 実装前に、明確化した受け入れ条件を再検証する。
- 調査結果 / トレードオフ: index.md を除外することで、対象はリポジトリの records ディレクトリ内の決定記録文書に明確化される。ナビゲーション文書自身や .docs/ja にある日本語ミラーは含まれない。この調整は当初の範囲を変更せず、既存のインストーラー決定とも矛盾しない。
- 現時点の結論: 再検証に合格した。明確化した docs-001-records-index を昇格し、records 目次と簡潔な AGENTS.md リンクを実装する。
- DECISIONS.yml への昇格: 検証済み。docs-001-records-index は実装承認済みの段階に進む。
- 根拠 / 参照 (任意): DECISIONS.yml (docs-001-records-index; installer-002-templates-agents-md; installer-005-agents-md-deploy); records/ 一覧; .docs/PRINCIPLES.md.

### Entry 0006 (2026-11-07)
- なぜ今記録するか: 統合時に、配布される AGENTS.md テンプレートからのリンクの挙動を確認した。
- 調査結果 / トレードオフ: install.sh は templates/AGENTS.md を配布するが、records/ は配布しない。そのためテンプレートに records/index.md への相対リンクを置くと、導入先で参照先が存在しない。リポジトリルートの AGENTS.md はリポジトリ内の目次へリンクできるが、配布用テンプレートには適さない。
- 現時点の結論: records/index.md へのリンクはリポジトリルートの AGENTS.md だけに置く。templates/AGENTS.md とその日本語ミラーには、このリポジトリ固有の目次へのリンクを置かない。records/ を配布するためにインストーラーのアセットを増やさない。
- DECISIONS.yml への昇格: docs-001-records-index に昇格済み。
- 根拠 / 参照 (任意): install.sh の DEPLOYMENT_ASSET_SPECS; DECISIONS.yml (installer-005-agents-md-deploy、installer-009-principles-md-deploy); ユーザー要求。

### Entry 0007 (2026-11-07)
- なぜ今記録するか: 実装結果と対象範囲の検証結果を記録する。
- 調査結果 / トレードオフ: records/index.md には自身を除く19件すべての記録文書が一度ずつ記載され、すべてのリンクが解決する。日本語目次の元記録リンク集合も一致し、リンクが解決する。リポジトリルートの AGENTS.md だけがローカル目次へリンクし、配布用テンプレートとその日本語ミラーにはリンクがない。DECISIONS.yml は YAML として解析でき、git diff --check は成功し、インストーラーテスト18件が成功した。記録が変わった際の目次更新は手動で行う。
- 現時点の結論: インストーラーの動作や配布アセットを変更せず、docs-001-records-index の決定に沿った実装となった。
- DECISIONS.yml への昇格: docs-001-records-index は implementation-validation 待ちで実装中。
- 根拠 / 参照 (任意): 目次とリンクの検証; Ruby による YAML 解析; git diff --check; bash tests/install.test.sh (18件成功).

### Entry 0008 (2026-11-07)
- なぜ今記録するか: implementation-validation による docs-001-records-index の完了確認が終わった。
- 調査結果 / トレードオフ: 両目次の記録一覧が完全でリンクが解決すること、配布用テンプレートにリポジトリ固有のリンクがないこと、決定リンクと状態が最新であることを確認し、対象の検証はすべて成功した。目次の同期は手動で維持する。
- 現時点の結論: 実装を承認し、未解決の阻害要因はない。
- DECISIONS.yml への昇格: docs-001-records-index -> ✅️Implementation Approved.
- 根拠 / 参照 (任意): 目次とリンクの検証; DECISIONS.yml の解析と契約確認; git diff --check; bash tests/install.test.sh (18件成功).

### Entry 0009 (2026-11-07)
- なぜ今記録するか: 新しいドキュメントを目次に追加する指示が削除されたことは望ましくない、というユーザーの意見を受けた。
- 調査結果 / トレードオフ: 保守指示は残す必要があるが、「ここに」では記録ごとの項目を AGENTS.md に追加するよう誤解され、肥大化の問題が再発しうる。新しい文書は該当する目次へ追加するよう案内する。リポジトリルートの AGENTS.md は records/index.md を参照する一方、配布用テンプレートにはリポジトリ固有のリンクを置かない。
- 現時点の結論: 候補文は「新しいドキュメントを作成したら、該当する目次に必ず追加すること。」とする。ルート AGENTS.md、配布用テンプレート、日本語テンプレートにこの指示を残し、records 目次へのリンクはリポジトリルートの AGENTS.md のみに維持する。
- DECISIONS.yml への昇格: discussion-validation 待ち。
- 根拠 / 参照 (任意): ユーザーの追加指示; docs-001-records-index; AGENTS.md; templates/AGENTS.md; .docs/ja/templates/AGENTS.md.

### Entry 0010 (2026-11-07)
- なぜ今記録するか: 有効な契約を更新する前に、ユーザーの追加要望を検証する。
- 調査結果 / トレードオフ: 「ここに」を「該当する目次に」へ置き換えることで、索引作成の指示を維持しつつ、記録ごとの項目を AGENTS.md に追加する誤解を避けられる。リポジトリ向けの指示と配布用テンプレートの双方に適用でき、テンプレートにはリポジトリ固有の records 目次リンクを置かない。
- 現時点の結論: 検証に合格した。docs-001-1-new-document-indexing-guidance を昇格し、ルート AGENTS.md と配布用テンプレートに、新規文書を該当する目次へ追加する簡潔な指示を残す。記録一覧自体は records/index.md に置く。
- DECISIONS.yml への昇格: 検証済み。docs-001-1-new-document-indexing-guidance の昇格待ち。
- 根拠 / 参照 (任意): ユーザーの追加指示; 現在の docs-001-records-index 契約; AGENTS.md; templates/AGENTS.md; .docs/ja/templates/AGENTS.md; インストーラーの配布範囲.

### Entry 0011 (2026-11-07)
- なぜ今記録するか: 追加要望への実装と対象範囲の検証結果を記録する。
- 調査結果 / トレードオフ: 簡潔な保守指示をルートの AGENTS.md、配布用テンプレート、日本語テンプレートに戻した。リポジトリ固有の records 目次リンクはルートの AGENTS.md だけに残る。インストーラーテスト18件、文言とリンク範囲の確認、DECISIONS.yml の YAML 解析と親子決定の状態確認、git diff --check が成功した。
- 現時点の結論: 新規文書を該当する目次に追加する指示を「該当する目次」表現で復元し、記録一覧を AGENTS.md に戻さない。
- DECISIONS.yml への昇格: docs-001-records-index と docs-001-1-new-document-indexing-guidance は implementation-validation 待ちで実装中。
- 根拠 / 参照 (任意): 文言と範囲の確認; Ruby による YAML 決定確認; git diff --check; bash tests/install.test.sh (18件成功).

### Entry 0012 (2026-11-07)
- なぜ今記録するか: implementation-validation によって、追加変更が有効な決定契約に沿うことを確認した。
- 調査結果 / トレードオフ: 英語版の両 AGENTS.md と日本語テンプレートに指示があり、records/index.md へのリンクはリポジトリルートの AGENTS.md だけにある。対象のインストーラーテストとドキュメント確認は成功し、決定リンクと状態も最新である。
- 現時点の結論: AGENTS.md に記録一覧を再び増やすことなく、目次更新の指示を維持する。
- DECISIONS.yml への昇格: docs-001-records-index と docs-001-1-new-document-indexing-guidance -> ✅️Implementation Approved.
- 根拠 / 参照 (任意): bash tests/install.test.sh (18件成功); 文言と配布範囲の確認; YAML の決定・リンク確認; git diff --check.
