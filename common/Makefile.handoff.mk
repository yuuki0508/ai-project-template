# =============================================================
# handoff / decisions inbox
#   既存の Makefile から include して使う:
#     include Makefile.handoff.mk
# =============================================================

PROJECT      ?= __PROJECT_SLUG__
INBOX        ?= docs/decisions/_inbox.md
GLOBAL_INBOX ?= $(HOME)/ai-knowledge/_inbox.md
PROMOTED     ?= $(dir $(GLOBAL_INBOX))_promoted.md
TODAY        := $(shell date +%F)

.PHONY: handoff done promote promoted inbox-sync

handoff: ## 作業終了時: 引き継ぎ観測プロンプトをクリップボードへ
	@if command -v pbcopy >/dev/null 2>&1; then \
		cat .ai/prompts/handoff.md | pbcopy; echo "→ クリップボードにコピーしました。AIに貼り付けてください。"; \
	elif command -v xclip >/dev/null 2>&1; then \
		cat .ai/prompts/handoff.md | xclip -selection clipboard; echo "→ クリップボードにコピーしました。AIに貼り付けてください。"; \
	elif command -v clip.exe >/dev/null 2>&1; then \
		cat .ai/prompts/handoff.md | clip.exe; echo "→ クリップボードにコピーしました。AIに貼り付けてください。"; \
	else \
		cat .ai/prompts/handoff.md; \
	fi

# usage: make done TASK=<タスク名>   抜け道: make done TASK=<名> FORCE=1
done: ## タスク完了: TASK=<名> 指定。handoff 未実施だと通らない
	@test -n "$(TASK)" || { echo "usage: make done TASK=<タスク名>"; exit 1; }
	@test -f tasks/active/$(TASK).md || { echo "tasks/active/$(TASK).md がありません"; exit 1; }
	@if [ -z "$(FORCE)" ] && ! grep -q "^- $(TODAY) | $(PROJECT) |" $(INBOX); then \
		echo ""; \
		echo "  今日の観測ログが $(INBOX) にありません。"; \
		echo "  先に  make handoff  を実行し、AIに貼り付けてください。"; \
		echo "  本当に何も無かった場合は  make done TASK=$(TASK) FORCE=1"; \
		echo ""; \
		exit 1; \
	fi
	@mkdir -p tasks/done
	@mv tasks/active/$(TASK).md tasks/done/$(TODAY)-$(TASK).md
	@$(MAKE) --no-print-directory inbox-sync
	@echo "→ tasks/done/$(TODAY)-$(TASK).md"
	@$(MAKE) --no-print-directory promote

inbox-sync: ## 案件内 inbox を横断 inbox へ集約（重複行はスキップ）
	@mkdir -p $(dir $(GLOBAL_INBOX))
	@touch $(GLOBAL_INBOX)
	@grep -E '^- [0-9]{4}-[0-9]{2}-[0-9]{2} \|' $(INBOX) 2>/dev/null | \
		while IFS= read -r l; do \
			grep -qxF -e "$$l" $(GLOBAL_INBOX) || echo "$$l" >> $(GLOBAL_INBOX); \
		done; true

promote: ## 昇格候補を判定する（人間が数えない）
	@AI_INBOX=$(GLOBAL_INBOX) bash bin/promote-check.sh

# usage: make promoted KW=<keyword> [NOTE=<昇格先メモ>]
promoted: ## 昇格済みとして記録し、以後の候補から除外する
	@test -n "$(KW)" || { echo "usage: make promoted KW=<keyword> [NOTE=<昇格先>]"; exit 1; }
	@test -f $(GLOBAL_INBOX) || { echo "横断inboxがありません: $(GLOBAL_INBOX)"; exit 1; }
	@touch $(PROMOTED)
	@if grep -qE '^[[:space:]]*$(KW)[[:space:]]*\|' $(PROMOTED); then \
		echo "既に登録済みです: $(KW)"; exit 1; \
	fi
	@c=`awk -F'[[:space:]]*[|][[:space:]]*' -v k='$(KW)' '/^-[[:space:]]/{ if ($$3==k) n++ } END{ print n+0 }' $(GLOBAL_INBOX)`; \
	test "$$c" -gt 0 || { echo "inbox に見つかりません: $(KW)"; exit 1; }; \
	printf '%s | %s | %s | %s\n' '$(KW)' "$$c" "`date +%F`" '$(NOTE)' >> $(PROMOTED); \
	echo "→ 昇格済みに記録しました: $(KW) （現在 $$c 件）"
