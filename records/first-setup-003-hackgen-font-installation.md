# Decision Record: first-setup-003-hackgen-font-installation

## Metadata
- Created At: 2026-08-16
- Scope: Ubuntu user-local installation of the latest HackGen Nerd Fonts

## Notes
- This file is append-only discussion history.
- Do not add mutable tracking fields here (status, remaining work, open action items).
- Do not keep open-question backlogs here. If clarification is needed, ask in chat and append the resolved facts.
- If a fact becomes a binding implementation constraint, promote it to `DECISIONS.yml`.
- Keep each entry as short as the discussion allows.

## Entry List

### Entry 0001 (2026-08-16)
- Why now: UbuntuへGitHubの最新HackGen Nerd Fontsリリースから`HackGenConsoleNF-Bold.ttf`と`HackGenConsoleNF-Regular.ttf`だけを取得してユーザー環境へ導入し、VS Codeのフォント設定は手動で行いたい。配置先として`install.sh`、`dev-tools.sh`、`first-setup.sh`のどこが適切かを決める必要がある。
- Broad-scan findings:
  - GitHub APIのlatest releaseは現時点で`v2.10.0`で、アセットは`HackGen_NF_v2.10.0.zip`。実際のZIPには`HackGenConsoleNF-Bold.ttf`と`HackGenConsoleNF-Regular.ttf`が含まれ、フォントメタデータのファミリー名は`HackGen Console NF`、スタイルはそれぞれ`Bold`と`Regular`だった。将来版は`HackGen_NF_*.zip`のパターンで選ぶ必要がある。
  - `install.sh`は対象プロジェクトへ管理アセットを配布し、DODKitを実行し、配布した`dev-tools.sh`を起動するオーケストレーターである。ここへフォントの外部ダウンロードを直接追加すると、プロジェクト導入のたびにユーザー環境を変更する副作用と、DODKit/helperの処理境界の混在が生じる。
  - `dev-tools.sh`はPython、Ruby、Node.js、rg、RTK、CodeGraph、uv、SerenaのCLIをinstall/status/init/dry-runで扱う。フォントを対象へ加えると、CLI検証、route選択、`--global`、AGENTS.md記録、既存のfocused testへ非CLI資産を混ぜることになるため、責務がずれる。
  - `first-setup.sh`はUbuntu/Linux/WSL向けの手動ブートストラップで、現在はAPT依存パッケージだけを導入し、`install.sh`から自動実行されない。既に`curl`と`unzip`を依存集合へ含み、`.dev/first-setup.sh`として配布する契約もあるため、OSユーザー環境の初期準備を置く場所としては最も近い。ただし、既存の引数なし実行は開発ツール依存のAPT導入に限定されており、フォントを無条件で追加すると任意機能のネットワーク取得が隠れてしまう。
  - リポジトリにはフォント配置、`fc-cache`、`fc-list`の既存実装はない。ユーザー単位の標準配置先は`$XDG_DATA_HOME/fonts`（未設定時は`$HOME/.local/share/fonts`）で、システム領域へsudoでコピーする必要はない。反映には`fontconfig`の`fc-cache`が必要になる。
- Focus areas:
  - `first-setup.sh`に、既存の引数なしAPTセットアップとは独立した明示的なHackGen導入モード（候補名: `--install-hackgen`）を追加するかどうか。既存モードの挙動と自動実行境界は維持する。
  - `HackGen_NF_*.zip`をGitHubのlatest releaseから動的に選択する取得方法、ZIPから指定2ファイルだけを安全に抽出する方法、HTTPS・一時ディレクトリ・失敗時cleanupの契約。
  - `$XDG_DATA_HOME/fonts/HackGen`へのユーザー単位配置、TTFを`0644`で更新する冪等性、`fc-cache`後に`HackGen Console NF`の2スタイルを検証する方法。root実行時に`/root`へ誤配置しない境界も含める。
  - `fontconfig`をAPT依存集合へ追加するか、既存環境の`fc-cache`を必須条件として検証するか。外部取得を伴う任意機能のため、非対話実行時に確認を追加するかも明示する。
