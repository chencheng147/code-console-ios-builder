# GitHub 公仓 iOS 免费构建机（不含业务源码）

把本目录单独推到一个 **GitHub Public** 仓库。仓库里只保留 Actions 脚本，不放 `mobile-app` 业务代码。

Secrets 清单见 `SECRETS.md`。一键建仓脚本见 `publish-public-builder.ps1`。

构建时由 Actions 用只读 token 拉取私有源码仓（Gitee / GitHub Private 均可），在 `macos-14` 上执行：

```text
eas build --platform ios --profile production --local
eas submit --path <ipa>
```

这样：

- 不消耗 Expo EAS Build 云构建次数
- 公有仓库的 GitHub Actions 分钟当前通常不计费（见下方边界）
- 业务源码仍留在私有仓

## 1. 创建公仓

推荐用脚本一键发布（会打开浏览器登录 GitHub，并可交互写入 Secrets）：

```powershell
cd C:\code\code-console\ci\github-ios-builder
powershell -ExecutionPolicy Bypass -File .\publish-public-builder.ps1
```

只建仓、稍后配 Secrets：

```powershell
powershell -ExecutionPolicy Bypass -File .\publish-public-builder.ps1 -SkipSecrets
```

手动方式：

```powershell
cd ci\github-ios-builder
git init
git add .
git commit -m "Add public iOS builder workflow"
# 需已安装并登录 gh
gh repo create code-console-ios-builder --public --source . --remote origin --push
```

## 2. 配置 Secrets

完整清单见同目录 `SECRETS.md`。

在公仓 Settings → Secrets and variables → Actions 中添加：

| Secret | 说明 |
|--------|------|
| `SOURCE_REPO_URL` | 私有源码 HTTPS 地址，例如 `https://gitee.com/superchenxiaodi/code-console.git` |
| `SOURCE_REPO_TOKEN` | 私有仓只读访问令牌（Gitee 私人令牌 / GitHub PAT，权限最小化） |
| `EXPO_TOKEN` | Expo 个人访问令牌，用于拉取 Expo 托管签名证书 |
| `ASC_API_KEY_P8` | App Store Connect API Key 的 `.p8` **全文** |
| `ASC_API_KEY_ID` | 例如 `KV696W6V28` |
| `ASC_API_KEY_ISSUER_ID` | 例如 `ae9a72e2-1fce-4ca3-9591-bd1e0d76a2fe` |

不要把 `.p8`、token、业务源码提交进这个公仓。

## 3. 触发构建

在业务仓 `mobile-app/` 一键触发（推荐）：

```powershell
cd C:\code\code-console\mobile-app
npm run release:ios:github
npm run release:ios:status
```

或本页 GitHub → Actions → `iOS TestFlight (public free builder)` → Run workflow。

可指定 `source_ref`（默认 `main`）。

## 4. 「无限次数」边界（必读）

公仓 + `eas build --local` **可以大幅降低费用**，但不是合同上的无限保证：

```text
GitHub 可随时调整公仓 Actions 政策
重度占用可能触发滥用审查、限流或排队变慢
macos runner 经常排队，单次 iOS 构建常要 30–90+ 分钟
Expo 托管证书、Apple API、网络仍可能失败
日志里可能出现源码片段——公仓日志对外可见，注意脱敏
```

更稳妥的理解：

```text
适合：Windows 无 Mac、想少花 EAS Build 额度、可接受排队
不适合：把公仓当生产级无限 CI SLA
```

完整产品侧步骤见仓库根目录 `docs/mobile-ios-testflight-runbook.md`。
