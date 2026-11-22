# RenkuOS 用 Go ツール

[English](README.md) · [Italiano](README.it.md) · 日本語 · [한국어](README.ko.md)

rclone、Syncthing、GitHub CLI、restic、Hugo、Caddy、fzf、lazygit を
RenkuOS(Haiku)の arm64、x86_64、32 ビット x86 向けにビルドしたものです。
非公式ビルドであり、各プロジェクトや GitHub とは関係ありません。

| ツール | バージョン | パッケージ | 32 ビット x86 のパッケージ |
| --- | --- | --- | --- |
| rclone | 1.76.0 | `rclone` | `rclone_x86` |
| Syncthing | 1.30.0 | `syncthing` | `syncthing_x86` |
| GitHub CLI (`gh`) | 2.100.0 | `github_cli` | `github_cli_x86` |
| restic | 0.19.1 | `restic` | `restic_x86` |
| Hugo | 0.165.0 | `hugo` | `hugo_x86` |
| Caddy | 2.11.9 | `caddy` | `caddy_x86` |
| fzf | 0.75.0 | `fzf` | `fzf_x86` |
| lazygit | 0.66.3 | `lazygit` | `lazygit_x86` |

## pkgman でインストール

リポジトリを一度追加してから、必要なものをインストールします。

| システム | リポジトリ | 例 |
| --- | --- | --- |
| arm64 | `pkgman add-repo http://pkgman.rainygirl.com/arm64` | `pkgman install rclone` |
| x86_64 | `pkgman add-repo https://pkgman.rainygirl.com/x86_64` | `pkgman install rclone` |
| 32 ビット x86 (x86_gcc2) | `pkgman add-repo https://pkgman.rainygirl.com/x86_gcc2` | `pkgman install rclone_x86` |

`pkgman add-repo` が `Operation not supported` で失敗する場合、そのイメージの
ネットワークキットに TLS がありません。アドレスの `https://` を `http://` に
置き換えてください。

各パッケージは `/boot/system/bin` にコマンドを 1 つインストールします
(`rclone`、`syncthing`、`gh`、`restic`、`hugo`、`caddy`、`fzf`、`lazygit`)。

## パッケージファイルからインストール

リポジトリを使わず、`package.sh` で作った `.hpkg` を使う場合:

```sh
pkgman install ./rclone-1.76.0-2-arm64.hpkg
```

パッケージのリビジョン: arm64 では `rclone`、`syncthing`、`github_cli` が
リビジョン 2、ほかはリビジョン 1 です。32 ビット x86 では `rclone_x86`、
`syncthing_x86`、`github_cli_x86` がリビジョン 2、ほかはリビジョン 1、
x86_64 はすべてリビジョン 1 です。arm64 のパッケージは、シグナルを配送する
golang_bin リビジョン 10 の Go ツールチェーンでビルドしています。

## rclone

```sh
rclone config                # リモートを設定
rclone copy ~/Documents remote:backup
```

`rclone mount` は使えません。Haiku には Go バインディングから使える FUSE が
ありません。それ以外は通常の rclone です。Terminal では設定ファイルは
`~/config/settings/rclone/rclone.conf` です。

## Syncthing

```sh
syncthing                    # 続いて http://127.0.0.1:8384 を開く
```

- 1.x 系です。Syncthing 2.x はデータベースに SQLite を使いますが、そのための
  ライブラリに Haiku 向けの移植がありません。
- Haiku 用のファイル監視がないため、フォルダーの変更は再スキャン時に検出
  されます。既定の間隔は 1 時間です。変更を早く反映したい場合は、フォルダー
  設定の *Full Rescan Interval* を短くしてください。
- 自動アップグレードは無効です。新しいバージョンは新しいパッケージとして
  提供されます。
- このパッケージはログイン時に Syncthing を起動しません。

## GitHub CLI

```sh
gh auth login
```

`gh` は Haiku の `open` コマンドでウェブページを開きます。2.100.0 は 32 ビット
用ツールチェーンでビルドできる最新のリリースで、3 つのシステムすべてに同じ
バージョンを提供しています。

## restic

```sh
restic init --repo ~/restic-repo
restic -r ~/restic-repo backup ~/Documents
restic -r ~/restic-repo snapshots
restic -r ~/restic-repo restore latest --target ~/restored
```

ローカルディレクトリ、SFTP、REST サーバー、S3 などのバックエンドへの
バックアップは通常の restic と同じように動きます。`restic mount`(FUSE が
ない)と `restic self-update` は使えません。拡張属性はバックアップされません。

## Hugo

```sh
hugo new site mysite
cd mysite
hugo server                  # その後 http://127.0.0.1:1313 を開く
hugo                         # public/ にビルド
```

標準エディションです。extended エディションの Sass コンパイラと WebP
エンコーダは cgo が必要なため、"Hugo extended" を必要とするテーマはビルド
できません。`hugo server` は実行中の変更を検知して再ビルドします。

## Caddy

```sh
caddy file-server --root ~/public_html --listen 127.0.0.1:8080
caddy run --config Caddyfile
caddy reload --config Caddyfile
caddy stop
```

標準モジュール(ファイルサーバー、リバースプロキシ、自動 HTTPS、Caddyfile)
入りです。管理エンドポイントは `localhost:2019` ではなく `127.0.0.1:2019` で
待ち受けます。x86_64 と 32 ビット x86 では Haiku に `/etc/hosts` がないため、
Go のプログラムはまだ `localhost` を引けません。そちらでは
`reverse_proxy 127.0.0.1:3000` のように `localhost` ではなく `127.0.0.1` で
書いてください。arm64 のビルドは Haiku の hosts ファイルを読むので、
`localhost` が使えます。

## fzf

```sh
ls /boot/system/bin | fzf
fzf --filter=term < list.txt   # 非対話
```

## lazygit

```sh
cd my-repository
lazygit
```

lazygit には `git` 2.32 以降が必要です。x86_64 と 32 ビット x86 の Haiku には
あります(`pkgman install git`、32 ビット x86 では `git_x86`)。RenkuOS arm64
のリポジトリにはまだ git がないため、そこでは lazygit はそのことを表示して
終了します。

## 実行中のコマンドを止めるには

3 つのシステムすべてで、Ctrl-C と `kill` で `syncthing`、`rclone serve`、
`hugo server`、`caddy file-server` などを止められます。arm64 では、修正した
ツールチェーンでビルドしたパッケージ(上のリビジョンを参照)が必要です。
以前の arm64 ビルドはどちらも無視し、`kill -9` でしか止まりませんでした。

## アンインストール

```sh
pkgman uninstall rclone      # または syncthing、github_cli、restic、hugo、caddy、
                             # fzf、lazygit。32 ビット x86 では _x86 を付ける
```

## ビルド

`build.sh` がワークステーション上でツールをクロスビルドし、`package.sh` が
パッケージを作ります。パッチと必要な Go ツールチェーンについては
[docs/PORTING.md](docs/PORTING.md)(英語)を参照してください。

## AI の利用について

このポートの一部は AI コーディングツール (Anthropic の Claude) の支援を受けて開発しました。
すべてのコードは作者がレビューし、テストしています。
