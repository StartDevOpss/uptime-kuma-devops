# Uptime Kuma — Pipeline DevOps (Portfólio)

Pipeline GitOps completo com GitHub Actions, ArgoCD, Helm e monitoramento via Prometheus + Grafana, rodando em Kubernetes local (Kind).

## Stack utilizada

| Camada | Tecnologia |
|---|---|
| App | [Uptime Kuma](https://github.com/louislam/uptime-kuma) — monitoramento de serviços |
| Container | Docker + GitHub Container Registry (GHCR) |
| CI/CD | GitHub Actions |
| GitOps | ArgoCD |
| Deploy | Helm Chart customizado |
| Cluster | Kubernetes local via Kind |
| Monitoramento | Prometheus + Grafana (kube-prometheus-stack) |
| Ingress | nginx ingress controller |

## Arquitetura

```
┌─────────────────────────────────────────────────────┐
│                   Desenvolvedor                     │
│              git push origin main                   │
└────────────────────────┬────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│              GitHub Actions (CI)                    │
│  1. Build da imagem Docker                          │
│  2. Push para GHCR                                  │
│  3. Atualiza tag no helm/uptime-kuma/values.yaml    │
│  4. Commit automático [skip ci]                     │
└────────────────────────┬────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│              ArgoCD (GitOps)                        │
│  Detecta mudança no values.yaml                     │
│  Aplica o Helm chart no cluster                     │
└────────────────────────┬────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│           Kind Cluster (Kubernetes local)           │
│                                                     │
│  namespace: uptime-kuma                             │
│    └── Deployment + Service + Ingress + PVC         │
│                                                     │
│  namespace: argocd                                  │
│    └── ArgoCD                                       │
│                                                     │
│  namespace: monitoring                              │
│    └── Prometheus + Grafana + Alertmanager          │
└─────────────────────────────────────────────────────┘
```

## Estrutura do repositório

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml              # CI: build, push e atualização GitOps
├── helm/
│   └── uptime-kuma/
│       ├── Chart.yaml
│       ├── values.yaml             # Tag da imagem atualizada automaticamente pelo CI
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── pvc.yaml
│           └── servicemonitor.yaml # Integração com Prometheus
├── monitoring/
│   ├── prometheus/
│   │   └── values.yaml            # Config do kube-prometheus-stack
│   └── grafana/
│       └── dashboard-configmap.yaml  # Dashboard customizado do Uptime Kuma
├── argocd/
│   └── application.yaml           # App ArgoCD apontando para o Helm chart
├── Dockerfile
└── start-services.ps1             # Script para subir todos os port-forwards
```

## Como executar localmente

### Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/)
- [ArgoCD CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/)

### 1. Criar o cluster Kind

```bash
kind create cluster --name uptime-kuma
```

### 2. Instalar o nginx ingress controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### 3. Instalar o ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=120s
```

### 4. Instalar o kube-prometheus-stack (Prometheus + Grafana)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f monitoring/prometheus/values.yaml
```

### 5. Criar a aplicação no ArgoCD

```bash
kubectl apply -f argocd/application.yaml
```

### 6. Subir os port-forwards (Windows)

```powershell
.\start-services.ps1
```

Para parar:

```powershell
.\start-services.ps1 -Stop
```

## Serviços disponíveis

| Serviço | URL | Credenciais |
|---|---|---|
| Uptime Kuma | http://localhost:3001 | Configurado no primeiro acesso |
| ArgoCD | https://localhost:8080 | admin / ver abaixo |
| Prometheus | http://localhost:9090 | — |
| Grafana | http://localhost:3000 | admin / senha definida em `monitoring/prometheus/values.yaml` |

> **Senha do ArgoCD:**
> ```bash
> kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
> ```

## Pipeline GitOps em ação

Cada `git push` na branch `main` dispara o ciclo completo:

1. **GitHub Actions** faz o build e push da imagem para o GHCR com tag `sha-<commit>`
2. **GitHub Actions** atualiza automaticamente a `tag` em `helm/uptime-kuma/values.yaml` e faz commit
3. **ArgoCD** detecta a mudança no repositório e aplica o Helm chart no cluster
4. O novo pod sobe com a imagem atualizada — zero intervenção manual

## Monitoramento

- **Prometheus** coleta métricas do cluster (nodes, pods, namespaces) via ServiceMonitor
- **Grafana** exibe dashboards automáticos na pasta "Portfolio"
- **Alertmanager** configurado junto ao stack (pronto para receber regras de alerta)
- **Uptime Kuma** monitora a disponibilidade de ArgoCD, Prometheus, Grafana e GitHub

## Decisões técnicas

**Por que Kind?** Cluster Kubernetes local gratuito, sem depender de cloud, ideal para portfólio e desenvolvimento.

**Por que GitOps com ArgoCD?** O repositório Git é a fonte de verdade. Nenhum `kubectl apply` manual em produção — tudo passa pelo pipeline.

**Por que Helm?** Parametrização limpa dos manifests. A tag da imagem é o único valor que muda a cada deploy, atualizado automaticamente pelo CI.

**Por que kube-prometheus-stack?** Solução completa (Prometheus + Grafana + Alertmanager + exporters) instalada com um único `helm install`.
