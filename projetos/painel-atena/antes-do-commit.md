# Antes do commit — Painel Atena

Itens específicos lidos pela skill global `antes-do-commit`. Front Angular; não segue o padrão do Argos.

## Itens específicos

1. **Funcionalidade visível** mudou? Atualizar o doc da área em `docs/` (cadastro → `cadastros.md`; roteamento, serviços, menu,
   Painel de Controle → `arquitetura.md`; regra de uma tela → `telas.md`). Item novo no menu: nome igual ao título da tela.
2. **Regra de cálculo da API** mudou (`../atena-api`)? Atualizar o texto de ajuda da tela que exibe o dado (ex.: `ajuda` em
   `dashboard.component.ts`). Endpoint/DTO mudou? Ajustar os dois lados.
3. **Regra não óbvia**: doc certo de `docs/` (índice no `CLAUDE.md`).
4. **Padrões** (`docs/padroes.md`): sem comentários no que foi adicionado (TS, HTML, SCSS); pt-BR; TS sem `any`/`enum` no código novo,
   imports e arrays de `@NgModule` do menor para o maior (pirâmide), `import type`; nenhum hex fora de `styles.scss`; CSS de componente
   com escopo.

## Finais de linha

`.editorconfig`: CRLF em `.ts/.html/.scss/.json`, LF em `.md/.yml/.conf`, UTF-8 sem BOM.

## Validação

- `npm run lint` e `ng build --configuration homologation` limpos.
- O `npm run build` de produção já falha por orçamento de bundle desde antes; não é critério.
