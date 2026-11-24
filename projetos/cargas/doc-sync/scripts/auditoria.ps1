# Ação "auditoria" da skill doc-sync para o Cargas. Executada pelo kb-tools.ps1 (dot-source), com as funções e variáveis dele.
# Regenera o catálogo completo das operações de auditoria (pares em upload/*/processos/auditoria-catalogo-de-operacoes*) a partir de
# cargas/Fontes/KrAudit.pas e KrConst.pas, com as units que referenciam cada constante. Só regrava os arquivos cujo conteúdo mudou.
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
