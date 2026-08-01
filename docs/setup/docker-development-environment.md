# Docker開発環境構築手順

## 1. 目的

Diet Plannerのローカル開発環境をDocker Composeで再現可能にします。

Laravel Sailをそのまま使うのではなく、以下の役割を個別のコンテナとして構築し、Webアプリケーション基盤を学びます。

- PHP-FPM
- Nginx
- PostgreSQL
- Redis
- Node.js / Vite
- Mailpit

## 2. 前提

以下が完了していることを前提とします。

- WSL2とUbuntuの導入
- Docker DesktopとWSL Integrationの有効化
- `~/src/DietPlanner`へのLaravelプロジェクト作成
- WSL内で`docker version`と`docker compose version`が成功

推奨する文書の順序です。

1. `wsl2-development-environment.md`
2. `local-application-setup.md`
3. `github-repository-setup.md`
4. 本書

## 3. バージョン基準

| 項目 | 基準 |
|---|---|
| 確認日 | 2026-07-30 |
| Laravel | 13.x |
| PHP | 8.4 |
| Node.js | 22 LTS |
| PostgreSQL | 17 |
| Redis | 7.4 |
| Nginx | 1.27系 |
| Docker Compose | V2 |

無条件に`latest`を使わず、プロジェクトで動作確認したバージョンへ固定します。

## 4. 学習目標

- DockerfileとDockerイメージの関係を理解する
- Docker Composeで複数サービスを管理する
- NginxとPHP-FPMの役割を理解する
- サービス名を使ったコンテナ間通信を理解する
- Bind MountとNamed Volumeを使い分ける
- Health Checkで依存サービスの状態を確認する
- 開発用構成と本番用構成を分離する

## 5. 完了条件

- [ ] `docker compose config`が成功する
- [ ] `app`、`nginx`、`db`、`redis`、`node`、`mailpit`が起動する
- [ ] PostgreSQLとRedisがHealthyになる
- [ ] `http://localhost:8080`でLaravelが表示される
- [ ] `http://localhost:8025`でMailpitが表示される
- [ ] LaravelからPostgreSQLへ接続できる
- [ ] LaravelからRedisへ接続できる
- [ ] マイグレーションとテストを実行できる
- [ ] Viteの変更がブラウザへ反映される

## 6. ディレクトリ構成

```text
DietPlanner/
├─ app/
├─ bootstrap/
├─ config/
├─ database/
├─ public/
├─ resources/
├─ routes/
├─ storage/
├─ tests/
├─ docker/
│  ├─ nginx/
│  │  └─ default.conf
│  └─ php/
│     ├─ Dockerfile
│     └─ php.ini
├─ compose.yaml
├─ .dockerignore
├─ .env
├─ .env.example
├─ composer.json
├─ package.json
└─ vite.config.ts
```

## 7. 作業ディレクトリ

```bash
cd ~/src/DietPlanner
pwd
docker version
docker compose version
```

## 8. Docker用ディレクトリ

```bash
mkdir -p docker/php docker/nginx
```

## 9. PHP-FPM用Dockerfile

`docker/php/Dockerfile`

```dockerfile
FROM php:8.4-fpm-bookworm

ARG UID=1000
ARG GID=1000

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/tmp/composer

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        libicu-dev \
        libpq-dev \
        libzip-dev \
        unzip \
        zip \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        intl \
        opcache \
        pdo_pgsql \
        zip \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

RUN groupadd --gid "${GID}" app \
    && useradd \
        --uid "${UID}" \
        --gid "${GID}" \
        --create-home \
        --shell /bin/bash \
        app \
    && sed -ri 's/^user = .*/user = app/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -ri 's/^group = .*/group = app/' /usr/local/etc/php-fpm.d/www.conf

COPY docker/php/php.ini /usr/local/etc/php/conf.d/99-app.ini

WORKDIR /var/www/html

CMD ["php-fpm"]
```

主なPHP拡張です。

