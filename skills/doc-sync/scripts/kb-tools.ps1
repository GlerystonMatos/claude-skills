<#
  Ferramentas da skill doc-sync (base docs-kb de um sistema).
  Uso: powershell -NoProfile -ExecutionPolicy Bypass -File "<pasta da skill>/scripts/kb-tools.ps1" <acao>
  Configuração do projeto: <claude-skills>/projetos/<repo>/doc-sync/config.json (sistema, objetivo, sigilo dos públicos,
  exceções de par, arquivos de controle e ações extras do projeto). Sem ela, valem os padrões genéricos.
  Ações:
    detectar     -> compara o estado atual (commits desde a última execução + stage + worktree + não rastreados)
                    com os hashes gravados na última execução; grava docs-kb/_mudancas.json e mostra o resumo.
    check        -> valida front matter, pares público/-dev, fontes, links, sigilo dos públicos, segredos e tamanho.
    para-enviar  -> compara os docs de docs-kb/upload com a última execução e gera docs-kb/_para-enviar.md.
    readme       -> regenera docs-kb/README.md (explicação e índice de todos os arquivos).
    manifest     -> grava docs-kb/_manifest.json (commit, data, histórico de execuções, fontes e hashes).
    finalizar    -> para-enviar + readme + manifest (nessa ordem), ao fim de cada execução da skill.
    <extra>      -> ação própria do projeto, declarada em acoesExtras da configuração (ex.: auditoria no Cargas); o script dela
                    roda aqui dentro (dot-source), com as funções e variáveis deste arquivo.
#>
param(
  [Parameter(Mandatory = $true)][string]$Acao
)
$ErrorActionPreference = 'Stop'
$Repo = (git rev-parse --show-toplevel).Trim() -replace '/', '\'
$kb = Join-Path $Repo 'docs-kb'
$up = Join-Path $kb 'upload'
$sup = Join-Path $up 'suporte'
$dev = Join-Path $up 'desenvolvimento'
$manPath = Join-Path $kb '_manifest.json'
$utf8 = New-Object Text.UTF8Encoding($false)
$ignorar = '(^|/)(node_modules|build|dist|target|bin|obj|__history|\.git|\.vs|docs-kb|\.claude)(/|$)|^(CLAUDE|README)\.md$'
$Central = (git -C $PSScriptRoot rev-parse --show-toplevel).Trim() -replace '/', '\'
$Remoto = (git -C $Repo remote get-url origin 2>$null)
$NomeRepo = if ($Remoto) { ([IO.Path]::GetFileName($Remoto.Trim().TrimEnd('/'))) -replace '\.git$', '' } else { Split-Path $Repo -Leaf }
$PastaConfig = Join-Path $Central "projetos\$NomeRepo\doc-sync"
$ArquivoConfig = Join-Path $PastaConfig 'config.json'
$Config = if (Test-Path $ArquivoConfig) { [IO.File]::ReadAllText($ArquivoConfig, (New-Object Text.UTF8Encoding($false))) | ConvertFrom-Json } else { $null }
$Sistema = if ($Config -and $Config.sistema) { $Config.sistema } else { $NomeRepo }
# nomes de clientes que não podem aparecer nos docs públicos (regex, alternativas com |); amplie na configuração ao encontrar novos
$clientesNoPublico = if ($Config -and $Config.clientesNoPublico) { $Config.clientesNoPublico } else { '' }
$acoesGenericas = 'detectar', 'check', 'para-enviar', 'readme', 'manifest', 'finalizar'
$gerados = '\.(exe|dll|bpl|dcu|dcp|res|dres|rsm|map|tds|identcache|local|dsk|~\w*|bak|zip|7z|pdf|png|jpg|jpeg|gif|ico|bmp)$'

