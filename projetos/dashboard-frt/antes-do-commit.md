# Antes do commit — Dashboard FRT

Itens específicos lidos pela skill global `antes-do-commit`. Front React/Vite sem MUI; segue o padrão do Argos com as adaptações do
`CLAUDE.md`.

## Itens específicos

1. **Regras do `CLAUDE.md`** (buscas em `src/`):
   - nada de `any`, `enum`, `export default` (só `App`), comentários, hex em `.tsx`, `fetch(` fora de `api/http.ts`, `localStorage`
     fora de `utils/preferenciasLocais.ts`, ` title=` (use `Dica`), axios, zustand, react-query ou roteador;
   - `import type` para tipos e imports em pirâmide (uma linha por comprimento crescente, depois os multilinha);
   - tela nova `lazy` no `App`; seleção nova com `Selecao`/`SelecaoMultipla`; lógica pura em `.ts` separado com teste vitest.
2. **Espelhos com a API** (`../dashboard-frt-api`):
   - `src/api/tipos.ts` × DTOs (`DashboardFrt.Domain/Dto`): mesmos nomes e propriedades (chaves com `JsonPropertyName` no front
     entre aspas; `Id`/`LicenciadoId` vêm de `DtoLicenciada`). DTOs de ingestão, login e cadastro não precisam de interface.
   - `intervaloDoPeriodo` (`features/filtros/filtros.ts`) × `ObterIntervaloPeriodo` (`DashboardService`), inclusive
     `MesesPeriodoPadrao`. Mudou um, mude o outro na mesma tarefa.
   - Endpoint usado pelo front existe na API (card sem endpoint não entra).
3. **Checklist de validação** na raiz: pedido implementado entra com a skill `checklist-prompt`.

## Finais de linha

`.editorconfig`/`.gitattributes`: CRLF em `.ts/.tsx/.json/.js/.css/.html/.svg`, LF em `.md/.yml/.conf/.sh`, `Dockerfile` e
`.dockerignore`, UTF-8 sem BOM. No índice tudo `i/lf`; na pasta, converta os divergentes com `perl` e confirme que `git write-tree`
não mudou.

## Validação

- `npm run build`, `npm run lint` e `npm test` limpos.
- Tela mexida → conferir no navegador (claro, escuro e celular) com a skill `api-teste`; se não der, dizer que ficou pendente.
