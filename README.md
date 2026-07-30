# ai-project-template

新規案件の初期環境を、AIコーディング前提の構成で一発生成するテンプレート。

対応スタック

| ID | 構成 |
|---|---|
| `laravel-mysql` | Laravel + MySQL |
| `next-nest-mysql` | Next.js + Nest.js + MySQL |
| `next-nest-supabase` | Next.js + Nest.js + Supabase |

## 使い方

```bash
git clone <このリポジトリ> 新案件名
cd 新案件名
./init.sh
```

質問に答えると、テンプレート機構（`common/` `stacks/` `init.sh`）が削除され、
そのディレクトリがそのまま案件リポジトリになる。gitの履歴は作り直され、
元のリモートは `template` という名前のリモートとして残る。

Windows は `init.cmd` をダブルクリック（Git Bash が必要）。

### オプション

```bash
# テンプレートを汚さず別ディレクトリに出力する
./init.sh --out ../新案件名

# 対話なしで一括生成
./init.sh --name shift-kanri --title "シフト管理" --stack laravel-mysql --yes
```

### ポート

**案件は1つずつ起動する前提**なので、全案件で同じポートを使う。

| | web | api | DB | メール確認 |
|---|---|---|---|---|
| `laravel-mysql` | 8080 | — | 3306 | 8025 |
| `next-nest-mysql` | 3000 | 4000 | 3306 | 8025 |
| `next-nest-supabase` | 3000 | 4000 | 54322 | 54324（Studio 54323） |

別案件が起動したままだと `port is already allocated` で失敗する。`docker compose ls` で
確認して `make down` する。ローカルのMySQL等と衝突する場合だけ `compose.yml` を直す。

## 生成後の流れ

```bash
docs/00_overview.md と docs/glossary.md を埋める   ← ここでAIの精度が決まる
make init      # フレームワークの雛形生成（初回のみ・ネットワーク必要）
make up
make check
```

## テンプレートの構造

```
├── init.sh                  生成スクリプト
├── init.cmd                 Windows用ランチャ
├── common/                  全スタック共通（docs / tasks / rules / prompts）
└── stacks/
    ├── laravel-mysql/
    ├── next-nest-mysql/
    └── next-nest-supabase/
        ├── context.md       ← 00-project-context.mdc に差し込まれる断片
        ├── compose.yml
        ├── Makefile
        ├── .env.example
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
| `__PORT_WEB__` `__PORT_API__` `__PORT_DB__` `__PORT_MAIL__` | ポート |
| `__DATE__` | 生成日 |
| `__SB_API__` `__SB_STUDIO__` `__SB_INBUCKET__` | Supabaseの各ポート |
| `__STACK_BLOCK__` | `stacks/*/context.md` の内容（00-project-context.mdc内） |

## スタックを追加する

1. `stacks/<新ID>/` を作り、`context.md` `compose.yml` `Makefile` `.env.example` `.gitignore` を置く
2. `Makefile` には少なくとも `init` `up` `down` `logs` `check` `migrate` を実装する
   （**コマンド名を揃えることが重要**。AIがスタックごとに覚え直さずに済む）
3. `init.sh` の `STACK_IDS` と `STACK_LABELS` に追記する

## 育て方

案件で「AIに同じ説明を2回した」ら、それは `common/.cursor/rules/10-conventions.mdc` か
スタックの規約ファイルに書くべき内容。案件側で直したら、テンプレートにも戻すこと。
テンプレートが育つほど、次の案件の立ち上がりが速くなる。
