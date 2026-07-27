# Diet Planner

AWS EC2上で公開する、個人向けのダイエット計画・記録Webアプリケーションです。

体重、食事、運動などを記録し、体重推移や目標達成状況をグラフで確認できるようにします。

本プロジェクトは、アプリケーション開発だけでなく、Docker、AWS、Infrastructure as Code、CI/CD、自動テスト、監視・運用までを一通り学び直すことを目的としています。

---

## 1. プロジェクトの目的

本プロジェクトの目的は、次のとおりです。

### アプリケーションとしての目的

* 日々の体重を記録できる
* 目標体重と期限を設定できる
* 食事や運動を記録できる
* 体重推移をグラフで確認できる
* 目標に対する進捗状況を確認できる
* PCとスマートフォンの両方から利用できる

### 学習としての目的

* WSL2を利用したLinux開発環境を構築する
* Dockerでローカル開発環境を再現可能にする
* GitHubを利用したソースコード管理を行う
* GitHub ActionsでCI/CDを構築する
* TerraformでAWSインフラをコード化する
* EC2上でDockerコンテナを稼働させる
* ステージング環境と本番環境を分離する
* 単体テスト、結合テスト、画面テストを自動化する
* ログ、監視、バックアップ、ロールバックを実装する

---

## 2. 完成イメージ

利用者はWebブラウザからログインし、次の操作を行えます。

1. 身長、現在体重、目標体重、目標期限を登録する
2. 日々の体重を記録する
3. 食事内容や摂取カロリーを記録する
4. 運動内容や消費カロリーを記録する
5. ダッシュボードで体重推移を確認する
6. 目標達成率や必要な減量ペースを確認する

---

## 3. MVPの対象機能

最初のリリースでは、以下の機能を実装します。

### 認証

* ユーザー登録
* ログイン
* ログアウト
* パスワード再設定

### プロフィール・目標

* 身長の登録
* 開始体重の登録
* 目標体重の登録
* 目標期限の登録
* 活動量の登録

### 体重記録

* 体重の登録
* 体脂肪率の登録
* 記録日の指定
* メモの登録
* 記録の編集
* 記録の削除

### 食事記録

* 食事区分の登録
* 摂取カロリーの登録
* タンパク質、脂質、炭水化物の登録
* メモの登録
* 記録の編集・削除

### 運動記録

* 運動種目の登録
* 運動時間の登録
* 消費カロリーの登録
* 運動強度の登録
* 記録の編集・削除

### ダッシュボード

* 現在体重
* 目標体重
* 目標達成率
* 体重推移グラフ
* 7日間移動平均
* 摂取カロリー推移
* 運動による消費カロリー推移
* 記録実施状況

---

## 4. MVPの対象外

以下は最初のリリースには含めません。

* AIによる食事・運動提案
* SNS機能
* 他ユーザーとの体重比較
* Apple Health連携
* Google Fit連携
* 市販食品データベース連携
* バーコード読み取り
* Push通知
* PWA対応
* 有料プラン
* 管理者向け分析画面
* ECSまたはKubernetesでの運用

これらは、MVP公開後の追加機能として検討します。

---

## 5. 技術スタック

### アプリケーション

| 分類      | 技術                        |
| ------- | ------------------------- |
| バックエンド  | Laravel                   |
| フロントエンド | Inertia.js、Vue 3          |
| CSS     | Tailwind CSS              |
| グラフ     | Chart.jsまたはApache ECharts |
| データベース  | PostgreSQL                |
| キャッシュ   | Redis                     |
| Webサーバー | Nginx                     |
| PHP実行環境 | PHP-FPM                   |

### ローカル開発

| 分類       | 技術                  |
| -------- | ------------------- |
| OS環境     | Windows＋WSL2 Ubuntu |
| コンテナ     | Docker Desktop      |
| 複数コンテナ管理 | Docker Compose      |
| ソース管理    | Git、GitHub          |

### AWS

| 分類                     | 技術                                  |
| ---------------------- | ----------------------------------- |
| コンピューティング              | Amazon EC2                          |
| コンテナレジストリ              | Amazon ECR                          |
| データベース                 | Amazon RDS for PostgreSQL           |
| ロードバランサー               | Application Load Balancer           |
| DNS                    | Amazon Route 53                     |
| TLS証明書                 | AWS Certificate Manager             |
| ファイル保存                 | Amazon S3                           |
| 秘密情報管理                 | AWS Systems Manager Parameter Store |
| リモート操作                 | AWS Systems Manager                 |
| ログ・監視                  | Amazon CloudWatch                   |
| Infrastructure as Code | Terraform                           |

### CI/CD・テスト

| 分類            | 技術                    |
| ------------- | --------------------- |
| CI/CD         | GitHub Actions        |
| PHPテスト        | PHPUnitまたはPest        |
| 静的解析          | LarastanまたはPHPStan    |
| PHPコード整形      | Laravel Pint          |
| JavaScriptテスト | Vitest                |
| ブラウザテスト       | Playwright            |
| 視覚回帰テスト       | Playwright Screenshot |

---

## 6. システム構成

