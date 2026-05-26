# ============================================================
# start-services.ps1
# Sobe todos os port-forwards em background
# Uso: .\start-services.ps1
# Para parar tudo: .\start-services.ps1 -Stop
# ============================================================

param([switch]$Stop)

if ($Stop) {
    Get-Job | Where-Object { $_.Name -like "pf-*" } | Stop-Job | Remove-Job
    Write-Host "Todos os port-forwards parados."
    exit
}

# Para qualquer port-forward anterior
Get-Job | Where-Object { $_.Name -like "pf-*" } | Stop-Job | Remove-Job

Write-Host "Subindo port-forwards..." -ForegroundColor Cyan

Start-Job -Name "pf-uptime-kuma" -ScriptBlock {
    kubectl port-forward svc/uptime-kuma -n uptime-kuma 3001:80
} | Out-Null

Start-Job -Name "pf-argocd" -ScriptBlock {
    kubectl port-forward svc/argocd-server -n argocd 8080:443
} | Out-Null

Start-Job -Name "pf-prometheus" -ScriptBlock {
    kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090
} | Out-Null

Start-Job -Name "pf-grafana" -ScriptBlock {
    kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80
} | Out-Null

Start-Sleep -Seconds 3

Write-Host ""
Write-Host "Servicos disponiveis:" -ForegroundColor Green
Write-Host "  Uptime Kuma  -> http://localhost:3001"   -ForegroundColor Yellow
Write-Host "  ArgoCD       -> https://localhost:8080"  -ForegroundColor Yellow
Write-Host "  Prometheus   -> http://localhost:9090"   -ForegroundColor Yellow
Write-Host "  Grafana      -> http://localhost:3000    (admin / senha do values.yaml)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Para parar tudo: .\start-services.ps1 -Stop" -ForegroundColor Gray

# Manter o script rodando e relancando port-forwards que caem
while ($true) {
    Start-Sleep -Seconds 30
    $jobs = @{
        "pf-uptime-kuma" = "kubectl port-forward svc/uptime-kuma -n uptime-kuma 3001:80"
        "pf-argocd"      = "kubectl port-forward svc/argocd-server -n argocd 8080:443"
        "pf-prometheus"  = "kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090"
        "pf-grafana"     = "kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80"
    }
    foreach ($name in $jobs.Keys) {
        $job = Get-Job -Name $name -ErrorAction SilentlyContinue
        if (-not $job -or $job.State -eq "Failed" -or $job.State -eq "Completed") {
            $cmd = $jobs[$name]
            Start-Job -Name $name -ScriptBlock { param($c) Invoke-Expression $c } -ArgumentList $cmd | Out-Null
        }
    }
}
