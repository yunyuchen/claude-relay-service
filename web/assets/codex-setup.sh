#!/usr/bin/env bash
set -e

# ============================================================
#  Codex CLI 一键安装配置脚本
#  用法: ./codex-setup.sh [API_KEY]
#        curl -fsSL https://YOUR_DOMAIN/web/assets/codex-setup.sh | bash -s -- YOUR_API_KEY
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

# ---------- 获取 API Key ----------
API_KEY="${1:-}"
if [ -z "$API_KEY" ]; then
  echo ""
  echo -e "${CYAN}========================================${NC}"
  echo -e "${CYAN}   Codex CLI 一键安装配置脚本${NC}"
  echo -e "${CYAN}========================================${NC}"
  echo ""
  read -rp "请输入你的 API 密钥 (cr_xxx): " API_KEY
  if [ -z "$API_KEY" ]; then
    err "API 密钥不能为空"
    exit 1
  fi
fi

# ---------- 自动检测 BASE_URL ----------
# 如果通过 curl | bash 运行，尝试从脚本下载地址推断
BASE_URL="${CODEX_BASE_URL:-}"
if [ -z "$BASE_URL" ]; then
  # 默认值，用户可通过环境变量 CODEX_BASE_URL 覆盖
  BASE_URL="https://YOUR_DOMAIN/openai"
  warn "BASE_URL 使用默认值: $BASE_URL"
  warn "如需自定义，请设置环境变量: export CODEX_BASE_URL=https://your-domain/openai"
fi

echo ""
info "开始安装 Codex CLI..."
echo ""

# ---------- 1. 检查 Node.js ----------
info "检查 Node.js 环境..."
if ! command -v node &>/dev/null; then
  err "未检测到 Node.js，请先安装 Node.js (https://nodejs.org/)"
  exit 1
fi
NODE_VER=$(node --version)
ok "Node.js 已安装: $NODE_VER"

if ! command -v npm &>/dev/null; then
  err "未检测到 npm，请检查 Node.js 安装"
  exit 1
fi
NPM_VER=$(npm --version)
ok "npm 已安装: $NPM_VER"

# ---------- 2. 安装 Codex CLI ----------
info "安装 @openai/codex ..."
if command -v codex &>/dev/null; then
  CURRENT_VER=$(codex --version 2>/dev/null || echo "unknown")
  warn "Codex CLI 已安装 ($CURRENT_VER)，正在升级..."
fi

npm install -g @openai/codex
ok "Codex CLI 安装完成: $(codex --version 2>/dev/null || echo 'installed')"

# ---------- 3. 写入配置文件 ----------
CODEX_DIR="$HOME/.codex"
mkdir -p "$CODEX_DIR"

info "写入配置文件 $CODEX_DIR/config.toml ..."
cat > "$CODEX_DIR/config.toml" << 'TOML_EOF'
model_provider = "crs"
model = "gpt-5-codex"
model_reasoning_effort = "high"
disable_response_storage = true
preferred_auth_method = "apikey"

[model_providers.crs]
name = "crs"
base_url = "BASE_URL_PLACEHOLDER"
wire_api = "responses"
requires_openai_auth = true
TOML_EOF

# 替换 BASE_URL 占位符
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s|BASE_URL_PLACEHOLDER|${BASE_URL}|g" "$CODEX_DIR/config.toml"
else
  sed -i "s|BASE_URL_PLACEHOLDER|${BASE_URL}|g" "$CODEX_DIR/config.toml"
fi
ok "config.toml 已写入"

info "写入认证文件 $CODEX_DIR/auth.json ..."
cat > "$CODEX_DIR/auth.json" << JSON_EOF
{
  "OPENAI_API_KEY": "${API_KEY}"
}
JSON_EOF
ok "auth.json 已写入"

# ---------- 4. 验证 ----------
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   安装完成!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "  Codex CLI:   $(codex --version 2>/dev/null || echo 'installed')"
echo -e "  配置目录:     $CODEX_DIR"
echo -e "  config.toml: $CODEX_DIR/config.toml"
echo -e "  auth.json:   $CODEX_DIR/auth.json"
echo ""
echo -e "  ${CYAN}现在可以运行 'codex' 开始使用了!${NC}"
echo ""
