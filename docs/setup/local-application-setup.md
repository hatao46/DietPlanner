# ローカルアプリケーション初期構築手順

## 1. 目的

Diet PlannerのLaravelアプリケーションを新規作成し、ローカル開発を開始できる基準状態を準備します。

採用する構成です。

- Laravel 13
- Laravel公式Vue Starter Kit
- Inertia
- Vue 3
- TypeScript
- Tailwind CSS
- shadcn-vue
- PostgreSQL
- Redis
- PHPUnitまたはPest

## 2. 前提

- WSL2とUbuntuの導入済み
- Docker DesktopとWSL Integrationの設定済み
- WSLで`docker version`が成功
- WSLで`docker compose version`が成功
- `~/src`が作成済み

推奨する文書の順序です。

1. `wsl2-development-environment.md`
2. 本書
3. `github-repository-setup.md`
4. `docker-development-environment.md`

本書前半でLaravelの雛形を作成し、後半の動作確認はDocker環境構築後に行います。

## 3. バージョン基準

| 項目 | 基準 |
|---|---|
| 確認日 | 2026-07-30 |
| Laravel | 13.x |
| PHP | 8.4 |
| Vue | 3 |
| Inertia | 3 |
| Node.js | 22 LTS |
| PostgreSQL | 17 |
| Redis | 7.4 |

新規作成時はLaravel公式ドキュメントで要件を再確認します。

## 4. 学習目標

- Laravelのディレクトリ構成を理解する
- Composerとnpmの役割を理解する
- Laravel InstallerとStarter Kitを理解する
- InertiaによるLaravelとVueの接続を理解する
- `.env`と`.env.example`を使い分ける
- APP_KEYの役割を理解する
- マイグレーションとSeederを実行する
- 開発開始前に基準状態をテストする

## 5. 完了条件

### プロジェクト作成

- [ ] `~/src/DietPlanner`がある
- [ ] Laravel 13が作成されている
- [ ] Vue Starter Kitを選択している
- [ ] Inertia、Vue 3、TypeScriptがある
- [ ] `.env`と`.env.example`がある
- [ ] `composer.json`と`package.json`がある

### Docker構築後

- [ ] `http://localhost:8080`を表示できる
- [ ] ユーザー登録できる
- [ ] ログイン・ログアウトできる
- [ ] ダッシュボードを表示できる
- [ ] PostgreSQLへマイグレーションできる
- [ ] Redisを利用できる
- [ ] PHPテストが成功する
- [ ] フロントエンドのビルドが成功する

## 6. 作成方針

WSLへPHPやComposerを恒久的に直接インストールせず、Laravel作成時だけComposerコンテナを利用します。

```text
WSL
  └ Docker
      └ 一時Composerコンテナ
          └ Laravel Installer
              └ DietPlanner生成
```

作成後のPHP、Composer、Node.jsもDockerコンテナ内で実行します。

## 7. 作業ディレクトリ

```bash
mkdir -p ~/src
cd ~/src
docker version
docker compose version
```

`DietPlanner`がすでにある場合は確認します。

```bash
ls -la ~/src/DietPlanner
```

既存ファイルがある場合は、本書の「既存ディレクトリがある場合」を参照します。

## 8. Laravel Installerをコンテナで実行する

```bash
cd ~/src
```

```bash
docker run --rm -it \
  --entrypoint sh \
  -u "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  -e COMPOSER_HOME=/tmp/composer \
  -v "$PWD":/workspace \
  -w /workspace \
  composer:2 \
  -lc '
    composer global require laravel/installer &&
    /tmp/composer/vendor/bin/laravel new DietPlanner
  '
```

処理後、一時コンテナは削除されます。プロジェクトファイルは`~/src/DietPlanner`へ残ります。

## 9. Laravel Installerの選択

質問内容はバージョンにより変わります。

| 質問 | 推奨 |
|---|---|
| Starter kit | Vue |
| Authentication | Laravel built-in authentication |
| Testing framework | PHPUnitまたはPest |
| Database | PostgreSQL |
| Run migrations | Docker構築前なら実行しない |
| Initialize Git | どちらでも可 |
| Install npm dependencies | Nodeがなければスキップ可 |

### PHPUnitとPest

既存のPHPUnit形式に慣れている場合はPHPUnitで問題ありません。

簡潔な記述を学ぶ場合はPestを選択できます。

## 10. 作成結果

```bash
cd ~/src/DietPlanner
ls -la
```

最低限、以下を確認します。

```text
app/
bootstrap/
config/
database/
public/
resources/
routes/
storage/
tests/
.env
.env.example
artisan
composer.json
package.json
vite.config.ts
```

Vue Starter Kitでは概ね次の構成があります。

```text
resources/js/
├─ components/
├─ composables/
├─ layouts/
├─ lib/
├─ pages/
└─ types/
```

