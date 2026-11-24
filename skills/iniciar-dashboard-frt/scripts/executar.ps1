try {
    iniciar-dashboard-frt
} catch {
    Write-Host "Falha ao abrir o dashboard: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Enter para fechar' | Out-Null
}
