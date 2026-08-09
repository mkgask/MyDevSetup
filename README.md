# MyDevSetup

自分で作って自分で使うための、AI 開発環境セットアップ用リポジトリです。

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
