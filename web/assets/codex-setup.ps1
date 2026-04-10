# ============================================================
#  Codex CLI 一键安装配置脚本 (Windows PowerShell)
#  用法: .\codex-setup.ps1 -ApiKey "YOUR_API_KEY"
#        irm "https://YOUR_DOMAIN/web/assets/codex-setup.ps1" | iex
# ============================================================

param(
    [string]$ApiKey = ""
)

$ErrorActionPreference = "Stop"

function Write-Info  { param($msg) Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-Ok    { param($msg) Write-Host "[OK]    $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

# ---------- 获取 API Key ----------
if (-not $ApiKey) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   Codex CLI 一键安装配置脚本" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    $ApiKey = Read-Host "请输入你的 API 密钥 (cr_xxx)"
    if (-not $ApiKey) {
        Write-Err "API 密钥不能为空"
        exit 1
    }
}

# ---------- BASE_URL ----------
$BaseUrl = $env:CODEX_BASE_URL
if (-not $BaseUrl) {
    $BaseUrl = "https://YOUR_DOMAIN/openai"
    Write-Warn "BASE_URL 使用默认值: $BaseUrl"
    Write-Warn "如需自定义，请设置环境变量: `$env:CODEX_BASE_URL = 'https://your-domain/openai'"
}

Write-Host ""
Write-Info "开始安装 Codex CLI..."
Write-Host ""

# ---------- 1. 检查 Node.js ----------
Write-Info "检查 Node.js 环境..."
try {
    $nodeVer = & node --version 2>&1
    Write-Ok "Node.js 已安装: $nodeVer"
} catch {
    Write-Err "未检测到 Node.js，请先安装 Node.js (https://nodejs.org/)"
    exit 1
}

try {
    $npmVer = & npm --version 2>&1
    Write-Ok "npm 已安装: $npmVer"
} catch {
    Write-Err "未检测到 npm，请检查 Node.js 安装"
    exit 1
}

# ---------- 2. 安装 Codex CLI ----------
Write-Info "安装 @openai/codex ..."
try {
    $existingVer = & codex --version 2>&1
    Write-Warn "Codex CLI 已安装 ($existingVer)，正在升级..."
} catch {
    # not installed yet
}

& npm install -g @openai/codex
if ($LASTEXITCODE -ne 0) {
    Write-Err "安装失败，请尝试以管理员身份运行 PowerShell"
    exit 1
}

try {
    $codexVer = & codex --version 2>&1
    Write-Ok "Codex CLI 安装完成: $codexVer"
} catch {
    Write-Ok "Codex CLI 安装完成"
}

# ---------- 3. 写入配置文件 ----------
$codexDir = Join-Path $env:USERPROFILE ".codex"
if (-not (Test-Path $codexDir)) {
    New-Item -ItemType Directory -Force -Path $codexDir | Out-Null
}

Write-Info "写入配置文件 $codexDir\config.toml ..."
$configContent = @"
model_provider = "crs"
model = "gpt-5-codex"
model_reasoning_effort = "high"
disable_response_storage = true
preferred_auth_method = "apikey"

[model_providers.crs]
name = "crs"
base_url = "$BaseUrl"
wire_api = "responses"
requires_openai_auth = true
"@
Set-Content -Path (Join-Path $codexDir "config.toml") -Value $configContent -Force
Write-Ok "config.toml 已写入"

Write-Info "写入认证文件 $codexDir\auth.json ..."
$authContent = @"
{
  "OPENAI_API_KEY": "$ApiKey"
}
"@
Set-Content -Path (Join-Path $codexDir "auth.json") -Value $authContent -Force
Write-Ok "auth.json 已写入"

# ---------- 4. 验证 ----------
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   安装完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

try { $finalVer = & codex --version 2>&1 } catch { $finalVer = "installed" }
Write-Host "  Codex CLI:   $finalVer"
Write-Host "  配置目录:     $codexDir"
Write-Host "  config.toml: $codexDir\config.toml"
Write-Host "  auth.json:   $codexDir\auth.json"
Write-Host ""
Write-Host "  现在可以运行 'codex' 开始使用了!" -ForegroundColor Cyan
Write-Host ""
