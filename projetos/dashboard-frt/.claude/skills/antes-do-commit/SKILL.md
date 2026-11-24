---
name: antes-do-commit
description: Checklist do Dashboard FRT antes de commitar — confere a origem, as regras do CLAUDE.md (any/enum, export default, hex, fetch solto, localStorage, title, comentários, imports), o espelho de src/api/tipos.ts com os DTOs e do intervalo dos períodos com a API, README e .env.example, finais de linha, e roda build, lint e testes. Use quando o usuário pedir "use antes do commit", "atualize o que for necessário antes do commit", "deixe pronto para commit" ou ao terminar uma funcionalidade.
---

# Antes do commit (Dashboard FRT)

Escopo = `git status` + `git diff HEAD` (stage e working tree). Para cada item, **corrija** o que faltar; no fim, liste o que foi
alterado e o que não se aplicava.

1. **Origem**: `git fetch` e `git status -sb`. Atrás de `origin`? Veja o que veio (`git log HEAD..@{u}`, `git show --stat`) e os
   arquivos tocados pelos dois lados antes de commitar. Se o trabalho local já incorpora o commit de fora, `git reset --soft @{u}`
   mantém o stage e evita conflito; se não, use a skill `validar-rebase`. Confirme que nada do commit de fora se perdeu sem motivo.
2. **Regras do `CLAUDE.md`** (buscas em `src/`):
   - nada de `any`, `enum`, `export default` (só `App`), comentários, hex em `.tsx`, `fetch(` fora de `api/http.ts`, `localStorage`
     fora de `utils/preferenciasLocais.ts`, ` title=` (use `Dica`), axios, zustand, react-query ou roteador;
   - `import type` para tipos e imports em pirâmide (uma linha por comprimento crescente, depois os multilinha);
   - tela nova `lazy` no `App`; seleção nova com `Selecao`/`SelecaoMultipla`; lógica pura em `.ts` separado com teste vitest.
3. **Espelhos com a API** (`../dashboard-frt-api`):
   - `src/api/tipos.ts` × DTOs (`DashboardFrt.Domain/Dto`): mesmos nomes e propriedades (chaves com `JsonPropertyName` no front
     entre aspas; `Id`/`LicenciadoId` vêm de `DtoLicenciada`). DTOs de ingestão, login e cadastro não precisam de interface.
   - `intervaloDoPeriodo` (`features/filtros/filtros.ts`) × `ObterIntervaloPeriodo` (`DashboardService`), inclusive
     `MesesPeriodoPadrao`. Mudou um, mude o outro na mesma tarefa.
   - Endpoint usado pelo front existe na API (card sem endpoint não entra).
4. **Docs**: comando, variável, estrutura ou fluxo de token mudou → `README.md` e `.env.example`. Regra que vale sempre mudou →
   `CLAUDE.md`. Pedido implementado → item no checklist de validação da raiz (skill `checklist-prompt`).
5. **Finais de linha** (`.editorconfig`/`.gitattributes`): CRLF em `.ts/.tsx/.json/.js/.css/.html/.svg`, LF em
   `.md/.yml/.conf/.sh`, `Dockerfile` e `.dockerignore`, UTF-8 sem BOM. `git ls-files --eol <arquivos>`: no índice tudo `i/lf`; na
   pasta, converta os divergentes com `perl -pi -e 's/(?<!\r)\n/\r\n/'` (respeita arquivo sem quebra no fim) e confirme que
   `git write-tree` não mudou.
6. **Validação**: `npm run build`, `npm run lint` e `npm test` limpos. Falhou → corrigir e repetir; reportar a saída se não der.
   Tela mexida → conferir no navegador (claro, escuro e celular) com a skill `api-teste`; se não der, diga que ficou pendente.
7. Não commitar por conta própria; sugerir a skill `texto-commit` para a mensagem.
