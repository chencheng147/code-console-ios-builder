# Publishes ci/github-ios-builder as a standalone PUBLIC GitHub repo.
# Does not print secret values. Requires network + GitHub auth.

[CmdletBinding()]
param(
  [string]$RepoName = 'code-console-ios-builder',
  [string]$Visibility = 'public',
  [switch]$SkipSecrets
)

$ErrorActionPreference = 'Stop'

function Resolve-Gh {
  $cmd = Get-Command gh -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $local = Join-Path $env:LOCALAPPDATA 'Programs\gh\gh.exe'
  if (Test-Path -LiteralPath $local) { return $local }
  throw '未找到 gh。请先安装 GitHub CLI：https://cli.github.com/'
}

$gh = Resolve-Gh
Write-Host "Using gh: $gh"

& $gh auth status
if ($LASTEXITCODE -ne 0) {
  Write-Host '需要登录 GitHub（会打开浏览器）：'
  & $gh auth login -h github.com -p https -w
  if ($LASTEXITCODE -ne 0) { throw 'gh auth login 失败' }
}

$builderRoot = $PSScriptRoot
$staging = Join-Path ([System.IO.Path]::GetTempPath()) ("code-console-ios-builder-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $staging | Out-Null

try {
  Copy-Item -LiteralPath (Join-Path $builderRoot '.github') -Destination (Join-Path $staging '.github') -Recurse -Force
  Copy-Item -LiteralPath (Join-Path $builderRoot 'README.md') -Destination (Join-Path $staging 'README.md') -Force
  Copy-Item -LiteralPath (Join-Path $builderRoot 'SECRETS.md') -Destination (Join-Path $staging 'SECRETS.md') -Force

  Push-Location $staging
  git init -b main | Out-Null
  git add .
  git commit -m 'Add public iOS TestFlight builder workflow' | Out-Null

  $created = & $gh repo create $RepoName --$Visibility --source . --remote origin --push
  if ($LASTEXITCODE -ne 0) { throw 'gh repo create / push 失败' }
  Write-Host "Public builder repo: $created"

  if ($SkipSecrets) {
    Write-Host '已跳过 Secrets。请按 SECRETS.md 手动配置。'
    return
  }

  $sourceUrl = Read-Host 'SOURCE_REPO_URL (例如 https://gitee.com/superchenxiaodi/code-console.git)'
  $sourceToken = Read-Host 'SOURCE_REPO_TOKEN (只读令牌)'
  $expoToken = Read-Host 'EXPO_TOKEN'
  $p8Path = Read-Host "ASC_API_KEY_P8 文件路径 [D:\apple\AuthKey_KV696W6V28.p8]"
  if ([string]::IsNullOrWhiteSpace($p8Path)) { $p8Path = 'D:\apple\AuthKey_KV696W6V28.p8' }
  if (-not (Test-Path -LiteralPath $p8Path)) { throw "找不到 .p8：$p8Path" }

  $keyId = 'KV696W6V28'
  $issuerId = 'ae9a72e2-1fce-4ca3-9591-bd1e0d76a2fe'

  & $gh secret set SOURCE_REPO_URL -b $sourceUrl
  & $gh secret set SOURCE_REPO_TOKEN -b $sourceToken
  & $gh secret set EXPO_TOKEN -b $expoToken
  & $gh secret set ASC_API_KEY_ID -b $keyId
  & $gh secret set ASC_API_KEY_ISSUER_ID -b $issuerId
  Get-Content -LiteralPath $p8Path -Raw | & $gh secret set ASC_API_KEY_P8

  Write-Host ''
  Write-Host 'Secrets 已写入。下一步：'
  Write-Host '1. 打开公仓 Actions → iOS TestFlight (public free builder) → Run workflow'
  Write-Host '2. source_ref 默认 main'
  Write-Host '3. 构建完成后到 App Store Connect 查 TestFlight build'
}
finally {
  Pop-Location -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
}
