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

## 埋める必要があるファイル

生成直後は空欄が残っている。**特に着手前の3つは、埋めないままAIに実装させると事故になる。**

### 着手前に埋める

| ファイル | 何を書くか |
|---|---|
| `docs/00_overview.md` | 背景 / 利用者 / **スコープの「やらないこと」** / 成功の基準 / 制約。「やらないこと」が空だとAIが機能を勝手に増やす |
| `docs/glossary.md` | 業務用語と識別子の対応。**サンプルの4語（案件・取引先・締め・論理削除）は必ず置き換えるか削除する。** 残すとAIが存在しないテーブルを前提にコードを書く |
| `.cursor/rules/00-project-context.mdc` | 末尾「この案件固有の制約」の `（未記入）` |
| `docs/10_requirements.md` | 機能一覧 F-xx と業務ルール BR-xx。**計算式は必ず具体例つきで書く**（推測されると事故になる） |
| `.env` | Supabase構成のみ。`make init` 実行後に表示される anon key と service_role key を貼る |

全部を机上で埋めるのは難しいので、最低限 **`00_overview.md` の「やらないこと」と `glossary.md`** の2つは着手前に埋める。

### 設計が固まってから埋める

| ファイル | 何を書くか |
|---|---|
| `docs/20_data_model.md` | テーブルの意味・関連・設計意図。**カラム定義は書かない**（マイグレーションが一次情報） |
| `docs/40_api.md` | エンドポイントと入出力 |
| `docs/ops/runbook.md` | 「デプロイ」「バックアップ」「環境変数」の3箇所。デプロイ先が決まってから |

### 埋めずにコピー元として残すもの

| ファイル | 使い方 |
|---|---|
| `docs/30_screens/_template.md` | 画面ごとに `S-01-一覧.md` などにコピー |
| `docs/decisions/_template.md` | ADRを書くときにコピー |
| `tasks/_template.md` | タスク起票時に `tasks/active/` へコピー |

上記以外（`10-conventions.mdc`、スタック固有の規約、`.ai/prompts/`、`Makefile`、`compose.yml` など）はそのまま使える。

**この案件で使わないドキュメントは、空のまま残さず削除する。** 空のファイルが残っていると、AIが「まだ書かれていない仕様がある」と誤認する。

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
