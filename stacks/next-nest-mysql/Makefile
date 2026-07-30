# コンテナをホストと同じUID/GIDで動かす。
# rootで npm install するとWSL2上のファイルがroot所有になり、エディタから保存できなくなる。
DC  := HOST_UID=$(shell id -u) HOST_GID=$(shell id -g) docker compose
WEB := $(DC) exec web
API := $(DC) exec api

.DEFAULT_GOAL := help
.PHONY: help init up down restart logs sh-web sh-api rebuild check check-web check-api fmt test migrate fresh seed studio

help: ## コマンド一覧
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "};{printf "  \033[36m%-11s\033[0m %s\n", $$1, $$2}'

init: ## 初回のみ: web / api の雛形を生成
	@test -f .env || cp .env.example .env
	@# バインドマウント先をホスト側で先に作る。Dockerに作らせるとroot所有になる
	@mkdir -p web api
	@if [ ! -f web/package.json ]; then \
	  $(DC) run --rm --no-deps -w /app web sh -lc \
	    'npx -y create-next-app@latest web --ts --tailwind --eslint --app --no-src-dir --use-npm --yes'; \
	fi
	@if [ ! -f api/package.json ]; then \
	  $(DC) run --rm --no-deps -w /app api sh -lc \
	    'npx -y @nestjs/cli@latest new api -p npm --skip-git --strict \
	     && cd api && npm i @prisma/client && npm i -D prisma \
	     && npx prisma init --datasource-provider mysql'; \
	fi
	@# prisma init が作るダミーの api/.env は使わない（接続情報は compose.yml 経由）
	@rm -f api/.env
	$(DC) up -d
	@echo ""
	@echo "  web         http://localhost:__PORT_WEB__"
	@echo "  api         http://localhost:__PORT_API__"
	@echo "  phpMyAdmin  http://localhost:__PORT_PMA__  (root / .env の DB_ROOT_PASSWORD)"
	@echo "  メール確認  http://localhost:__PORT_MAIL__"
	@echo "  次に api/prisma/schema.prisma を書いて make migrate"

up: ## 起動
	@test -f .env || cp .env.example .env
	@mkdir -p web api
	$(DC) up -d

down: ## 停止
	$(DC) down

restart: down up ## 再起動

rebuild: ## Nodeのバージョンを変えた後にイメージを取り直して作り直す
	$(DC) pull
	$(DC) up -d --force-recreate

logs: ## ログ追尾
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

migrate: ## Prismaマイグレーション作成＆適用
	$(API) npx prisma migrate dev

fresh: ## DBを作り直して初期データ投入
	$(API) npx prisma migrate reset --force

seed: ## 初期データ投入
	$(API) npx prisma db seed

studio: ## Prisma Studio
	$(API) npx prisma studio
