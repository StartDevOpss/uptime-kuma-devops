# Uptime Kuma — Pipeline DevOps (Portfólio)

Pipeline completo de CI/CD com GitHub Actions + Kubernetes para o Uptime Kuma.

## Stack utilizada

- **App:** Uptime Kuma (monitoramento de serviços)
- **Container Registry:** GitHub Container Registry (GHCR)
- **CI/CD:** GitHub Actions
- **Orquestração:** Kubernetes

## Estrutura do projeto

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml      # Pipeline de build e deploy
├── k8s/
│   ├── deployment.yaml     # Deployment + PVC
│   ├── service.yaml        # Service (ClusterIP)
│   └── ingress.yaml        # Ingress (acesso externo)
├── Dockerfile
└── README.md
```

## Passo a passo

### 1. Fork e clone

```bash
# Fork este repositório no GitHub, depois clone:
git clone https://github.com/SEU_USUARIO/uptime-kuma-devops
cd uptime-kuma-devops
```

### 2. Instalar o Kind (Kubernetes local)

```bash
# macOS
brew install kind

# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind
```

### 3. Criar o cluster local

```bash
kind create cluster --name uptime-kuma
```

### 4. Criar o namespace no Kubernetes

```bash
kubectl create namespace uptime-kuma
```

### 5. Aplicar os manifests

```bash
kubectl apply -f k8s/
```

### 6. Configurar o Secret no GitHub

```bash
# Exportar o KUBECONFIG do cluster
kubectl config view --raw > kubeconfig.yaml

# Copiar o conteúdo e adicionar como secret no GitHub:
# Repositório → Settings → Secrets → New repository secret
# Nome: KUBECONFIG
# Valor: (cole o conteúdo do kubeconfig.yaml)
```

### 7. Editar os arquivos com seu usuário

No `k8s/deployment.yaml`, troque:
```
image: ghcr.io/SEU_USUARIO/uptime-kuma:latest
```

No `k8s/ingress.yaml`, troque:
```
host: uptime.SEU_DOMINIO.com
```

### 8. Fazer o primeiro deploy

```bash
git add .
git commit -m "feat: primeiro deploy do Uptime Kuma"
git push origin main
```

O pipeline vai:
1. Fazer o build da imagem Docker
2. Publicar no GHCR
3. Fazer o deploy no Kubernetes automaticamente

### 9. Acessar a aplicação

```bash
# Para testar localmente sem domínio:
kubectl port-forward svc/uptime-kuma 3001:80 -n uptime-kuma

# Acessar em: http://localhost:3001
```

## Próximos passos (diferenciais para o portfólio)

- [ ] Instalar ArgoCD e migrar para GitOps
- [ ] Adicionar Helm chart
- [ ] Configurar monitoramento com Prometheus + Grafana
- [ ] Configurar TLS com cert-manager
