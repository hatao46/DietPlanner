# GitHubリポジトリ構築・運用設定手順

## 1. 目的

Diet PlannerプロジェクトをGitHubで安全に管理するため、以下を設定します。

- GitHubリポジトリ
- SSH認証
- ローカルGit
- 初回push
- `.gitignore`と改行コード
- ブランチとPull Requestの運用
- mainブランチの保護
- 秘密情報の混入防止
- SSHエラーの切り分け

## 2. 前提

- WSL2とUbuntuの構築が完了している
- `~/src/DietPlanner`にプロジェクトがある
- GitHubアカウントを作成済み
- WSL内にGitをインストール済み

推奨する順序です。

1. `wsl2-development-environment.md`
2. `local-application-setup.md`
3. 本書
4. `docker-development-environment.md`

## 3. 学習目標

- GitとGitHubの違いを理解する
- ローカルとリモートの関係を理解する
- commit、push、pull、fetchを使い分ける
- SSH公開鍵認証を理解する
- ブランチとPull Requestを使う
- mainブランチを保護する
- 秘密情報をGit履歴へ入れない
- Windows GitとWSL Gitの違いを把握する

## 4. 完了条件

- [ ] GitHubにPrivateリポジトリがある
- [ ] WSLからGitHubへSSH認証できる
- [ ] Gitユーザー名とメールアドレスが設定されている
- [ ] `main`ブランチがある
- [ ] `origin`が登録されている
- [ ] 初回commitとpushが成功する
- [ ] `.env`が無視されている
- [ ] `.gitattributes`がある
- [ ] featureブランチを作成できる
- [ ] Pull Requestを作成できる
- [ ] mainへの直接pushを避ける運用が決まっている

## 5. 使用中のGitとSSHを確認する

WSLで実行します。

```bash
which git
which ssh
git --version
echo "$HOME"
pwd
```

想定例です。

```text
/usr/bin/git
/usr/bin/ssh
/home/<Linuxユーザー名>
/home/<Linuxユーザー名>/src/DietPlanner
```

### WindowsとWSLの違い

| 実行環境 | SSH設定 |
|---|---|
| WSL Git | `/home/<ユーザー名>/.ssh` |
| Windows Git | `C:\Users\<ユーザー名>\.ssh` |
| VS CodeをWSL接続で開く | 通常はWSL側 |
| VS CodeをWindowsフォルダで開く | 通常はWindows側 |

本プロジェクトでは、WSL内のプロジェクトを`code .`で開き、WSL側のGitとSSHを使用します。

## 6. Git基本設定

```bash
git config --global user.name "GitHubで使用する表示名"
git config --global user.email "GitHubに登録したメールアドレス"
git config --global init.defaultBranch main
git config --global core.autocrlf input
```

確認します。

```bash
git config --global --list
git config --list --show-origin
```

GitHubのメールアドレスを公開したくない場合は、GitHubのEmail設定に表示される`noreply`アドレスを利用できます。

## 7. SSH鍵を確認する

```bash
ls -al ~/.ssh
```

以下があれば、既存鍵を利用できます。

```text
id_ed25519
id_ed25519.pub
```

- `id_ed25519`は秘密鍵
- `id_ed25519.pub`は公開鍵

秘密鍵をGitHubやリポジトリへ登録してはいけません。

## 8. SSH鍵を作成する

鍵がない場合です。

```bash
ssh-keygen -t ed25519 -C "GitHubに登録したメールアドレス"
```

通常は保存先を変更せずEnterを押します。

```text
/home/<Linuxユーザー名>/.ssh/id_ed25519
```

パスフレーズを設定し、パスワードマネージャーで管理します。

パスフレーズを`docs`や`.env`へ平文保存しません。

## 9. SSH Agentへ登録する

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh-add -l
```

パスフレーズを設定している場合は入力します。

## 10. GitHubへ公開鍵を登録する

公開鍵を表示します。

```bash
cat ~/.ssh/id_ed25519.pub
```

GitHubでは、リポジトリのSettingsではなく、個人アカウントのSettingsを開きます。

```text
GitHub右上のプロフィール画像
  └ Settings
      └ Access
          └ SSH and GPG keys
              └ New SSH key
```

| 項目 | 例 |
|---|---|
| Title | `WSL2 Ubuntu - 自宅PC` |
| Key type | `Authentication Key` |
| Key | 公開鍵の1行全体 |

`Add SSH key`を押します。

## 11. GitHubのホスト鍵を確認する

初回接続です。

```bash
ssh -T git@github.com
```

次のような確認が表示されます。

```text
The authenticity of host 'github.com' can't be established.
ED25519 key fingerprint is SHA256:...
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

表示されたフィンガープリントをGitHub公式値と照合します。

```text
https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
```

一致を確認した場合だけ`yes`を入力します。

## 12. SSH接続テスト

```bash
ssh -T git@github.com
```

成功例です。

```text
Hi <GitHubユーザー名>! You've successfully authenticated, but GitHub does not provide shell access.
```

