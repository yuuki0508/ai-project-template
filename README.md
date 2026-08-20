# ai-project-template

新規案件の初期環境を、AIコーディング前提の構成で一発生成するテンプレート。

対応スタック

| ID | 構成 |
|---|---|
| `laravel-mysql` | Laravel + MySQL |
| `next-nest-mysql` | Next.js + Nest.js + MySQL |
| `next-nest-supabase` | Next.js + Nest.js + Supabase |

## 使い方

実際の進め方・プロンプト例は [`common/.ai/WORKFLOW.md`](common/.ai/WORKFLOW.md) を参照。
既存システムへの移植手順もこちらにある。

```bash
git clone <このリポジトリ> 新案件名
cd 新案件名
./init.sh
```

聞かれること

1. 案件の識別子（英小文字・数字・ハイフン）
2. 表示名 / 1行説明
3. スタック
4. PHP / Node のバージョン（**空欄で最新**）
5. GitHubにリポジトリを作るか（作る場合はリポジトリ名と public / private）

答えると、テンプレート機構（`common/` `stacks/` `init.sh`）が削除され、
そのディレクトリがそのまま案件リポジトリになる。gitの履歴は作り直され、
元のリモートは `template` という名前のリモートとして残る。

Windows は `init.cmd` をダブルクリック（Git Bash が必要）。

### オプション

```bash
# テンプレートを汚さず別ディレクトリに出力する
./init.sh --out ../新案件名

# 対話なしで一括生成（未指定の項目は既定値。GitHubは作らない）
./init.sh --name shift-kanri --title "シフト管理" --stack laravel-mysql --yes

# バージョンを固定
./init.sh --php 8.3 --node 22

# GitHubリポジトリまで作る
./init.sh --github --visibility private --gh-repo my-org/shift-kanri
```

| オプション | 既定 | 内容 |
|---|---|---|
| `--php` `--node` | 未指定 = `latest` タグ | ランタイムのバージョン |
| `--github` / `--no-github` | 対話で確認 | GitHubリポジトリを作るか |
| `--visibility` | `private` | `private` / `public` / `internal` |
| `--gh-repo` | 識別子と同じ名前 | `owner/name` 形式も可 |
| `--out` | カレント（in-place） | 出力先 |
| `--yes` | — | 確認と対話をすべて省略 |

### ランタイムのバージョン

空欄のままにすると `php:fpm-alpine` `node:alpine`（= latest）を使う。
**長く保守する案件では固定すること。** latest のままだと再ビルドのタイミングで
勝手に上がって壊れる。

生成後の変更場所は1箇所だけ。変更したら `make rebuild && make check`。

| スタック | 場所 |
|---|---|
| `laravel-mysql` | `docker/php/Dockerfile` の `FROM` 行（PHPとNodeの両方） |
| `next-nest-*` | `compose.yml` の `x-node` の `image` |

Laravel構成のNodeはVite用。`node:<ver>-alpine` から実体をコピーして同梱している。

### GitHubリポジトリの作成

`gh` が入っていて認証済みなら、初期コミットまで済ませて push する。
`gh` が無い / 未認証の場合はスキップして、手動用のコマンドを表示するだけで止まる
（生成物とローカルのコミットはそのまま残る）。

### ポート

**案件は1つずつ起動する前提**なので、全案件で同じポートを使う。

| | アプリ | api | phpMyAdmin | DB | メール確認 |
|---|---|---|---|---|---|
| `laravel-mysql` | 8000 | — | 8080 | 3306 | 8025 |
| `next-nest-mysql` | 3000 | 4000 | 8080 | 3306 | 8025 |
| `next-nest-supabase` | 3000 | 4000 | —（Studio 54323） | 54322 | 54324 |

MySQL構成には phpMyAdmin が常に入る（8080）。Supabase構成は Supabase Studio が同じ役割を果たす。

別案件が起動したままだと `port is already allocated` で失敗する。`docker compose ls` で
確認して `make down` する。ローカルのMySQL等と衝突する場合だけ `compose.yml` を直す。

