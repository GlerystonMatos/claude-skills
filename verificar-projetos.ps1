param(
  [string]$PastaProjetos
)

$ErrorActionPreference = 'Stop'
$PastaConfiguracoes = Join-Path $PSScriptRoot 'projetos'
$ArquivoPastaSalva = Join-Path $PSScriptRoot '.pasta-projetos'
$PastasDeSkills = @('.claude\skills', '.claude\commands', '.agents\skills')
$NomesGlobais = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'skills') -Directory | ForEach-Object Name
$Avisos = 0

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

function Get-RepositoriosDosProjetos([string]$Raiz) {
  Get-ChildItem -LiteralPath $Raiz -Directory -Recurse -Depth 3 -Force -Filter '.git' -ErrorAction SilentlyContinue |
    Where-Object {
      $_.FullName -notmatch '\\node_modules\\' -and
      -not $_.FullName.StartsWith($PSScriptRoot + '\', [StringComparison]::OrdinalIgnoreCase)
    } |
    ForEach-Object { $_.Parent }
}

function Get-NomeDoRepositorio([string]$Pasta) {
  $Remoto = (& git -C $Pasta remote get-url origin 2>$null)
  if ($LASTEXITCODE -eq 0 -and $Remoto) { return ([IO.Path]::GetFileName($Remoto.Trim().TrimEnd('/'))) -replace '\.git$', '' }
  return Split-Path $Pasta -Leaf
}

function Write-Aviso([string]$Texto) {
  Write-Host "aviso: $Texto"
  $script:Avisos++
}

Write-Host 'Verificando o claude-skills'
& node (Join-Path $PSScriptRoot 'scripts\verificar-repositorio.mjs')
if ($LASTEXITCODE -ne 0) { $Avisos++ }

$Raiz = Get-PastaProjetos
Write-Host "Verificando os projetos em $Raiz (nada e copiado nem removido)"
$Encontrados = @{}

Get-RepositoriosDosProjetos $Raiz | ForEach-Object {
  $Pasta = $_.FullName
  $Repo = Get-NomeDoRepositorio $Pasta
  $Encontrados[$Repo] = $Pasta

  foreach ($Relativo in $PastasDeSkills) {
    $PastaDeSkill = Join-Path $Pasta $Relativo
    if (-not (Test-Path -LiteralPath $PastaDeSkill)) { continue }
    Get-ChildItem -LiteralPath $PastaDeSkill -Force | ForEach-Object {
      $Nome = [IO.Path]::GetFileNameWithoutExtension($_.Name)
      if ($NomesGlobais -contains $Nome) {
        Write-Aviso "$Repo tem a skill local '$Nome' em $Relativo, que e global e a esconde; remova do projeto"
      } else {
        Write-Aviso "$Repo tem a skill local '$Nome' em $Relativo; leve para skills/ (se servir a outros projetos) ou para projetos/$Repo/"
      }
    }
  }
}

Get-ChildItem -LiteralPath $PastaConfiguracoes -Directory | Where-Object { -not $Encontrados.ContainsKey($_.Name) } | ForEach-Object {
  Write-Host "info:  projetos/$($_.Name) nao tem repositorio local nesta maquina (o nome vem do remote origin); se o projeto acabou, apague a pasta"
}

if ($Avisos -eq 0) { Write-Host 'Tudo certo: claude-skills consistente e nenhuma skill local nos projetos.' }
