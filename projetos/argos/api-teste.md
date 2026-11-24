# API e front de teste — Argos

Configuração lida pela skill global `api-teste`. `<scripts>` = `claude-skills/projetos/argos/api-teste/scripts`.

- **Do usuário (não derrubar)**: API em 5180/5003. **Teste**: API em 5190, front em 5191.
- **Nunca** usar o `dados/` original nem o Firestore de produção.

1. **Dados**: copie `dados/` da raiz do repositório (ou a pasta informada pelo usuário) para `<scratchpad>/api/dados/` só se ainda não
   existir. Em seguida `python <scripts>/usuario_teste.py preparar <scratchpad>`: cria na **cópia** o usuário fixo `teste-validacao`
   (perfil Administrador, colaborador TST) com senha aleatória em `<scratchpad>/usuario-teste.json` (nunca exibir). Assim todas as telas
   carregam com os dados da cópia (o bootstrap, sem `AppUsuarios.json`, não lista usuários nem carrega Cronômetro e parte das
   Configurações — use só se o usuário pedir).
2. **Publicar**: encerre só a API de teste (`Argos.Api.exe` escutando na 5190, confirme pela porta) e
   `cd argos-back && dotnet publish Argos.Api -c Release -o <scratchpad>/api`.
3. **Variáveis**:
   - `CHAVE_CRIPTOGRAFIA` = a do `.env` da raiz (obrigatório o valor certo: sem ela os tokens viram vazios e salvar grava vazio);
   - `AUTH__JWT_CHAVE` qualquer (≥ 32 bytes); `AUTH__USUARIO`/`AUTH__SENHA` do `.env` só no modo bootstrap;
   - `ARMAZENAMENTO__PROJETO_FIRESTORE` **vazia** (arquivos JSON) — ou `FIRESTORE_EMULATOR_HOST` para o emulador;
   - `ASPNETCORE_URLS=http://localhost:5190`;
   - proxy morto (Google/Gemini falham rápido) e `NO_PROXY=.atlassian.net` se o Jira real for necessário.
4. **Executar** a partir de `<scratchpad>/api` (o `dados/` fica ao lado do exe). Health: `GET http://localhost:5190/health`; no log, a
   linha "Armazenamento de dados: arquivos JSON em …scratchpad…".
5. **Front**: `cd argos-front && VITE_API_URL=http://localhost:5190 npx vite --port 5191`.
6. **Login** na API: `POST /api/auth/login` com `{ login, senha }` → `Authorization: Bearer <token>`.
7. **Login no navegador**:
   1. `python <scripts>/usuario_teste.py sessao <scratchpad> argos-front/public/sessao-teste.txt` (usa `http://localhost:5190`).
   2. Em `http://localhost:5191/`: `sessionStorage.setItem('argos:sessao', JSON.parse(await (await fetch('/sessao-teste.txt')).text()))`
      e `location.reload()` (chave de `api/sessao.ts`).
   3. Apague `argos-front/public/sessao-teste.txt` na hora.
