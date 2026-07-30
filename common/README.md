# __PROJECT_TITLE__

__ONELINER__

- スタック: __STACK_LABEL__
- 起動後: http://localhost:__PORT_WEB__

## 3分で動かす

```bash
cp .env.example .env
make init    # 初回のみ（フレームワークの雛形を生成）
make up
make migrate
```

うまくいかないときは `docs/ops/runbook.md`。

## このリポジトリの構成

| 場所 | 内容 |
|---|---|
| `.cursor/rules/` | AIに読ませるルール。`00`と`10`は常時読み込み |
| `CLAUDE.md` | Cursor以外のエージェント向けの入口 |
| `docs/` | 仕様・データモデル・用語辞書・決定記録・運用手順 |
| `tasks/` | AIに任せる作業単位。1タスク1ファイル |
| `.ai/prompts/` | 定型プロンプト |
| `Makefile` | 開発コマンドの入口。`make check` が検証の窓口 |

## AIで開発するときの流れ

1. `tasks/_template.md` をコピーして `tasks/active/` にタスクを1枚作る
2. `.ai/prompts/01-implement-feature.md` の文面でAIに投げる
3. `make check` を通す
4. `.ai/prompts/03-close-session.md` で引き継ぎメモを書かせる

詳しくは `tasks/README.md`。

## 定型プロンプト

| ファイル | 使う場面 |
|---|---|
| `01-implement-feature.md` | 新機能の実装を依頼する |
| `02-audit-spec-drift.md` | 仕様書と実装のズレを点検させる |
| `03-close-session.md` | 作業を終えて引き継ぎメモを書かせる |
| `04-resume-project.md` | 久しぶりの案件を再開する |
