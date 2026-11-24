# Front de teste — Painel Atena

Configuração lida pela skill global `api-teste`. O painel não tem API própria: usa a API de teste da `atena-api` (porta 3190), subida
antes pela configuração `api-teste` da atena-api (`projetos/atena-api/api-teste.md`, a partir de `../atena-api`).

- **Do usuário (não derrubar)**: `ng serve` em 4200, API em 3000. **Teste**: front em 3191, API em 3190.
- `src/environments/environment.ts` aponta fixo para `http://localhost:3000/api/v1`: **não alterar**. A troca para 3190 é feita só na
  cópia compilada, no scratchpad.

1. **API**: siga a configuração da atena-api até o health check em `http://localhost:3190/api/v1/integridade`.
2. **Build**: `npx ng build --configuration development --output-path <scratchpad>/painel` (não usa o `dist/` do projeto).
3. **Apontar para a API de teste**: nos `.js` de `<scratchpad>/painel/browser` (ou da raiz da saída, conforme a versão do Angular),
   troque `http://localhost:3000/api/v1` por `http://localhost:3190/api/v1` (`grep -l` + `sed -i`) e confirme com `grep` que não sobrou
   `localhost:3000`.
4. **Servir**: `npx --yes serve -s <scratchpad>/painel/browser -l 3191` em segundo plano (`-s` devolve o `index.html` nas rotas do SPA).
   A CORS da atena-api (`CorsConfig`, `app.cors.allowed-origins`) só aceita a 4200 por padrão: suba a API de teste com
   `APP_CORS_ALLOWED_ORIGINS=http://localhost:3191` no ambiente.
5. **Login no navegador** sem digitar senha:
   1. Faça o login de teste por curl (credencial do usuário de teste da atena-api, sem exibir) e grave a resposta em
      `<scratchpad>/painel/browser/sessao-teste.json` — fica no scratchpad, nunca no projeto.
   2. Em `http://localhost:3191/`, reproduza o `salvarSessao` de `core/services/auth.service.ts`:
      `const r = await (await fetch('/sessao-teste.json')).json(); localStorage.setItem('tokennrt', r.token);
      localStorage.setItem('userName', r.nome); localStorage.setItem('userId', String(r.usuarioId));
      if (r.refreshToken) localStorage.setItem('refreshnrt', r.refreshToken);
      localStorage.setItem('user_data', JSON.stringify({ ...r, token: undefined, refreshToken: undefined }));` e navegue para
      `/painel/home`.
   3. Apague `sessao-teste.json` na hora.
6. **Conferência**: validar pelo DOM, uma ação por chamada; mudança que depende de regra da API → conferir o texto de ajuda da tela.
7. **Ao terminar**: encerre o `serve` (porta 3191) e a API de teste (porta 3190); `<scratchpad>/painel` pode ser apagado.
