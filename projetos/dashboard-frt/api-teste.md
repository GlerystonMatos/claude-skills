# API e front de teste — Dashboard FRT

Configuração lida pela skill global `api-teste`. A API fica em `../dashboard-frt-api` (ou em `DASHBOARD_FRT_API`).
`<scripts>` = `claude-skills/projetos/dashboard-frt/api-teste/scripts`; rode `node <scripts>/ambiente-teste.mjs` a partir da raiz do
front (ele acha a API pelo diretório atual). Esta máquina não tem Python.

- **Do usuário (não derrubar)**: API em 5000/5001. **Teste**: API em 5290, front em 5291.
- **Nunca** apontar para o banco `dashboard_frt` original. Nunca exibir `<scratchpad>/api-teste.json` nem o token.

1. **Banco**: `node <scripts>/ambiente-teste.mjs banco <scratchpad>`. Lê a conexão do `CONNECTION_STRING` do `.env` da API (ou do
   `appsettings.Development.json`), troca `host.docker.internal` por `127.0.0.1` e copia o banco para `dashboard_frt_teste` com
   `pg_dump`/`pg_restore` (binários de `C:\Program Files\PostgreSQL\<versão>\bin` ou `PG_BIN`). `--recriar` copia de novo. Grava em
   `<scratchpad>/api-teste.json` a conexão da cópia e uma chave JWT aleatória, mantida entre execuções.
2. **API**: `node <scripts>/ambiente-teste.mjs api <scratchpad>`. Faz `dotnet publish` para `<scratchpad>/api` e sobe em
   `http://localhost:5290` (ambiente `Development`, Swagger em `/swagger`, conexão e chave por variável, proxy morto para os webhooks
   dos licenciados, CORS aberto). Espera `GET /HealthCheck/Check`; log em `<scratchpad>/api.log`. O aviso "Failed to determine the
   https port" é esperado.
3. **Licenciados** (opcional): `node <scripts>/ambiente-teste.mjs licenciados <scratchpad>` lista `Id | Nome | Ativo` da cópia.
4. **Token**: `node <scripts>/ambiente-teste.mjs token <scratchpad> <arquivo> [licenciadoId]`. Sem licenciado gera `AdminGlobal` (vê
   todos); com o id gera `AdminLicenciado` daquele licenciado. Claims iguais às do `AccessToken.GenerateToken` da API, válido por 4 h.
5. **curl**: `T=$(cat <scratchpad>/token.txt)` e `curl -H "Authorization: Bearer $T" http://localhost:5290/api/Dashboard/...`.
   Endpoints na tabela do README da API.
6. **Front**: `VITE_API_URL=http://localhost:5290 npx vite --port 5291 --strictPort`.
7. **Entrar no navegador**, sem `?token=` na URL:
   1. `node <scripts>/ambiente-teste.mjs token <scratchpad> public/token-teste.txt`.
   2. Em `http://localhost:5291/`: `sessionStorage.setItem('dashboard-frt:token', (await (await fetch('/token-teste.txt')).text()).trim())`
      e `location.reload()` (chave de `src/api/sessao.ts`).
   3. Apague `public/token-teste.txt` na hora.
   4. Aparecer "Abra o dashboard novamente pelo Veica Web…" = token recusado: confira se a API de teste é a mesma da chave gravada.
8. **Conferência**: Manutenção e Conformidade só aparecem no menu com `TELAS_EM_DESENVOLVIMENTO_VISIVEIS = true`
   (`src/configuracao.ts`).
9. **Ao terminar**: `node <scripts>/ambiente-teste.mjs parar <scratchpad>` (encerra a API pelo PID) e encerre o Vite pela porta 5291.
   O banco `dashboard_frt_teste` fica; apague com `dropdb` só se o usuário pedir.