| 拡張 | 用途 |
|---|---|
| `pdo_pgsql` | PostgreSQL接続 |
| `redis` | Redis接続 |
| `bcmath` | 数値計算 |
| `intl` | 国際化・日付処理 |
| `zip` | ZIP処理 |
| `opcache` | PHPコードキャッシュ |

## 10. PHP設定

`docker/php/php.ini`

```ini
[PHP]
date.timezone = Asia/Tokyo
memory_limit = 256M
max_execution_time = 60
max_input_time = 60
post_max_size = 20M
upload_max_filesize = 20M

display_errors = On
display_startup_errors = On
error_reporting = E_ALL

[opcache]
opcache.enable = 1
opcache.enable_cli = 1
opcache.validate_timestamps = 1
opcache.revalidate_freq = 0
```

これは開発用です。本番では`display_errors = Off`にします。

## 11. Nginx設定

`docker/nginx/default.conf`

```nginx
server {
    listen 80;
    server_name _;
    root /var/www/html/public;
    index index.php index.html;

    charset utf-8;
    client_max_body_size 20m;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico {
        access_log off;
        log_not_found off;
    }

    location = /robots.txt {
        access_log off;
        log_not_found off;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $realpath_root;
        fastcgi_read_timeout 60s;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log warn;
}
```

`app:9000`の`app`はComposeのサービス名です。

## 12. node設定

`docker/node/Dockerfile`

```docker
FROM node:22-bookworm AS node

FROM php:8.4-cli-bookworm

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

WORKDIR /var/www/html
```

## 13. Composeファイル

プロジェクト直下の`compose.yaml`

```yaml
name: diet_planner

services:
  app:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
      args:
        UID: ${UID:-1000}
        GID: ${GID:-1000}
    image: diet_planner-app:local
    working_dir: /var/www/html
    volumes:
      - ./:/var/www/html
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - app-network
    restart: unless-stopped

  nginx:
    image: nginx:1.27-alpine
    ports:
      - "${APP_HTTP_PORT:-8080}:80"
    volumes:
      - ./:/var/www/html:ro
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - app
    networks:
      - app-network
    restart: unless-stopped

  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: ${DB_DATABASE:-diet_planner}
      POSTGRES_USER: ${DB_USERNAME:-diet_planner}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-local_password}
      TZ: Asia/Tokyo
    ports:
      - "${DB_FORWARD_PORT:-5432}:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \"$${POSTGRES_USER}\" -d \"$${POSTGRES_DB}\""]
      interval: 5s
      timeout: 5s
      retries: 10
      start_period: 10s
    networks:
      - app-network
    restart: unless-stopped

  redis:
    image: redis:7.4-alpine
    command: ["redis-server", "--appendonly", "yes"]
    ports:
      - "${REDIS_FORWARD_PORT:-6379}:6379"
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 10
    networks:
      - app-network
    restart: unless-stopped

  node:
    build:
      context: .
      dockerfile: ./docker/node/Dockerfile
    working_dir: /var/www/html
    user: "${UID:-1000}:${GID:-1000}"
    environment:
      HOME: /tmp
      CHOKIDAR_USEPOLLING: "true"
    ports:
      - "${VITE_FORWARD_PORT:-5173}:5173"
    volumes:
      - ./:/var/www/html
      - node-modules:/var/www/html/node_modules
    command:
      - sh
      - -lc
      - npm install && npm run dev -- --host 0.0.0.0
    networks:
      - app-network
    restart: "no"

  mailpit:
    image: axllent/mailpit:latest
    ports:
      - "${MAILPIT_SMTP_FORWARD_PORT:-1025}:1025"
      - "${MAILPIT_UI_FORWARD_PORT:-8025}:8025"
    networks:
      - app-network
    restart: unless-stopped

networks:
  app-network:
    driver: bridge

volumes:
  postgres-data:
  redis-data:
  node-modules:
```

Mailpitも、運用を固定する段階では確認済みバージョンへ固定します。

## 14. `.dockerignore`

```gitignore
.git
.github
.idea
.vscode
node_modules
vendor
storage/logs/*
storage/framework/cache/*
storage/framework/sessions/*
storage/framework/views/*
.env
.env.*
!.env.example
npm-debug.log
coverage
playwright-report
test-results
```

