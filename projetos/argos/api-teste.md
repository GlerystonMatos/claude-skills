Base: padrao-argos

# API e front de teste — Argos

- `<back>` = `argos-back`, `<projeto Api>` = `Argos.Api`, `<front>` = `argos-front`.
- **Portas**: do usuário 5180/5003 (não derrubar); teste API 5190, front 5191.
- **Dados**: `dados/` da raiz → `<scratchpad>/api/dados/` (fica ao lado do exe). `<dados>` = `<scratchpad>/api/dados`,
  `<modelo>` = `argos`. O bootstrap, sem `AppUsuarios.json`, não lista usuários nem carrega Cronômetro e parte das Configurações —
  use só se o usuário pedir.
- **Nunca** usar o Firestore de produção.
- **Variáveis próprias**: `ARMAZENAMENTO__PROJETO_FIRESTORE` **vazia** (arquivos JSON) — ou `FIRESTORE_EMULATOR_HOST` para o emulador;
  `NO_PROXY=.atlassian.net` se o Jira real for necessário (Google/Gemini continuam bloqueados).
- **Log**: a linha "Armazenamento de dados: arquivos JSON em …scratchpad…".
- `<chave sessão>` = `argos:sessao` (de `api/sessao.ts`).
