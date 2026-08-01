.PHONY: up down stop build ps logs shell test migrate fresh

up:
	docker compose up -d

down:
	docker compose down

stop:
	docker compose stop

build:
	docker compose up -d --build

ps:
	docker compose ps

logs:
	docker compose logs -f --tail=100

shell:
	docker compose exec --user app app bash

test:
	docker compose exec --user app app php artisan test

migrate:
	docker compose exec --user app app php artisan migrate

fresh:
	docker compose exec --user app app php artisan migrate:fresh --seed