`.dockerignore`は、不要ファイルや秘密情報をDockerのBuild Contextへ送らないための設定です。

## 15. `.env`のDocker用設定

UIDとGIDを確認します。

```bash
id -u
id -g
```

`.env`へ追記します。

```dotenv
UID=1000
GID=1000

APP_HTTP_PORT=8080
VITE_FORWARD_PORT=5173
DB_FORWARD_PORT=5432
REDIS_FORWARD_PORT=6379
MAILPIT_SMTP_FORWARD_PORT=1025
MAILPIT_UI_FORWARD_PORT=8025
```

Laravelの接続設定を変更します。

```dotenv
APP_NAME="Diet Planner"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8080

APP_LOCALE=ja
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=ja_JP

DB_CONNECTION=pgsql
DB_HOST=db
DB_PORT=5432
DB_DATABASE=diet_planner
DB_USERNAME=diet_planner
DB_PASSWORD=local_password

SESSION_DRIVER=redis
CACHE_STORE=redis
QUEUE_CONNECTION=redis

REDIS_CLIENT=phpredis
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_FROM_ADDRESS="noreply@DietPlanner.local"
MAIL_FROM_NAME="${APP_NAME}"
```

コンテナ間接続では`localhost`ではなく、`db`、`redis`、`mailpit`のサービス名を使用します。

## 16. `.env.example`

`.env.example`にも必要な変数名を記載しますが、本番の秘密情報は記載しません。

```dotenv
APP_NAME="Diet Planner"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8080

DB_CONNECTION=pgsql
DB_HOST=db
DB_PORT=5432
DB_DATABASE=diet_planner
DB_USERNAME=diet_planner
DB_PASSWORD=change_me

SESSION_DRIVER=redis
CACHE_STORE=redis
QUEUE_CONNECTION=redis

REDIS_CLIENT=phpredis
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025

UID=1000
GID=1000
APP_HTTP_PORT=8080
VITE_FORWARD_PORT=5173
DB_FORWARD_PORT=5432
REDIS_FORWARD_PORT=6379
MAILPIT_SMTP_FORWARD_PORT=1025
MAILPIT_UI_FORWARD_PORT=8025
```

## 17. Vite設定

既存の`vite.config.ts`または`vite.config.js`の`defineConfig`へ、次の`server`設定を追加します。

```typescript
server: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: true,
    hmr: {
        host: 'localhost',
    },
    watch: {
        usePolling: true,
    },
},
```

Starter Kitが生成した既存の`plugins`や入力ファイル設定は維持してください。

## 18. 設定検証とビルド

```bash
docker compose config
docker compose config --services
docker compose build --no-cache app
```

## 19. 起動

```bash
docker compose up -d
docker compose ps
```

ログ確認です。

```bash
docker compose logs --tail=100
docker compose logs -f app
docker compose logs -f nginx
docker compose logs -f node
```

## 20. PHPとComposer

```bash
docker compose exec app php -v
docker compose exec app composer --version
docker compose exec app php -m | grep -E 'pdo_pgsql|redis'
docker compose exec --user app app composer install
```

## 21. APP_KEYと権限

```bash
docker compose exec --user app app php artisan key:generate
grep '^APP_KEY=' .env
```

権限エラーが出る場合です。

```bash
sudo chown -R "$(id -u):$(id -g)" storage bootstrap/cache
chmod -R ug+rwX storage bootstrap/cache
docker compose run --rm --user root node \
  chown -R 1000:1000 /var/www/html/node_modules
```

`chmod -R 777`は使用しません。

## 22. PostgreSQL

```bash
docker compose exec db psql -U diet_planner -d diet_planner
```

PostgreSQL内で確認します。

```sql
SELECT current_database();
SELECT version();
\q
```

Laravelから確認します。

```bash
docker compose exec --user app app php artisan migrate
docker compose exec --user app app php artisan migrate:status
```

## 23. Redis

```bash
docker compose exec redis redis-cli ping
```

`PONG`が表示されることを確認します。

