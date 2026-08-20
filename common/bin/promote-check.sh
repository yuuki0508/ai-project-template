#!/usr/bin/env bash
#
# promote-check.sh — inbox を走査し、昇格候補を機械的に判定する
#
#   usage:
#     bin/promote-check.sh              # 横断 inbox を見る
#     bin/promote-check.sh path/to.md   # 任意の inbox を見る
#
#   env:
#     AI_INBOX   横断 inbox のパス（既定: ~/ai-knowledge/_inbox.md）
#     THRESHOLD  昇格閾値（既定: 2）
#
set -euo pipefail

INBOX="${1:-${AI_INBOX:-$HOME/ai-knowledge/_inbox.md}}"
THRESHOLD="${THRESHOLD:-2}"

if [ ! -f "$INBOX" ]; then
  echo "inbox が見つかりません: $INBOX" >&2
  echo "AI_INBOX で場所を指定するか、make handoff-sync で作成してください。" >&2
  exit 1
fi

printf 'inbox: %s  (閾値: %s回)\n\n' "$INBOX" "$THRESHOLD"

awk -v th="$THRESHOLD" '
  # "- date | project | keyword | type | content" の行だけを対象にする
  /^-[[:space:]]/ {
    line = $0
    sub(/^-[[:space:]]+/, "", line)
    n = split(line, f, /[[:space:]]*\|[[:space:]]*/)
    if (n < 5) next

    proj = f[2]; kw = f[3]

    count[kw]++

    # 同一案件を二重に数えない
    if (index(seen[kw], "<" proj ">") == 0) {
      seen[kw] = seen[kw] "<" proj ">"
      projects[kw]++
      projlist[kw] = (projlist[kw] == "" ? proj : projlist[kw] ", " proj)
    }
  }

  function flush_section(title, mode,   cmd, kw, hit) {
    hit = 0
    for (kw in count) {
      if (mode == "cross" && projects[kw] >= th) hit = 1
      if (mode == "local" && projects[kw] <  th && count[kw] >= th) hit = 1
    }
    if (!hit) return 0

    printf "%s\n", title
    fflush()

    cmd = "sort -t\"|\" -k2 -rn"
    for (kw in count) {
      if (mode == "cross" && projects[kw] >= th)
        printf "  %-26s |%3d件 / %d案件  [%s]\n", kw, count[kw], projects[kw], projlist[kw] | cmd
      if (mode == "local" && projects[kw] < th && count[kw] >= th)
        printf "  %-26s |%3d件           [%s]\n", kw, count[kw], projlist[kw] | cmd
    }
    close(cmd)
    printf "\n"
    return 1
  }

  END {
    a = flush_section("== 横断ルールへ昇格 (10-conventions.mdc) ==", "cross")
    b = flush_section("== 案件内の決定へ昇格 (decisions/NNNN-*.md) ==", "local")

    if (!a && !b) printf "昇格候補なし。\n\n"

    printf "%s\n", "-- 全 keyword --"
    fflush()
    cmd = "sort -t\"|\" -k2 -rn"
    for (kw in count)
      printf "  %-26s |%3d件 / %d案件\n", kw, count[kw], projects[kw] | cmd
    close(cmd)
  }
' "$INBOX"
