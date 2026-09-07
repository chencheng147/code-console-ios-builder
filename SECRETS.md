# GitHub 公仓 iOS Builder — Secrets 准备清单

在把 `ci/github-ios-builder/` 推成 Public 仓之后，到该仓：

```text
Settings → Secrets and variables → Actions → New repository secret
```

按下面逐项添加。**不要把真实值写进仓库、Issue、聊天记录或截图。**

## 必填 Secrets

| Name | 从哪里拿 | 注意 |
|------|----------|------|
| `SOURCE_REPO_URL` | 私有源码 HTTPS 地址 | 例：`https://gitee.com/superchenxiaodi/code-console.git` |
| `SOURCE_REPO_TOKEN` | Gitee「私人令牌」或 GitHub PAT | **只读**即可；权限最小化；可随时吊销 |
| `EXPO_TOKEN` | https://expo.dev/settings/access-tokens | 能访问 `@15536085723/codeconsole` 的 token |
| `ASC_API_KEY_P8` | `AuthKey_KV696W6V28.p8` 文件全文 | 含 `-----BEGIN PRIVATE KEY-----` 整段；本机常见路径 `D:\apple\AuthKey_KV696W6V28.p8` |
| `ASC_API_KEY_ID` | App Store Connect API Key ID | 当前项目：`KV696W6V28` |
| `ASC_API_KEY_ISSUER_ID` | App Store Connect Issuer ID | 当前项目：`ae9a72e2-1fce-4ca3-9591-bd1e0d76a2fe` |

## 本机快速检查（不打印密钥内容）

在 PowerShell 里：

```powershell
# 1) .p8 是否存在
Test-Path -LiteralPath 'D:\apple\AuthKey_KV696W6V28.p8'

# 2) 只看长度，不 echo 内容
(Get-Item -LiteralPath 'D:\apple\AuthKey_KV696W6V28.p8').Length

# 3) Expo 是否已登录（生成 EXPO_TOKEN 前可先确认账号）
cd C:\code\code-console\mobile-app
npx.cmd --yes eas-cli@20.5.1 whoami --non-interactive
```

## 用 gh 写入 Secrets（公仓创建并登录后）

把下面里的 `OWNER/REPO` 换成公仓名，在**本机**执行（会读取本地 `.p8`，不会提交进 git）：

```powershell
$BuilderRepo = 'OWNER/code-console-ios-builder'   # 改成你的公仓
$SourceRepoUrl = 'https://gitee.com/superchenxiaodi/code-console.git'
$SourceToken = Read-Host 'SOURCE_REPO_TOKEN'
$ExpoToken = Read-Host 'EXPO_TOKEN'

gh secret set SOURCE_REPO_URL -R $BuilderRepo -b $SourceRepoUrl
gh secret set SOURCE_REPO_TOKEN -R $BuilderRepo -b $SourceToken
gh secret set EXPO_TOKEN -R $BuilderRepo -b $ExpoToken
gh secret set ASC_API_KEY_ID -R $BuilderRepo -b 'KV696W6V28'
gh secret set ASC_API_KEY_ISSUER_ID -R $BuilderRepo -b 'ae9a72e2-1fce-4ca3-9591-bd1e0d76a2fe'
gh secret set ASC_API_KEY_P8 -R $BuilderRepo < 'D:\apple\AuthKey_KV696W6V28.p8'
```

## 触发第一次构建

1. 打开公仓 → Actions → `iOS TestFlight (public free builder)` → Run workflow  
2. `source_ref` 默认 `main`（确认私有仓该分支已包含要用的 mobile-app 代码）  
3. 等 macOS job 结束（常见 30–90+ 分钟，可能排队）  
4. 到 App Store Connect 查新 build 是否进入 TestFlight

## 安全提醒

```text
公仓日志对外可见：避免在 workflow 里 echo token / .p8
SOURCE_REPO_TOKEN 权限保持只读，定期轮换
构建机工作区会短暂出现私有源码；不要 upload-artifact 整个 source 目录
```
