---
name: api-teste
description: Sobe a API da Íris em modo de teste isolado (publish numa pasta temporária, cópia de dados/ e arquivos/, porta 5290, usuário de teste só na cópia) e o front apontando para ela (porta 5291), para validar mudanças no navegador ou via curl sem tocar os dados reais. Use antes de testar endpoints/telas de ponta a ponta.
---

# API e front de teste (Íris)

Regras: **nunca** usar `dados/` nem `arquivos/` originais; nunca derrubar a API do usuário (`dotnet run` em 5013, Docker em 5013/3012).
`<temp>` = pasta temporária da sessão (scratchpad do agente), nunca dentro do repositório. Nunca exibir senhas nem tokens.

1. **Dados**: copie `dados/` e `arquivos/` da raiz do repositório (ou as pastas informadas pelo usuário) para `<temp>/api-dados/` e
   `<temp>/api-arquivos/` só se ainda não existirem — a cópia é reaproveitada entre testes. Em seguida rode
   `python .agents/skills/api-teste/scripts/usuario_teste.py preparar <temp>`: cria na **cópia** o usuário interno `teste-validacao`
   (perfil Administrador) com senha aleatória guardada em `<temp>/usuario-teste.json`. Sem `AppUsuarios.json` na cópia, use o acesso
   inicial (bootstrap) — nesse modo a tela Usuários não lista ninguém.
2. **Publicar**: encerre só uma API de teste anterior (confira pela porta 5290 antes) e rode
   `cd iris-back && dotnet publish Iris.Api -c Release -o <temp>/api`.
3. **Variáveis** (a API não lê o `.env`; passe no ambiente do processo, sem exibir valores):
   - `CHAVE_CRIPTOGRAFIA` = a do `.env` da raiz (**obrigatório** o valor certo: sem ela os dados cifrados e as URLs assinadas não
     batem);
   - `AUTH__JWT_CHAVE` qualquer (≥ 32 bytes); `AUTH__USUARIO`/`AUTH__SENHA` do `.env` só no modo bootstrap;
   - `ARMAZENAMENTO__PASTA_DADOS=<temp>/api-dados`, `ARMAZENAMENTO__PASTA_ARQUIVOS=<temp>/api-arquivos`;
   - `FUSO_HORARIO=America/Sao_Paulo`, `ASPNETCORE_URLS=http://localhost:5290`.
4. **Executar** em segundo plano a partir de `<temp>/api` (sem `--launch-profile`), log em `<temp>/api.log`; confirme
   `GET http://localhost:5290/health` e que o log aponta as pastas da cópia.
5. **Front**: `cd iris-front && VITE_API_URL=http://localhost:5290 npx vite --port 5291` em segundo plano.
6. **curl** com acento no Git Bash: JSON com `\uXXXX`. Login: `POST /api/auth/login` com `{ "login", "senha" }` →
   `Authorization: Bearer <token>`. Swagger em `http://localhost:5290/swagger`.
7. **Login no navegador** sem digitar senha:
   1. Com a API no ar: `python .agents/skills/api-teste/scripts/usuario_teste.py sessao <temp> iris-front/public/sessao-teste.txt`
      (grava a sessão no formato do `sessionStorage`, sem imprimir o token).
   2. Em `http://localhost:5291/`: `sessionStorage.setItem('iris:sessao', JSON.parse(await (await fetch('/sessao-teste.txt')).text()))`
      e `location.reload()` (chave de `api/sessao.ts`).
   3. **Apague `iris-front/public/sessao-teste.txt` na mesma hora** (nunca pode ir para o git).
8. **Navegador** (automação do navegador, quando disponível): validar pelo DOM, uma ação por chamada; medir 360–400 px e os notebooks
   de 14" (1280×720, 1366×768, 1536×864), nos temas claro e escuro. Medidas de layout: skill `medir-layout`.
9. Ao terminar: encerre os dois processos de teste (`netstat -ano | grep -E ":(5290|5291) "` → `taskkill //F //PID`) e confirme que
   `iris-front/public/sessao-teste.txt` não existe.
