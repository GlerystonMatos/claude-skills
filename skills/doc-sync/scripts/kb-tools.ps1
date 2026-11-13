<#
  Ferramentas da skill doc-sync (base docs-kb do sistema Cargas).
  Uso: powershell -NoProfile -ExecutionPolicy Bypass -File .claude/skills/doc-sync/scripts/kb-tools.ps1 <acao>
  Ações:
    detectar     -> compara o estado atual (commits desde a última execução + stage + worktree + não rastreados)
                    com os hashes gravados na última execução; grava docs-kb/_mudancas.json e mostra o resumo.
    check        -> valida front matter, pares público/-dev, fontes, links, sigilo dos públicos, segredos e tamanho.
    para-enviar  -> compara os docs de docs-kb/upload com a última execução e gera docs-kb/_para-enviar.md.
    readme       -> regenera docs-kb/README.md (explicação e índice de todos os arquivos).
    manifest     -> grava docs-kb/_manifest.json (commit, data, histórico de execuções, fontes e hashes).
    finalizar    -> para-enviar + readme + manifest (nessa ordem), ao fim de cada execução da skill.
    auditoria    -> regenera o catálogo completo das operações de auditoria (pares em upload/*/processos/
                    auditoria-catalogo-de-operacoes*) a partir de cargas/Fontes/KrAudit.pas e KrConst.pas, com as
                    units que referenciam cada constante. Só regrava os arquivos cujo conteúdo mudou.
#>
param(
  [Parameter(Mandatory = $true)][ValidateSet('detectar', 'check', 'para-enviar', 'readme', 'manifest', 'finalizar', 'mover', 'auditoria')]
  [string]$Acao
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
# nomes de clientes que não podem aparecer nos docs públicos (regex, alternativas com |); amplie ao encontrar novos
$clientesNoPublico = 'Diageo|Ambev|Socen'
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

  'mover' {
    # migração única: docs-kb/<pasta>/<x>.md -> docs-kb/upload/{suporte|desenvolvimento}/<pasta>/<x>.md
    $src = Get-ChildItem $kb -Recurse -Filter *.md | Where-Object { $_.FullName -notlike "$up\*" -and $_.Name -notlike '_*' -and $_.Name -ne 'README.md' }
    $map = @{}
    foreach ($f in $src) { $rel = $f.FullName.Substring($kb.Length + 1); $map[$f.FullName.ToLower()] = Join-Path $(if ($f.BaseName -like '*-dev') { $dev } else { $sup }) $rel }
    foreach ($f in $src) {
      $t = ReadT $f.FullName; $old = $f.DirectoryName; $new = Split-Path $map[$f.FullName.ToLower()]
      $t = [regex]::Replace($t, '\]\(([^)#\s]+?\.md)(#[^)\s]*)?\)', {
          param($m)
          $tgt = [IO.Path]::GetFullPath((Join-Path $old ($m.Groups[1].Value -replace '/', '\')))
          $nt = if ($map.ContainsKey($tgt.ToLower())) { $map[$tgt.ToLower()] } else { $tgt }
          '](' + (RelPath $new $nt) + $m.Groups[2].Value + ')' })
      $t = [regex]::Replace($t, '(?m)^(fontes:\s*)\[(.*)\]', {
          param($m)
          $fs = $m.Groups[2].Value.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ } | ForEach-Object {
            if ($_ -like 'docs-kb/*') { $abs = (Join-Path $Repo ($_ -replace '/', '\')).ToLower(); if ($map.ContainsKey($abs)) { RelRepo $map[$abs] } else { $_ } } else { $_ } }
          $m.Groups[1].Value + '[' + ($fs -join ', ') + ']' })
      WriteT $map[$f.FullName.ToLower()] $t
      Remove-Item $f.FullName
    }
    Get-ChildItem $kb -Directory | Where-Object { $_.FullName -ne $up -and -not (Get-ChildItem $_.FullName -Recurse -File) } | Remove-Item -Recurse
    "movidos: $($src.Count)"
  }

  'auditoria' {
    # Catálogo das operações de auditoria, gerado de forma determinística a partir do código (não editar à mão).
    $cp = [Text.Encoding]::GetEncoding(1252)
    $fKr = 'cargas/Fontes/KrAudit.pas'; $fCt = 'cargas/Fontes/KrConst.pas'
    $src = [IO.File]::ReadAllText((Join-Path $Repo ($fKr -replace '/', '\')), $cp)
    $intf = $src.Substring(0, $src.IndexOf("`nimplementation"))
    $consts = [ordered]@{}; $dupNum = @{}
    foreach ($m in [regex]::Matches($intf, '(?m)^[ \t]*(ac\w+)[ \t]*=[ \t]*(\d+)[ \t]*;[ \t]*(?://[ \t]*(.*?))?[ \t]*\r?$')) {
      $c = [pscustomobject]@{ Nome = $m.Groups[1].Value; Num = [int]$m.Groups[2].Value; Coment = $m.Groups[3].Value.Trim() }
      $consts[$c.Nome] = $c
      if (-not $dupNum[$c.Num]) { $dupNum[$c.Num] = @() }; $dupNum[$c.Num] += $c.Nome
    }
    # registros em InicializaAuditoria (sem comentários)
    $i = $src.IndexOf('procedure InicializaAuditoria;'); $j = $src.IndexOf("`nend;", $i)
    $body = $src.Substring($i, $j - $i)
    $body = [regex]::Replace($body, '\{[^}]*\}', '')
    $body = [regex]::Replace($body, '(?s)\(\*.*?\*\)', '')
    $body = [regex]::Replace($body, '(?m)^[ \t]*//.*$', '')
    $body = [regex]::Replace($body, '(?m)\)[ \t]*;[ \t]*//.*$', ');')
    $totAdd = [regex]::Matches($body, 'AuditControl\.Add\s*\(').Count
    $regs = [ordered]@{}; $regDup = @(); $regSemConst = @()
    $q = "'((?:[^']|'')*)'"
    foreach ($m in [regex]::Matches($body, "AuditControl\.Add\s*\(\s*(\w+)\s*,\s*$q\s*,\s*$q\s*(?:,\s*(\w+)\s*)?\)")) {
      $n = $m.Groups[1].Value
      $r = [pscustomobject]@{ Nome = $n; Descr = ($m.Groups[2].Value -replace "''", "'").Trim(); Chave = ($m.Groups[3].Value -replace "''", "'").Trim(); Tab = $m.Groups[4].Value }
      if (-not $consts.Contains($n)) { $regSemConst += $r; continue }
      if ($regs.Contains($n)) { $regDup += $r } else { $regs[$n] = $r }
    }
    $naoInterpretados = $totAdd - ($regs.Count + $regDup.Count + $regSemConst.Count)
    # tabelas de histórico por documento (iTab* de KrConst.pas, usadas pelo histórico de auditoria aberto nas telas)
    $ct = [IO.File]::ReadAllText((Join-Path $Repo ($fCt -replace '/', '\')), $cp)
    $tabNum = @{}; foreach ($m in [regex]::Matches($ct, '(?m)^\s*(iTab[A-Z]\w*)\s*=\s*(\d+)\s*;')) { $tabNum[$m.Groups[1].Value] = [int]$m.Groups[2].Value }
    $tabNome = @{ iTabMeg = 'Mapa de Entrega'; iTabMnf = 'Manifesto'; iTabPtc = 'Protocolo'; iTabOpg = 'Contrato de Frete'; iTabAct = 'ACT'; iTabMcl = 'Solicitação de Coleta'; iTabMcg = 'Mapa de Carregamento' }
    # onde cada constante é referenciada (todas as .pas versionadas, exceto KrAudit.pas)
    $uso = @{}
    foreach ($f in (git -C $Repo ls-files '*.pas')) {
      if ($f -eq $fKr -or $f -match $ignorar) { continue }
      $t = [IO.File]::ReadAllText((Join-Path $Repo ($f -replace '/', '\')), $cp)
      $un = if ($f -like 'cargas/Fontes/*') { [IO.Path]::GetFileNameWithoutExtension($f) } else { $f -replace '\.pas$', '' }
      foreach ($tk in @([regex]::Matches($t, '\bac[A-Z]\w*\b') | ForEach-Object { $_.Value } | Sort-Object -Unique)) {
        if ($consts.Contains($tk)) { if (-not $uso[$tk]) { $uso[$tk] = New-Object Collections.Generic.List[string] }; if (-not $uso[$tk].Contains($un)) { $uso[$tk].Add($un) } }
      }
    }
    $ops = @($consts.Values | Sort-Object Num, Nome)
    $semReg = @($ops | Where-Object { -not $regs.Contains($_.Nome) })
    $semUso = @($ops | Where-Object { -not $uso[$_.Nome] })
    $commit = (git -C $Repo rev-parse HEAD).Trim()
    $faixa = 50
    $esc = { param($s) ($s -replace '\|', '/' -replace '\s+', ' ').Trim() }
    # público: nomes de clientes viram "cliente específico" (sigilo); o -dev mantém o texto original
    $semCliente = { param($s) [regex]::Replace($s, "(?i)(\b(d[aoe]s?|para\s+[ao]s?|com\s+[ao]s?)\s+)?\b($clientesNoPublico)\b", ' de cliente específico').Trim() -replace '\s{2,}', ' ' }
    $descPub = { param($o) if ($regs.Contains($o.Nome)) { & $semCliente (& $esc $regs[$o.Nome].Descr) } else { $c = ($o.Coment -split '//')[0] -replace "^'[^']*'\s*-\s*", '' -replace "'", ''; if ($c) { (& $semCliente (& $esc $c)) + ' _(sem descrição no sistema)_' } else { '_(sem descrição no sistema)_' } } }
    $fm = { param($tipoDoc, $fontes, $pub)
      "---`r`nsistema: Cargas`r`nmodulo: seguranca-usuarios-configuracao`r`ntipo: $tipoDoc`r`nfontes: [$($fontes -join ', ')]`r`ncommit: $commit`r`n" +
      $(if ($pub) { "categoria_sugerida: Suporte`r`nconfidencialidade: interno" } else { "categoria_sugerida: Desenvolvimento`r`nconfidencialidade: restrito-desenvolvimento" }) + "`r`n---`r`n`r`n" }
    $base = 'auditoria-catalogo-de-operacoes'
    $pathSup = Join-Path $sup 'processos'; $pathDev = Join-Path $dev 'processos'
    $saida = @{}
    function Grava($p, $conteudo) {
      # preserva o arquivo (e o commit do front matter) se só o commit mudaria
      $norm = { param($x) ($x -replace '(?m)^commit: .*$', '') -replace "`r?`n", "`n" }
      if ((Test-Path $p) -and ((& $norm (ReadT $p)).TrimEnd() -eq (& $norm $conteudo).TrimEnd())) { return 'igual' }
      WriteT $p $conteudo; 'gravado'
    }
    $partes = @($ops | Group-Object { [int][math]::Floor(($_.Num - 1) / $faixa) } | Sort-Object { [int]$_.Name })
    $infoPartes = @()
    foreach ($g in $partes) {
      $ini = [int]$g.Name * $faixa + 1; $fim = $ini + $faixa - 1
      $nomeP = '{0}-{1:0000}-{2:0000}' -f $base, $ini, $fim
      $infoPartes += [pscustomobject]@{ Nome = $nomeP; Ini = $ini; Fim = $fim; Qtd = $g.Count; SemReg = @($g.Group | Where-Object { -not $regs.Contains($_.Nome) }).Count }
      # público
      $s = (& $fm 'processo' @("docs-kb/upload/desenvolvimento/processos/$nomeP-dev.md") $true)
      $s += "# Cargas — Segurança, Usuários e Configuração — Catálogo de operações de auditoria ($ini a $fim)`r`n`r`n"
      $s += "Lista gerada automaticamente a partir do código do sistema; não editar à mão. Índice e explicação das colunas: [Catálogo de operações de auditoria]($base.md). **(Confirmado no código)**`r`n`r`n"
      $s += "| Nº | Operação | Chave de pesquisa (como informar na consulta) | Também no histórico da tela |`r`n|---|---|---|---|`r`n"
      foreach ($o in $g.Group) {
        $r = $regs[$o.Nome]; $ch = if ($r -and $r.Chave) { & $esc $r.Chave } else { '—' }
        $tb = if ($r -and $r.Tab -and $tabNome[$r.Tab]) { $tabNome[$r.Tab] } else { '—' }
        $s += "| $($o.Num) | $(& $descPub $o) | $ch | $tb |`r`n"
      }
      $s += "`r`n## Fontes`r`n`r`nDetalhes técnicos: documento restrito correspondente (-dev).`r`n"
      $saida[(Join-Path $pathSup "$nomeP.md")] = $s
      # -dev
      $s = (& $fm 'processo' @($fKr, $fCt) $false)
      $s += "# Cargas — Segurança, Usuários e Configuração — Catálogo de operações de auditoria ($ini a $fim) (técnico)`r`n`r`n"
      $s += "Documento restrito, gerado por ``kb-tools.ps1 auditoria`` (não editar à mão). Versão pública: ``processos/$nomeP.md``. Índice: ``processos/$base-dev.md``. **(Confirmado no código)**`r`n`r`n"
      $s += "| Nº | Constante | Descrição (``InicializaAuditoria``) | Chave | Tabela | Referenciada em |`r`n|---|---|---|---|---|---|`r`n"
      foreach ($o in $g.Group) {
        $r = $regs[$o.Nome]
        $de = if ($r) { & $esc $r.Descr } else { '**não registrada** — comentário: ' + $(if ($o.Coment) { & $esc $o.Coment } else { '—' }) }
        $ch = if ($r -and $r.Chave) { & $esc $r.Chave } else { '—' }
        $tb = if ($r -and $r.Tab) { $r.Tab } else { '—' }
        $us = if ($uso[$o.Nome]) { $l = @($uso[$o.Nome] | Sort-Object); (($l | Select-Object -First 5) -join ', ') + $(if ($l.Count -gt 5) { " (+$($l.Count - 5))" } else { '' }) } else { '_nenhuma_' }
        $s += "| $($o.Num) | ``$($o.Nome)`` | $de | $ch | $tb | $us |`r`n"
      }
      $s += "`r`n## Fontes`r`n`r`n- ``$fKr`` — constantes ``ac*`` (interface) e ``InicializaAuditoria``.`r`n- ``$fCt`` — constantes ``iTab*`` (coluna Tabela).`r`n- Coluna ""Referenciada em"": busca do identificador em todas as ``.pas`` versionadas (units de ``cargas/Fontes`` sem caminho; até 5 nomes).`r`n"
      $saida[(Join-Path $pathDev "$nomeP-dev.md")] = $s
    }
    # índice público
    $s = (& $fm 'processo' @("docs-kb/upload/desenvolvimento/processos/$base-dev.md") $true)
    $s += "# Cargas — Segurança, Usuários e Configuração — Catálogo de operações de auditoria`r`n`r`n"
    $s += "Lista completa das operações que o Cargas registra na auditoria, gerada automaticamente a partir do código a cada atualização da documentação (não editar à mão). Processo: [Auditoria do sistema](auditoria-do-sistema.md). Tela de consulta: [Auditoria - Consulta](../telas/seguranca-usuarios-configuracao--auditoria-consulta.md).`r`n`r`n"
    $s += "## Resumo`r`n`r`n- Operações existentes: **$($ops.Count)** (números de $(($ops | Select-Object -First 1).Num) a $(($ops | Select-Object -Last 1).Num)). **(Confirmado no código)**`r`n"
    $s += "- Com descrição cadastrada (aparecem na lista **Operação** da tela de consulta): **$($ops.Count - $semReg.Count)**. **(Confirmado no código)**`r`n"
    $s += "- Sem descrição cadastrada: **$($semReg.Count)**. Se algum registro antigo tiver uma dessas operações, a grade da consulta mostra ""Todos"" no lugar da descrição e a operação não pode ser escolhida no filtro. **(Confirmado no código)**`r`n"
    # números compartilhados / registros duplicados: a consulta usa sempre o primeiro registro do número
    $ordem = @($regs.Keys)
    foreach ($num in @($dupNum.Keys | Where-Object { $dupNum[$_].Count -gt 1 } | Sort-Object)) {
      $nomes = @($dupNum[$num] | Sort-Object { $ix = [array]::IndexOf($ordem, $_); if ($ix -lt 0) { 99999 } else { $ix } })
      $ds = @($nomes | ForEach-Object { if ($regs.Contains($_)) { '"' + (& $semCliente (& $esc $regs[$_].Descr)) + '"' } })
      if ($ds.Count -gt 1) { $s += "- O número **$num** é usado por mais de uma operação ($($ds -join ' e ')). Na consulta, os registros de todas elas aparecem com a descrição $($ds[0]) e o filtro por esse número traz todas. **(Confirmado no código)**`r`n" }
    }
    foreach ($r in $regDup) { if ($regs.Contains($r.Nome)) { $s += "- A operação **$($consts[$r.Nome].Num)** tem duas descrições no código; a consulta mostra sempre ""$(& $semCliente (& $esc $regs[$r.Nome].Descr))"" (a outra, ""$(& $semCliente (& $esc $r.Descr))"", não aparece). **(Confirmado no código)**`r`n" } }
    $s += "`r`n## Como ler as colunas`r`n`r`n"
    $s += "- **Nº**: número fixo da operação, gravado em cada registro de auditoria. Não muda entre versões. **(Confirmado no código)**`r`n"
    $s += "- **Operação**: descrição exibida na lista e na grade da consulta. **(Confirmado no código)**`r`n"
    $s += "- **Chave de pesquisa**: o que o sistema grava no campo Chave e como informá-la na consulta (partes separadas por ponto e vírgula, ex.: ""Empresa;Série;CTRC"" → ``001;1;12345``). Ao escolher a operação, a tela mostra essa dica ao lado de Chave. ""—"" = sem dica cadastrada. **(Confirmado no código)**`r`n"
    $s += "- **Também no histórico da tela**: além da consulta geral, a operação aparece no histórico de auditoria aberto a partir da tela indicada (que filtra pelo documento e por esse grupo de operações). **(Confirmado no código)**`r`n`r`n"
    $s += "## Partes do catálogo`r`n`r`n| Números | Arquivo | Operações | Sem descrição |`r`n|---|---|---|---|`r`n"
    foreach ($p in $infoPartes) { $s += "| $($p.Ini) a $($p.Fim) | [$($p.Nome).md]($($p.Nome).md) | $($p.Qtd) | $($p.SemReg) |`r`n" }
    $s += "`r`n## Fontes`r`n`r`nDetalhes técnicos: documento restrito correspondente (-dev).`r`n"
    $saida[(Join-Path $pathSup "$base.md")] = $s
    # índice -dev
    $s = (& $fm 'processo' @($fKr, $fCt) $false)
    $s += "# Cargas — Segurança, Usuários e Configuração — Catálogo de operações de auditoria (técnico)`r`n`r`n"
    $s += "Documento restrito, gerado por ``kb-tools.ps1 auditoria`` (executado em toda rodada da skill ``doc-sync``; não editar à mão). Versão pública: ``processos/$base.md``. Processo: ``processos/auditoria-do-sistema-dev.md``. **(Confirmado no código)**`r`n`r`n"
    $s += "## Como é montado`r`n`r`n- Constantes: ``ac<Nome> = <n>;`` na interface de ``$fKr`` (comentário da linha usado quando não há registro).`r`n- Registro: chamadas ``AuditControl.Add(constante, descrição, chave, [iTab*])`` em ``InicializaAuditoria`` (linhas comentadas ignoradas). ``AudName``/``GetListaOperacao`` (``KrUtil.pas``) e ``AudChaveName`` leem esse registro; constante sem ``Add`` não aparece na lista e ``AudName`` devolve ""Todos"".`r`n- Tabela: 4º parâmetro do ``Add``; ``ListaDeOperacoes(iTab)`` monta o ``OPERACAO IN (...)`` do ``TfrmDgCliAud`` (``MostraAuditoria``).`r`n`r`n"
    $s += "## Números`r`n`r`n- Constantes ``ac*``: $($ops.Count); chamadas ``Add`` ativas: $totAdd; registradas: $($regs.Count); constantes sem registro: $($semReg.Count); sem referência fora de ``KrAudit.pas``: $($semUso.Count).`r`n"
    $dn = @($dupNum.Keys | Where-Object { $dupNum[$_].Count -gt 1 } | Sort-Object)
    $s += "- Números repetidos entre constantes: " + $(if ($dn) { ($dn | ForEach-Object { "$_ (" + ($dupNum[$_] -join ', ') + ')' }) -join '; ' } else { 'nenhum' }) + ".`r`n"
    $s += "- ``Add`` duplicado para a mesma constante: " + $(if ($regDup) { ($regDup | ForEach-Object { '`' + $_.Nome + '`' }) -join ', ' } else { 'nenhum' }) + ".`r`n"
    $s += "- ``Add`` com identificador que não é constante ``ac*`` da interface: " + $(if ($regSemConst) { ($regSemConst | ForEach-Object { '`' + $_.Nome + '`' }) -join ', ' } else { 'nenhum' }) + ".`r`n"
    $s += "- ``Add`` não interpretados pelo gerador (verificar formato): $naoInterpretados.`r`n`r`n"
    $s += "## Constantes sem registro em InicializaAuditoria`r`n`r`n"
    if ($semReg) { $s += "| Nº | Constante | Referenciada em |`r`n|---|---|---|`r`n"; foreach ($o in $semReg) { $s += "| $($o.Num) | ``$($o.Nome)`` | $(if ($uso[$o.Nome]) { ($uso[$o.Nome] | Sort-Object) -join ', ' } else { '_nenhuma_' }) |`r`n" } } else { $s += "Nenhuma.`r`n" }
    $s += "`r`nGravar com uma constante não registrada funciona (o ``INSERT`` em ``ADT`` não valida), mas o registro fica sem descrição na consulta e não é filtrável. **(Confirmado no código)**`r`n`r`n"
    $s += "## Tabelas (iTab*)`r`n`r`n| Constante | Valor | Histórico na tela | Operações |`r`n|---|---|---|---|`r`n"
    foreach ($k in ($tabNum.Keys | Sort-Object { $tabNum[$_] })) { $s += "| ``$k`` | $($tabNum[$k]) | $(if ($tabNome[$k]) { $tabNome[$k] } else { '—' }) | $(@($regs.Values | Where-Object { $_.Tab -eq $k }).Count) |`r`n" }
    $s += "`r`n## Partes`r`n`r`n| Números | Arquivo | Operações | Sem registro |`r`n|---|---|---|---|`r`n"
    foreach ($p in $infoPartes) { $s += "| $($p.Ini) a $($p.Fim) | ``$($p.Nome)-dev.md`` | $($p.Qtd) | $($p.SemReg) |`r`n" }
    $s += "`r`n## Fontes`r`n`r`n- ``$fKr``; ``$fCt``.`r`n"
    $saida[(Join-Path $pathDev "$base-dev.md")] = $s
    # grava e marca como obsoletas partes antigas que deixaram de existir
    $res = @{ gravado = 0; igual = 0 }
    foreach ($p in $saida.Keys) { $res[(Grava $p $saida[$p])]++ }
    foreach ($d in @(Get-ChildItem $pathSup, $pathDev -Filter "$base-*.md" -ErrorAction SilentlyContinue)) {
      if (-not $saida.ContainsKey($d.FullName)) { $t = ReadT $d.FullName; if ($t -notmatch '(?m)^obsoleto: true') { WriteT $d.FullName ($t -replace '(?m)^(confidencialidade: .*)$', "`$1`r`nobsoleto: true"); "obsoleto: $(RelKb $d.FullName)" } }
    }
    "auditoria: $($ops.Count) operações ($($semReg.Count) sem registro), $($infoPartes.Count) partes | arquivos gravados: $($res.gravado), sem mudança: $($res.igual) | Add não interpretados: $naoInterpretados"
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
    $pub = [ordered]@{
      'arquivo-fonte' = '\b\w+\.(pas|dfm|dpr|dproj|sql|cs|tsx?)\b'
      'classe/unit'   = '\b(T(frm|dm|Kr)[A-Z]\w+|Kr[A-Z][a-z]\w+)\b'
      'sql'           = '\b(SELECT\s+.+\s+FROM|INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM|CREATE\s+TABLE)\b'
      'caminho'       = '(cargas/Fontes|cargas\\Fontes|update\.sql|Cargas32\.(sql|dpr))'
      'nome-interno'  = '(`FORTES`|usu[aá]rio FORTES|Cortana|CaImpXML|CABAIXAIMG|`AUTOMATICO`|`CARGASSAC`|TOTVS)'
      'cliente'       = "(?i)\b($clientesNoPublico)\b"
      'link-dev'      = '-dev\.md'
    }
    $sec = [ordered]@{
      'url'        = 'https?://(?!tempuri\.org|calculadorafrete\.antt\.gov\.br)[^\s)`>\]]+'
      'credencial' = '(?i)\b(senha|password|passwd|pwd|token|secret|app_?key|api_?key|client_?secret)\b\s*[:=]\s*[''"][^''"]{4,}[''"]'
      'guid'       = '\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b'
    }
    $par_excecoes = 'upload/suporte/telas/seguranca-usuarios-configuracao--configuracao-preferencias-parte-2.md', 'upload/desenvolvimento/modulos/edi-integracoes-clientes-parte-3-dev.md', 'upload/desenvolvimento/glossario-parte-2-dev.md'
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
    [void]$s.AppendLine('# docs-kb — Base de conhecimento do sistema Cargas')
    [void]$s.AppendLine()
    [void]$s.AppendLine("Atualizado em $(Get-Date -Format 'yyyy-MM-dd HH:mm') (commit $((git -C $Repo rev-parse --short HEAD).Trim())). Este arquivo é regenerado pela skill ``/doc-sync`` a cada execução; não edite à mão.")
    [void]$s.AppendLine()
    [void]$s.AppendLine('## Objetivo')
    [void]$s.AppendLine()
    [void]$s.AppendLine('A pasta `docs-kb/` guarda a documentação do sistema Cargas (TMS desktop Delphi, `cargas/Fontes`) gerada a partir do código-fonte, para servir de base de conhecimento (RAG) do assistente **Argos**. Cada afirmação vem do código e é marcada como "Confirmado no código" ou "Inferido (verificar)". O envio ao Google Drive é manual.')
    [void]$s.AppendLine()
    [void]$s.AppendLine('## Por que o nome docs-kb')
    [void]$s.AppendLine()
    [void]$s.AppendLine('"kb" é a sigla de *knowledge base* (base de conhecimento): `docs-kb` significa "documentação da base de conhecimento". O nome foi definido no pedido original de geração da documentação, por ser o conteúdo que alimenta a base de conhecimento do assistente Argos.')
    [void]$s.AppendLine()
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
      '_mapa-arquivos.csv' = 'Cada unit de `cargas/Fontes` → módulo. Usado para localizar o módulo de arquivos novos.'
      '_mapa-telas.csv' = 'Cada item do menu principal → código de permissão → handler → units.'
    }
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
          $tit = if ($t -match '(?m)^#\s+(.+)$') { ($matches[1] -replace '^Cargas\s*[—-]\s*', '').Trim() } else { '' }
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
