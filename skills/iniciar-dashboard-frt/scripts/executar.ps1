param([switch]$Redefinir)

try {
    iniciar-dashboard-frt -Redefinir:$Redefinir
} catch {
    Write-Host "Falha ao abrir o dashboard: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Enter para fechar' | Out-Null
}