## 11. ファイル所有者

```bash
ls -ln
id -u
id -g
```

root所有の場合です。

```bash
sudo chown -R "$(id -u):$(id -g)" ~/src/DietPlanner
```

## 12. 既存ディレクトリがある場合

READMEや`docs`を先に作成していると、Laravel Installerが空でないディレクトリへの作成を拒否する場合があります。

### 一時ディレクトリへ生成

```bash
cd ~/src
```

```bash
docker run --rm -it \
  --entrypoint sh \
  -u "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  -e COMPOSER_HOME=/tmp/composer \
  -v "$PWD":/workspace \
  -w /workspace \
  composer:2 \
  -lc '
    composer global require laravel/installer &&
    /tmp/composer/vendor/bin/laravel new DietPlanner-bootstrap
  '
```

### 既存ディレクトリをバックアップ

```bash
cp -a DietPlanner \
  "DietPlanner.backup.$(date +%Y%m%d%H%M%S)"
```

### 統合

```bash
sudo apt update
sudo apt install -y rsync
```

```bash
rsync -a \
  --exclude='.git' \
  DietPlanner-bootstrap/ \
  DietPlanner/
```

同名ファイルの上書きには注意します。統合後に一時ディレクトリを削除します。

```bash
rm -rf DietPlanner-bootstrap
```

## 13. `.env`と`.env.example`

### `.env`

- 端末・環境固有の設定
- APP_KEY
- DBパスワード
- API認証情報
- Gitへcommitしない

### `.env.example`

- 必要な設定項目の雛形
- 秘密値を含めない
- Gitへcommitする

確認します。

```bash
grep -n '^\.env' .gitignore
```

Git初期化後です。

```bash
git check-ignore -v .env
```

## 14. 基本設定

Docker構築時に`.env`を次へ変更します。

```dotenv
APP_NAME="Diet Planner"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8080

APP_LOCALE=ja
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=ja_JP
```

日時方針の推奨です。

- DBの日時：UTCを基本
- 画面表示：Asia/Tokyo
- 日付だけ：`date`型
- 日時変換：Carbonで明示

## 15. README

Laravel標準READMEをプロジェクト用に更新します。

含める内容です。

- プロジェクト目的
- 学習目標
- MVP機能
- 技術スタック
- 環境構成
- ローカル起動方法
- テスト方法
- 公開条件
- docsへのリンク

## 16. 文書配置

```text
docs/
├─ setup/
│  ├─ wsl2-development-environment.md
│  ├─ local-application-setup.md
│  ├─ github-repository-setup.md
│  └─ docker-development-environment.md
└─ requirements/
   └─ non-functional-requirements.md
```

## 17. 次にDocker環境を作る

ここで`docker-development-environment.md`に従い、以下を作成します。

- PHP-FPM
- Nginx
- PostgreSQL
- Redis
- Node/Vite
- Mailpit

Docker構築後、以下へ戻ります。

# Docker環境構築後の作業

## 18. コンテナ起動

```bash
cd ~/src/DietPlanner
docker compose up -d --build
docker compose ps
```

## 19. PHP依存関係

```bash
docker compose exec --user app app composer install
```

## 20. Node依存関係

```bash
docker compose exec node npm install
```

Nodeサービスが起動時に`npm install`する構成なら自動実行されます。

## 21. APP_KEY

```bash
docker compose exec --user app app php artisan key:generate
grep '^APP_KEY=' .env
```

## 22. 設定キャッシュ

```bash
docker compose exec --user app app php artisan optimize:clear
```

`.env`を変更した後に実行します。

## 23. PostgreSQL設定

```dotenv
DB_CONNECTION=pgsql
DB_HOST=db
DB_PORT=5432
DB_DATABASE=diet_planner
DB_USERNAME=diet_planner
DB_PASSWORD=local_password
```

確認します。

```bash
docker compose exec --user app app php artisan migrate:status
```

## 24. マイグレーション

```bash
docker compose exec --user app app php artisan migrate
docker compose exec --user app app php artisan db:seed
```

開発DBを作り直す場合です。

```bash
docker compose exec --user app app php artisan migrate:fresh --seed
```

既存データが削除されます。

## 25. Redis設定

```dotenv
SESSION_DRIVER=redis
CACHE_STORE=redis
QUEUE_CONNECTION=redis

REDIS_CLIENT=phpredis
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379
```

```bash
docker compose exec --user app app php artisan optimize:clear
docker compose exec --user app app php artisan tinker
```

```php
cache()->put('setup-check', 'ok', 60);
cache()->get('setup-check');
exit
```

`"ok"`が返ることを確認します。

## 26. ストレージリンク

```bash
docker compose exec --user app app php artisan storage:link
```

