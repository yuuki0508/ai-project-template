#!/usr/bin/env bash
#
# promote-check.sh — inbox を走査し、昇格候補を機械的に判定する
#
#   usage:
#     bin/promote-check.sh              # 横断 inbox を見る
#     bin/promote-check.sh path/to.md   # 任意の inbox を見る
#
#   env:
#     AI_INBOX     横断 inbox のパス（既定: ~/ai-knowledge/_inbox.md）
#     AI_PROMOTED  昇格済みリスト（既定: inbox と同じディレクトリの _promoted.md）
#     THRESHOLD    昇格閾値（既定: 2）
#
#   _promoted.md の形式（1行1keyword。# 始まりと空行は無視）:
#     keyword | 昇格時点の件数 | 日付 | 昇格先メモ
#
set -euo pipefail

INBOX="${1:-${AI_INBOX:-$HOME/ai-knowledge/_inbox.md}}"
THRESHOLD="${THRESHOLD:-2}"
PROMOTED="${AI_PROMOTED:-$(dirname "$INBOX")/_promoted.md}"

if [ ! -f "$INBOX" ]; then
  echo "inbox が見つかりません: $INBOX" >&2
  echo "AI_INBOX で場所を指定するか、make inbox-sync で作成してください。" >&2
  exit 1
fi

[ -f "$PROMOTED" ] || : > "$PROMOTED"

printf 'inbox: %s  (閾値: %s回)\n\n' "$INBOX" "$THRESHOLD"

awk -v th="$THRESHOLD" -v prom="$PROMOTED" '
  # ---- 昇格済みリスト ----
  FILENAME == prom {
    line = $0
    sub(/^[[:space:]]+/, "", line); sub(/[[:space:]]+$/, "", line)
    if (line == "" || line ~ /^#/) next
    n = split(line, g, /[[:space:]]*\|[[:space:]]*/)
    kw = g[1]
    if (kw == "") next
    promoted[kw] = 1
    pcount[kw] = (n >= 2 && g[2] ~ /^[0-9]+$/) ? g[2] + 0 : 0
    pnote[kw]  = (n >= 4) ? g[4] : ""
    next
  }

  # ---- 観測ログ ----
  # "- date | project | keyword | type | content" の行だけを対象にする
  /^-[[:space:]]/ {
    line = $0
    sub(/^-[[:space:]]+/, "", line)
    n = split(line, f, /[[:space:]]*\|[[:space:]]*/)
    if (n < 5) next

    proj = f[2]; kw = f[3]
    count[kw]++

    if (index(seen[kw], "<" proj ">") == 0) {
      seen[kw] = seen[kw] "<" proj ">"
      projects[kw]++
      projlist[kw] = (projlist[kw] == "" ? proj : projlist[kw] ", " proj)
    }
  }

  function want(kw, mode) {
    if (mode == "cross")  return (!promoted[kw] && projects[kw] >= th)
    if (mode == "local")  return (!promoted[kw] && projects[kw] <  th && count[kw] >= th)
    if (mode == "regres") return ( promoted[kw] && count[kw] > pcount[kw] && pcount[kw] > 0)
    return 0
  }

  function flush_section(title, mode,   cmd, kw, hit) {
    hit = 0
    for (kw in count) if (want(kw, mode)) hit = 1
    if (!hit) return 0

    printf "%s\n", title
    fflush()
    cmd = "sort -t\"|\" -k2 -rn"
    for (kw in count) {
      if (!want(kw, mode)) continue
      if (mode == "cross")
        printf "  %-26s |%3d件 / %d案件  [%s]\n", kw, count[kw], projects[kw], projlist[kw] | cmd
      else if (mode == "local")
        printf "  %-26s |%3d件           [%s]\n", kw, count[kw], projlist[kw] | cmd
      else
        printf "  %-26s |%3d件（昇格時 %d件）  %s\n", kw, count[kw], pcount[kw], pnote[kw] | cmd
    }
    close(cmd)
    printf "\n"
    return 1
  }

  END {
    a = flush_section("== 横断ルールへ昇格 (10-conventions.mdc) ==", "cross")
    b = flush_section("== 案件内の決定へ昇格 (decisions/NNNN-*.md) ==", "local")
    c = flush_section("== 昇格後も再発している（ルールが効いていない） ==", "regres")

    if (!a && !b && !c) printf "昇格候補なし。\n\n"

    printf "%s\n", "-- 全 keyword --"
    fflush()
    cmd = "sort -t\"|\" -k2 -rn"
    for (kw in count)
      printf "  %-26s |%3d件 / %d案件%s\n", kw, count[kw], projects[kw], (promoted[kw] ? "  [昇格済]" : "") | cmd
    close(cmd)
  }
' "$PROMOTED" "$INBOX"
