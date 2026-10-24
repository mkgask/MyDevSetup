# MyDevSetup

自分で作って自分で使うための、AI 開発環境セットアップ用リポジトリです。

## First setup (Linux/WSL)

`install.sh` は最後に `.dev/dev-tools.sh` を実行するため、その前に OS の初期セットアップを実行してください。`curl` が必要です。

```bash
curl -fsSL https://raw.githubusercontent.com/mkgask/mydevsetup/main/first-setup.sh | bash
```

通常ユーザーで実行してください。`sudo` を使うのは apt の操作だけです。proto と mise は未導入の場合だけユーザー単位で導入し、HackGen フォントもユーザー単位で導入します。proto/mise のactivation hookや言語ランタイム、plugin、その他の開発ツールは導入しません。managerの実行ファイルが標準導入先にある場合だけ、そのPATHを `~/.bashrc` に追加します。

現在の対話shellでmanager commandを使う場合は、sourceするか新しいshellを開いてください。これは対話shellのPATHを更新するための案内で、`.dev/dev-tools.sh` のmanager検出には必須ではありません。

```bash
source ~/.bashrc
```

旧版で配置された `.dev/first-setup.sh` は自動で削除・更新しません。不要な場合は手動で削除してください。

## Install

導入先のプロジェクトのルートディレクトリで実行してください。

```bash
curl -fsSL https://raw.githubusercontent.com/mkgask/mydevsetup/main/install.sh | bash
```

既定では GitHub Copilot 向けに導入します。Cursor を使う場合は `cursor` を指定してください。

```bash
curl -fsSL https://raw.githubusercontent.com/mkgask/mydevsetup/main/install.sh | bash -s -- cursor
```

## Development tools

導入後、対象プロジェクトのルートで `.dev/dev-tools.sh` を実行します。

```bash
# 現在の状態を確認
bash .dev/dev-tools.sh status

# 導入予定を確認
bash .dev/dev-tools.sh install --dry-run

# 不足しているツールを導入
bash .dev/dev-tools.sh install

# 現在のプロジェクトを Copilot 向けに初期化
bash .dev/dev-tools.sh init

# Cursor 向けに初期化する場合
bash .dev/dev-tools.sh init --agent cursor
```

`init` の対象は `--agent copilot|cursor` で指定できます。省略時は Copilot です。Cursor 向けに導入した場合は、init 実行時にも `--agent cursor` を指定してください。

### 対象ツール

- Python (`python3`)
- Ruby (`ruby`)
- Node.js (`node`)
- ripgrep (`rg`)
- RTK (`rtk`)
- CodeGraph (`codegraph`)
- uv (`uv`)
- Serena (`serena`)

以下のパッケージマネージャーがインストールされていれば、利用可能な導入経路として考慮します: `apt-get`、`dnf`、`yum`、`pacman`、`zypper`、`apk`、`nix`、`proto`、`mise`、`asdf`、`brew`

`install` で新たに `proto` または `mise` 経由の導入に成功した場合は、現在のシェルを有効化し、次回以降の Bash でも利用できるように必要な manager 設定と `~/.bashrc` の activation 行を冪等に更新します。既存ツール、`status`、`init`、`install --dry-run` はこの設定を変更しません。
