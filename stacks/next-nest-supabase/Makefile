# コンテナをホストと同じUID/GIDで動かす。
# rootで npm install するとWSL2上のファイルがroot所有になり、エディタから保存できなくなる。
DC  := HOST_UID=$(shell id -u) HOST_GID=$(shell id -g) docker compose
WEB := $(DC) exec web
API := $(DC) exec api
SB  := npx -y supabase@latest

.DEFAULT_GOAL := help
.PHONY: help init up down restart logs sh-web sh-api rebuild check check-web check-api fmt test migrate new-migration fresh pull status studio

help: ## コマンド一覧
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "};{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

init: ## 初回のみ: Supabase初期化 + web / api の雛形を生成
	@test -f .env || cp .env.example .env
	@# バインドマウント先をホスト側で先に作る。Dockerに作らせるとroot所有になる
	@mkdir -p web api
	@test -d supabase || $(SB) init
	$(SB) start
	@if [ ! -f web/package.json ]; then \
	  $(DC) run --rm --no-deps -w /app web sh -lc \
	    'npx -y create-next-app@latest web --ts --tailwind --eslint --app --no-src-dir --use-npm --yes \
	     && cd web && npm i @supabase/supabase-js @supabase/ssr'; \
	fi
	@if [ ! -f api/package.json ]; then \
	  $(DC) run --rm --no-deps -w /app api sh -lc \
	    'npx -y @nestjs/cli@latest new api -p npm --skip-git --strict \
	     && cd api && npm i @prisma/client @supabase/supabase-js && npm i -D prisma \
	     && npx prisma init --datasource-provider postgresql'; \
	fi
	@rm -f api/.env
	$(DC) up -d
	@echo ""
	@echo "  ★ 上に表示された anon key / service_role key を .env に貼ってください"
	@echo "  web http://localhost:__PORT_WEB__   api http://localhost:__PORT_API__"
	@echo "  Studio http://localhost:__SB_STUDIO__       メール http://localhost:__SB_INBUCKET__"

up: ## 起動（Supabase + web/api）
	@test -f .env || cp .env.example .env
	@mkdir -p web api
	$(SB) start
	$(DC) up -d

down: ## 停止
	$(DC) down
	$(SB) stop

restart: down up ## 再起動

rebuild: ## Nodeのバージョンを変えた後にイメージを取り直して作り直す
	$(DC) pull
	$(DC) up -d --force-recreate

logs: ## web/api のログ追尾
	$(DC) logs -f --tail=100

sh-web: ## webコンテナに入る
	$(WEB) sh

sh-api: ## apiコンテナに入る
	$(API) sh

check: check-api check-web ## lint + 型 + テスト（AIはこれを通すこと）

check-api: ## api の検証
	$(API) npm run lint
	$(API) npx tsc --noEmit
	$(API) npm test -- --passWithNoTests

check-web: ## web の検証
	$(WEB) npm run lint
	$(WEB) npx tsc --noEmit

fmt: ## 自動整形
	$(API) npx prettier --write "src/**/*.ts"
	$(WEB) npx prettier --write "**/*.{ts,tsx}"

test: ## テストのみ
	$(API) npm test -- --passWithNoTests

new-migration: ## 新しいマイグレーションSQLを作る  例: make new-migration NAME=create_partners
	$(SB) migration new $(NAME)

migrate: ## マイグレーションを適用してPrismaの型を更新
	$(SB) migration up
	@$(MAKE) pull

pull: ## DBスキーマからPrismaスキーマと型を再生成
	$(API) npx prisma db pull
	$(API) npx prisma generate

fresh: ## DBを作り直してマイグレーションとseedを再適用
	$(SB) db reset
	@$(MAKE) pull

status: ## Supabaseの起動状態とキーを表示
	$(SB) status

studio: ## Supabase Studio を開く
	@echo "http://localhost:__SB_STUDIO__"

