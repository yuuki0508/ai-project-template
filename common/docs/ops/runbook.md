# 運用手順 — __PROJECT_TITLE__

## 初回セットアップ

```bash
make init     # フレームワークの雛形生成（初回のみ）
make up       # 起動
make migrate  # マイグレーション
make seed     # 初期データ
```

- アプリ: http://localhost:__PORT_WEB__
- api: http://localhost:__PORT_API__
- phpMyAdmin: http://localhost:__PORT_PMA__ （MySQL構成のみ。ユーザー `root` / パスワードは `.env` の `DB_ROOT_PASSWORD`）
- メール確認: http://localhost:__PORT_MAIL__

**phpMyAdmin からスキーマを変更しないこと。** データの確認と調査に使う。
テーブル定義の一次情報はマイグレーションであり、GUIで直接変更すると実装と履歴が食い違う。

## 日常のコマンド

| コマンド | 内容 |
|---|---|
| `make up` / `make down` | 起動 / 停止 |
| `make logs` | ログ追尾 |
| `make sh` | コンテナに入る |
| `make check` | lint・型チェック・テストを一括実行 |
| `make fmt` | 自動整形 |
| `make fresh` | DBを作り直して初期データ投入 |

## ランタイムのバージョンを変える

PHP / Node のバージョンは1箇所で管理している。上げたら `make check` を通して確認する。

| スタック | 変更場所 |
|---|---|
| Laravel + MySQL | `docker/php/Dockerfile` の `FROM` 行（PHP / Node 両方） |
| Next.js + Nest.js | `compose.yml` の `x-node` の `image` |

```bash
# 変更後
make rebuild
make check
```

バージョンを固定していない場合は `latest` タグになっている。長く保守する案件では
`php:8.3-fpm-alpine` `node:22-alpine` のように固定しておくこと（latest のままだと
再ビルドのタイミングで勝手に上がって壊れる）。

## 環境変数

`.env` が唯一の置き場で、`.env.example` がその雛形（＝一次情報）。
`compose.yml` は値を直接持たず `${VAR}` で参照するだけにしてある。
**パスワードやキーを `compose.yml` や Makefile に書かないこと。**

新しい変数を追加したら必ず `.env.example` にも追記する。追記を忘れると、
別マシンでの `make init` が「変数がありません」で止まる。

`.env.example` にはローカル専用の既定値だけを置く。本番の値は書かず、
デプロイ先の環境変数に設定する。

| 変数 | 用途 | 取得元 |
|---|---|---|
|  |  |  |

### 起動時に「.env に XXX がありません」と出る

`compose.yml` は `${VAR:?...}` 記法で必須変数を宣言している。
`.env` に該当行を足せば起動する（`.env.example` を参照）。
空文字で通してパスワード無しのDBが出来上がるのを防ぐための、意図的な失敗。

## デプロイ

| 環境 | URL | 手順 |
|---|---|---|
| ステージング |  |  |
| 本番 |  |  |

## バックアップ

- 対象:
- 頻度:
- 復元手順:

## 障害対応

### ファイルが root 所有になって編集できない（WSL2 / Linux）

コンテナはホストと同じUID/GIDで動かしているので通常は起きない。
過去に root で起動した痕跡がある場合は次で戻す。

```bash
sudo chown -R $USER:$USER .
```

Laravel構成で画面が500になる場合は、php-fpm が `storage/` に書けていない。

```bash
make perms
```

### DBに接続できない

```bash
make down && make up
docker compose ps          # 起動状態
docker compose logs db     # DBのログ
```

### ポートが衝突している

**別の案件を起動したままにしていないか確認する**（`docker compose ls` で確認できる）。
案件は1つずつ起動する運用なので、まず不要な方を `make down` する。

ローカルにインストール済みのMySQL等と衝突している場合は、`compose.yml` の
`ports` と `.env` の該当行を書き換える（この案件は web=__PORT_WEB__ / db=__PORT_DB__）。

## 引き継ぎ・保守メモ

<!-- 半年後の自分が読む場所。ハマった罠、顧客特有の運用、触ると危ない箇所 -->

-
