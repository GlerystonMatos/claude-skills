---
name: api-teste
description: Sobe a API do Portal do Cliente em modo de teste isolado (publish numa pasta temporária, cópia de dados/ e arquivos/, porta 5290) e o front apontando para ela (porta 5291), para validar mudanças no navegador ou via curl sem tocar os dados reais. Use antes de testar endpoints/telas de ponta a ponta.
---

# API e front de teste (Portal do Cliente)

Regras: **nunca** usar `dados/` nem `arquivos/` originais; nunca derrubar a API do usuário (`dotnet run` em 5013, Docker em 5013/3012).
`<temp>` = pasta temporária da sessão (scratchpad do agente), nunca dentro do repositório.

1. **Dados**: copie `dados/` e `arquivos/` da raiz do repositório (ou as pastas informadas pelo usuário) para `<temp>/api-dados/` e
   `<temp>/api-arquivos/` só se ainda não existirem — a cópia é reaproveitada entre testes. Para entrar pelo acesso inicial (bootstrap),
   a cópia não pode ter usuário ativo com Administrador total: remova `PortalUsuarios.json` da cópia (nesse modo a tela Usuários não
   lista ninguém) ou use um login real informado pelo usuário.
2. **Publicar**: encerre só uma API de teste anterior (confira pela porta 5290 antes) e rode
   `cd portal-back && dotnet publish PortalCliente.Api -c Release -o <temp>/api`.
3. **Variáveis** (a API não lê o `.env`; passe no ambiente do processo, sem exibir valores):
   - `CHAVE_CRIPTOGRAFIA` = a do `.env` da raiz (**obrigatório** o valor certo: sem ela os dados cifrados e as URLs assinadas não
     batem);
   - `AUTH__JWT_CHAVE` qualquer (≥ 32 bytes), `AUTH__USUARIO`/`AUTH__SENHA` do `.env` (bootstrap);
   - `ARMAZENAMENTO__PASTA_DADOS=<temp>/api-dados`, `ARMAZENAMENTO__PASTA_ARQUIVOS=<temp>/api-arquivos`;
   - `FUSO_HORARIO=America/Sao_Paulo`, `ASPNETCORE_URLS=http://localhost:5290`.
4. **Executar** em segundo plano a partir de `<temp>/api`, log em `<temp>/api.log`; confirme `GET http://localhost:5290/health` e que
   o log aponta as pastas da cópia.
5. **Front**: `cd portal-front && VITE_API_URL=http://localhost:5290 npx vite --port 5291` em segundo plano.
6. **curl** com acento no Git Bash: JSON com `\uXXXX`. Login: `POST /api/auth/login` com `{ "login", "senha" }` →
   `Authorization: Bearer <token>`. Swagger em `http://localhost:5290/swagger`.
7. **Navegador** (automação do navegador, quando disponível): validar pelo DOM, uma ação por chamada; medir 360–400 px e os notebooks
   de 14" (1280×720, 1366×768, 1536×864).
8. Ao terminar: encerre os dois processos de teste.
