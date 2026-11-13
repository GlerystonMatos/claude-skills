---
name: api-teste
description: Sobe a API do Argos em modo de teste isolado (publish no scratchpad, cópia dos dados, porta 5190, serviços externos bloqueados por proxy morto) e o front apontando para ela (porta 5191), para validar mudanças no navegador ou via curl sem tocar dados reais nem chamar serviços externos. Use antes de testar endpoints/telas de ponta a ponta.
---

# API e front de teste (Argos)

Regras: **nunca** usar `dados/` original nem o Firestore de produção.

1. **Dados**: copie `dados/` da raiz do repositório (ou a pasta informada pelo usuário) para `<scratchpad>/api/dados/` só se ainda
   não existir — a cópia é reaproveitada entre testes. Para entrar pelo bootstrap, rode sem `AppUsuarios.json` na cópia (nesse modo a tela Usuários não lista ninguém).
2. **Publicar**: `taskkill //F //IM Argos.Api.exe` (só a de teste; a do usuário usa 5180/5003 — confirme pela porta antes) e
   `cd argos-back && dotnet publish Argos.Api -c Release -o <scratchpad>/api`.
3. **Variáveis** (a API não lê o `.env`; passe no ambiente do processo, sem exibir valores):
   - `CHAVE_CRIPTOGRAFIA` = a do `.env` da raiz (**obrigatório** o valor certo: sem ela os tokens viram vazios e salvar grava vazio);
   - `AUTH__JWT_CHAVE` qualquer (≥ 32 bytes), `AUTH__USUARIO`/`AUTH__SENHA` do `.env` (bootstrap);
   - `ARMAZENAMENTO__PROJETO_FIRESTORE` **vazia** (arquivos JSON) — ou `FIRESTORE_EMULATOR_HOST` para o emulador;
   - `ASPNETCORE_URLS=http://localhost:5190`;
   - `HTTPS_PROXY`/`HTTP_PROXY=http://127.0.0.1:9` (Google/Gemini falham rápido) e `NO_PROXY=.atlassian.net` se o Jira real for necessário.
4. **Executar** em segundo plano a partir de `<scratchpad>/api` (o `dados/` fica ao lado do exe), log em `<scratchpad>/api.log`; confirme
   `GET http://localhost:5190/health` e a linha "Armazenamento de dados: arquivos JSON em …scratchpad…" no log.
5. **Front**: `cd argos-front && VITE_API_URL=http://localhost:5190 npx vite --port 5191` em segundo plano.
6. **curl** com acento no Git Bash: JSON com `\uXXXX`. Login: `POST /api/auth/login` com `{ login, senha }` → `Authorization: Bearer <token>`.
7. **Navegador** (claude-in-chrome): com a aba oculta, validar pelo DOM (`javascript_tool`), uma ação por chamada.
8. Ao terminar: encerre os dois processos de teste.
