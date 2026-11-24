# Antes do commit — Painel Atena

Itens específicos lidos pela skill global `antes-do-commit`. Front Angular; não segue o padrão do Argos.

**Relacionados**: `../atena-api`.
**Espelho de tipos**: models de `src/app/core/models` × DTOs (records) da atena-api.

## Itens específicos

1. **Funcionalidade visível** mudou? Atualizar o doc da área em `docs/` (cadastro → `cadastros.md`; roteamento, serviços, menu,
   Painel de Controle → `arquitetura.md`; regra de uma tela → `telas.md`). Item novo no menu: nome igual ao título da tela.
2. **Regra de cálculo da API** mudou (`../atena-api`)? Atualizar o texto de ajuda da tela que exibe o dado (ex.: `ajuda` em
   `dashboard.component.ts`).
3. **Regra não óbvia**: doc certo de `docs/` (índice no `CLAUDE.md`).
4. **Padrões** (`docs/padroes.md`), além das regras básicas (valem no código novo; sem comentários também em HTML e SCSS): arrays de
   `@NgModule` em pirâmide como os imports; hex só em `styles.scss`; CSS de componente com escopo.

## Validação

`npm run lint` e `ng build --configuration homologation` no lugar do `npm run build`: o build de produção já falha por orçamento de
bundle desde antes e não é critério.
