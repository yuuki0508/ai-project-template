#!/usr/bin/env bash
#
# 新規案件の初期環境を生成する。
#
#   対話モード : ./init.sh
#   一括モード : ./init.sh --name shift-kanri --title "シフト管理" --stack laravel-mysql --yes
#   別ディレクトリに出力 : ./init.sh --out ../shift-kanri
#
#   --php 8.3 / --node 22   バージョン固定（省略すると latest タグ）
#   --github --visibility private --gh-repo owner/name   GitHubリポジトリを作成
#   --no-github                                          作成しない（対話をスキップ）
#
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGE="$SELF_DIR/.scaffold-stage"

STACK_IDS=("laravel-mysql" "next-nest-mysql" "next-nest-supabase")
STACK_LABELS=("Laravel + MySQL" "Next.js + Nest.js + MySQL" "Next.js + Nest.js + Supabase")

# テンプレート側だけに存在し、生成後の案件には残さないもの
TEMPLATE_ONLY=("common" "stacks" "init.sh" "init.cmd" "README.md" ".scaffold-stage")

SLUG=""; TITLE=""; ONELINER=""; STACK=""; OUT=""; ASSUME_YES=0
PHP_VERSION=""; NODE_VERSION=""; PHP_SET=0; NODE_SET=0
GH_CREATE=""; GH_VIS="private"; GH_REPO=""

die()  { printf '\033[31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }
info() { printf '\033[36m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m! %s\033[0m\n' "$*" >&2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --name)     SLUG="${2:-}"; shift 2 ;;
    --title)    TITLE="${2:-}"; shift 2 ;;
    --oneliner) ONELINER="${2:-}"; shift 2 ;;
    --stack)    STACK="${2:-}"; shift 2 ;;
    --out)      OUT="${2:-}"; shift 2 ;;
    --php)      PHP_VERSION="${2:-}"; PHP_SET=1; shift 2 ;;
    --node)     NODE_VERSION="${2:-}"; NODE_SET=1; shift 2 ;;
    --github)   GH_CREATE=1; shift ;;
    --no-github) GH_CREATE=0; shift ;;
    --visibility) GH_VIS="${2:-}"; shift 2 ;;
    --gh-repo)  GH_REPO="${2:-}"; shift 2 ;;
    --yes|-y)   ASSUME_YES=1; shift ;;
    --help|-h)  sed -n '2,13p' "$0"; exit 0 ;;
    *)          die "不明なオプション: $1" ;;
  esac
done

# ---------- 質問 ----------
if [ -z "$SLUG" ]; then
  read -r -p "案件の識別子（英小文字・数字・ハイフン。例: shift-kanri）: " SLUG
fi
echo "$SLUG" | grep -Eq '^[a-z][a-z0-9-]{1,39}$' || die "識別子は英小文字で始まり、英小文字・数字・ハイフンのみ（2〜40文字）"

if [ -z "$TITLE" ]; then
  read -r -p "案件の表示名（日本語可。例: 飲食店シフト管理）: " TITLE
fi
[ -n "$TITLE" ] || TITLE="$SLUG"

if [ -z "$ONELINER" ] && [ "$ASSUME_YES" != "1" ]; then
  read -r -p "システムの1行説明（誰が何をするためのものか）: " ONELINER
fi
[ -n "$ONELINER" ] || ONELINER="（未記入。docs/00_overview.md に書くこと）"

if [ -z "$STACK" ]; then
  echo ""
  echo "技術スタックを選択:"
  i=1; for label in "${STACK_LABELS[@]}"; do echo "  $i) $label"; i=$((i+1)); done
  read -r -p "番号 [1]: " n; n="${n:-1}"
  case "$n" in 1|2|3) STACK="${STACK_IDS[$((n-1))]}" ;; *) die "1〜3で選択してください" ;; esac
