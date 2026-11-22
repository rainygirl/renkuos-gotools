# RenkuOS 用 Go ツール

[English](README.md) · [Italiano](README.it.md) · 日本語 · [한국어](README.ko.md)

rclone、Syncthing、GitHub CLI を RenkuOS(Haiku)の arm64、x86_64、32 ビット x86
向けにビルドしたものです。非公式ビルドであり、rclone プロジェクト、Syncthing
Foundation、GitHub とは関係ありません。

| ツール | バージョン | パッケージ | 32 ビット x86 のパッケージ |
| --- | --- | --- | --- |
| rclone | 1.76.0 | `rclone` | `rclone_x86` |
| Syncthing | 1.30.0 | `syncthing` | `syncthing_x86` |
| GitHub CLI (`gh`) | 2.100.0 | `github_cli` | `github_cli_x86` |

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
(`rclone`、`syncthing`、`gh`)。

## パッケージファイルからインストール

リポジトリを使わず、`package.sh` で作った `.hpkg` を使う場合:

```sh
pkgman install ./rclone-1.76.0-1-arm64.hpkg
```

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

## arm64 で実行中のコマンドを止めるには

RenkuOS arm64 では、Go のプログラムはまだ Ctrl-C や `kill` に反応しません
(Go ランタイムがシグナルを配送しないため)。そのため `syncthing` や
`rclone serve` は動き続けます。Syncthing はウェブページ(Actions ->
Shutdown)から終了し、それ以外は `kill -9 <team id>` か ProcessController で
止めてください。x86_64 と 32 ビット x86 には影響しません。

## アンインストール

```sh
pkgman uninstall rclone      # または syncthing、github_cli。32 ビット x86 では _x86 を付ける
```

## ビルド

`build.sh` がワークステーション上でツールをクロスビルドし、`package.sh` が
パッケージを作ります。パッチと必要な Go ツールチェーンについては
[docs/PORTING.md](docs/PORTING.md)(英語)を参照してください。

## AI の利用について

このポートの一部は AI コーディングツール (Anthropic の Claude) の支援を受けて開発しました。
すべてのコードは作者がレビューし、テストしています。