これは認証成功です。

## 13. GitHubリポジトリを作成する

GitHub右上の`+`から`New repository`を選びます。

| 項目 | 推奨値 |
|---|---|
| Owner | 自分のアカウント |
| Repository name | `DietPlanner` |
| Description | `AWS EC2で公開するダイエット計画Webアプリ` |
| Visibility | `Private` |
| Add a README file | チェックしない |
| Add .gitignore | 選択しない |
| License | `None` |

ローカルにプロジェクトがあるため、GitHub側では初期ファイルを作成しない方が履歴競合を避けやすくなります。

## 14. ローカルリポジトリを初期化する

```bash
cd ~/src/DietPlanner
git init
git branch -M main
git status
```

Laravel Installerが既にGitを初期化している場合、`git init`は再初期化になるだけです。

## 15. `.gitignore`を確認する

プロジェクト直下に作成します。

最低限、次を無視します。

```gitignore
/.phpunit.cache
/node_modules
/public/build
/public/hot
/public/storage
/storage/*.key
/vendor
.env
.env.backup
.env.production
.phpunit.result.cache
auth.json
npm-debug.log
yarn-error.log
/.idea
/.vscode
```

`.env`の確認です。

```bash
git check-ignore -v .env
```

`.gitignore`は暗号化機能ではありません。すでにcommitしたファイルを履歴から消す機能もありません。

## 16. `.gitattributes`

プロジェクト直下へ作成します。

```gitattributes
* text=auto eol=lf

*.bat text eol=crlf
*.cmd text eol=crlf
*.ps1 text eol=crlf

*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.pdf binary
*.zip binary
```

WSL/Linuxで扱うソースはLFへ統一します。

## 17. 秘密情報を確認する

```bash
git status --short
```

次が追加対象にないことを確認します。

```text
.env
*.pem
*.key
id_ed25519
AWS認証情報
本番DBパスワード
個人用パスフレーズメモ
```

簡易検索です。

```bash
grep -RIn \
  --exclude-dir=.git \
  --exclude-dir=vendor \
  --exclude-dir=node_modules \
  -E 'AWS_SECRET_ACCESS_KEY|BEGIN OPENSSH PRIVATE KEY|DB_PASSWORD=' \
  .
```

`.env.example`の例示値は構いませんが、本番値は記載しません。

## 18. 初回commit

```bash
git add .
git status
git diff --cached
git commit -m "chore: initialize Laravel project"
git log --oneline --decorate -5
```

## 19. リモートを登録する

SSH URLの例です。

```text
git@github.com:<GitHubユーザー名>/DietPlanner.git
```

```bash
git remote add origin \
  git@github.com:<GitHubユーザー名>/DietPlanner.git
git remote -v
```

すでに`origin`がある場合です。

```bash
git remote set-url origin \
  git@github.com:<GitHubユーザー名>/DietPlanner.git
```

## 20. 初回push

```bash
git push -u origin main
```

以降は次でpushできます。

```bash
git push
```

## 21. GitHub上の確認

- ソースコードが表示される
- READMEと`docs/setup`がある
- `.env`が表示されない
- commit履歴がある
- mainが既定ブランチになっている

## 22. ブランチ運用

軽量なmain中心の運用にします。

```text
main
├─ feature/weight-record
├─ feature/dashboard
├─ fix/login-validation
├─ docs/docker-setup
└─ chore/update-dependencies
```

| 種類 | 例 |
|---|---|
| 機能 | `feature/weight-record` |
| 修正 | `fix/login-validation` |
| 文書 | `docs/docker-setup` |
| 設定 | `chore/docker-compose` |
| テスト | `test/goal-service` |
| 改善 | `refactor/daily-summary` |

## 23. 作業ブランチ

```bash
git switch main
git pull --ff-only
git switch -c docs/docker-setup
git branch --show-current
```

## 24. 日常のcommit

```bash
git status
git diff
git add <対象ファイル>
git diff --cached
git commit -m "docs: add Docker development setup guide"
git push -u origin docs/docker-setup
```

可能な範囲で`git add .`ではなく対象を明示します。

## 25. commitメッセージ

```text
<type>: <概要>
```

例です。

```text
feat: add weight record form
fix: prevent access to another user's record
test: add goal calculation tests
docs: add Docker setup guide
chore: update dependencies
refactor: extract daily summary service
ci: add pull request checks
```

## 26. Pull Request

PR本文例です。

```markdown
## 変更内容

- Docker Compose構成を追加
- PHP-FPM、Nginx、PostgreSQL、Redisを追加
- 環境構築手順を追加

## 確認方法

1. `docker compose up -d --build`
2. `docker compose ps`
3. `http://localhost:8080`を確認
4. `php artisan test`を実行

## チェック

- [ ] 秘密情報を含んでいない
- [ ] ローカルテスト済み
- [ ] ドキュメント更新済み
```

## 27. mainブランチ保護

GitHubで次を開きます。

```text
Repository
  └ Settings
      └ Rules
          └ Rulesets
              └ New ruleset
                  └ New branch ruleset
