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

# 現在のプロジェクトを初期化
bash .dev/dev-tools.sh init
```

### 対象ツール

- Python (`python3`)
- Ruby (`ruby`)
- ripgrep (`rg`)
- RTK (`rtk`)
- CodeGraph (`codegraph`)
- uv (`uv`)
- Serena (`serena`)

以下のパッケージマネージャーがインストールされていれば、利用可能な導入経路として考慮します: `apt-get`、`dnf`、`yum`、`pacman`、`zypper`、`apk`、`nix`、`proto`、`mise`、`asdf`、`brew`
