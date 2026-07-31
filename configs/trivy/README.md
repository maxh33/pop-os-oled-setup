# Trivy (aquasecurity/trivy)

Scanner de segurança CLI, self-hosted, sem ceiling de SaaS — SCA (dependência vulnerável), misconfig de infra (Dockerfile/Kubernetes/Terraform/Helm/CloudFormation/Ansible — **não cobre docker-compose puro**, limitação da própria ferramenta), CVE de imagem de container.

## Instalação (sem sudo)

```bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b ~/.local/bin
trivy --version
```

`https://get.trivy.dev` (URL "oficial" mais curta) retornou HTTP 400 na instalação original — usar a URL do GitHub acima direto, já testada.

## Uso

```bash
# CVE de imagem (HIGH/CRITICAL)
trivy image <imagem:tag> --severity HIGH,CRITICAL

# Misconfig de IaC (não cobre docker-compose)
trivy config . --severity HIGH,CRITICAL
```

**Aviso de recurso, não pular**: `docker pull`/`trivy image` em lote (várias imagens grandes seguidas) pode travar o WSL2 inteiro se não tiver cap de memória — ver `docs/18-wsl2-vmmem-freeze.md` e `configs/wsl/.wslconfig` antes de rodar em lote numa VM WSL. Rodar uma imagem por vez, checando `free -h` entre cada, se não tiver certeza que o cap está ativo.

## Status neste momento

Uso manual de auditoria — ainda não está em hook de git nem na VPS. Decisão de virar automático/hook fica pendente até o workflow manual se provar no dia a dia.
