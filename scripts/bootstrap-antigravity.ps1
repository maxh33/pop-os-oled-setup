<#
.SYNOPSIS
    bootstrap-antigravity.ps1 - Automated Setup for Antigravity CLI on Windows
    Repository: https://github.com/maxh33/pop-os-oled-setup
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$ConfigDir = Join-Path $RepoRoot "configs\antigravity"

function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }

Write-Host "======================================================" -ForegroundColor Magenta
Write-Host "    Antigravity CLI Bootstrap (Windows)               " -ForegroundColor Magenta
Write-Host "======================================================" -ForegroundColor Magenta

# 1. Directories
$GeminiHome = Join-Path $env:USERPROFILE ".gemini"
$AgyCliDir = Join-Path $GeminiHome "antigravity-cli"
$GeminiConfigDir = Join-Path $GeminiHome "config"

Write-Info "Criando diretórios em $GeminiHome..."
New-Item -ItemType Directory -Force -Path $AgyCliDir | Out-Null
New-Item -ItemType Directory -Force -Path $GeminiConfigDir | Out-Null

# 2. Configurações Centrais
Write-Info "Copiando arquivos de configuração..."

$SettingsSrc = Join-Path $ConfigDir "settings.json"
if (Test-Path $SettingsSrc) {
    Copy-Item -Path $SettingsSrc -Destination (Join-Path $AgyCliDir "settings.json") -Force
    Write-Success "settings.json aplicado."
}

$GeminiMdSrc = Join-Path $ConfigDir "GEMINI.md"
if (Test-Path $GeminiMdSrc) {
    $GeminiMdDst = Join-Path $GeminiConfigDir "GEMINI.md"
    $AgentsMdDst = Join-Path $GeminiConfigDir "AGENTS.md"
    Copy-Item -Path $GeminiMdSrc -Destination $GeminiMdDst -Force
    Copy-Item -Path $GeminiMdSrc -Destination $AgentsMdDst -Force
    Write-Success "GEMINI.md e AGENTS.md aplicados."
}

$McpSrc = Join-Path $ConfigDir "mcp_config.json"
if (Test-Path $McpSrc) {
    Copy-Item -Path $McpSrc -Destination (Join-Path $GeminiConfigDir "mcp_config.json") -Force
    Write-Success "mcp_config.json aplicado."
}

# 3. GitHub CLI & Token
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Info "GitHub CLI detectado. Para configurar tokens dinâmicos no PowerShell, adicione ao seu `$PROFILE:"
    Write-Host '    if (Get-Command gh -ErrorAction SilentlyContinue) { $env:GITHUB_PERSONAL_ACCESS_TOKEN = (gh auth token 2>$null); $env:GITHUB_TOKEN = $env:GITHUB_PERSONAL_ACCESS_TOKEN }' -ForegroundColor Gray
} else {
    Write-Warn "GitHub CLI ('gh') não encontrado. Instale com 'winget install GitHub.cli' para autenticação dinâmica."
}

# 4. Navegador e Automação Agêntica
if (Get-Command uv -ErrorAction SilentlyContinue) {
    Write-Info "Verificando browser-use via uv..."
    $tools = & uv tool list 2>$null
    if ($tools -notmatch "browser-use") {
        Write-Info "Instalando browser-use..."
        & uv tool install browser-use
    } else {
        Write-Success "browser-use já instalado."
    }
} else {
    Write-Warn "'uv' não encontrado. Instale via 'winget install astral-sh.uv' para gerenciar ferramentas agênticas."
}

Write-Host "------------------------------------------------------" -ForegroundColor Magenta
Write-Success "Bootstrap concluído com sucesso!"
Write-Host "Execute 'agy mcp list' para validar a conexão dos servidores MCP."
Write-Host "======================================================" -ForegroundColor Magenta