fi
STACK_DIR="$SELF_DIR/stacks/$STACK"
[ -d "$STACK_DIR" ] || die "スタック '$STACK' が見つかりません（${STACK_IDS[*]}）"
STACK_LABEL="$STACK"
for i in 0 1 2; do [ "${STACK_IDS[$i]}" = "$STACK" ] && STACK_LABEL="${STACK_LABELS[$i]}"; done

# ---------- ランタイムのバージョン ----------
need_php=0; need_node=0
case "$STACK" in
  laravel-mysql)                        need_php=1; need_node=1 ;;
  next-nest-mysql|next-nest-supabase)   need_node=1 ;;
esac

if [ "$need_php" -eq 1 ] && [ "$PHP_SET" -eq 0 ] && [ "$ASSUME_YES" -ne 1 ]; then
  read -r -p "PHPのバージョン（空欄で最新。例: 8.3）: " PHP_VERSION
fi
if [ "$need_node" -eq 1 ] && [ "$NODE_SET" -eq 0 ] && [ "$ASSUME_YES" -ne 1 ]; then
  read -r -p "Node.jsのバージョン（空欄で最新。例: 22）: " NODE_VERSION
fi
for v in "$PHP_VERSION" "$NODE_VERSION"; do
  [ -z "$v" ] && continue
  echo "$v" | grep -Eq '^[0-9]+(\.[0-9]+)*$' || die "バージョンは数字とドットのみ（例: 22 / 8.3 / 20.11）: $v"
done

if [ -n "$PHP_VERSION" ]; then
  PHP_IMAGE="php:${PHP_VERSION}-fpm-alpine"; PHP_LABEL="$PHP_VERSION"
else
  PHP_IMAGE="php:fpm-alpine";               PHP_LABEL="latest"
fi
if [ -n "$NODE_VERSION" ]; then
  NODE_IMAGE="node:${NODE_VERSION}-alpine"; NODE_LABEL="$NODE_VERSION"
else
  NODE_IMAGE="node:alpine";                 NODE_LABEL="latest"
fi

# ---------- GitHub ----------
if [ -z "$GH_CREATE" ]; then
  if [ "$ASSUME_YES" -eq 1 ]; then
    GH_CREATE=0
  else
    read -r -p "GitHubにリポジトリを作成しますか？ [y/N]: " a
    case "$a" in y|Y|yes) GH_CREATE=1 ;; *) GH_CREATE=0 ;; esac
  fi
fi
if [ "$GH_CREATE" -eq 1 ]; then
  if [ -z "$GH_REPO" ]; then
    read -r -p "  リポジトリ名（owner/name も可） [$SLUG]: " GH_REPO
    GH_REPO="${GH_REPO:-$SLUG}"
  fi
  if [ "$ASSUME_YES" -ne 1 ]; then
    read -r -p "  公開設定 [1=private / 2=public] (1): " a
    case "$a" in 2) GH_VIS="public" ;; *) GH_VIS="private" ;; esac
  fi
fi
case "$GH_VIS" in private|public|internal) ;; *) die "--visibility は private / public / internal" ;; esac

# ポートは固定。案件は同時に起動しない前提。
# 衝突したら生成後に compose.yml と .env の該当行を直せばよい。
PORT_WEB=3000
PORT_API=4000
PORT_DB=3306
PORT_MAIL=8025
PORT_PMA=8080
SB_API=54321; SB_STUDIO=54323; SB_INBUCKET=54324
case "$STACK" in
  laravel-mysql)      PORT_WEB=8000 ;;
  next-nest-supabase) PORT_DB=54322; PORT_MAIL=$SB_INBUCKET ;;
esac

DB_NAME="$(echo "$SLUG" | tr '-' '_')"
TODAY="$(date +%Y-%m-%d)"

RUNTIME_SUMMARY="Node $NODE_LABEL"
[ "$need_php" -eq 1 ] && RUNTIME_SUMMARY="PHP $PHP_LABEL / Node $NODE_LABEL"

GH_SUMMARY="作成しない"
[ "$GH_CREATE" -eq 1 ] && GH_SUMMARY="$GH_REPO を作成（$GH_VIS）"