```

推奨設定です。

| 設定 | 推奨 |
|---|---|
| Ruleset name | `protect-main` |
| Enforcement | `Active` |
| Target | Default branch |
| Restrict deletions | 有効 |
| Block force pushes | 有効 |
| Require pull request | 有効 |
| Require status checks | CI構築後に有効 |
| Require conversation resolution | 有効 |
| Linear history | 任意 |

一人開発では、承認者1名を必須にするとマージできない場合があります。

最初は次を推奨します。

- PR経由を必須
- Review approvalは必須にしない
- CI成功を必須
- Force push禁止
- ブランチ削除禁止

PrivateリポジトリのRuleset機能はGitHubプランにより利用範囲が異なる場合があります。

## 28. Merge方式

`Squash and merge`を基本にします。

```text
Settings
  └ General
      └ Pull Requests
```

推奨設定です。

- Allow squash merging：有効
- Allow merge commits：無効または必要時のみ
- Allow rebase merging：任意
- Automatically delete head branches：有効

## 29. Issue管理

Issue例です。

```markdown
## 概要

体重記録の登録・編集・削除機能を実装する。

## 完了条件

- [ ] 体重を登録できる
- [ ] 日付重複の方針が実装されている
- [ ] 本人以外は変更できない
- [ ] Validationがある
- [ ] Feature Testがある
- [ ] 画面から操作できる
```

## 30. `Host key verification failed`

エラー例です。

```text
Host key verification failed.
fatal: Could not read from remote repository.
```

主な原因です。

1. GitHubのホスト鍵を未登録
2. `known_hosts`に古い鍵がある
3. Windows GitとWSL Gitで別設定を参照
4. VS Codeが想定外のGitを使用
5. プロキシや社内ネットワークの影響
6. リモートURLが誤っている

## 31. SSHエラー時の環境確認

```bash
which git
which ssh
git remote -v
echo "$HOME"
git config --show-origin --get core.sshCommand
```

VS Codeのターミナルでも同じ結果になるか確認します。

## 32. SSH詳細ログ

```bash
ssh -vT git@github.com
```

確認する内容です。

- どの`known_hosts`を読むか
- どの秘密鍵を試すか
- ホスト鍵で失敗しているか
- 公開鍵認証で失敗しているか

| エラー | 意味 |
|---|---|
| `Host key verification failed` | GitHubサーバー自体の確認に失敗 |
| `Permission denied (publickey)` | 自分の公開鍵認証に失敗 |

## 33. `known_hosts`確認

```bash
ssh-keygen -F github.com
ls -l ~/.ssh/known_hosts
```

初回でファイルが存在しない場合は正常です。

## 34. 古いホスト鍵を削除する

GitHub公式フィンガープリントを確認し、古い登録が原因と判断した場合だけ実施します。

```bash
cp ~/.ssh/known_hosts \
  ~/.ssh/known_hosts.backup.$(date +%Y%m%d%H%M%S)
ssh-keygen -R github.com
ssh -T git@github.com
```

再表示されたフィンガープリントを公式値と照合してから受け入れます。

次は設定しません。

```sshconfig
StrictHostKeyChecking no
```

ホスト確認を無効化するため危険です。

## 35. SSH鍵を明示する

複数鍵がある場合、`~/.ssh/config`へ設定します。

```sshconfig
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

権限を設定します。

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
ssh -T git@github.com
```

## 36. リモートURL確認

```bash
git remote -v
```

SSH形式です。

```text
git@github.com:<GitHubユーザー名>/DietPlanner.git
```

HTTPSからSSHへ変更します。

```bash
git remote set-url origin \
  git@github.com:<GitHubユーザー名>/DietPlanner.git
```

## 37. 秘密情報をcommitした場合

まだpushしていない直前commitの場合です。

```bash
git rm --cached .env
echo ".env" >> .gitignore
git add .gitignore
git commit --amend
```

GitHubへpush済みの場合は、次を実施します。

1. 秘密情報を即時失効・再発行
2. Git履歴から削除
3. GitHubの警告を確認
4. 影響範囲を調査

履歴削除だけでは安全になりません。必ず認証情報をローテーションします。

## 38. 日常フロー

```bash
git switch main
git pull --ff-only
git switch -c feature/example

# 実装・テスト

git status
git add <対象ファイル>
git commit -m "feat: add example feature"
git push -u origin feature/example
```

GitHubでPRを作成し、CI成功後にSquash Mergeします。

```bash
git switch main
git pull --ff-only
git branch -d feature/example
git fetch --prune
```

## 39. 参考資料

- https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository
- https://docs.github.com/en/authentication/connecting-to-github-with-ssh
- https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection
- https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
- https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository

## 40. 変更履歴

| バージョン | 日付 | 内容 |
|---|---|---|
| 0.1 | 2026-07-30 | 初版 |