本番の画像保存はS3を利用する予定です。

## 27. 画面確認

```text
http://localhost:8080
```

確認内容です。

- LaravelまたはStarter Kitの画面
- CSS適用
- JavaScriptエラーなし
- Laravel例外なし

## 28. 認証確認

最低限、以下を確認します。

1. ユーザー登録
2. ログイン
3. ダッシュボード
4. ログアウト
5. 再ログイン
6. プロフィール設定

Starter Kitにはパスワード再設定やメール認証なども含まれます。

## 29. テストユーザー

```bash
docker compose exec --user app app php artisan tinker
```

```php
App\Models\User::factory()->create([
    'name' => 'Test User',
    'email' => 'test@example.com',
    'password' => bcrypt('password'),
]);
exit
```

ローカル・ステージング用です。本番へ同じパスワードを作成しません。

## 30. 初期テスト

```bash
docker compose exec --user app app php artisan test
```

PHPUnitの場合です。

```bash
docker compose exec --user app app ./vendor/bin/phpunit
```

Pestの場合です。

```bash
docker compose exec --user app app ./vendor/bin/pest
```

初期状態の失敗は、アプリ実装前に解消します。

## 31. フロントエンド

```bash
docker compose exec node npm run build
docker compose logs -f node
```

## 32. Pint

```bash
docker compose exec --user app app ./vendor/bin/pint --test
```

整形します。

```bash
docker compose exec --user app app ./vendor/bin/pint
```

## 33. ルート一覧

```bash
docker compose exec --user app app php artisan route:list
```

認証関連ルートを確認します。

## 34. DB状態

```bash
docker compose exec --user app app php artisan migrate:status
```

```bash
docker compose exec db \
  psql \
  -U diet_planner \
  -d diet_planner \
  -c '\dt'
```

## 35. グラフライブラリ

Chart.jsを採用する場合です。

```bash
docker compose exec node npm install chart.js vue-chartjs
```

```bash
git diff package.json package-lock.json
```

実装はMVPフェーズで行います。

## 36. 初期品質チェック

```bash
docker compose config
docker compose ps
docker compose exec --user app app php artisan about
docker compose exec --user app app php artisan migrate:status
docker compose exec --user app app php artisan test
docker compose exec --user app app ./vendor/bin/pint --test
docker compose exec node npm run build
```

すべて成功することを確認します。

## 37. commit例

アプリ雛形です。

```bash
git add .
git status
git commit -m "chore: initialize Laravel Vue application"
git push
```

Docker構成を別commitにする場合です。

```bash
git add compose.yaml docker .dockerignore Makefile .env.example
git commit -m "chore: add Docker development environment"
git push
```

## 38. 基準タグ

初期環境とテストが成功した段階です。

```bash
git tag -a v0.1.0 -m "Initial local development environment"
git push origin v0.1.0
```

任意ですが、アプリ実装前へ戻りやすくなります。

## 39. トラブルシューティング

### Laravel Installerが対話入力できない

`-it`を付け、WSLのUbuntuターミナルから実行します。

### Permission denied

```bash
sudo chown -R "$(id -u):$(id -g)" ~/src/DietPlanner
```

### プロジェクトディレクトリが空でない

一時ディレクトリへ生成し、`rsync`で統合します。

### npm installが失敗する

ComposerコンテナにはNode.jsがありません。Docker構築後に実行します。

```bash
docker compose exec node npm install
```

### APP_KEYがない

```bash
docker compose exec --user app app php artisan key:generate
```

### PostgreSQLドライバがない

```bash
docker compose exec app php -m | grep pdo_pgsql
```

表示されない場合です。

```bash
docker compose build --no-cache app
docker compose up -d
```

### CSSが表示されない

```bash
docker compose ps node
docker compose logs node
```

### 認証画面がない

Vue Starter Kitを選択していない可能性があります。実装開始前なら作り直す方が安全です。

### テストDBの差異

重要なFeature TestはPostgreSQLで動かします。SQLiteだけでは本番との差異を見逃す場合があります。

## 40. 実装前に決めること

- プロフィール項目
- 目標体重と期限
- 同日の体重記録を複数許可するか
- PFC入力を必須にするか
- 消費カロリーを手入力にするか
- 数値精度
- タイムゾーン
- データ削除
- 退会時の削除
- Laravel Policyによる認可

`docs/requirements/`とER図へ記録します。

## 41. 参考資料

- https://laravel.com/docs/13.x/installation
- https://laravel.com/docs/13.x/starter-kits
- https://laravel.com/starter-kits
- https://laravel.com/docs/13.x/vite
- https://laravel.com/docs/13.x/database

## 42. 変更履歴

| バージョン | 日付 | 内容 |
|---|---|---|
| 0.1 | 2026-07-30 | 初版 |
