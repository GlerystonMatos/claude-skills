# API e front de teste — Íris

Configuração lida pela skill global `api-teste`. `<scripts>` = `claude-skills/projetos/iris/api-teste/scripts`.

- **Do usuário (não derrubar)**: `dotnet run` em 5013, Docker em 5013/3012. **Teste**: API em 5290, front em 5291.
- **Nunca** usar `dados/` nem `arquivos/` originais.

1. **Dados**: copie `dados/` e `arquivos/` da raiz do repositório (ou as pastas informadas pelo usuário) para
   `<scratchpad>/api-dados/` e `<scratchpad>/api-arquivos/` só se ainda não existirem. Em seguida
   `python <scripts>/usuario_teste.py preparar <scratchpad>`: cria na **cópia** o usuário interno `teste-validacao` (perfil
   Administrador) com senha aleatória em `<scratchpad>/usuario-teste.json`. Sem `AppUsuarios.json` na cópia, use o acesso inicial
   (bootstrap) — nesse modo a tela Usuários não lista ninguém.
2. **Publicar**: encerre só a API de teste (porta 5290) e `cd iris-back && dotnet publish Iris.Api -c Release -o <scratchpad>/api`.
3. **Variáveis**:
   - `CHAVE_CRIPTOGRAFIA` = a do `.env` da raiz (obrigatório o valor certo: sem ela os dados cifrados e as URLs assinadas não batem);
   - `AUTH__JWT_CHAVE` qualquer (≥ 32 bytes); `AUTH__USUARIO`/`AUTH__SENHA` do `.env` só no modo bootstrap;
   - `ARMAZENAMENTO__PASTA_DADOS=<scratchpad>/api-dados`, `ARMAZENAMENTO__PASTA_ARQUIVOS=<scratchpad>/api-arquivos`;
   - `FUSO_HORARIO=America/Sao_Paulo`, `ASPNETCORE_URLS=http://localhost:5290`.
4. **Executar** a partir de `<scratchpad>/api` (sem `--launch-profile`). Health: `GET http://localhost:5290/health`; o log deve apontar
   as pastas da cópia.
5. **Front**: `cd iris-front && VITE_API_URL=http://localhost:5290 npx vite --port 5291`.
6. **Login** na API: `POST /api/auth/login` com `{ "login", "senha" }` → `Authorization: Bearer <token>`. Swagger em
   `http://localhost:5290/swagger`.
7. **Login no navegador**:
   1. `python <scripts>/usuario_teste.py sessao <scratchpad> iris-front/public/sessao-teste.txt` (usa `http://localhost:5290`).
   2. Em `http://localhost:5291/`: `sessionStorage.setItem('iris:sessao', JSON.parse(await (await fetch('/sessao-teste.txt')).text()))`
      e `location.reload()` (chave de `api/sessao.ts`).
   3. Apague `iris-front/public/sessao-teste.txt` na hora.
