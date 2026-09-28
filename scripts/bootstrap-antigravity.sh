#!/usr/bin/env bash
# ==============================================================================
# bootstrap-antigravity.sh - Automated Setup for Antigravity CLI (Linux / WSL2)
# Repository: https://github.com/maxh33/pop-os-oled-setup
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_DIR="${REPO_ROOT}/configs/antigravity"

info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[1;32m[OK]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }

echo "======================================================"
echo "    Antigravity CLI Bootstrap (Linux / WSL2)          "
echo "======================================================"

# 1. Directories
info "Criando diretórios de configuração do Antigravity..."
mkdir -p "${HOME}/.gemini/antigravity-cli"
mkdir -p "${HOME}/.gemini/config"

# 2. Configurações Centrais
info "Aplicando configurações do repositório..."

if [[ -f "${CONFIG_DIR}/settings.json" ]]; then
    cp -v "${CONFIG_DIR}/settings.json" "${HOME}/.gemini/antigravity-cli/settings.json"
fi

if [[ -f "${CONFIG_DIR}/GEMINI.md" ]]; then
    cp -v "${CONFIG_DIR}/GEMINI.md" "${HOME}/.gemini/config/GEMINI.md"
    ln -sf "${HOME}/.gemini/config/GEMINI.md" "${HOME}/.gemini/config/AGENTS.md"
    success "Regras globais GEMINI.md e symlink AGENTS.md configurados."
fi

if [[ -f "${CONFIG_DIR}/mcp_config.json" ]]; then
    cp -v "${CONFIG_DIR}/mcp_config.json" "${HOME}/.gemini/config/mcp_config.json"
    success "Servidores MCP (context7, github, playwright) configurados."
fi

# 3. Integração com GitHub CLI para tokens dinâmicos
if command -v gh &> /dev/null; then
    BASHRC_LINE='if command -v gh &> /dev/null; then export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token 2>/dev/null)"; export GITHUB_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN"; fi'
    if ! grep -q "GITHUB_PERSONAL_ACCESS_TOKEN" "${HOME}/.bashrc" 2>/dev/null; then
        info "Configurando exportação dinâmica de token do GitHub no ~/.bashrc..."
        echo -e "\n# GitHub Token export for MCP tools\n${BASHRC_LINE}" >> "${HOME}/.bashrc"
        success "Token dinâmico configurado no ~/.bashrc."
    fi
else
    warn "GitHub CLI ('gh') não encontrado. Instale com 'sudo apt install gh' para autenticação de tokens automática."
fi

# 4. Navegador e Automação Agêntica
info "Verificando ambiente de automação de navegador..."
if [[ -d "${HOME}/.config/BraveSoftware/Brave-Browser" && ! -e "${HOME}/.config/google-chrome" ]]; then
    info "Criando symlink de compatibilidade Chrome -> Brave para ferramentas de automação..."
    ln -s "${HOME}/.config/BraveSoftware/Brave-Browser" "${HOME}/.config/google-chrome"
    success "Symlink ~/.config/google-chrome configurado."
fi

# Configurar Brave nativo com CDP port 9222 para automação sem perfil virgem
if [[ -f "/usr/share/applications/brave-browser.desktop" && ! -f "${HOME}/.local/share/applications/brave-browser.desktop" ]]; then
    info "Configurando lançador desktop do Brave com --remote-debugging-port=9222..."
    mkdir -p "${HOME}/.local/share/applications"
    cp "/usr/share/applications/brave-browser.desktop" "${HOME}/.local/share/applications/brave-browser.desktop"
    sed -i 's|Exec=/usr/bin/brave-browser-stable|Exec=/usr/bin/brave-browser-stable --remote-debugging-port=9222|g' "${HOME}/.local/share/applications/brave-browser.desktop"
    update-desktop-database "${HOME}/.local/share/applications/" 2>/dev/null || true
    success "Lançador do Brave com porta 9222 configurado."
fi

# Garantir Native Messaging Host para Claude in Chrome bridge
info "Verificando Native Messaging Host para Claude in Chrome..."
CLAUDE_WRAPPER_DIR="${HOME}/.claude/chrome"
mkdir -p "${CLAUDE_WRAPPER_DIR}"
if [[ ! -f "${CLAUDE_WRAPPER_DIR}/chrome-native-host" ]]; then
    cat << 'EOF' > "${CLAUDE_WRAPPER_DIR}/chrome-native-host"
#!/bin/sh
exec claude --chrome-native-host
EOF
    chmod +x "${CLAUDE_WRAPPER_DIR}/chrome-native-host"
    success "Script chrome-native-host criado em ${CLAUDE_WRAPPER_DIR}."
fi

for BROWSER_DIR in "${HOME}/.config/BraveSoftware/Brave-Browser" "${HOME}/.config/google-chrome"; do
    if [[ -d "${BROWSER_DIR}" ]]; then
        NATIVE_DIR="${BROWSER_DIR}/NativeMessagingHosts"
        mkdir -p "${NATIVE_DIR}"
        if [[ ! -f "${NATIVE_DIR}/com.anthropic.claude_code_browser_extension.json" ]]; then
            cat << EOF > "${NATIVE_DIR}/com.anthropic.claude_code_browser_extension.json"
{
  "name": "com.anthropic.claude_code_browser_extension",
  "description": "Claude Code Browser Extension Native Host",
  "path": "${CLAUDE_WRAPPER_DIR}/chrome-native-host",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://fcoeoabgfenejglbffodgkkbkcdhcgfn/"
  ]
}
EOF
            success "Manifest de Native Messaging instalado em ${NATIVE_DIR}."
        fi
    fi
done

if command -v uv &> /dev/null; then
    if ! uv tool list | grep -q "browser-use" 2>/dev/null; then
        info "Instalando browser-use via uv..."
        uv tool install browser-use || warn "Falha ao instalar browser-use via uv."
    else
        success "browser-use já instalado via uv."
    fi
else
    warn "'uv' não encontrado. Recomenda-se instalar uv para gerenciar ferramentas agênticas python."
fi

# 5. Validação de Binários e Chaves
echo "------------------------------------------------------"
info "Auditando ambiente do Antigravity CLI..."

if ! command -v agy &> /dev/null; then
    warn "Binário 'agy' não detectado no PATH."
    echo "  -> Se instalado em ~/.local/bin/agy, adicione 'export PATH=\"\$HOME/.local/bin:\$PATH\"' ao ~/.bashrc"
else
    success "Antigravity CLI detectado: $(agy --version 2>/dev/null || echo 'versão OK')"
fi

if [[ -z "${GEMINI_API_KEY:-}" ]] && ! grep -q "GEMINI_API_KEY" "${HOME}/.secrets" 2>/dev/null && ! grep -q "GEMINI_API_KEY" "${HOME}/.gemini/.env" 2>/dev/null; then
    warn "GEMINI_API_KEY não localizada em ~/.secrets ou ~/.gemini/.env."
    echo "  -> Para configurar: echo 'export GEMINI_API_KEY=\"sua-chave\"' >> ~/.secrets"
else
    success "Credencial GEMINI_API_KEY verificada."
fi

echo "------------------------------------------------------"
success "Bootstrap do Antigravity CLI concluído com sucesso!"
echo "Para verificar status dos MCPs, execute: agy mcp list"
echo "======================================================"
