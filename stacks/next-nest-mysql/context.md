## スタック構成（Next.js + Nest.js + MySQL）

ローカル: web http://localhost:__PORT_WEB__ / api http://localhost:__PORT_API__ / メール確認 http://localhost:__PORT_MAIL__ / MySQL localhost:__PORT_DB__

| 層 | 技術 | ディレクトリ |
|---|---|---|
| フロント | Next.js（App Router / TypeScript / Tailwind）Node __NODE_LABEL__ | `web/` |
| API | Nest.js（TypeScript） | `api/` |
| ORM | Prisma | `api/prisma/schema.prisma` |
| DB | MySQL 8.0 | `api/prisma/migrations/` |
| メール | Mailpit（送信は全部ここで止まる） | — |

- web → api はサーバー側から `http://api:__PORT_API__`、ブラウザからは `http://localhost:__PORT_API__`
- DB名 `__DB_NAME__`
- 検証: `make check` = ESLint + `tsc --noEmit` + Jest（web / api 両方）
- Node のバージョンは `compose.yml` の `x-node` の `image` で管理。変更したら `make rebuild`

## この構成での約束

- **型の定義元はAPI側。** `api/src/**/dto/` の型を `web/` から再定義せずに共有する
- フロントに業務ロジックを置かない。計算・判定はAPI側で行い、フロントは表示に専念する
- Prisma のスキーマ変更は必ずマイグレーションを生成する（`make migrate`）。`db push` は使わない
- Server Component をデフォルトとし、`"use client"` は必要な葉のコンポーネントだけに付ける
