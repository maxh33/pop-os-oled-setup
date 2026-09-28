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

echo "------------------------------------------------------"
success "Bootstrap do Antigravity CLI concluído com sucesso!"
echo "Para verificar status dos MCPs, execute: agy mcp list"
echo "======================================================"