case "$STACK" in
  laravel-mysql)
    PORT_SUMMARY="web=$PORT_WEB / db=$PORT_DB / phpMyAdmin=$PORT_PMA / mail=$PORT_MAIL" ;;
  next-nest-mysql)
    PORT_SUMMARY="web=$PORT_WEB / api=$PORT_API / db=$PORT_DB / phpMyAdmin=$PORT_PMA / mail=$PORT_MAIL" ;;
  *)
    PORT_SUMMARY="web=$PORT_WEB / api=$PORT_API / db=$PORT_DB / mail=$PORT_MAIL" ;;
esac

TARGET="${OUT:-$SELF_DIR}"
MODE="in-place"; [ -n "$OUT" ] && MODE="out-of-place"

cat <<SUMMARY

────────────────────────────────
  識別子      : $SLUG
  表示名      : $TITLE
  説明        : $ONELINER
  スタック    : $STACK_LABEL
  ランタイム  : $RUNTIME_SUMMARY
  DB名        : $DB_NAME
  ポート      : $PORT_SUMMARY
  GitHub      : $GH_SUMMARY
  出力先      : $TARGET  ($MODE)
────────────────────────────────
SUMMARY

if [ "$MODE" = "in-place" ]; then
  echo "※ in-place: このディレクトリからテンプレート機構（common/ stacks/ init.sh）を削除し、案件リポジトリに置き換えます。"
fi
if [ "$ASSUME_YES" -ne 1 ]; then
  read -r -p "この内容で生成しますか？ [y/N]: " a
  case "$a" in y|Y|yes) ;; *) echo "中止しました。"; exit 0 ;; esac
fi

# ---------- ステージングに組み立て ----------
rm -rf "$STAGE"; mkdir -p "$STAGE"
cp -a "$SELF_DIR/common/." "$STAGE/"
cp -a "$STACK_DIR/." "$STAGE/"
rm -f "$STAGE/context.md"

# スタック固有の文脈ブロックを 00-project-context.mdc に差し込む
CTX="$STACK_DIR/context.md"
CTXFILE="$STAGE/.cursor/rules/00-project-context.mdc"
if [ -f "$CTX" ] && [ -f "$CTXFILE" ]; then
  sed -e "/__STACK_BLOCK__/r $CTX" -e "/__STACK_BLOCK__/d" "$CTXFILE" > "$CTXFILE.new"
  mv "$CTXFILE.new" "$CTXFILE"
fi

# ---------- プレースホルダ置換 ----------
esc() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
S_SLUG="$(esc "$SLUG")"; S_TITLE="$(esc "$TITLE")"; S_ONE="$(esc "$ONELINER")"
S_STACK="$(esc "$STACK")"; S_SLABEL="$(esc "$STACK_LABEL")"; S_DB="$(esc "$DB_NAME")"

while IFS= read -r f; do
  case "$f" in *.png|*.jpg|*.jpeg|*.gif|*.ico|*.zip|*.pdf) continue ;; esac
  sed -e "s/__PROJECT_SLUG__/$S_SLUG/g" \
      -e "s/__PROJECT_TITLE__/$S_TITLE/g" \
      -e "s/__ONELINER__/$S_ONE/g" \
      -e "s/__STACK_ID__/$S_STACK/g" \
      -e "s/__STACK_LABEL__/$S_SLABEL/g" \
      -e "s/__DB_NAME__/$S_DB/g" \
      -e "s/__PORT_WEB__/$PORT_WEB/g" \
      -e "s/__PORT_API__/$PORT_API/g" \
      -e "s/__PORT_DB__/$PORT_DB/g" \
      -e "s/__PORT_MAIL__/$PORT_MAIL/g" \
      -e "s/__PORT_PMA__/$PORT_PMA/g" \
      -e "s/__DATE__/$TODAY/g" \
      -e "s/__PHP_IMAGE__/$PHP_IMAGE/g" \
      -e "s/__PHP_LABEL__/$PHP_LABEL/g" \
      -e "s/__NODE_IMAGE__/$NODE_IMAGE/g" \
      -e "s/__NODE_LABEL__/$NODE_LABEL/g" \
      -e "s/__SB_API__/$SB_API/g" \
      -e "s/__SB_STUDIO__/$SB_STUDIO/g" \
      -e "s/__SB_INBUCKET__/$SB_INBUCKET/g" \
      "$f" > "$f.tmp" && cat "$f.tmp" > "$f" && rm -f "$f.tmp"