```text
利用者
  |
  v
Route 53
  |
  v
Application Load Balancer
  |
  +-- stg.example.com --> Staging EC2
  |
  +-- app.example.com --> Production EC2
                            |
              +-------------+-------------+
              |             |             |
              v             v             v
         RDS PostgreSQL    S3         CloudWatch
```

ステージング環境と本番環境では、EC2、データベース、設定値を分離します。

DockerイメージはAmazon ECRに保存します。

---

## 7. 環境構成

| 環境         | 用途      | URL例                      | デプロイ方法       |
| ---------- | ------- | ------------------------- | ------------ |
| Local      | 開発・デバッグ | `http://localhost`        | 手動           |
| Staging    | 結合・画面確認 | `https://stg.example.com` | `main`更新時に自動 |
| Production | 実利用     | `https://app.example.com` | 承認後に実行       |

### 環境間のデプロイ原則

ステージング環境と本番環境では、同じソースコードから個別にDockerイメージを作成しません。

以下の流れを採用します。

```text
Gitコミット
  ↓
Dockerイメージを1回だけビルド
  ↓
Amazon ECRへ保存
  ↓
ステージングへデプロイ
  ↓
自動テスト
  ↓
手動承認
  ↓
同じDockerイメージを本番へデプロイ
```

Dockerイメージには、GitのコミットSHAをタグとして付与します。

---

## 8. Git運用方針

基本ブランチは`main`とします。

機能開発時は、`main`から作業ブランチを作成します。

```text
main
 └─ feature/weight-record
 └─ feature/dashboard
 └─ fix/login-error
```

基本的な流れは次のとおりです。

1. 作業ブランチを作成する
2. 実装する
3. ローカルでテストする
4. GitHubへpushする
5. Pull Requestを作成する
6. CIが成功していることを確認する
7. `main`へマージする
8. ステージングへ自動デプロイする
9. ステージング試験後に本番へ昇格する

`main`への直接pushは原則行いません。

---

## 9. CI/CD方針

### Pull Request作成時

以下を自動実行します。

* Laravel Pint
* LarastanまたはPHPStan
* ESLint
* PHP単体テスト
* Laravel Featureテスト
* JavaScript単体テスト
* Playwright E2Eテスト
* Dockerイメージのビルド確認

いずれかが失敗した場合、`main`へマージしません。

### `main`マージ時

以下を自動実行します。

1. 本番用Dockerイメージをビルドする
2. GitコミットSHAをタグとして付与する
3. Amazon ECRへpushする
4. ステージングEC2へデプロイする
5. DBマイグレーションを実行する
6. Health Checkを実行する
7. ステージング環境でE2Eテストを実行する

### 本番デプロイ時

以下を実行します。

1. ステージング環境のテスト成功を確認する
2. GitHub Actions上で本番デプロイを承認する
3. ステージングで確認済みのDockerイメージを本番へデプロイする
4. DBマイグレーションを実行する
5. Health Checkを実行する
6. 失敗した場合は直前のDockerイメージへ戻す

---

## 10. テスト方針

### Unit Test

計算ロジックを対象にします。

* BMI計算
* 目標達成率
* 7日間移動平均
* 目標達成予測日
* カロリー集計

### Feature Test

LaravelのHTTP処理とデータベース処理を対象にします。

* ユーザー登録
* ログイン
* 体重記録の登録・更新・削除
* 食事記録の登録・更新・削除
* 運動記録の登録・更新・削除
* 入力バリデーション
* 他ユーザーのデータを操作できないこと

### E2E Test

Playwrightを使って実際のブラウザ操作を確認します。

* ユーザー登録からログインまで
* 目標設定
* 体重記録
* 食事記録
* 運動記録
* ダッシュボードへの反映
* ログアウト

### 視覚回帰テスト

主要画面について、基準画像との差分を確認します。

* ログイン画面
* ダッシュボード
* 体重記録画面
* スマートフォン表示
* PC表示

---

## 11. セキュリティ方針

* AWSルートユーザーにMFAを設定する
* AWSアクセスキーをGitHubへ保存しない
* GitHub ActionsとAWSはOIDCで連携する
* EC2への接続は原則としてAWS Systems Managerを利用する
* EC2のSSHポートをインターネットへ公開しない
* DBをインターネットへ直接公開しない
* 本番環境はHTTPSのみで公開する
* パスワードを平文で保存しない
* ユーザーごとのデータアクセスをPolicyで制御する
* `.env`ファイルをGitへコミットしない
* 秘密情報はParameter StoreまたはSecrets Managerで管理する
* LaravelのCSRF対策を有効にする
* XSS、SQLインジェクション、認可漏れを確認する
* ログへパスワードや秘密情報を出力しない

---

## 12. 公開条件

本番環境を公開済みと判断するためには、以下をすべて満たす必要があります。

### アプリケーション

* [ ] ユーザー登録、ログイン、ログアウトができる
* [ ] 目標体重と期限を登録できる
* [ ] 体重を登録・編集・削除できる
* [ ] 食事を登録・編集・削除できる
* [ ] 運動を登録・編集・削除できる
* [ ] ダッシュボードに記録内容が反映される
* [ ] 他ユーザーのデータを閲覧・更新できない
* [ ] スマートフォンで主要操作ができる

