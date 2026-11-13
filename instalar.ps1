param(
  [string[]]$PastasGlobais = @(
    (Join-Path $env:USERPROFILE '.claude\skills'),
    (Join-Path $env:USERPROFILE '.codex\skills')
  )
)

$ErrorActionPreference = 'Stop'
$PastaSkills = Join-Path $PSScriptRoot 'skills'

function Test-JuncaoParaOrigem([string]$Destino, [string]$Origem) {
  $Item = Get-Item -LiteralPath $Destino -Force
  return ($Item.LinkType -eq 'Junction') -and ((@($Item.Target)[0]).TrimEnd('\') -ieq $Origem.TrimEnd('\'))
}

function Mover-ParaBackup([string]$PastaGlobal, [string]$Destino) {
  $PastaBackup = Join-Path (Split-Path $PastaGlobal -Parent) 'skills-backup'
  New-Item -ItemType Directory -Force $PastaBackup | Out-Null
  $Backup = Join-Path $PastaBackup ('{0}-{1:yyyyMMddHHmmss}' -f (Split-Path $Destino -Leaf), (Get-Date))
  Move-Item -LiteralPath $Destino -Destination $Backup
  Write-Host "  copia antiga movida para $Backup"
}

function Instalar-SkillsEm([string]$PastaGlobal) {
  Write-Host "== $PastaGlobal"
  New-Item -ItemType Directory -Force $PastaGlobal | Out-Null
  Get-ChildItem -LiteralPath $PastaSkills -Directory | ForEach-Object {
    $Origem = $_.FullName
    $Destino = Join-Path $PastaGlobal $_.Name
    if (Test-Path -LiteralPath $Destino) {
      if (Test-JuncaoParaOrigem $Destino $Origem) {
        Write-Host "ok        $($_.Name)"
        return
      }
      Mover-ParaBackup $PastaGlobal $Destino
    }
    New-Item -ItemType Junction -Path $Destino -Target $Origem | Out-Null
    Write-Host "instalada $($_.Name)"
  }
}

function Remover-JuncoesOrfas([string]$PastaGlobal) {
  Get-ChildItem -LiteralPath $PastaGlobal -Directory -Force |
    Where-Object { $_.LinkType -eq 'Junction' -and -not (Test-Path -LiteralPath (@($_.Target)[0])) } |
    ForEach-Object {
      Remove-Item -LiteralPath $_.FullName -Force
      Write-Host "removida  $($_.Name) (nao existe mais no repositorio)"
    }
}

foreach ($PastaGlobal in $PastasGlobais) {
  Instalar-SkillsEm $PastaGlobal
  Remover-JuncoesOrfas $PastaGlobal
}
