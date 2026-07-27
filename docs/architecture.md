# アーキテクチャ設計書

## 1. 文書の目的

本書は、Diet Plannerのシステム構成と、その構成を選択した理由を定義するものです。

設計にあたっては、[README.md](../README.md)の技術スタック・システム構成と、[非機能要件定義書](./requirements/non-functional-requirements.md)の要件(可用性、性能、セキュリティ、費用上限など)を前提とします。本書中の「AV-01」「SC-08」などのIDは、非機能要件定義書の要件IDを指します。

本プロジェクトは個人開発・学習目的であるため、冗長化や高可用性よりも、構成のシンプルさ、再構築可能性(Infrastructure as Code)、費用上限(月額5,000円目標)を優先します。

---

## 2. 全体構成

### 2.1 システム構成図

```text
利用者(PC・スマートフォン)
  |
  | HTTPS
  v
Route 53(独自ドメイン ※TODO-01)
  |
  v
Application Load Balancer(ACM証明書でTLS終端)
  |
  +-- stg.example.com --> Staging EC2(1台)
  |
  +-- app.example.com --> Production EC2(1台)
                            |
        +-------------------+-------------------+
        |                   |                   |
        v                   v                   v
   RDS PostgreSQL      Amazon S3         CloudWatch
   (Single-AZ)      (将来の添付ファイル用)   (Logs / Metrics / Alarm)

Amazon ECR(Dockerイメージ保存・ステージング/本番共通)
AWS Systems Manager(EC2管理・Parameter Store)
GitHub Actions(CI/CD、OIDCでAWSと連携)
```

### 2.2 環境構成

| 環境 | 構成 | 備考 |
|------|------|------|
| Local | Docker Compose(Nginx、PHP-FPM、PostgreSQL、Redis、Node) | MT-01。本番データはコピーしない(DT-05) |
| Staging | EC2 1台+RDS(ステージング用) | 常時起動の要否は費用試算時に判断(TODO-05、CO-04) |
| Production | EC2 1台+RDS(本番用) | ステージングで検証した同一Dockerイメージをデプロイ |

ステージングと本番は、EC2、RDS、Parameter Storeの設定値をすべて分離します。

### 2.3 初期リリースで採用しない構成

非機能要件定義書「4.3 初期リリースで許容する事項」に基づき、以下は採用しません。

* EC2の複数台構成・Auto Scaling
* RDS Multi-AZ
* マルチリージョン構成
* ECS・Kubernetes(README.md「4. MVPの対象外」)

---

## 3. 技術スタック

- フロントエンド: Inertia.js、Vue 3、Tailwind CSS、Chart.jsまたはApache ECharts
- バックエンド: Laravel(PHP-FPM)、Nginx
- データベース: PostgreSQL(Amazon RDS、Single-AZ)
- キャッシュ・セッション: Redis
- インフラ: Amazon EC2、ECR、RDS、ALB、Route 53、ACM、S3、Systems Manager(Parameter Store含む)、CloudWatch
- IaC: Terraform(MT-02)
- CI/CD: GitHub Actions(MT-06、OIDC連携 SC-13/SC-14)

詳細はREADME.md「5. 技術スタック」を参照します。

---

## 4. コンポーネント設計

### 4.1 EC2内のコンテナ構成

EC2上ではDocker Composeにより、以下のコンテナを稼働させます。

| コンテナ | 役割 |
|----------|------|
| Nginx | リバースプロキシ、静的ファイル配信、アクセスログ出力(LG-02、LG-03) |
| PHP-FPM(Laravel) | アプリケーションロジック、認証・認可、Inertia.jsレスポンス生成 |
| Redis | セッション管理、キャッシュ |

PostgreSQLはコンテナではなくRDSを使用します(ローカル環境のみコンテナで代替)。

### 4.2 AWSマネージドサービス

| サービス | 役割 | 関連要件 |
|----------|------|----------|
| ALB | TLS終端、HTTP→HTTPSリダイレクト、Health Check | SC-06、SC-07、AV-03、PF-04 |
| RDS PostgreSQL | データ永続化、自動バックアップ | BK-01、BK-02 |
| ECR | Dockerイメージ保存。ライフサイクルポリシーで古いイメージを削除 | CO-06 |
| Parameter Store | DB接続情報等の秘密情報管理 | SC-15 |
| Systems Manager | EC2へのリモート接続(SSH非公開) | SC-09、SC-10 |
| CloudWatch | ログ収集(保存期間付き)、メトリクス、アラーム | LG-01〜LG-05、MN-01〜MN-08、CO-05 |
| AWS Budgets | 月額予算の50%・80%・100%で通知 | CO-01、CO-02 |
| S3 | 将来の添付ファイル等の保存(MVP時点では未使用)。バージョニング要否はTODO-04 | BK-03 |

---

## 5. ネットワーク設計

| 項目 | 方針 | 関連要件 |
|------|------|----------|
| VPC | ステージング・本番で共通のVPCを使用し、サブネットで分離する(費用優先。分離方式はTerraform設計時に確定) | CO-01 |
| パブリックサブネット | ALB、EC2を配置 | - |
| プライベートサブネット | RDSを配置し、インターネットへ公開しない | SC-08 |
| Security Group | ALB→EC2、EC2→RDSの最小許可のみ。SSHポートは原則公開しない | SC-08、SC-09 |
| EC2への接続 | Systems Manager Session Managerを使用 | SC-10 |

