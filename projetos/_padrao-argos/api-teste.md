# API e front de teste — base do padrão do Argos

Base comum lida pela skill global `api-teste` quando a configuração do projeto começa com `Base: padrao-argos`. A configuração do
projeto preenche os marcadores: `<back>`/`<front>` (pastas), `<projeto Api>` (projeto .NET da API), `<exe>` (nome do executável),
`<porta API>`/`<porta front>` (teste), as portas do usuário, `<dados>` (pasta da cópia com `AppUsuarios.json`), `<modelo>` do usuário de
teste (`argos` ou `iris`), `<chave sessão>` do `sessionStorage` e as variáveis próprias.

1. **Dados**: copie as pastas de dados da raiz do repositório (ou as informadas pelo usuário) para o `<scratchpad>` só se a cópia ainda
   não existir. Em seguida `node <scripts-globais>/usuario-teste.mjs preparar <scratchpad> --dados <dados> --modelo <modelo>`: cria na
   **cópia** o usuário `teste-validacao` (perfil Administrador) com senha aleatória em `<scratchpad>/usuario-teste.json` (nunca
   exibir). Sem `AppUsuarios.json` na cópia, a API entra no acesso inicial (bootstrap), que não carrega todas as telas.
2. **Publicar**: encerre só a API de teste (processo escutando na `<porta API>`, confirme pela porta) e
   `cd <back> && dotnet publish <projeto Api> -c Release -o <scratchpad>/api`.
3. **Variáveis**:
   - `CHAVE_CRIPTOGRAFIA` = a do `.env` da raiz (**obrigatório** o valor certo: sem ela os dados cifrados não batem e salvar grava
     vazio);
   - `AUTH__JWT_CHAVE` qualquer (≥ 32 bytes); `AUTH__USUARIO`/`AUTH__SENHA` do `.env` só no modo bootstrap;
   - `ASPNETCORE_URLS=http://localhost:<porta API>`;
   - proxy morto e as variáveis próprias da configuração do projeto.
4. **Executar** em segundo plano a partir de `<scratchpad>/api` (sem `--launch-profile`). Health: `GET http://localhost:<porta API>/health`;
   o log deve apontar os dados da **cópia**.
5. **Front**: `cd <front> && VITE_API_URL=http://localhost:<porta API> npx vite --port <porta front> --strictPort`.
6. **Login** na API: `POST /api/auth/login` com `{ "login", "senha" }` → `Authorization: Bearer <token>`. Swagger em
   `http://localhost:<porta API>/swagger`.
7. **Login no navegador**:
   1. `node <scripts-globais>/usuario-teste.mjs sessao <scratchpad> <front>/public/sessao-teste.txt --url http://localhost:<porta API>`
      (grava a sessão no formato do `sessionStorage`, sem imprimir o token).
   2. Em `http://localhost:<porta front>/`:
      `sessionStorage.setItem('<chave sessão>', JSON.parse(await (await fetch('/sessao-teste.txt')).text()))` e `location.reload()`.
   3. Apague `<front>/public/sessao-teste.txt` na hora. O token vale até a API reiniciar.
8. **Ao terminar**: encerre os processos das duas portas de teste e confirme que `<front>/public/sessao-teste.txt` não existe.