Laravelから確認します。

```bash
docker compose exec --user app app php artisan tinker
```

```php
cache()->put('docker-test', 'ok', 60);
cache()->get('docker-test');
exit
```

## 24. ブラウザ確認

| 対象 | URL |
|---|---|
| Laravel | `http://localhost:8080` |
| Mailpit | `http://localhost:8025` |
| Vite | `http://localhost:5173` |

## 25. メール確認

```bash
docker compose exec --user app app php artisan tinker
```

```php
Illuminate\Support\Facades\Mail::raw(
    'Mailpit test',
    fn ($message) => $message->to('test@example.com')->subject('Mailpit test')
);
exit
```

Mailpitで受信を確認します。

## 26. テスト

```bash
docker compose exec --user app app php artisan test
docker compose exec --user app app ./vendor/bin/pint --test
docker compose exec node npm run build
```

## 27. よく使うコマンド

```bash
docker compose up -d
docker compose stop
docker compose down
docker compose up -d --build
docker compose ps
docker compose logs -f --tail=100
docker compose exec --user app app bash
docker compose exec --user app app php artisan
docker compose exec --user app app composer install
docker compose exec node npm install
```

Volumeも削除する場合です。

```bash
docker compose down -v
```

この操作はローカルDBデータを削除します。

## 28. Makefile例

```makefile
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
```

Makefileのコマンド行はタブでインデントします。

## 29. Git管理

Gitへ追加します。

```text
compose.yaml
docker/php/Dockerfile
docker/php/php.ini
docker/nginx/default.conf
.dockerignore
.env.example
Makefile
```

Gitへ追加しません。

```text
.env
vendor/
node_modules/
storage/logs/
```

確認します。

```bash
git status
git check-ignore -v .env
```

## 30. トラブルシューティング

### Docker daemonへ接続できない

```powershell
wsl --shutdown
```

Docker Desktopを再起動し、WSLで確認します。

```bash
docker version
```

### ポートが使用中

`.env`の転送ポートだけを変更します。

```dotenv
DB_FORWARD_PORT=15432
REDIS_FORWARD_PORT=16379
```

コンテナ内部の`DB_PORT=5432`は変更しません。

### DB接続エラー

```dotenv
DB_HOST=db
DB_PORT=5432
```

設定キャッシュを削除します。

```bash
docker compose exec --user app app php artisan optimize:clear
```

### Nginxの502

```bash
docker compose ps app
docker compose logs app
docker compose exec nginx nc -zv app 9000
```

### CSSが反映されない

```bash
docker compose ps node
docker compose logs node
docker compose restart node
```

### PostgreSQLがHealthyにならない

```bash
docker compose logs db
```

ローカルデータを破棄してよい場合だけ実行します。

```bash
docker compose down -v
docker compose up -d
```

## 31. セキュリティ上の注意

- `.env`をGitへcommitしない
- ローカルのパスワードを本番で再利用しない
- Docker Socketをアプリへマウントしない
- `privileged: true`を付けない
- 不要なホストポートを公開しない
- 本番で`APP_DEBUG=true`にしない
- Docker Desktopとベースイメージを定期更新する
- 本番ではソースコードをBind Mountしない

## 32. 本番との差

| 開発 | 本番 |
|---|---|
| Bind Mount | ソースをイメージへCOPY |
| Vite開発サーバー | `npm run build`済み |
| ローカルPostgreSQL | Amazon RDS |
| Mailpit | Amazon SES等 |
| 手動起動 | CI/CD |
| `.env` | Parameter Store等 |
| `APP_DEBUG=true` | `APP_DEBUG=false` |

## 33. 参考資料

- https://docs.docker.com/desktop/features/wsl/
- https://docs.docker.com/desktop/features/wsl/use-wsl/
- https://docs.docker.com/compose/how-tos/production/
- https://laravel.com/docs/13.x/installation
- https://laravel.com/docs/13.x/deployment

## 34. 変更履歴

| バージョン | 日付 | 内容 |
|---|---|---|
| 0.1 | 2026-07-30 | 初版 |
