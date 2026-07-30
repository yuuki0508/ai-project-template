## スタック構成（Laravel + MySQL）

ローカル: アプリ http://localhost:__PORT_WEB__ / メール確認 http://localhost:__PORT_MAIL__ / MySQL localhost:__PORT_DB__

| 層 | 技術 | ディレクトリ |
|---|---|---|
| アプリ | Laravel（PHP __PHP_LABEL__ / php-fpm） | `app/` `routes/` `resources/` |
| DB | MySQL 8.0 | `database/migrations/` |
| Web | Nginx | `docker/nginx/` |
| メール | Mailpit（送信は全部ここで止まる） | — |
| ビルド | Node __NODE_LABEL__（Vite。PHPコンテナに同梱） | `vite.config.js` |

- DB名 `__DB_NAME__` / ユーザー `__DB_NAME__` / パスワードは `.env.example` 参照
- コマンドはホストから `make` 経由で実行する。`php artisan` を直接叩かない（コンテナ内で動かす必要がある）
- 検証: `make check` = Pint（整形チェック）+ Larastan（静的解析）+ PHPUnit
- PHP / Node のバージョンは `docker/php/Dockerfile` の `FROM` 行で管理。変更したら `make rebuild`

## この構成での約束

- ビジネスロジックはコントローラに書かず、`app/Services/` に置く
- クエリはEloquentを基本とし、複雑な集計のみ生SQL。生SQLを書く場合は必ずバインドパラメータを使う
- バリデーションは FormRequest に書く
- 画面はBladeで作る（別途SPA構成が必要なら先に相談する）
