## スタック構成（Next.js + Nest.js + Supabase）

ローカル: web http://localhost:__PORT_WEB__ / api http://localhost:__PORT_API__ / Supabase Studio http://localhost:__SB_STUDIO__ / メール確認 http://localhost:__SB_INBUCKET__

| 層 | 技術 | ディレクトリ |
|---|---|---|
| フロント | Next.js（App Router / TypeScript / Tailwind）Node __NODE_LABEL__ | `web/` |
| API | Nest.js（TypeScript） | `api/` |
| DB / 認証 / ストレージ | Supabase（ローカルはSupabase CLIで起動） | `supabase/migrations/` |
| ORM | Prisma（PostgreSQL） | `api/prisma/schema.prisma` |

- ローカルDBは `localhost:__PORT_DB__`。コンテナ内からは `host.docker.internal:__PORT_DB__`
- 検証: `make check` = ESLint + `tsc --noEmit` + Jest（web / api 両方）
- Node のバージョンは `compose.yml` の `x-node` の `image` で管理。変更したら `make rebuild`

## この構成での約束

- **DBスキーマの一次情報は `supabase/migrations/` のSQL。** Prisma は型生成と参照用（`prisma db pull` で追従させる）
- RLS（Row Level Security）は全テーブルで有効にする。ポリシーもマイグレーションに含める
- `service_role` キーは **API側（サーバー）だけ**で使う。フロントに絶対に持ち込まない
- フロントからDBを直接叩かず、Nest.js API を経由する（業務ロジックをフロントに漏らさないため）
  - 例外を作る場合は ADR に理由を残す