function ReadT($p) { [IO.File]::ReadAllText($p, $utf8) }
function WriteT($p, $t) {
  $t = ($t.TrimStart([char]0xFEFF) -replace "`r?`n", "`r`n"); if (-not $t.EndsWith("`r`n")) { $t += "`r`n" }
  $d = Split-Path $p; if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force $d | Out-Null }
  [IO.File]::WriteAllText($p, $t, $utf8)
}
function RelKb($p) { $p.Substring($kb.Length + 1) -replace '\\', '/' }
function RelRepo($p) { $p.Substring($Repo.Length + 1) -replace '\\', '/' }
function RelPath($fromDir, $to) {
  $u1 = New-Object Uri(($fromDir.TrimEnd('\') + '\'))
  [Uri]::UnescapeDataString($u1.MakeRelativeUri((New-Object Uri($to))).ToString())
}
function FrontMatter($t) {
  $h = [ordered]@{}
  if ($t -match '(?s)^﻿?---\r?\n(.*?)\r?\n---') { foreach ($l in $matches[1] -split "`r?`n") { if ($l -match '^(\w+):\s*(.*)$') { $h[$matches[1]] = $matches[2].Trim() } } }
  $h
}
function ListaFontes($v) { if ($v -match '^\[(.*)\]$') { @($matches[1].Split(',') | ForEach-Object { $_.Trim().Trim('"', "'") } | Where-Object { $_ }) } else { @() } }
function Docs { if (Test-Path $up) { Get-ChildItem $up -Recurse -Filter *.md | Sort-Object FullName } }
function LerManifest { if (Test-Path $manPath) { ReadT $manPath | ConvertFrom-Json } else { $null } }
function MapaObj($o) { $h = @{}; if ($o) { foreach ($p in $o.psobject.Properties) { $h[$p.Name] = $p.Value } }; $h }
function HashArquivos([string[]]$rels) {
  $h = @{}; $ex = @($rels | Where-Object { $_ -and (Test-Path (Join-Path $Repo ($_ -replace '/', '\'))) } | Sort-Object -Unique)
  # hash de blob do git (sha1 de "blob <tamanho>\0<conteúdo>"), calculado aqui para aceitar qualquer caminho/encoding
  $sha = [Security.Cryptography.SHA1]::Create()
  foreach ($r in $ex) {
    $b = [IO.File]::ReadAllBytes((Join-Path $Repo ($r -replace '/', '\')))
    $hd = [Text.Encoding]::ASCII.GetBytes("blob $($b.Length)`0")
    $all = New-Object byte[] ($hd.Length + $b.Length); [Array]::Copy($hd, $all, $hd.Length); [Array]::Copy($b, 0, $all, $hd.Length, $b.Length)
    $h[$r] = ([BitConverter]::ToString($sha.ComputeHash($all)) -replace '-', '').ToLower()
  }
  $h
}
function HashDoc($p) { $s = [Security.Cryptography.SHA1]::Create(); ([BitConverter]::ToString($s.ComputeHash([IO.File]::ReadAllBytes($p))) -replace '-', '').ToLower() }
function IndiceFontes {
  # arquivo de código -> docs -dev que o citam
  $idx = @{}
  foreach ($d in Docs | Where-Object { $_.BaseName -like '*-dev' }) {
    foreach ($f in ListaFontes (FrontMatter (ReadT $d.FullName))['fontes']) { if ($f -notlike 'docs-kb/*') { if (-not $idx[$f]) { $idx[$f] = @() }; $idx[$f] += (RelKb $d.FullName) } }
  }
  $idx
}
function ParPublico($devRel) { ($devRel -replace '^upload/desenvolvimento/', 'upload/suporte/') -replace '-dev\.md$', '.md' }

switch ($Acao) {

  default {
    $extra = if ($Config -and $Config.acoesExtras) { $Config.acoesExtras.$Acao } else { $null }
    if (-not $extra) {
      $extras = if ($Config -and $Config.acoesExtras) { @($Config.acoesExtras.psobject.Properties.Name) } else { @() }
      throw "Ação desconhecida: $Acao. Genéricas: $($acoesGenericas -join ', ')$(if ($extras) { "; do projeto: $($extras -join ', ')" })"
    }
    . (Join-Path $PastaConfig $extra)
  }

  'detectar' {
    $man = LerManifest
    if (-not $man) { throw 'docs-kb/_manifest.json não existe: a documentação inicial ainda não foi gerada.' }
    $base = $man.commit
    $git = @()
    $commitOk = $true
    git -C $Repo cat-file -e "$base^{commit}" 2>$null; if ($LASTEXITCODE -ne 0) { $commitOk = $false }
    if ($commitOk) { $git += git -C $Repo diff --name-only "$base..HEAD" }
    $git += git -C $Repo diff --name-only --cached
    $git += git -C $Repo diff --name-only
    $git += git -C $Repo ls-files --others --exclude-standard
    $hashAnt = MapaObj $man.hashes
    $cand = @($git + @($hashAnt.Keys)) | Where-Object { $_ -and $_ -notmatch $ignorar -and $_ -notmatch $gerados } | Sort-Object -Unique
    $hashAtual = HashArquivos $cand
    $idx = IndiceFontes
    $mapaArq = @{}; $csv = Join-Path $kb '_mapa-arquivos.csv'
    if (Test-Path $csv) { foreach ($l in [IO.File]::ReadAllLines($csv, $utf8) | Select-Object -Skip 1) { $c = $l.Split(';'); if ($c.Count -ge 2) { $mapaArq[$c[1]] = $c[0] } } }
    $alt = @(); $nov = @(); $rem = @(); $semDoc = @()
    foreach ($f in $cand) {
      $existe = $hashAtual.ContainsKey($f); $tinha = $hashAnt.ContainsKey($f)
      if (-not $existe) { if ($tinha -or $idx[$f]) { $rem += $f }; continue }
      if ($tinha -and $hashAnt[$f] -eq $hashAtual[$f]) { continue }   # já processado na última execução
      if ($idx[$f]) { $alt += $f } elseif ($tinha) { $semDoc += $f } else { $nov += $f }
    }
    $docsAlt = @($alt | ForEach-Object { $idx[$_] } | Sort-Object -Unique)
    $docsObs = @($rem | ForEach-Object { $idx[$_] } | Where-Object { $_ } | Sort-Object -Unique)
    $res = [ordered]@{
      ultimaExecucao = [ordered]@{ commit = $base; data = $man.geradoEm; commitNoHistorico = $commitOk }
      head = (git -C $Repo rev-parse HEAD).Trim()
      arquivosAlterados = @($alt); arquivosNovosSemDoc = @($nov | ForEach-Object { [ordered]@{ arquivo = $_; moduloProvavel = $mapaArq[$_] } })
      arquivosAlteradosSemDoc = @($semDoc); arquivosRemovidos = @($rem)
      docsARegenerar = @($docsAlt | ForEach-Object { [ordered]@{ dev = $_; publico = (ParPublico $_) } })
      docsPossivelmenteObsoletos = @($docsObs | ForEach-Object { [ordered]@{ dev = $_; publico = (ParPublico $_) } })
    }
    WriteT (Join-Path $kb '_mudancas.json') ($res | ConvertTo-Json -Depth 6)
    if (-not $commitOk) { "AVISO: o commit da última execução ($base) não existe mais no histórico; sugerir 'full'." }
    "última execução: $($man.geradoEm) @ $base"
    "arquivos alterados com doc: $($alt.Count) | novos sem doc: $($nov.Count) | alterados sem doc: $($semDoc.Count) | removidos: $($rem.Count)"
    "pares a regenerar: $($docsAlt.Count) | possivelmente obsoletos: $($docsObs.Count)"
    'detalhes: docs-kb/_mudancas.json'
  }

  'check' {
    $req = 'sistema', 'modulo', 'tipo', 'fontes', 'commit', 'categoria_sugerida', 'confidencialidade'
    $pub = [ordered]@{ 'arquivo-fonte' = '\b\w+\.(pas|dfm|dpr|dproj|sql|cs|tsx?|java|py|go|rb|php)\b' }
    if ($Config -and $Config.publicoProibido) { foreach ($p in $Config.publicoProibido.psobject.Properties) { $pub[$p.Name] = $p.Value } }
    $pub['sql'] = '\b(SELECT\s+.+\s+FROM|INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM|CREATE\s+TABLE)\b'
    if ($clientesNoPublico) { $pub['cliente'] = "(?i)\b($clientesNoPublico)\b" }
    $pub['link-dev'] = '-dev\.md'
    $urlsPermitidas = if ($Config -and $Config.urlsPermitidas) { "(?!$($Config.urlsPermitidas))" } else { '' }
    $sec = [ordered]@{
      'url'        = "https?://$urlsPermitidas[^\s)``>\]]+"
      'credencial' = '(?i)\b(senha|password|passwd|pwd|token|secret|app_?key|api_?key|client_?secret)\b\s*[:=]\s*[''"][^''"]{4,}[''"]'
      'guid'       = '\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b'
    }
    $par_excecoes = if ($Config -and $Config.excecoesDePar) { @($Config.excecoesDePar) } else { @() }
    $iss = New-Object System.Collections.Generic.List[object]
    function Add($f, $k, $m) { $iss.Add([pscustomobject]@{ Arquivo = $f; Tipo = $k; Detalhe = $m }) }
    foreach ($d in Docs) {
      $rel = RelKb $d.FullName; $t = ReadT $d.FullName; $h = FrontMatter $t
      $isDev = $d.FullName -like "$dev\*"
      if ($isDev -ne ($d.BaseName -like '*-dev')) { Add $rel 'pasta' 'sufixo -dev e pasta não conferem' }
      foreach ($k in $req) { if (-not $h[$k]) { Add $rel 'front-matter' "falta $k" } }
      $body = $t -replace '(?s)^﻿?---.*?\r?\n---\r?\n', ''
      $fontes = ListaFontes $h['fontes']
      foreach ($f in $fontes) { if (-not (Test-Path (Join-Path $Repo ($f -replace '/', '\')))) { Add $rel 'fonte-inexistente' $f } }
      if ($isDev) {
        if ($h['confidencialidade'] -ne 'restrito-desenvolvimento' -or $h['categoria_sugerida'] -ne 'Desenvolvimento') { Add $rel 'sigilo' 'front matter de -dev incorreto' }
        $p = Join-Path $Repo ((ParPublico $rel) -replace '^', 'docs-kb/' -replace '/', '\')
        if (-not (Test-Path $p) -and $par_excecoes -notcontains $rel) { Add $rel 'par' 'sem público' }
      } else {
        if ($h['confidencialidade'] -ne 'interno' -or $h['categoria_sugerida'] -ne 'Suporte') { Add $rel 'sigilo' 'front matter de público incorreto' }
        if ($fontes | Where-Object { $_ -notlike 'docs-kb/upload/desenvolvimento/*-dev.md' }) { Add $rel 'sigilo' 'fontes de código no público' }
        $p = Join-Path $dev (($d.FullName.Substring($sup.Length + 1)) -replace '\.md$', '-dev.md')
        if (-not (Test-Path $p) -and $par_excecoes -notcontains $rel) { Add $rel 'par' 'sem -dev' }
        foreach ($k in $pub.Keys) { foreach ($m in [regex]::Matches($body, $pub[$k]) | Select-Object -First 3) { Add $rel "publico:$k" $m.Value } }
      }
      foreach ($k in $sec.Keys) { foreach ($m in [regex]::Matches($body, $sec[$k]) | Select-Object -First 3) { Add $rel "segredo:$k" $m.Value } }
      $w = ([regex]::Matches($body, '\S+')).Count; if ($w -gt 1600) { Add $rel 'tamanho' "$w palavras" }
      foreach ($m in [regex]::Matches($body, '\]\(([^)#\s]+\.md)')) { if (-not (Test-Path (Join-Path $d.DirectoryName ($m.Groups[1].Value -replace '/', '\')))) { Add $rel 'link-quebrado' $m.Groups[1].Value } }
    }
    $all = @(Docs)
    "docs: $($all.Count) | suporte: $(@($all | Where-Object { $_.FullName -like "$sup\*" }).Count) | desenvolvimento: $(@($all | Where-Object { $_.FullName -like "$dev\*" }).Count)"
    if ($iss.Count -eq 0) { 'nenhum problema encontrado' } else { $iss | Format-Table -AutoSize | Out-String -Width 220 }
  }

  { $_ -in 'para-enviar', 'finalizar' } {
    $man = LerManifest; $ant = @{}
    if ($man -and $man.docs) { foreach ($x in $man.docs) { if ($x.hash) { $ant[$x.caminho] = $x.hash } } }
    $nov = @(); $alt = @(); $obs = @()
    foreach ($d in Docs) {
      $rel = RelKb $d.FullName; $hh = HashDoc $d.FullName
      if ((FrontMatter (ReadT $d.FullName))['obsoleto'] -eq 'true') { $obs += $rel; continue }
      if (-not $ant.ContainsKey($rel)) { $nov += $rel } elseif ($ant[$rel] -ne $hh) { $alt += $rel }
    }
    foreach ($k in $ant.Keys) { if (-not (Test-Path (Join-Path $kb ($k -replace '/', '\')))) { $obs += "$k (removido)" } }
    function Bloco($titulo, $lista) {
      $lista = @($lista | Where-Object { $_ })
      $s = "### $titulo ($(@($lista).Count))`r`n`r`n"
      if (@($lista).Count -eq 0) { return $s + "_nenhum_`r`n`r`n" }
      $s + ((@($lista) | ForEach-Object { '- `' + ($_ -replace '^upload/', '') + '`' }) -join "`r`n") + "`r`n`r`n"
    }
    $g = { param($l, $pasta) @($l | Where-Object { $_ -like "upload/$pasta/*" }) }
    $md = "# Arquivos para enviar ao Google Drive`r`n`r`n" +
    "Gerado em $(Get-Date -Format 'yyyy-MM-dd HH:mm') (commit $((git -C $Repo rev-parse --short HEAD).Trim())). Caminhos relativos a ``docs-kb/upload/``. Arquivo de controle: não enviar.`r`n`r`n" +
    "## Pasta do Drive: suporte (público)`r`n`r`n" + (Bloco 'Novos' (& $g $nov 'suporte')) + (Bloco 'Alterados' (& $g $alt 'suporte')) + (Bloco 'Obsoletos — remover no Drive' (& $g $obs 'suporte')) +
    "## Pasta do Drive: desenvolvimento (restrita)`r`n`r`n" + (Bloco 'Novos' (& $g $nov 'desenvolvimento')) + (Bloco 'Alterados' (& $g $alt 'desenvolvimento')) + (Bloco 'Obsoletos — remover no Drive' (& $g $obs 'desenvolvimento'))
    WriteT (Join-Path $kb '_para-enviar.md') $md
    "para enviar: novos $($nov.Count) | alterados $($alt.Count) | obsoletos $($obs.Count) -> docs-kb/_para-enviar.md"
    if ($Acao -eq 'finalizar') { & $PSCommandPath readme; & $PSCommandPath manifest }
  }

  'readme' {
    $desc = @{
      'modulos' = 'Visão de cada módulo funcional: propósito, telas, entidades, regras, integrações e telas não detalhadas.'
      'entidades' = 'Conceitos de negócio (cadastros e documentos) — no público, significado e ciclo de vida; no -dev, campos, chaves e relações no banco.'
      'telas' = 'Uma tela por arquivo (`<modulo>--<tela>`): caminho de menu, permissões, campos, ações e regras.'
      'processos' = 'Fluxos complexos: objetivo, gatilho, passos, estados, regras, integrações e efeitos.'
    }
    $s = New-Object Text.StringBuilder
    [void]$s.AppendLine("# docs-kb — Base de conhecimento do sistema $Sistema")
    [void]$s.AppendLine()
    [void]$s.AppendLine("Atualizado em $(Get-Date -Format 'yyyy-MM-dd HH:mm') (commit $((git -C $Repo rev-parse --short HEAD).Trim())). Este arquivo é regenerado pela skill ``/doc-sync`` a cada execução; não edite à mão.")
    [void]$s.AppendLine()
    [void]$s.AppendLine('## Objetivo')
    [void]$s.AppendLine()
    $objetivo = if ($Config -and $Config.objetivo) { $Config.objetivo } else { "A pasta ``docs-kb/`` guarda a documentação do sistema $Sistema gerada a partir do código-fonte, para servir de base de conhecimento. Cada afirmação vem do código e é marcada como `"Confirmado no código`" ou `"Inferido (verificar)`". O envio ao Google Drive é manual." }
    [void]$s.AppendLine($objetivo)
    [void]$s.AppendLine()
    if ($Config -and $Config.porqueNome) {
      [void]$s.AppendLine('## Por que o nome docs-kb')
      [void]$s.AppendLine()
      [void]$s.AppendLine($Config.porqueNome)
      [void]$s.AppendLine()
    }
    [void]$s.AppendLine('## Organização e sigilo')
    [void]$s.AppendLine()
    [void]$s.AppendLine('- `upload/` contém **somente** o que vai para o Drive, separado por público:')
    [void]$s.AppendLine('  - `upload/suporte/` — conteúdo funcional (regras de negócio, telas, campos, fluxos), `categoria_sugerida: Suporte`, `confidencialidade: interno`. Sem nomes técnicos, defeitos, permissões especiais, nomes internos ou de clientes.')
    [void]$s.AppendLine('  - `upload/desenvolvimento/` — conteúdo **sigiloso**, só para o desenvolvimento: código (classes, métodos, arquivos), arquitetura, estrutura do banco, leiautes, possíveis defeitos e riscos de segurança. Arquivos com sufixo `-dev`, `categoria_sugerida: Desenvolvimento`, `confidencialidade: restrito-desenvolvimento`.')
    [void]$s.AppendLine('- Todo documento existe em par com o mesmo caminho: `suporte/<pasta>/<nome>.md` ↔ `desenvolvimento/<pasta>/<nome>-dev.md`. O `fontes` do público aponta para o par `-dev`; o do `-dev` lista os arquivos de código.')
    [void]$s.AppendLine('- Arquivos de controle ficam na raiz de `docs-kb/` (prefixo `_` e este README) e **não** vão para o Drive.')
    [void]$s.AppendLine()
    [void]$s.AppendLine('## Arquivos de controle (raiz de docs-kb, não enviar)')
    [void]$s.AppendLine()
    [void]$s.AppendLine('| Arquivo | Conteúdo |')
    [void]$s.AppendLine('|---|---|')
    $ctl = [ordered]@{
      'README.md' = 'Este arquivo: objetivo, organização e índice de todos os arquivos.'
      '_manifest.json' = 'Controle da skill: commit e data da última execução, histórico de execuções, fontes e hash de cada doc e hash de cada arquivo de código já processado.'
      '_para-enviar.md' = 'Lista do que enviar/remover no Drive desde a execução anterior (novos, alterados, obsoletos), por pasta.'
      '_mudancas.json' = 'Resultado da última detecção de mudanças (arquivos de código e pares de docs afetados).'
      '_mapa.md' = 'Mapa técnico inicial do repositório (stack, módulos, processos). Sigiloso.'
      '_mapa-arquivos.csv' = 'Cada arquivo de código → módulo. Usado para localizar o módulo de arquivos novos.'
    }
    if ($Config -and $Config.arquivosDeControle) { foreach ($p in $Config.arquivosDeControle.psobject.Properties) { $ctl[$p.Name] = $p.Value } }
    foreach ($k in $ctl.Keys) { if (Test-Path (Join-Path $kb $k)) { [void]$s.AppendLine("| ``$k`` | $($ctl[$k]) |") } }
    [void]$s.AppendLine()
    $all = @(Docs)
    [void]$s.AppendLine("## Conteúdo de upload/ ($($all.Count) arquivos)")
    [void]$s.AppendLine()
    foreach ($raiz in @(@{ n = 'suporte'; p = $sup }, @{ n = 'desenvolvimento'; p = $dev })) {
      $da = @($all | Where-Object { $_.FullName -like "$($raiz.p)\*" })
      [void]$s.AppendLine("### upload/$($raiz.n)/ ($($da.Count) arquivos)")
      [void]$s.AppendLine()
      $grupos = $da | Group-Object { $r = $_.FullName.Substring($raiz.p.Length + 1); if ($r -match '\\') { $r.Split('\')[0] } else { '.' } } | Sort-Object Name
      foreach ($g in $grupos) {
        $titulo = if ($g.Name -eq '.') { "upload/$($raiz.n)/ (raiz)" } else { "upload/$($raiz.n)/$($g.Name)/" }
        [void]$s.AppendLine("#### $titulo ($($g.Count))")
        [void]$s.AppendLine()
        if ($desc[$g.Name]) { [void]$s.AppendLine($desc[$g.Name]); [void]$s.AppendLine() }
        [void]$s.AppendLine('| Arquivo | Módulo | Conteúdo |')
        [void]$s.AppendLine('|---|---|---|')
        foreach ($d in $g.Group) {
          $t = ReadT $d.FullName; $h = FrontMatter $t
          $tit = if ($t -match '(?m)^#\s+(.+)$') { ($matches[1] -replace "^$([regex]::Escape($Sistema))\s*[—-]\s*", '').Trim() } else { '' }
          [void]$s.AppendLine("| ``$($d.Name)`` | $($h['modulo']) | $($tit -replace '\|', '/') |")
        }
        [void]$s.AppendLine()
      }
    }
    WriteT (Join-Path $kb 'README.md') $s.ToString()
    "README atualizado: $($all.Count) arquivos indexados"
  }

  'manifest' {
    $man = LerManifest
    $hist = @(); if ($man -and $man.execucoes) { $hist = @($man.execucoes) }
    $commit = (git -C $Repo rev-parse HEAD).Trim()
    $staged = @(git -C $Repo diff --name-only --cached | Where-Object { $_ -notmatch $ignorar }).Count
    $wt = @(git -C $Repo diff --name-only | Where-Object { $_ -notmatch $ignorar }).Count
    $agora = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK')
    $items = @(); $todasFontes = @()
    foreach ($d in Docs) {
      $h = FrontMatter (ReadT $d.FullName); $f = ListaFontes $h['fontes']
      $todasFontes += $f | Where-Object { $_ -notlike 'docs-kb/*' }
      $o = [ordered]@{ caminho = (RelKb $d.FullName); confidencialidade = $h['confidencialidade']; fontes = @($f); hash = (HashDoc $d.FullName) }
      if ($h['obsoleto'] -eq 'true') { $o.obsoleto = $true }
      $items += $o
    }
    # hashes: fontes dos docs + arquivos já avaliados (mudanças sem doc), para não reprocessar na próxima execução
    $avaliados = @(); $mj = Join-Path $kb '_mudancas.json'
    if (Test-Path $mj) { $mu = ReadT $mj | ConvertFrom-Json; $avaliados = @($mu.arquivosAlteradosSemDoc) + @($mu.arquivosNovosSemDoc | ForEach-Object { $_.arquivo }) }
    $hashAnt = if ($man) { MapaObj $man.hashes } else { @{} }
    $hashes = HashArquivos (@($todasFontes) + $avaliados + @($hashAnt.Keys))
    $hashesOrd = [ordered]@{}; foreach ($k in $hashes.Keys | Sort-Object) { $hashesOrd[$k] = $hashes[$k] }
    $hist += [ordered]@{ commit = $commit; data = $agora; arquivosEmStage = $staged; arquivosAlteradosNoWorktree = $wt }
    $hist = @($hist | Select-Object -Last 30)
    $novo = [ordered]@{ commit = $commit; geradoEm = $agora; execucoes = $hist; docs = $items; hashes = $hashesOrd }
    WriteT $manPath ($novo | ConvertTo-Json -Depth 6)
    "manifest: $($items.Count) docs, $($hashesOrd.Count) arquivos de código com hash, commit $commit"
  }
}
