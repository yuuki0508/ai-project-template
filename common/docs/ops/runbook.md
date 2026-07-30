# 運用手順 — __PROJECT_TITLE__

## 初回セットアップ

```bash
make init     # フレームワークの雛形生成（初回のみ）
make up       # 起動
make migrate  # マイグレーション
make seed     # 初期データ
```

- web: http://localhost:__PORT_WEB__
- api: http://localhost:__PORT_API__
- メール確認: http://localhost:__PORT_MAIL__

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

`.env.example` が一次情報。新しい変数を追加したら必ず `.env.example` にも追記する。

| 変数 | 用途 | 取得元 |
|---|---|---|
|  |  |  |

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
