Base: padrao-argos

# API e front de teste — Íris

- `<back>` = `iris-back`, `<projeto Api>` = `Iris.Api`, `<front>` = `iris-front`.
- **Portas**: do usuário `dotnet run` em 5013, Docker em 5013/3012 (não derrubar); teste API 5290, front 5291.
- **Dados**: `dados/` e `arquivos/` da raiz → `<scratchpad>/api-dados/` e `<scratchpad>/api-arquivos/`. `<dados>` =
  `<scratchpad>/api-dados`, `<modelo>` = `iris`. No bootstrap a tela Usuários não lista ninguém.
- **Variáveis próprias**: `ARMAZENAMENTO__PASTA_DADOS=<scratchpad>/api-dados`, `ARMAZENAMENTO__PASTA_ARQUIVOS=<scratchpad>/api-arquivos`,
  `FUSO_HORARIO=America/Sao_Paulo`. Sem a `CHAVE_CRIPTOGRAFIA` certa, as URLs assinadas também não batem.
- `<chave sessão>` = `iris:sessao` (de `api/sessao.ts`).
