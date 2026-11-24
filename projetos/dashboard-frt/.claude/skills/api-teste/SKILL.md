---
name: api-teste
description: Sobe a API do Dashboard FRT (../dashboard-frt-api) em modo de teste isolado — cópia do PostgreSQL em dashboard_frt_teste, publish no scratchpad, porta 5290, chave JWT própria, serviços externos bloqueados por proxy morto — e o front apontando para ela (porta 5291), entrando com um token de teste gerado pelo script, sem senha e sem exibir o token. Use para conferir telas no navegador (claro, escuro e celular) ou endpoints via curl sem tocar o banco real.
---

# API e front de teste (Dashboard FRT)

Regras: **nunca** apontar para o banco `dashboard_frt` original nem para a API do usuário (5000/5001). Nunca exibir o conteúdo de
`<scratchpad>/api-teste.json` nem o token. O script é `.claude/skills/api-teste/scripts/ambiente-teste.mjs` (Node; esta máquina não
tem Python) e lê a API em `../dashboard-frt-api` (ou em `DASHBOARD_FRT_API`). Rode-o a partir da raiz do front.

1. **Banco**: `node .claude/skills/api-teste/scripts/ambiente-teste.mjs banco <scratchpad>`. Lê a conexão do `CONNECTION_STRING` do
   `.env` da API (ou do `appsettings.Development.json`), troca `host.docker.internal` por `127.0.0.1` e copia o banco para
   `dashboard_frt_teste` com `pg_dump`/`pg_restore` (binários de `C:\Program Files\PostgreSQL\<versão>\bin` ou `PG_BIN`). A cópia é
   reaproveitada entre testes; `--recriar` copia de novo. Grava em `<scratchpad>/api-teste.json` a conexão da cópia e uma chave JWT
   aleatória, mantida entre execuções.
2. **API**: `node ... api <scratchpad>`. Faz `dotnet publish` para `<scratchpad>/api` (não usa o `bin` do projeto, que pode estar travado
   pela API do usuário) e sobe em segundo plano em `http://localhost:5290`. Ambiente `Development` (Swagger em `/swagger`), conexão e
   chave por variável de ambiente, `HTTPS_PROXY`/`HTTP_PROXY=http://127.0.0.1:9` (webhooks dos licenciados falham rápido) e CORS
   aberto (lista vazia). Espera `GET /HealthCheck/Check`; log em `<scratchpad>/api.log`. O aviso "Failed to determine the https port"
   é esperado (só HTTP).
3. **Licenciados** (opcional): `node ... licenciados <scratchpad>` lista `Id | Nome | Ativo` da cópia.
4. **Token**: `node ... token <scratchpad> <arquivo> [licenciadoId]`. Sem licenciado gera `AdminGlobal` (vê todos); com o id gera
   `AdminLicenciado` daquele licenciado. Claims iguais às do `AccessToken.GenerateToken` da API (`id`, `perfil`, `role`,
   `licenciadoId`, issuer e audience do `appsettings.json`), válido por 4 h.
5. **curl**: `T=$(cat <scratchpad>/token.txt)` e `curl -H "Authorization: Bearer $T" http://localhost:5290/api/Dashboard/...`; nunca
   imprimir `$T`. Endpoints na tabela do README da API.
6. **Front**: `VITE_API_URL=http://localhost:5290 npx vite --port 5291 --strictPort` em segundo plano. O Vite escuta só em `::1`, então
   `curl http://127.0.0.1:5291` falha; use `localhost` no navegador.
7. **Entrar no navegador** (claude-in-chrome), sem `?token=` na URL:
   1. `node ... token <scratchpad> public/token-teste.txt`.
   2. Em `http://localhost:5291/`: `sessionStorage.setItem('dashboard-frt:token', (await (await fetch('/token-teste.txt')).text()).trim())`
      e `location.reload()` (chave de `src/api/sessao.ts`).
   3. **Apague `public/token-teste.txt` na mesma hora** (nunca pode ir para o git).
   4. Aparecer "Abra o dashboard novamente pelo Veica Web…" = token recusado: confira se a API de teste é a mesma da chave gravada.
8. **Conferência**: valide pelo DOM (`javascript_tool`); confira tema claro e escuro e o celular (janela de 390 px ou `iframe` 390×844
   com `src='/'`, onde a sessão do `sessionStorage` também vale). Manutenção e Conformidade só aparecem no menu com
   `TELAS_EM_DESENVOLVIMENTO_VISIVEIS = true` (`src/configuracao.ts`).
9. **Ao terminar**: `node ... parar <scratchpad>` (encerra a API pelo PID), encerre o Vite (`netstat -ano | grep -E ":(5290|5291) "` →
   `taskkill //F //T //PID`), feche a aba e confirme que `public/token-teste.txt` não existe. O banco `dashboard_frt_teste` fica para a
   próxima vez; apague com `dropdb` só se o usuário pedir.
