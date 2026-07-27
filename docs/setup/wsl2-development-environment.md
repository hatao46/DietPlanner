# WSL2開発環境構築手順

## 1. この文書の目的

本書は、Diet Plannerプロジェクトのローカル開発環境として、Windows上にWSL2とUbuntuを導入し、Docker Desktopと連携する手順を記録するものです。

開発端末を変更した場合や、環境を再構築する場合でも、同じ手順で開発環境を再現できる状態を目指します。

---

## 2. 対象環境

本書では、次の環境を前提とします。

| 項目 | 前提 |
|---|---|
| ホストOS | Windows 11 |
| Linux環境 | WSL2 |
| Linuxディストリビューション | Ubuntu |
| コンテナ実行環境 | Docker Desktop |
| ソースコード管理 | Git / GitHub |
| ターミナル | Windows TerminalまたはPowerShell |

> Windows 10を使用する場合は、WSL2およびDocker Desktopのシステム要件を別途確認してください。

---

## 3. このステップの学習目標

このステップでは、次の内容を理解することを目標とします。

- Windows上でLinux環境を動作させる仕組みを理解する
- WSL1とWSL2の違いを理解する
- Ubuntuの基本的なコマンド操作を行える
- WindowsとWSLのファイルシステムの違いを理解する
- Docker DesktopとWSL2の連携方法を理解する
- Gitを使ってGitHubリポジトリを操作できる
- ローカル開発用の作業ディレクトリを適切な場所に作成できる

---

## 4. 完了条件

以下をすべて満たした時点で、このステップを完了とします。

- [ ] WSL2が有効になっている
- [ ] Ubuntuがインストールされている
- [ ] UbuntuがWSL2として動作している
- [ ] Ubuntuのパッケージ更新が完了している
- [ ] Gitが使用できる
- [ ] Docker Desktopがインストールされている
- [ ] Docker DesktopとUbuntuが連携している
- [ ] WSL内で`docker version`を実行できる
- [ ] WSL内で`docker compose version`を実行できる
- [ ] Linux側に開発用ディレクトリを作成している
- [ ] GitHubとのSSH接続またはHTTPS接続ができる

---

## 5. WSL2とUbuntuのインストール

### 5.1 PowerShellを管理者権限で起動する

Windowsのスタートメニューで`PowerShell`を検索し、右クリックして「管理者として実行」を選択します。

### 5.2 Ubuntuをインストールする

PowerShellで次のコマンドを実行します。

```powershell
wsl --install -d Ubuntu
```

yutah/yutah

コマンド実行後に再起動を求められた場合は、Windowsを再起動します。

### 5.3 WSLの状態を確認する

再起動後、PowerShellで次のコマンドを実行します。

```powershell
wsl --list --verbose
```

短縮形でも実行できます。

```powershell
wsl -l -v
```

次のように、Ubuntuの`VERSION`が`2`になっていることを確認します。

```text
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

### 5.4 WSLの既定バージョンを2に設定する

必要に応じて、次のコマンドを実行します。

```powershell
wsl --set-default-version 2
```

UbuntuがWSL1になっている場合は、次のコマンドでWSL2へ変換します。

```powershell
wsl --set-version Ubuntu 2
```

---

## 6. Ubuntuの初期設定

### 6.1 Ubuntuを起動する

WindowsのスタートメニューからUbuntuを起動します。

初回起動時に、Linux側のユーザー名とパスワードを設定します。

このユーザー名とパスワードはWindowsのアカウントとは別のものです。

### 6.2 パッケージ一覧を更新する

Ubuntuで次のコマンドを実行します。

```bash
sudo apt update
```

### 6.3 インストール済みパッケージを更新する

```bash
sudo apt upgrade -y
```

### 6.4 基本ツールをインストールする

```bash
sudo apt install -y \
  git \
  curl \
  unzip \
  zip \
  make \
  ca-certificates \
  gnupg \
  lsb-release