## 生成後の流れ

```bash
docs/00_overview.md と docs/glossary.md を埋める   ← ここでAIの精度が決まる
make init      # フレームワークの雛形生成（初回のみ・ネットワーク必要）
make up
make check
```

空欄が残っているファイルの一覧と優先順位は、生成された案件側の `README.md`
（テンプレートでは `common/README.md`）の「埋める必要があるファイル」にある。

以降の日々の進め方は、生成された案件の `.ai/WORKFLOW.md` に入っている。

## テンプレートの構造

```
├── init.sh                  生成スクリプト
├── init.cmd                 Windows用ランチャ
├── .gitattributes           改行コードをLFに固定（Windowsでのclone対策）
├── common/                  全スタック共通（docs / tasks / rules / prompts）
└── stacks/
    ├── laravel-mysql/
    ├── next-nest-mysql/
    └── next-nest-supabase/
        ├── context.md       ← 00-project-context.mdc に差し込まれる断片
        ├── compose.yml
        ├── Makefile
        ├── .env.example        認証情報の唯一の置き場
        └── .cursor/rules/   スタック固有の規約（globsで条件付き注入）
```

生成時は `common/` → `stacks/<選択>/` の順にコピーされる。同名ファイルはスタック側が勝つ。

## プレースホルダ

テキストファイル中の以下の文字列が置換される。

| トークン | 内容 |
|---|---|
| `__PROJECT_SLUG__` | 案件識別子（英数ハイフン） |
| `__PROJECT_TITLE__` | 表示名 |
| `__ONELINER__` | 1行説明 |
| `__STACK_ID__` / `__STACK_LABEL__` | スタックID / 表示名 |
| `__DB_NAME__` | DB名（slugのハイフンを`_`に置換） |
| `__PORT_WEB__` `__PORT_API__` `__PORT_DB__` `__PORT_MAIL__` `__PORT_PMA__` | ポート |
| `__DATE__` | 生成日 |
| `__PHP_IMAGE__` / `__NODE_IMAGE__` | `php:8.3-fpm-alpine` / `node:22-alpine` など |
| `__PHP_LABEL__` / `__NODE_LABEL__` | 表示用のバージョン文字列（未指定なら `latest`） |
| `__SB_API__` `__SB_STUDIO__` `__SB_INBUCKET__` | Supabaseの各ポート |
| `__STACK_BLOCK__` | `stacks/*/context.md` の内容（00-project-context.mdc内） |

## スタックを追加する

1. `stacks/<新ID>/` を作り、`context.md` `compose.yml` `Makefile` `.env.example` `.gitignore` を置く
2. `Makefile` には少なくとも `init` `up` `down` `logs` `rebuild` `check` `migrate` を実装する
   （コンテナを `HOST_UID` / `HOST_GID` で動かすこと。rootで動かすとWSL2でファイルがroot所有になる）
   （**コマンド名を揃えることが重要**。AIがスタックごとに覚え直さずに済む）
3. `init.sh` の `STACK_IDS` と `STACK_LABELS` に追記する

## 育て方

案件側で `make done` するたび、AIが観測した「リポジトリに書かれていなかった情報」が
`docs/decisions/_inbox.md` に溜まり、横断inbox（既定 `~/ai-knowledge/_inbox.md`）へ集約される。

`make promote` を叩くと昇格候補が出る。

| 条件 | 昇格先 |
|---|---|
| 同一 keyword が同一案件で2回以上 | 案件の `docs/decisions/NNNN-*.md` |
| 同一 keyword が**2案件以上**で出現 | `common/.cursor/rules/10-conventions.mdc`<br>スタック固有なら `stacks/<id>/.cursor/rules/` |

**テンプレートに戻すまでが1セット。** 案件側だけ直すと次の案件で同じ説明を繰り返すことになる。
テンプレートが育つほど、次の案件の立ち上がりが速くなる。