- Explicit exclusions: `install.sh`実行時の自動フォント導入、`dev-tools.sh`のCLI対象・AGENTS.md管理ブロック・manager routeへのフォント追加、VS Codeの`settings.json`やagent設定の変更、システム全体`/usr/share/fonts`へのsudo導入、Windows側フォント登録、フォント以外のHackGenバリエーション、Nerd Fontsの再合成、最新版以外の固定バージョン採用は今回の対象外とする。WSLでWindows側のVS Codeから同じフォントが見えるかは、Ubuntuユーザー環境への導入契約とは分けて確認する。
- Current conclusion: 配置責務は`first-setup.sh`が最も適切。ただし、APT依存配列へフォントを混ぜたり、引数なし実行で毎回ダウンロードしたりせず、明示的なHackGen導入モードとして分離する方向を候補とする。実装する場合はGitHub latestから`HackGen_NF_*.zip`を取得し、指定のRegular/BoldだけをユーザーのXDGフォントディレクトリへ配置し、`fc-cache`とフォント名検証まで行う。VS Codeのフォント設定はリポジトリから変更せず、利用者が`HackGen Console NF`を手動指定する。`install.sh`と`dev-tools.sh`は変更対象から除外する。
- Next validation target: discussion-validationでは、明示モードをfirst-setupへ追加することが既存のAPT依存・手動実行・Ubuntu/Linux境界と整合するか、latest assetの動的選択を`gh`既存依存または構造化API parserで安全に行えるかを確認する。併せて、`fontconfig`の前提、非rootユーザー単位配置、更新時のatomic/idempotent behavior、ZIP内の想定外パス拒否、ネットワーク失敗・欠落TTF・`fc-cache`失敗の終了契約をmockで検証できるfocused test境界を確定する。
- Promotion to DECISIONS.yml: pending
- Evidence / references: `install.sh`; `templates/first-setup.sh`; `templates/dev-tools.sh`; `tests/install.test.sh`; `tests/first-setup.test.sh`; `tests/dev-tools.test.sh`; `README.md`; `DECISIONS.yml` decisions `installer-011-2`, `installer-011-9`, `installer-011-22`, `installer-011-23`, `installer-011-24`; `https://api.github.com/repos/yuru7/HackGen/releases/latest`; `https://github.com/yuru7/HackGen/releases/`

### Entry 0002 (2026-08-16)
- Why now: `first-setup.sh`はOSセットアップ後、`dev-tools.sh`を実行する前に一度だけ手動実行する前提であり、毎回の実行を想定した補助コマンドではない。この運用前提により、前Entryで候補にした明示的なHackGen専用モードの必要性を見直す。
- Findings / trade-offs:
  - 無引数のfirst-setup実行でAPT依存とHackGen導入を続けて行う方が、利用者の実行手順を増やさず、OS初期準備という既存責務にも適合する。`install.sh`からの自動実行ではないため、プロジェクト導入のたびにフォントを変更する境界も維持できる。
  - インストール済み判定はfontconfigの検索結果や追加コマンドに依存せず、ユーザー単位の対象ディレクトリに`HackGenConsoleNF-Regular.ttf`と`HackGenConsoleNF-Bold.ttf`の両方が存在することを受け入れ条件にする。両方が存在する場合はGitHubへの問い合わせ、ZIPダウンロード、展開、コピーを行わない。
  - 片方だけが存在する場合は不完全な導入として扱い、最新版ZIPから2ファイルを一組で取得して揃える。既存の片方だけを残して組み合わせを作らず、インストール中に失敗しても既存ファイルを先に削除しない。
  - 「最新版」は初回導入時にGitHub latestから取得する意味とし、既存の2ファイルを検出した再実行ではリリースタグ比較や自動更新を行わない。リリースAPIへの問い合わせ、バージョンマーカー、旧版削除を追加すると、一度きりのbootstrapの責務とテスト範囲を広げる。将来の明示的な更新機能は別議論とする。
  - フォントキャッシュ反映は導入後に`fc-cache`を使う候補とし、そのため`fontconfig`をAPT依存集合へ追加する必要性をdiscussion-validationで確認する。導入済みの再実行でもキャッシュ更新だけを許可するか、ファイル存在時は完全にスキップするかを実装契約で確定する。
