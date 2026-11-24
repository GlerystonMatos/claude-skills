# Antes do commit — Dashboard FRT

Itens específicos lidos pela skill global `antes-do-commit`. Front React/Vite sem MUI; segue o padrão do Argos com as adaptações do
`CLAUDE.md` (sem base: o armazenamento é PostgreSQL na API).

**Relacionados**: `../dashboard-frt-api`.
**Espelho de tipos**: `src/api/tipos.ts` × DTOs de `../dashboard-frt-api/DashboardFrt.Domain/Dto` (chaves com `JsonPropertyName` no
front entre aspas; `Id`/`LicenciadoId` vêm de `DtoLicenciada`; DTOs de ingestão, login e cadastro não precisam de interface).

## Itens específicos

1. **Regras do `CLAUDE.md`** (buscas em `src/`), além das regras básicas:
   - nada de `export default` (só `App`), `fetch(` fora de `api/http.ts`, `localStorage` fora de `utils/preferenciasLocais.ts`,
     ` title=` (use `Dica`), axios, zustand, react-query ou roteador;
   - tela nova `lazy` no `App`; seleção nova com `Selecao`/`SelecaoMultipla`; lógica pura em `.ts` separado com teste vitest.
2. **Outro espelho com a API**:
   - `intervaloDoPeriodo` (`features/filtros/filtros.ts`) × `ObterIntervaloPeriodo` (`DashboardService`), inclusive
     `MesesPeriodoPadrao`. Mudou um, mude o outro na mesma tarefa.
   - Card sem endpoint na API não entra.

## Validação

Tela mexida → conferir no navegador (claro, escuro e celular) com a skill `api-teste`; se não der, dizer que ficou pendente.