### テスト

* [ ] Unit Testが成功する
* [ ] Feature Testが成功する
* [ ] Playwright E2Eテストが成功する
* [ ] 主要画面の視覚回帰テストが成功する
* [ ] ステージング環境でSmoke Testが成功する

### インフラ

* [ ] TerraformからAWS環境を構築できる
* [ ] ステージング環境と本番環境が分離されている
* [ ] EC2でDockerコンテナが稼働している
* [ ] RDS PostgreSQLへ接続できる
* [ ] HTTPSでアクセスできる
* [ ] 独自ドメインでアクセスできる
* [ ] EC2がAWS Systems Managerで管理できる
* [ ] AWSの秘密情報がソースコードに含まれていない

### CI/CD

* [ ] Pull Request作成時にCIが実行される
* [ ] CI失敗時にマージを防止できる
* [ ] `main`へのマージでステージングへ自動デプロイされる
* [ ] ステージングと本番で同じDockerイメージを使用する
* [ ] 本番デプロイに承認処理がある
* [ ] 直前のDockerイメージへロールバックできる

### 運用

* [ ] LaravelとNginxのログを確認できる
* [ ] CloudWatchでEC2を監視できる
* [ ] エラー発生時に通知される
* [ ] RDSの自動バックアップが設定されている
* [ ] バックアップから復元できることを確認している
* [ ] デプロイ・復旧・ロールバック手順が文書化されている

---

## 13. プロジェクトの完了条件

本プロジェクトは、次の状態になった時点で初期目標達成とします。

1. MVP機能が本番環境で利用できる
2. 独自ドメインからHTTPSでアクセスできる
3. ローカル、ステージング、本番の3環境が存在する
4. Dockerによって各環境の実行方法が標準化されている
5. TerraformによってAWSインフラを再構築できる
6. GitHub Actionsでテストとデプロイが自動化されている
7. ステージングで確認したDockerイメージを本番へ昇格できる
8. 自動テストによって主要機能が保護されている
9. ログ、監視、バックアップ、ロールバックの仕組みがある
10. READMEおよび運用手順を参照すれば、環境の構築と運用方法が分かる

---

## 14. Phase 1の完了条件

企画・要件フェーズは、次の状態になった時点で完了とします。

* [ ] プロジェクトの目的が文章化されている
* [ ] 学習したい技術が一覧化されている
* [ ] MVP機能が決定している
* [ ] MVP対象外の機能が決定している
* [ ] 技術スタックが仮決定している
* [ ] ローカル、ステージング、本番の役割が決定している
* [ ] システム構成の概要が記載されている
* [ ] CI/CDの基本方針が記載されている
* [ ] テスト方針が記載されている
* [ ] 本番公開条件がチェックリスト化されている

---

## 15. ローカル環境の起動方法

詳細な構築手順は、Docker環境作成後に更新します。

```bash
git clone <repository-url>
cd diet-planner

cp .env.example .env

docker compose up -d --build

docker compose exec app composer install
docker compose exec app php artisan key:generate
docker compose exec app php artisan migrate --seed
docker compose exec node npm install
docker compose exec node npm run build
```

ブラウザで以下へアクセスします。

```text
http://localhost
```

---

## 16. テスト実行方法

```bash
docker compose exec app php artisan test
```

```bash
docker compose exec app ./vendor/bin/pint --test
```

```bash
docker compose exec app ./vendor/bin/phpstan analyse
```

```bash
docker compose exec node npm run test
```

```bash
docker compose exec node npx playwright test
```

---

## 17. ドキュメント

詳細な設計・運用ドキュメントは`docs`ディレクトリで管理します。現在の構成は次のとおりです。

```text
docs/
├─ requirements/
│   ├─ functional-requirements.md      機能要件定義書
│   └─ non-functional-requirements.md  非機能要件定義書
├─ architecture.md                     アーキテクチャ設計書
├─ security.md                         セキュリティ設計書
├─ backup-restore.md                   バックアップ・リストア設計書
├─ monitoring.md                       監視設計書
└─ runbook.md                          運用手順書(デプロイ・障害対応・ロールバック含む)
```

実装の進行に合わせて、以下の追加を予定します。

* database-design.md(データベース設計書)
* screen-design.md(画面設計書)

READMEには概要を記載し、詳細な設計や運用手順は`docs`ディレクトリへ分離します。

---

## 18. 現在の進捗

* [x] プロジェクト目的の整理
* [x] 学習目標の整理
* [x] MVP候補の整理
* [x] 技術スタックの仮決定
* [ ] WSL2環境構築
* [ ] Docker開発環境構築
* [ ] Laravelプロジェクト作成
* [ ] MVP機能実装
* [ ] 自動テスト構築
* [ ] AWS環境構築
* [ ] CI/CD構築
* [ ] 本番公開

---

## 19. ライセンス

本プロジェクトは個人学習用です。

公開リポジトリにする場合は、MIT Licenseなどの採用を別途検討します。