- Focus areas:
  - 無引数first-setupの既存APT処理の後へ、HackGenのペア存在判定とユーザー単位コピーを追加する境界。明示的なHackGen専用引数は候補から外す。
  - `$XDG_DATA_HOME/fonts/HackGen`（未設定時は`$HOME/.local/share/fonts/HackGen`）を対象にしたペア判定、最新版アセット選択、ZIP内の指定TTF抽出、一時ファイルからの更新、`fc-cache`の扱い。
  - focused testで、完全導入済みなら外部取得系コマンドを呼ばないこと、片方欠落なら2本を一組で導入すること、取得・展開・キャッシュ失敗を明示的な非0として扱うことを検証する。
- Explicit exclusions: 無引数実行での毎回の最新版チェック、既存フォントの自動アップデート・旧版削除・バージョンマーカー、HackGen専用の明示モード、システム全体フォント領域へのsudoコピー、VS Code設定変更、`dev-tools.sh`や`install.sh`へのフォント処理追加は今回の対象外とする。
- Current conclusion: 無引数の`first-setup.sh`でHackGen導入を行う。対象ユーザーのフォントディレクトリにRegular/Boldの両方があれば導入済みとして再インストールせず、片方でも欠ける場合だけGitHub latestの`HackGen_NF_*.zip`から2ファイルを一組で取得する。初回導入時の「最新版」と、将来リリースへの自動追従は分離し、更新機能は今回作らない。前Entryの「明示的なHackGen導入モード」はこの結論で置き換える。
- Next validation target: discussion-validationでは、無引数APTセットアップへの統合が`installer-011-22-first-setup-dependencies`の手動・Linux/WSL・非自動実行契約に適合するか、`fontconfig`追加と`fc-cache`が必要最小限か、root実行時もユーザー単位配置を誤らないかを確認する。promotion時は、ペア存在時のネットワーク・展開・コピー抑止、片方欠落時の一組更新、旧版を自動更新しない境界を`DECISIONS.yml`へ明示する。
- Promotion to DECISIONS.yml: pending
- Evidence / references: 前Entryの調査結果; `templates/first-setup.sh`; `tests/first-setup.test.sh`; `DECISIONS.yml` `installer-011-22-first-setup-dependencies`; ユーザー補足

### Entry 0003 (2026-08-16)
- Why now: Gate A step 2として、Entry 0002の無引数統合・ペア存在判定・自動更新を行わない方向を、現在のfirst-setup契約と実行環境でvalidationした。
- Landscape validation: `templates/first-setup.sh`、`tests/first-setup.test.sh`、`install.sh`の手動配布境界、`DECISIONS.yml`のfirst-setup契約を再確認した。実環境では`fc-cache`と`fc-scan`が利用可能で、`fontconfig`は導入済みだった。`gh api`は未認証環境で`gh auth login`を要求するためlatest取得経路には不適切だが、公開GitHub APIを`curl`で取得し`jq`で`.assets[]`から`HackGen_NF_*.zip`を選ぶ方法は、現行latestの`HackGen_NF_v2.10.0.zip`で成立した。
- Directional fit: first-setupをOSセットアップ後に一度だけ手動実行し、その後dev-tools.shを実行するという利用者の運用に対して、無引数実行へHackGenを含める方向は直接適合する。install.shからの自動実行、dev-tools.shのCLI inventory、VS Code設定を広げないため、元の責務分離も維持する。
- Contract fit: `installer-011-22-first-setup-dependencies`のAPT更新・インストール・Linux/WSL・非root時のsudo・他managerへfallbackしない契約を維持し、依存集合へ`fontconfig`と`jq`を追加する。フォントは実行ユーザーの`$XDG_DATA_HOME/fonts/HackGen`（未設定時は`$HOME/.local/share/fonts/HackGen`）へsudoなしで配置する。Regular/Boldの両方が存在する場合は、API問い合わせ、ZIP取得、展開、コピー、`fc-cache`をすべて省略する。片方でも欠ける場合だけlatestのZIPから2ファイルを一組で取得し、配置後に`fc-cache`を実行する。既存ペアのリリースタグ比較、旧版削除、無引数再実行時の自動更新は行わない。
- Hidden bindings: latestアセット選択は未認証の`gh api`ではなく`curl`+`jq`の構造化解析とし、候補が一つでない場合をエラーにする必要がある。ZIPから必要な2ファイルが揃わなければコピーを開始せず、取得・展開・キャッシュ更新の失敗は明示的な非0終了とする。片方欠落時の再導入で既存の片方を先に削除しない更新手順と、ユーザー単位フォント配置を新しいbindingとしてDECISIONS.ymlへ昇格する必要がある。
- Promotion targets: `installer-011-22-first-setup-dependencies`へ`fontconfig`と`jq`を追加し、新規`installer-011-25-hackgen-font-installation`で無引数実行、latest ZIPの選択、対象2ファイル、ユーザー単位配置、両方存在時の完全スキップ、片方欠落時の一組導入、`fc-cache`、自動更新非対応、失敗時の終了契約を定める。`installer-011-23-first-setup-deployment`と`installer-011-24-executable-helper-deployment`は既存の配布・実行権限契約を継承し、`tests/first-setup.test.sh`へfocused testを追加する。
- Validation result: PASS — broad scanはfirst-setupの依存・配布・手動実行境界、GitHub取得方法、fontconfig、ユーザー単位配置、既存ペア判定、失敗時のテスト境界を覆っている。無引数統合への絞り込みは利用者の実行順と既存責務から導かれ、明示モードや自動更新を除外する理由も明確である。現時点でDECISIONS.ymlは未変更で、次段階は上記targetのpromotionである。
- Promotion to DECISIONS.yml: ready -> `installer-011-22-first-setup-dependencies`, new `installer-011-25-hackgen-font-installation`
- Evidence / references: `templates/first-setup.sh`; `tests/first-setup.test.sh`; `install.sh`; `DECISIONS.yml`; `https://api.github.com/repos/yuru7/HackGen/releases/latest`; live checks for `fc-cache`, `fc-scan`, `gh api`, and `curl`+`jq`

