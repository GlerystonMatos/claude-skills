$ErrorActionPreference = 'Stop'

$Inicio = '# >>> iniciar-dashboard-frt'
$Fim = '# <<< iniciar-dashboard-frt'
$Bloco = @'
# >>> iniciar-dashboard-frt
function Open-DashboardFrt {
    $email = Read-Host 'E-mail'
    $senhaSegura = Read-Host 'Senha' -AsSecureString
    $senha = [System.Net.NetworkCredential]::new('', $senhaSegura).Password
    $corpo = [System.Text.Encoding]::UTF8.GetBytes((@{ email = $email; senha = $senha } | ConvertTo-Json -Compress))
    $senha = $null
    try {
        $r = Invoke-RestMethod -Method Post `
            -Uri 'https://dashboard-frt-api.veica.com.br/Login/Authenticate' `
            -ContentType 'application/json; charset=utf-8' `
            -Body $corpo `
            -ErrorAction Stop
    } finally {
        $corpo = $null
    }

    Start-Process "https://dashboard-frt.veica.com.br/?token=$([uri]::EscapeDataString($r.token))"
}

Set-Alias -Name iniciar-dashboard-frt -Value Open-DashboardFrt
# <<< iniciar-dashboard-frt
'@

$Perfis = @($PROFILE.CurrentUserCurrentHost)
$Pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
if ($Pwsh) { $Perfis += (& $Pwsh.Source -NoProfile -Command '$PROFILE.CurrentUserCurrentHost') }

foreach ($Perfil in $Perfis) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $Perfil) -Force | Out-Null
    $Atual = if (Test-Path -LiteralPath $Perfil) { [System.IO.File]::ReadAllText($Perfil) } else { '' }

    $SemMarcado = [regex]::Replace($Atual, "(?ms)^$([regex]::Escape($Inicio)).*?^$([regex]::Escape($Fim))[^\n]*\n?", '')
    $SemAntigo = [regex]::Replace($SemMarcado, '(?ms)^function Open-DashboardFrt \{.*?^Set-Alias -Name iniciar-dashboard-frt -Value Open-DashboardFrt[^\n]*\n?', '')
    $Novo = $SemAntigo.TrimEnd() + $(if ($SemAntigo.Trim()) { "`r`n`r`n" } else { '' }) + ($Bloco -replace "`r?`n", "`r`n") + "`r`n"

    if ($Novo -eq $Atual) {
        Write-Host "ok          $Perfil"
        continue
    }
    $Situacao = if ($SemAntigo -ne $SemMarcado) { 'substituido (versao antiga com credenciais gravadas removida)' } elseif ($SemMarcado -ne $Atual) { 'atualizado' } else { 'instalado' }
    [System.IO.File]::WriteAllText($Perfil, $Novo, [System.Text.UTF8Encoding]::new($true))
    Write-Host "$Situacao  $Perfil"
}
