param(
  [string]$PastaProjetos = 'C:\Projetos'
)

$ErrorActionPreference = 'Stop'
$PastaDestino = Join-Path $PSScriptRoot 'projetos'
$PastasDeSkills = @('.claude\skills', '.claude\commands', '.agents\skills')
$NomesGlobais = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'skills') -Directory | ForEach-Object Name

function Get-PastasDeSkillDosProjetos {
  Get-ChildItem -LiteralPath $PastaProjetos -Directory | Where-Object { $_.FullName -ne $PSScriptRoot } | ForEach-Object {
    $Raiz = $_.FullName
    Get-ChildItem -LiteralPath $Raiz -Directory -Recurse -Depth 2 -Force -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -notmatch '\\node_modules\\' } |
      ForEach-Object {
        foreach ($Relativo in $PastasDeSkills) {
          if ($_.FullName.EndsWith('\' + $Relativo, [StringComparison]::OrdinalIgnoreCase)) { $_ }
        }
      }
  }
}

function Get-NomeDoProjeto([string]$PastaDeSkill) {
  $Raiz = Split-Path (Split-Path $PastaDeSkill -Parent) -Parent
  return Split-Path $Raiz -Leaf
}

function Test-EhCopiaDeSkillGlobal($Item) {
  return $NomesGlobais -contains [IO.Path]::GetFileNameWithoutExtension($Item.Name)
}

if (Test-Path -LiteralPath $PastaDestino) {
  Remove-Item -LiteralPath $PastaDestino -Recurse -Force
}

Get-PastasDeSkillDosProjetos | ForEach-Object {
  $PastaDeSkill = $_.FullName
  $Projeto = Get-NomeDoProjeto $PastaDeSkill
  $Relativo = $PastaDeSkill.Substring((Split-Path (Split-Path $PastaDeSkill -Parent) -Parent).Length + 1)
  Get-ChildItem -LiteralPath $PastaDeSkill -Force | ForEach-Object {
    if (Test-EhCopiaDeSkillGlobal $_) {
      Write-Host "aviso: $Projeto tem copia da skill global '$($_.Name)' em $PastaDeSkill; remova do projeto"
      return
    }
    $Destino = Join-Path (Join-Path $PastaDestino $Projeto) $Relativo
    New-Item -ItemType Directory -Force $Destino | Out-Null
    Copy-Item -LiteralPath $_.FullName -Destination $Destino -Recurse -Force
    Write-Host "coletada  $Projeto\$Relativo\$($_.Name)"
  }
}