### Entry 0004 (2026-08-16)
- Why now: Gate A step 3として、discussion-validationでreadyとなったHackGen導入方針をDECISIONS.ymlへ昇格した。
- Promotion result: `installer-011-22-first-setup-dependencies`へHackGen導入に必要な`fontconfig`と`jq`を追加し、first-setupの初期セットアップ責務を更新した。新規`installer-011-25-hackgen-font-installation`へ、無引数実行、ユーザー単位配置、Regular/Boldのペア存在時の完全スキップ、latest ZIPからの一組導入、`fc-cache`、失敗時の非0、自動更新非対応、VS Code設定非変更を昇格した。両決定は`⚠️Discussion Approved`とし、本記録へリンクした。
- Scope preserved: `install.sh`、`dev-tools.sh`、`templates/first-setup.sh`、focused test、VS Code設定はこのpromotionでは変更していない。`installer-011-23-first-setup-deployment`と`installer-011-24-executable-helper-deployment`の既存契約も変更していない。
- Promotion to DECISIONS.yml: promoted -> `installer-011-22-first-setup-dependencies`, new `installer-011-25-hackgen-font-installation`
- Evidence / references: `DECISIONS.yml`; `templates/first-setup.sh`; `tests/first-setup.test.sh`; Entry 0003 validation result PASS

### Entry 0005 (2026-08-16)
- Why now: 利用者から、first-setup.shはOSセットアップ後に一度だけ実行する前提を決定へ明記しつつ、誤再実行時の強い副作用も避けたいという補足があった。
- Clarification: `installer-011-22-first-setup-dependencies`に一度だけ実行する運用前提を追加した。ただしこれは再実行を禁止する契約ではなく、既存APT処理は既存のapt-get契約に従い、HackGenは`installer-011-25-hackgen-font-installation`のペア存在判定によって再取得・再配置・追加のキャッシュ更新を行わない安全境界を維持する。
- Current conclusion: first-setupの想定ライフサイクルと、誤再実行時のHackGen側の低副作用契約をDECISIONS.ymlへ明示した。完全なスクリプト全体の無副作用を主張せず、既存APT処理とHackGen処理の責務を分けている。
- Promotion to DECISIONS.yml: updated -> `installer-011-22-first-setup-dependencies`, `installer-011-25-hackgen-font-installation`
- Evidence / references: `DECISIONS.yml`; user clarification; Entry 0004 promotion result