---

## 6. データフロー

1. 利用者がブラウザからRoute 53経由で独自ドメインへアクセスする
2. ALBがTLSを終端し(HTTPはHTTPSへリダイレクト)、対象環境のEC2へ転送する
3. EC2上のNginxがリクエストを受け、PHP-FPM(Laravel)へ渡す
4. Laravelが認証・認可(自ユーザーのデータのみ操作可能。SC-02〜SC-04)を行い、RDSへ読み書きする。セッション・キャッシュはRedisを使用する
5. LaravelがInertia.js経由でVueコンポーネントへデータを渡し、画面を描画する
6. 各種ログはCloudWatch Logsへ送信し、保存期間(14〜30日)を設定する(LG-01〜LG-05、CO-05)

ダッシュボード表示ではEager Loadingを徹底し、N+1問題を回避します(PF-03、性能試験方針 5.3)。

---

## 7. データベース設計

想定利用規模(登録ユーザー10人以下、記録は1ユーザー1日十数件。非機能要件定義書 5.1)を踏まえ、小規模なRDSインスタンス1台で構成します。

主要テーブルの想定は以下のとおりです。詳細なテーブル定義は実装フェーズで別途データベース設計書として作成します。

- users(ユーザー。収集する個人情報はメールアドレスのみとする。DT-01、DT-02)
- profiles(身長・開始体重・目標体重・目標期限・活動量)
- weight_records(体重記録)
- meal_records(食事記録)
- exercise_records(運動記録)

すべての記録テーブルは`user_id`で所有者を紐づけ、Laravel Policyで他ユーザーのデータへのアクセスを禁止します(SC-03、SC-04)。退会時のデータ削除方針は実装前に決定します(DT-04)。

---

## 8. デプロイ・ロールバック設計

README.md「7. 環境構成」「9. CI/CD方針」に基づきます。

1. GitコミットごとにDockerイメージを1回だけビルドし、コミットSHAタグでECRへ保存する
2. ステージングへデプロイし、マイグレーション・Health Check・E2Eテストを実行する
3. 手動承認後、同一イメージを本番へデプロイする
4. 障害時はECR上の直前イメージタグへ切り替えてロールバックする(AV-05: 30分以内目標)

デプロイ時の短時間停止は許容します(非機能要件定義書 4.3)。

---

## 9. API設計方針

- MVPでは外部公開APIは持たず、Inertia.jsによりLaravelのルーティング・認証機構をそのまま利用する構成とします
- 将来モバイルアプリ等が必要になった場合のREST API追加はMVP対象外とします

---

## 10. 設計上の判断と理由(ADR)

| ID | 決定事項 | 理由 |
|----|----------|------|
| ADR-01 | Inertia.js + Vue 3を採用 | SPA向けAPI設計のコストをかけず、Laravelの認証・認可・バリデーションをそのまま活用できるため |
| ADR-02 | EC2各環境1台構成(冗長化なし) | 可用性目標が月間稼働率99%(AV-01、目標レベル)であり、費用上限(月額5,000円。CO-01)の範囲では冗長化よりシンプルさを優先するため |
| ADR-03 | RDS Single-AZを採用 | Multi-AZは費用が倍増する一方、RPO 24時間・RTO 24時間(7.2)は自動バックアップからの復元で満たせるため |
| ADR-04 | ECS/Kubernetesを使わずEC2+Docker Composeを採用 | 学習目的をEC2でのコンテナ運用に置いており、オーケストレーションはMVP対象外のため |
| ADR-05 | ステージング・本番で同一Dockerイメージを使用 | 環境差異によるデプロイ事故を防ぎ、ステージングでの検証結果を本番でも保証するため |
| ADR-06 | EC2接続はSSM Session Managerのみ | SSHポート非公開(SC-09)と鍵管理の排除を両立できるため |
| ADR-07 | ALBを採用(当面) | ACMによるTLS終端・Health Check・HTTPSリダイレクトを簡潔に実現できるため。ただし費用超過時はALBなし構成への変更を検討する(10.3 費用超過時の対応順序) |
| ADR-08 | セッションストアにRedisを採用 | Laravel標準対応であり、将来EC2を複数台化する場合もセッション共有へ移行しやすいため |

---

## 11. 未決事項

非機能要件定義書「14. 未決事項」と連動します。

| ID | 内容 | 影響範囲 |
|----|------|----------|
| TODO-01 | 独自ドメイン名 | Route 53、ACM証明書 |
| TODO-04 | S3バージョニングの使用 | S3構成 |
| TODO-05 | ステージングの常時起動 | EC2構成、費用 |
| - | VPC・サブネットの分離方式の詳細 | Terraform設計時に確定 |
| - | EC2・RDSのインスタンスサイズ | 費用試算時に確定 |

---

## 12. 変更履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|----------|
| 0.1 | 2026-07-27 | 初版作成 |
| 0.2 | 2026-07-27 | 非機能要件定義書(0.1版)の要件IDと整合するよう全面改訂 |
