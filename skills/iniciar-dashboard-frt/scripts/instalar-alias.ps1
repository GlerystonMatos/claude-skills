$ErrorActionPreference = 'Stop'

$Inicio = '# >>> iniciar-dashboard-frt'
$Fim = '# <<< iniciar-dashboard-frt'
$Bloco = @'
# >>> iniciar-dashboard-frt
function Open-DashboardFrt {
    param([switch]$Redefinir)

    $arquivo = Join-Path $env:APPDATA 'iniciar-dashboard-frt\credencial.xml'
    if ($Redefinir -and (Test-Path -LiteralPath $arquivo)) { Remove-Item -LiteralPath $arquivo -Force }

    $salva = Test-Path -LiteralPath $arquivo
    if ($salva) {
        $credencial = Import-Clixml -LiteralPath $arquivo
    } else {
        $email = Read-Host 'E-mail'
        $senhaSegura = Read-Host 'Senha' -AsSecureString
        $credencial = [System.Management.Automation.PSCredential]::new($email, $senhaSegura)
    }

    $corpo = [System.Text.Encoding]::UTF8.GetBytes((@{ email = $credencial.UserName; senha = $credencial.GetNetworkCredential().Password } | ConvertTo-Json -Compress))
    try {
        $r = Invoke-RestMethod -Method Post `
            -Uri 'https://dashboard-frt-api.veica.com.br/Login/Authenticate' `
            -ContentType 'application/json; charset=utf-8' `
            -Body $corpo `
            -ErrorAction Stop
    } catch {
        $status = [int]$_.Exception.Response.StatusCode
        if ($salva -and $status -ge 400 -and $status -lt 500) {
            Remove-Item -LiteralPath $arquivo -Force
            Write-Host 'Login recusado com a credencial salva; ela foi apagada e sera pedida de novo.' -ForegroundColor Yellow
        }
        throw
    } finally {
        $corpo = $null
    }

    if (-not $salva) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $arquivo) -Force | Out-Null
        $credencial | Export-Clixml -LiteralPath $arquivo
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

$CredencialAntiga = Join-Path $env:APPDATA 'iniciar-dashboard-frtcredencial.xml'
$CredencialNova = Join-Path $env:APPDATA 'iniciar-dashboard-frt\credencial.xml'
if ((Test-Path -LiteralPath $CredencialAntiga) -and -not (Test-Path -LiteralPath $CredencialNova)) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $CredencialNova) -Force | Out-Null
    Move-Item -LiteralPath $CredencialAntiga -Destination $CredencialNova
    Write-Host "credencial salva movida para $CredencialNova"
}