### Entry 0006 (2026-08-16)
- Why now: `first-setup`配下の親決定が依存パッケージ、実行環境、ライフサイクル、配布、ログ、HackGenの取得・配置・失敗契約を一つのdecisionへ詰め込んでおり、次の実装判断で必要な制約を拾いにくくなっていた。
- Refactoring result: `installer-011-22-first-setup-dependencies`を初期準備の親責務とし、依存パッケージ集合、APT実行契約、first-setupライフサイクル、出力契約をsub_decisionsへ分割した。`installer-011-23-first-setup-deployment`も配置先、自動実行境界、配布asset loopへ分割した。`installer-011-25-hackgen-font-installation`はfirst-setup統合、ユーザー単位配置、既存ペア判定、latest asset選択、アーカイブ導入、失敗・キャッシュ、非目標へ分割した。
- Current conclusion: 親decisionは責務の要約に縮小し、実装を直接拘束する独立ルールをsub_decisionsへ移した。既存のdecision ID、status、link、実装上の制約は維持し、別テーマの決定をfirst-setupへ追加していない。
- Promotion to DECISIONS.yml: restructured -> `installer-011-22-first-setup-dependencies`, `installer-011-23-first-setup-deployment`, `installer-011-25-hackgen-font-installation`
- Evidence / references: `DECISIONS.yml`; Entries 0001-0005; existing sub_decision structure under `dev-tools`

### Entry 0007 (2026-08-16)
- Why now: Entry 0006の分割後も、APTの実行順・対応環境・副作用境界・focused test、ならびにHackGenのアーカイブ検証・配置・失敗・キャッシュが同じsub_decisionに残っていたため、独立した実装拘束をさらに分離した。
- Refactoring result: `installer-011-22-first-setup-dependencies`はAPTパッケージ集合、APT順序・権限、対応環境、ライフサイクル、副作用境界、出力、focused testへ分割した。`installer-011-25-hackgen-font-installation`はアーカイブ内容検証、段階的配置、導入失敗、キャッシュ更新、更新方針・非目標を独立したsub_decisionsへ分けた。
- Current conclusion: 分割はdecisionの階層と可読性だけを変更し、実装上の拘束、親のstatus/link、既存のdecision IDは維持した。相互参照で重複していたHackGenのライフサイクル説明はfirst-setup側のライフサイクル決定へ集約した。
- Promotion to DECISIONS.yml: refined -> `installer-011-22-first-setup-dependencies`, `installer-011-25-hackgen-font-installation`
- Evidence / references: `DECISIONS.yml`; Entry 0006; `templates/first-setup.sh`; `tests/first-setup.test.sh`

### Entry 0008 (2026-08-16)
- Why now: Gate Bの実装として、promotedされたfirst-setup契約をテンプレートへ反映した。
- Implementation result: `templates/first-setup.sh`へ`fontconfig`と`jq`をAPT依存として追加し、APT導入完了後にユーザー単位のHackGen導入を実行する処理を追加した。両方の指定TTFが対象ディレクトリに存在する場合はAPI、ダウンロード、展開、配置、`fc-cache`をスキップし、片方でも欠ける場合は公開GitHub APIと`jq`で`HackGen_NF_*.zip`を一つ選び、`unzip`で指定2ファイルだけを検証・一時展開してから`0644`で配置し、成功後だけ`fc-cache`を実行する。
- Test result: `tests/first-setup.test.sh`へ初回導入、完全ペア再実行、片側欠落からの修復、アーカイブ内フォント欠損時の既存ファイル保持を追加した。focused testは2件、install/dev-toolsを含む既存shell testはすべてPASSした。
- Current conclusion: 実装は`installer-011-22-first-setup-dependencies`と`installer-011-25-hackgen-font-installation`の契約を満たした。新しいbindingは発生していないため、DECISIONS.ymlの対象親・sub_decisionsを`✅️Implementation Approved`へ更新した。
- Promotion to DECISIONS.yml: implementation approved -> `installer-011-22-first-setup-dependencies`, `installer-011-25-hackgen-font-installation`
- Evidence / references: `templates/first-setup.sh`; `tests/first-setup.test.sh`; Bash syntax check; jq selector check; `tests/first-setup.test.sh`, `tests/install.test.sh`, `tests/dev-tools.test.sh`
