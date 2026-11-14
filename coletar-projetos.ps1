param(
  [string]$PastaProjetos
)

$ErrorActionPreference = 'Stop'
$PastaDestino = Join-Path $PSScriptRoot 'projetos'
$ArquivoPastaSalva = Join-Path $PSScriptRoot '.pasta-projetos'
$PastasDeSkills = @('.claude\skills', '.claude\commands', '.agents\skills')
$NomesGlobais = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'skills') -Directory | ForEach-Object Name

function Get-PastaProjetos {
  if ($PastaProjetos) { $Pasta = $PastaProjetos }
  else {
    $Salva = if (Test-Path -LiteralPath $ArquivoPastaSalva) { (Get-Content -LiteralPath $ArquivoPastaSalva -Raw).Trim() } else { '' }
    $Pergunta = if ($Salva) { "Pasta dos projetos nesta maquina [$Salva]" } else { 'Pasta dos projetos nesta maquina' }
    $Pasta = (Read-Host $Pergunta).Trim().Trim('"')
    if (-not $Pasta) { $Pasta = $Salva }
  }
  if (-not $Pasta -or -not (Test-Path -LiteralPath $Pasta -PathType Container)) { throw "Pasta dos projetos nao encontrada: '$Pasta'" }
  $Pasta = (Resolve-Path -LiteralPath $Pasta).Path.TrimEnd('\')
  Set-Content -LiteralPath $ArquivoPastaSalva -Value $Pasta -Encoding UTF8
  return $Pasta
}

function Get-PastasDeSkillDosProjetos([string]$Raiz) {
  Get-ChildItem -LiteralPath $Raiz -Directory -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue |
    Where-Object {
      $_.FullName -notmatch '\\node_modules\\' -and
      -not $_.FullName.StartsWith($PSScriptRoot + '\', [StringComparison]::OrdinalIgnoreCase)
    } |
    ForEach-Object {
      foreach ($Relativo in $PastasDeSkills) {
        if ($_.FullName.EndsWith('\' + $Relativo, [StringComparison]::OrdinalIgnoreCase)) { $_ }
      }
    }
}

function Get-RaizDoProjeto([string]$PastaDeSkill) {
  return Split-Path (Split-Path $PastaDeSkill -Parent) -Parent
}

function Test-EhCopiaDeSkillGlobal($Item) {
  return $NomesGlobais -contains [IO.Path]::GetFileNameWithoutExtension($Item.Name)
}

$Raiz = Get-PastaProjetos
Write-Host "Coletando de $Raiz (nada e removido de projetos/; projetos de outras maquinas sao mantidos)"

Get-PastasDeSkillDosProjetos $Raiz | ForEach-Object {
  $PastaDeSkill = $_.FullName
  $RaizDoProjeto = Get-RaizDoProjeto $PastaDeSkill
  $Projeto = Split-Path $RaizDoProjeto -Leaf
  $Relativo = $PastaDeSkill.Substring($RaizDoProjeto.Length + 1)
  $Destino = Join-Path (Join-Path $PastaDestino $Projeto) $Relativo

  Get-ChildItem -LiteralPath $PastaDeSkill -Force | ForEach-Object {
    if (Test-EhCopiaDeSkillGlobal $_) {
      Write-Host "aviso: $Projeto tem copia da skill global '$($_.Name)' em $PastaDeSkill; remova do projeto"
      return
    }
    New-Item -ItemType Directory -Force $Destino | Out-Null
    Copy-Item -LiteralPath $_.FullName -Destination $Destino -Recurse -Force
    Write-Host "coletada  $Projeto\$Relativo\$($_.Name)"
  }

  if (Test-Path -LiteralPath $Destino) {
    Get-ChildItem -LiteralPath $Destino -Force | Where-Object { -not (Test-Path -LiteralPath (Join-Path $PastaDeSkill $_.Name)) } | ForEach-Object {
      Write-Host "aviso: $Projeto\$Relativo\$($_.Name) esta no repositorio mas nao no projeto local; se foi removida, apague de projetos/ manualmente"
    }
  }
}
