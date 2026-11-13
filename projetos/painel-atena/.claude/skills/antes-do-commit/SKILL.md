---
name: antes-do-commit
description: Checklist do Painel Atena antes de commitar — confere e atualiza o que acompanha uma mudança (docs, textos de ajuda, CLAUDE.md), remove comentários, normaliza finais de linha e roda lint e build. Use quando o usuário pedir "atualize o que for necessário antes do commit", "deixe pronto para commit" ou ao terminar uma funcionalidade.
---

# Antes do commit (Painel Atena)

Escopo = `git status` + `git diff HEAD` (stage e working tree). Para cada item, **corrija** o que faltar; no fim, liste o que foi
alterado e o que não se aplicava.

1. **Funcionalidade visível** mudou? Atualizar o doc da área em `docs/` (cadastro → `cadastros.md`; roteamento, serviços, menu,
   Painel de Controle → `arquitetura.md`; regra de uma tela → `telas.md`). Item novo no menu: nome igual ao título da tela.
2. **Regra de cálculo da API** mudou (`../atena-api`)? Atualizar o texto de ajuda da tela que exibe o dado (ex.: `ajuda` em
   `dashboard.component.ts`). Endpoint/DTO mudou? Ajustar os dois lados.
3. **Regra não óbvia** nova ou revertida? Registrar no doc certo de `docs/` (ver índice no `CLAUDE.md`), sucinto, sem duplicar.
4. **Padrões** (`docs/padroes.md`): sem comentários no que foi adicionado (TS, HTML, SCSS); pt-BR; TS sem `any`/`enum` no código
   novo, imports e arrays de `@NgModule` do menor para o maior (pirâmide), `import type`; nenhum hex fora de `styles.scss`; CSS de componente com escopo.
5. **Finais de linha** (`.editorconfig`): CRLF em `.ts/.html/.scss/.json`, LF em `.md/.yml/.conf`, UTF-8 sem BOM. Conferir os arquivos
   alterados (`git diff --name-only HEAD`) e corrigir os divergentes.
6. **Validação**: `npm run lint` e `ng build --configuration homologation` limpos. Falhou → corrigir e repetir; reportar a saída se não
   der. (O `npm run build` de produção já falha por orçamento de bundle desde antes; não é critério.)
7. Não commitar; sugerir a skill `texto-commit` para a mensagem.
