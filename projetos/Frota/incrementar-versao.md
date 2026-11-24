# Incrementar versão — Frota

Configuração lida pela skill global `incrementar-versao`. Vale para os dois clones do repositório (`Frota`, branch `suporte`, e
`FrotaXE6`, branch `suportexe6`).

- **Banco**: `.set ScriptVersion=N` em `Scripts/Update.sql` e `Scripts/UpdateMSSQL.sql`.
- **`.ver` ativos**: `Scripts/Frota.ver` (itens dentro de `<Modulo nome="...">`) e
  `ApiSOAPAbastecimento/CaAbastecimento/CaAbastecimento.ver` (itens direto na `<Versao>`).
- **Não atualizar**: `Scripts/FrotaOld.ver` (histórico parado), `bin/Frota.ver` (cópia de saída; no FrotaXE6 em `windows-1252`) e
  `IntegraMovidesk/IntegraMovidesk.ver` (ignorado pelo git, vem de importação externa).
- **Mapa de pastas**: fontes do Frota → `Scripts/Frota.ver`; `ApiSOAPAbastecimento/**` → `CaAbastecimento.ver`.
- **Módulos** do `Frota.ver`: `Geral`, `Abastecimento`, `Manutenção`, `Material`, `Pneu`, `Administração`, `Veiculo` (sem acento, a
  grafia mais usada no histórico; ignore as variantes `Veículo`, `Veiculos` e `Abestecimento`).
- **Banco subiu** (`ScriptVersion` novo): atualize também `INSERT INTO INFO (... VERSAOBD, ... VERSAOEXE ...)` em `Scripts/Frota.sql` e
  `Scripts/Frota_SqlServer.sql` e `update INFO set INFO.VERSAOEXE = '...'` em `Scripts/Update.sql` e `Scripts/UpdateMSSQL.sql`.
- **Exemplo de salto de banco**: `CaAbastecimento.ver` em `2.400.5.1` com o banco em `414` → `2.414.0.0`.
- **Commit** (só com pedido): `TEL - <chamado> - <resumo>`, como no `git log`.