```

### 6.5 バージョンを確認する

```bash
git --version
curl --version
make --version
```

2026/07/28 実施記録
```bash
yutah@hatao-pc:~$ git --version
git version 2.53.0
yutah@hatao-pc:~$ curl --version
curl 8.18.0 (x86_64-pc-linux-gnu) libcurl/8.18.0 OpenSSL/3.5.5 zlib/1.3.1 brotli/1.2.0 zstd/1.5.7 libidn2/2.3.8 libpsl/0.21.2 libssh2/1.11.1 nghttp2/1.68.0 librtmp/2.3 mit-krb5/1.22.1 OpenLDAP/2.6.10
Release-Date: 2026-01-07, security patched: 8.18.0-1ubuntu2.3
Protocols: dict file ftp ftps gopher gophers http https imap imaps ipfs ipns ldap ldaps mqtt pop3 pop3s rtmp rtsp scp sftp smb smbs smtp smtps telnet tftp ws wss
Features: alt-svc AsynchDNS brotli GSS-API HSTS HTTP2 HTTPS-proxy IDN IPv6 Kerberos Largefile libz NTLM PSL SPNEGO SSL threadsafe TLS-SRP UnixSockets zstd
yutah@hatao-pc:~$ make --version
GNU Make 4.4.1
Built for x86_64-pc-linux-gnu
Copyright (C) 1988-2023 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
yutah@hatao-pc:~$
```

---

## 7. WSLのファイル配置方針

ソースコードは、Windows側の`C:\`配下ではなく、WSLのLinuxファイルシステム内に配置します。

### 推奨する配置

```text
/home/<Linuxユーザー名>/src/diet-planner
```

例：

```bash
mkdir -p ~/src
cd ~/src
```

### 推奨しない配置

```text
/mnt/c/Users/<Windowsユーザー名>/Documents/diet-planner
```

`/mnt/c`配下でも開発は可能ですが、次の問題が発生する可能性があります。

- ファイルアクセスが遅くなる
- LinuxとWindowsでファイル権限の扱いが異なる
- 大量の依存ファイルを扱う処理が遅くなる
- Dockerのボリュームマウントが遅くなる
- 大文字・小文字の扱いで差異が発生する

Laravelの`vendor`やNode.jsの`node_modules`には多数のファイルが含まれるため、Linux側へ配置する方が適しています。

---

## 8. Gitの初期設定

### 8.1 ユーザー名を設定する

```bash
git config --global user.name "GitHubで使用する名前"
```

例：

```bash
git config --global user.name "Yuta"
```

### 8.2 メールアドレスを設定する

```bash
git config --global user.email "GitHubで使用するメールアドレス"
```

### 8.3 設定内容を確認する

```bash
git config --global --list
```

### 8.4 改行コードを設定する

WSL上では、Gitが改行コードを自動的にCRLFへ変換しない設定を推奨します。

```bash
git config --global core.autocrlf input
```

### 8.5 デフォルトブランチ名を設定する

```bash
git config --global init.defaultBranch main
```

---

## 9. GitHubとのSSH接続設定

GitHubへの接続はHTTPSでも可能ですが、本プロジェクトではSSH接続を推奨します。

### 9.1 SSH鍵を作成する

```bash
ssh-keygen -t ed25519 -C "GitHubで使用するメールアドレス"
```

保存先を変更しない場合は、Enterキーを押します。

```text
/home/<ユーザー名>/.ssh/id_ed25519
```

パスフレーズは任意ですが、設定することを推奨します。

### 9.2 SSH Agentを起動する

```bash
eval "$(ssh-agent -s)"
```

### 9.3 SSH鍵を登録する

```bash
ssh-add ~/.ssh/id_ed25519
```

### 9.4 公開鍵を表示する

```bash
cat ~/.ssh/id_ed25519.pub
```

表示された内容をコピーし、GitHubの以下の画面へ登録します。

```text
GitHub
  └ Settings
      └ SSH and GPG keys
          └ New SSH key