done < <(find "$STAGE" -type f)

# ---------- 配置 ----------
if [ "$MODE" = "out-of-place" ]; then
  [ -e "$TARGET" ] && die "出力先が既に存在します: $TARGET"
  mkdir -p "$TARGET"
  cp -a "$STAGE/." "$TARGET/"
  rm -rf "$STAGE"
else
  for p in "${TEMPLATE_ONLY[@]}"; do
    [ "$p" = ".scaffold-stage" ] && continue
    rm -rf "$SELF_DIR/$p"
  done
  cp -a "$STAGE/." "$SELF_DIR/"
  rm -rf "$STAGE"
fi

# ---------- git ----------
cd "$TARGET"
if [ "$MODE" = "in-place" ] && [ -d .git ]; then
  ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
  rm -rf .git
  git init -q
  [ -n "$ORIGIN" ] && git remote add template "$ORIGIN" || true
elif [ ! -d .git ]; then
  git init -q
fi
git add -A >/dev/null 2>&1 || true
MSG="chore: $SLUG 初期構成（$STACK_LABEL）"
if git config user.email >/dev/null 2>&1; then
  git commit -qm "$MSG" >/dev/null 2>&1 || true
else
  git -c user.name=scaffold -c user.email=scaffold@local commit -qm "$MSG" >/dev/null 2>&1 || true
fi
# ブランチ名の正規化は、コミットが1つ出来てからでないと失敗する
git branch -M main >/dev/null 2>&1 || true

# ---------- GitHubリポジトリ作成 ----------
GH_DONE=0
if [ "$GH_CREATE" -eq 1 ]; then
  if ! command -v gh >/dev/null 2>&1; then
    warn "gh コマンドが見つかりません。GitHubリポジトリの作成をスキップしました。"
  elif ! gh auth status >/dev/null 2>&1; then
    warn "gh が未認証です。'gh auth login' の後に手動で作成してください。"
  else
    info "GitHubリポジトリを作成しています: $GH_REPO ($GH_VIS)"
    if gh repo create "$GH_REPO" "--$GH_VIS" --source=. --remote=origin --push; then
      GH_DONE=1
      GH_URL="$(gh repo view "$GH_REPO" --json url -q .url 2>/dev/null || true)"
    else
      warn "GitHubリポジトリの作成に失敗しました。ローカルのコミットは残っています。"
    fi
  fi
  if [ "$GH_DONE" -ne 1 ]; then
    warn "手動でやり直す場合: gh repo create $GH_REPO --$GH_VIS --source=. --remote=origin --push"
  fi
fi

ok ""
ok "生成しました: $TARGET"
if [ "$GH_DONE" -eq 1 ]; then
  ok "GitHub: ${GH_URL:-$GH_REPO}"
fi
cat <<'NEXT'

次の手順
  1. README.md の「埋める必要があるファイル」を見て空欄を埋める
     最低限 docs/00_overview.md の「やらないこと」と docs/glossary.md（AIの精度がここで決まる）
  2. make init    ... フレームワークの雛形を作成（初回のみ）
  3. make up      ... 起動
  4. make check   ... lint / 型 / テストが通ることを確認
  5. tasks/active/ に最初のタスクを1枚置いてから、AIに実装させる

テンプレート更新を取り込みたい場合: git fetch template && git merge template/main --allow-unrelated-histories
NEXT
