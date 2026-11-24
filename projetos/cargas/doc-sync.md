# doc-sync — Cargas

Configuração lida pela skill global `doc-sync`. O `kb-tools.ps1` lê `doc-sync/config.json` (sistema, objetivo do README, sigilo dos
públicos — units Delphi, `cargas/Fontes`, nomes internos, clientes —, URLs permitidas, exceções de par e a ação extra `auditoria`).

## Ação `auditoria` (sempre, em toda execução, mesmo sem mudanças detectadas)

1. Rode `kb-tools.ps1 auditoria` (script em `doc-sync/scripts/auditoria.ps1`). Ele regenera de forma determinística o catálogo completo
   das operações de auditoria a partir de `cargas/Fontes/KrAudit.pas` (constantes `ac*` + `InicializaAuditoria`) e `KrConst.pas`
   (`iTab*`), com as units que usam cada constante:
   `upload/{suporte,desenvolvimento}/processos/auditoria-catalogo-de-operacoes[-NNNN-NNNN][-dev].md` (índice + partes por faixa de 50
   números). Só regrava arquivos cujo conteúdo mudou; partes que deixarem de existir são marcadas `obsoleto: true`. Nunca editar esses
   arquivos à mão.
2. Conferir no resultado: "Add não interpretados" deve ser 0 (se não for, ajustar o parser em `doc-sync/scripts/auditoria.ps1`) e, se
   surgir nome de cliente nas descrições, incluí-lo em `clientesNoPublico` do `doc-sync/config.json` e rodar de novo.
3. Se `KrAudit.pas`, `KrUtilAuditoria.pas`, `DgAud.pas/.dfm`, `RlDgAud.pas/.dfm`, `dgCliAud.pas/.dfm` ou as rotinas de auditoria de
   `KrUtil.pas` (`AudName`, `GetListaOperacao`, `MostraAuditoria`) mudarem, regenerar também os pares descritivos:
   `telas/seguranca-usuarios-configuracao--auditoria-consulta`, `processos/auditoria-gravacao-dos-registros`,
   `processos/auditoria-do-sistema` e `entidades/registro-de-auditoria` (mantendo todos os filtros, botões, regras, histórico por
   documento e pontos de atenção).