```

### 9.5 接続を確認する

```bash
ssh -T git@github.com
```

初回接続時に確認を求められた場合は、接続先を確認したうえで`yes`を入力します。

接続に成功すると、GitHubのユーザー名を含むメッセージが表示されます。

---

## 10. Docker Desktopのインストール

### 10.1 Docker Desktopをインストールする

WindowsへDocker Desktopをインストールします。

インストール時または初回起動時に、WSL2 backendを使用する設定を有効にします。

### 10.2 WSL2 backendを確認する

Docker Desktopで次の画面を開きます。

```text
Settings
  └ General
      └ Use the WSL 2 based engine
```

`Use the WSL 2 based engine`が有効になっていることを確認します。

### 10.3 Ubuntuとの連携を有効にする

Docker Desktopで次の画面を開きます。

```text
Settings
  └ Resources
      └ WSL Integration
```

次を有効にします。

- `Enable integration with my default WSL distro`
- `Ubuntu`

設定を変更した場合は、`Apply & restart`を実行します。

---

## 11. WSL内でDockerの動作を確認する

Ubuntuを起動し、次のコマンドを実行します。

### 11.1 Dockerのバージョン確認

```bash
docker version
```

ClientとServerの両方が表示されることを確認します。

### 11.2 Docker Composeのバージョン確認

```bash
docker compose version
```

### 11.3 テスト用コンテナを起動する

```bash
docker run --rm hello-world
```

`Hello from Docker!`が表示されれば、Docker DesktopとWSL2の連携は成功しています。

### 11.4 コンテナ一覧を確認する

```bash
docker ps
```

エラーが表示されなければ問題ありません。

---

## 12. 開発用ディレクトリの作成

Ubuntuで次のコマンドを実行します。

```bash
mkdir -p ~/src
cd ~/src
```

現在のディレクトリを確認します。

```bash
pwd
```

次のようなパスが表示されることを確認します。

```text
/home/<Linuxユーザー名>/src
```

このディレクトリ配下に、Diet Plannerのリポジトリを作成またはcloneします。

```bash
cd ~/src
git clone git@github.com:<GitHubユーザー名>/<リポジトリ名>.git
```

リポジトリをまだ作成していない場合は、次のステップで作成します。

---

## 13. WindowsからWSLのファイルを開く

### 13.1 エクスプローラーから開く

エクスプローラーのアドレスバーへ、次を入力します。

```text
\\wsl$
```

Ubuntuのホームディレクトリは、次のような場所から参照できます。

```text
\\wsl$\Ubuntu\home\<Linuxユーザー名>
```

### 13.2 WSLから現在の場所を開く

Ubuntuで次のコマンドを実行します。

```bash
explorer.exe .
```

現在のディレクトリがWindowsのエクスプローラーで開きます。

---

## 14. Visual Studio Codeとの連携

Visual Studio Codeを使用する場合は、WSL拡張機能をインストールします。

### 14.1 VS CodeでWSLディレクトリを開く

Ubuntuでプロジェクトディレクトリへ移動します。

```bash
cd ~/src/diet-planner
```

次のコマンドを実行します。

```bash
code .
```

VS Codeの画面左下に、WSL接続中であることが表示されることを確認します。

例：

```text
WSL: Ubuntu
```

VS CodeをWindows側として開いた状態で、`\\wsl$`経由のフォルダを直接編集するのではなく、WSL拡張機能を使用して開くことを推奨します。

---

## 15. 動作確認チェックリスト

### WSL2

```bash
uname -a
```

```powershell
wsl -l -v
```

確認事項：

- Ubuntuが表示される
- VERSIONが2になっている

### Git

```bash
git --version
git config --global --list
```

確認事項：

- Gitのバージョンが表示される
- ユーザー名とメールアドレスが設定されている

### GitHub

```bash
ssh -T git@github.com
```

確認事項：

- GitHubへの認証成功メッセージが表示される

### Docker

```bash
docker version
docker compose version
docker run --rm hello-world
```

確認事項：

- Docker ClientとServerが表示される
- Docker Composeのバージョンが表示される
- `Hello from Docker!`が表示される

### 作業ディレクトリ

```bash
cd ~/src
pwd
```

確認事項：

- `/home/<Linuxユーザー名>/src`が表示される

---

## 16. よくある問題

### 16.1 `docker: command not found`と表示される

確認事項：

1. Docker Desktopが起動しているか
2. Docker DesktopでWSL2 backendが有効か
3. Docker DesktopのWSL IntegrationでUbuntuが有効か
4. Ubuntuを再起動したか

WSLを再起動する場合は、PowerShellで次を実行します。

```powershell
wsl --shutdown
```

その後、UbuntuとDocker Desktopを起動し直します。

### 16.2 Docker daemonへ接続できない

次のようなエラーが表示される場合があります。

```text
Cannot connect to the Docker daemon
```

Docker Desktopが起動していることを確認します。

続いて、PowerShellでWSLを停止します。

```powershell
wsl --shutdown
```

Docker Desktopを再起動し、Ubuntuから再度確認します。

```bash
docker version
```

### 16.3 UbuntuがWSL1になっている

PowerShellで確認します。

```powershell
wsl -l -v
```

UbuntuのVERSIONが1の場合は、次を実行します。

```powershell
wsl --set-version Ubuntu 2
```

### 16.4 GitHubへのSSH接続に失敗する

SSH鍵が登録されているか確認します。

```bash
ssh-add -l
```

鍵が表示されない場合は、次を実行します。

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

詳細ログを確認する場合は、次を実行します。

```bash
ssh -vT git@github.com
```

### 16.5 ファイル操作やDockerが遅い

プロジェクトが`/mnt/c`配下に配置されていないか確認します。

```bash
pwd
```

次のようなパスの場合は、Linux側への移動を検討します。

```text
/mnt/c/Users/...
```

推奨するパスは次のとおりです。

```text
/home/<Linuxユーザー名>/src/...
```

### 16.6 `code`コマンドが使用できない

Visual Studio CodeとWSL拡張機能がインストールされていることを確認します。

一度Visual Studio CodeをWindows側で起動し、コマンドパレットから次を実行します。

```text
WSL: Connect to WSL
```

その後、Ubuntuで再度実行します。

```bash
code .
```

---

## 17. セキュリティ上の注意

- SSH秘密鍵をGitへコミットしない
- `.ssh`ディレクトリを共有フォルダへコピーしない
- GitHubのアクセストークンをソースコードへ記載しない
- Dockerコンテナへ不要な特権を付与しない
- 不明なコマンドを`sudo`で実行しない
- Ubuntu、Docker Desktop、Gitを定期的に更新する
- 会社の端末を使用する場合は、社内のセキュリティルールを確認する

---

## 18. このステップで作成されるもの

このステップの完了時点で、次が準備されます。

```text
Windows
├─ WSL2
│  └─ Ubuntu
│     ├─ Git
│     ├─ SSH設定
│     └─ ~/src
│
├─ Docker Desktop
│  └─ UbuntuとのWSL Integration
│
└─ Visual Studio Code
   └─ WSL拡張機能
```

Laravel、PHP、PostgreSQL、Redisなどは、原則として次のDocker開発環境構築ステップでコンテナとして用意します。

ホスト側のUbuntuへ直接PHPやPostgreSQLをインストールしない方針とします。

---

## 19. 次のステップ

WSL2開発環境の構築が完了したら、次の作業へ進みます。

1. GitHubリポジトリの作成
2. Laravelプロジェクトの作成
3. Dockerfileの作成
4. Docker Composeによる開発環境の構築
5. Nginx、PHP-FPM、PostgreSQL、Redisの起動確認

---

## 20. 変更履歴

| バージョン | 日付 | 変更内容 |
|---|---|---|
| 0.1 | 2026-07-28 | 初版作成 |
