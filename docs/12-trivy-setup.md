# 12 - Trivy (Aqua Security)

Este documento descreve como instalar e usar o Trivy neste ambiente (Pop!_OS / Ubuntu) para varredura de vulnerabilidades em imagens, sistemas de arquivos e código IaC. Instruções foram pensadas para reprodução em estações de desenvolvimento e CI.

## Por que usar
- Varredura rápida de imagens/container, filesystem e IaC
- Saída em JSON/SARIF (útil para CI e integração com scanners)
- Fácil execução local e em GitHub Actions

## Instalação (Pop!_OS / Ubuntu)
Opção A — repositório oficial (recomendado):

```bash
sudo apt-get update
sudo apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
  | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy
```

Opção B — Homebrew (Linux/macOS):

```bash
brew install aquasecurity/trivy/trivy
```

Opção C — baixar binário (releases):
- Baixar a release adequada de https://github.com/aquasecurity/trivy/releases e mover para /usr/local/bin

## Preparar o DB de vulnerabilidades
Baixar/atualizar DB localmente (executar periodicamente):

```bash
trivy db update
# ou para só baixar sem scan
trivy --download-db-only
```

## Comandos úteis
Scan de imagem Docker local:

```bash
# ex: registry/image:tag
trivy image --severity HIGH,CRITICAL --no-progress --format table registry/image:tag
trivy image --severity MEDIUM,HIGH,CRITICAL --format json -o trivy-image-report.json registry/image:tag
```

Scan do sistema de arquivos (diretório do projeto):

```bash
trivy fs --security-checks vuln,config --severity MEDIUM,HIGH,CRITICAL .
trivy fs --format json -o trivy-fs-report.json .
```

Scan de repositório/CI (varredura de dependências):

```bash
trivy repo --scanners vuln .
```

IaC / Config (Terraform, Kubernetes, CloudFormation):

```bash
trivy config --severity HIGH,CRITICAL ./iac-directory
# ou para IaC e configs combinadas
trivy iac --format json -o trivy-iac.json ./
```

## Exemplo: executar em CI (GitHub Actions)
Adicione um passo no workflow:

```yaml
- name: Scan with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    format: 'json'
    output: 'trivy-report.json'
    scan-type: 'fs' # or 'image'
    severity: 'MEDIUM,HIGH,CRITICAL'
```

Após gerar trivy-report.json, publicar artefato ou usar SARIF para integrar com Code Scanning.

## .trivyignore (exemplo)
Criar um arquivo `.trivyignore` na raiz para ignorar vulnerabilidades conhecidas/aceitas:

```
# Ignorar CVE específico
CVE-2022-0001
# Ignorar pacote ou path
node_modules/**
```

## Dicas e práticas
- Atualizar DB antes de scans automatizados (`trivy db update`).
- Em máquinas de desenvolvimento, usar cache: export TRIVY_CACHE_DIR="$HOME/.cache/trivy".
- Para reduzir ruído, filtrar por severidade: `--severity HIGH,CRITICAL`.
- Em CI, gerar JSON/SARIF e falhar o job apenas para severidades críticas.
- Execute `trivy --help` para ver subcomandos (image, fs, repo, config, iac, k8s).

## Observações específicas para este repositório
- Este repositório guarda scripts e imagens de configuração; recomenda-se rodar `trivy fs` na raiz do repo antes de publicar os artefatos.
- Para conter falsos positivos em pacotes de sistema, use `.trivyignore` para arquivos/paths ou CVEs conhecidos que foram avaliados manualmente.

---
Guia criado com base no uso esperado neste ambiente Pop!_OS/Ubuntu. Solicite alterações se quiser exemplos de workflows específicos (scanner de imagens Docker push, GitLab CI, ou policy de falha por severidade).