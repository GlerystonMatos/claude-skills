# Antes do commit — Assistente de Pneus

Itens específicos lidos pela skill global `antes-do-commit`. Front React/Vite com MUI e ícones Phosphor, sem back-end próprio (a API é
a do DVEICA); segue o padrão do Argos com as adaptações do `AGENTS.md` do projeto (sem base: não há armazenamento nem migração aqui).

**Relacionados**: nenhum repositório local; a API do DVEICA não está na pasta dos projetos.
**Espelho de tipos**: `src/api/tipos.ts` × respostas de `/api/assistente-pneus/*` do DVEICA. Mudou um contrato, ajuste o tipo, o
módulo `src/api/<area>Api.ts` e os dados da API simulada (`projetos/assistente-pneus/api-teste/scripts/api-simulada.mjs`).

## Itens específicos

1. **Buscas em `src/`**, além das regras básicas e dos padrões:
   - nada de `export default` (só `App`), `fetch(` fora de `api/http.ts`, `sessionStorage` fora de `api/sessao.ts`, `localStorage`,
     axios, roteador, Tailwind ou hex fora de `theme.ts`;
   - imports em pirâmide: `node "<projetos>/claude-skills/skills/revisar-padroes/scripts/verificar-imports.mjs" --verificar` sobre os
     `.ts`/`.tsx` de `src/`;
   - funções e componentes com retorno explícito; lógica pura nova em `.ts` com `*.test.ts` ao lado.
2. **Identidade visual**: a densidade do Argos não foi adotada (botões de 44 px, cantos 12 px); não trocar tamanhos nas telas sem
   decisão registrada no `AGENTS.md`. Todo botão com ícone Phosphor de 16 px. Regras do `MuiCssBaseline` em `theme.ts` reproduzem o
   reset do Tailwind antigo: não remover sem medir o layout.
3. **Regras de domínio** do `AGENTS.md` mexidas (payload, validação, giro do hodômetro, edição)? Atualize o `AGENTS.md` e os testes de
   `movimentacao/` e `estado/`.
4. **Deploy**: porta 8080 em `Dockerfile`, `nginx.conf` e `cloudbuild.yaml` iguais; o passo de validação do Cloud Build roda lint e
   testes.

## Validação

`npm run build`, `npm run lint` (0 avisos) e `npm test`. Tela mexida → conferir no navegador com a skill `api-teste` (API simulada),
em claro, escuro e celular; mudança que deveria preservar o layout → comparar com o `main` pelo `comparar-layout.mjs`.
