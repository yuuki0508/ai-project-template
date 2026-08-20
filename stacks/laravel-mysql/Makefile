# 雛形生成はホストと同じUID/GIDで実行する。
# rootで作るとWSL2上のファイルがroot所有になり、エディタから保存できなくなる。
RUN_AS := --user "$(shell id -u):$(shell id -g)" -e HOME=/tmp

DC  := docker compose
APP := $(DC) exec app

.DEFAULT_GOAL := help
.PHONY: help init up down restart logs sh rebuild perms check fmt lint stan test migrate fresh seed tinker

help: ## コマンド一覧
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "};{printf "  \033[36m%-11s\033[0m %s\n", $$1, $$2}'

init: ## 初回のみ: Laravelの雛形を生成して初期設定
	@test -f .env || cp .env.example .env
	@if [ ! -f artisan ]; then \
	  $(DC) run --rm --no-deps $(RUN_AS) app sh -lc 'composer create-project laravel/laravel /tmp/app --no-interaction -q && cp -an /tmp/app/. /var/www/html/ && rm -rf /tmp/app'; \
	fi
	$(DC) run --rm --no-deps $(RUN_AS) app sh -lc 'composer require --dev laravel/pint larastan/larastan -q'
	$(DC) up -d
	@$(MAKE) perms
	$(APP) php artisan key:generate
	@$(MAKE) migrate
	@echo ""
	@echo "  アプリ      http://localhost:__PORT_WEB__"
	@echo "  phpMyAdmin  http://localhost:__PORT_PMA__  (root / .env の DB_ROOT_PASSWORD)"
	@echo "  メール確認  http://localhost:__PORT_MAIL__"

up: ## 起動
	@test -f .env || cp .env.example .env
	$(DC) up -d

down: ## 停止
	$(DC) down

restart: down up ## 再起動

rebuild: ## PHP/Nodeのバージョンを変えた後にイメージを作り直す
	$(DC) build --no-cache app
	$(DC) up -d --force-recreate

perms: ## storage / bootstrap/cache を書き込み可能にする（php-fpmはwww-dataで動くため）
	$(DC) exec -u root app sh -lc 'chmod -R a+rwX storage bootstrap/cache'

logs: ## ログ追尾
	$(DC) logs -f --tail=100

sh: ## appコンテナに入る
	$(APP) sh

check: lint stan test ## 整形チェック + 静的解析 + テスト（AIはこれを通すこと）

fmt: ## 自動整形
	$(APP) ./vendor/bin/pint

lint: ## 整形チェックのみ
	$(APP) ./vendor/bin/pint --test

stan: ## 静的解析
	$(APP) ./vendor/bin/phpstan analyse --memory-limit=1G

test: ## テスト
	$(APP) php artisan test

migrate: ## マイグレーション
	$(APP) php artisan migrate

fresh: ## DBを作り直して初期データ投入
	$(APP) php artisan migrate:fresh --seed

seed: ## 初期データ投入
	$(APP) php artisan db:seed

tinker: ## 対話シェル
	$(APP) php artisan tinker

include Makefile.handoff.mk
