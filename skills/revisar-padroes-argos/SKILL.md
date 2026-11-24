---
name: revisar-padroes-argos
description: Roda a validação completa de um projeto (build, lint, testes) e o revisa contra o pacote de padrões do Argos (C:\Projetos\argos\argos-doc\padroes) — buscas objetivas do checklist 09b (fetch solto, any/enum, export default, hex, localStorage, comentários, ordem dos imports), Docker/nginx/CI conforme 07a/07b e regras de UI de 04a/04b — e entrega um relatório com o que está no padrão, o que está fora (arquivo:linha) e o que depende de decisão. Use quando o usuário pedir "validação completa", "verificar os padrões do Argos", "o que está fora do padrão" ou "revise de novo se ficou algo pendente" num projeto que segue o Argos.
argument-hint: [pasta do projeto]
---

# Revisar contra os padrões do Argos

Objetivo: dizer, com evidência, se o projeto passa na validação e onde ele foge dos padrões do Argos, sem corrigir nada antes do
aval do usuário.

## 1. Contexto antes de revisar
- `git fetch` e compare com o remoto (`git status -sb`, `git log HEAD..origin/<branch>`). Cópia local atrasada já gerou revisão errada.
- Leia o `CLAUDE.md` e o README do projeto. Adaptações registradas ali (ex.: Tailwind no lugar do MUI) valem: não as aponte como
  desvio, só confira se estão sendo seguidas.
- Leia em `C:\Projetos\argos\argos-doc\padroes\` os arquivos que se aplicam: sempre `09b-checklist-front-ui-infra.md`; para front
  `03-frontend.md`, `04a-ui-tema-layouts.md` e `04b-ui-catalogo-componentes.md`; para Docker/CI `07a` e `07b`; para back-end/dados
  `09a-checklist-estrutura-back-dados.md` e os documentos que ele cita.

## 2. Validação
- Rode os scripts que existirem no `package.json`: `npm run build`, `npm run lint`, `npm test`. No back-end .NET: `dotnet build` e
  `dotnet test`. Registre o resultado de cada um (passou, quantos testes, avisos). Lint sem saída com código 0 conta como limpo.
- Se houver Dockerfile e o Docker estiver disponível, construa a imagem em segundo plano e confira: sobe, responde na porta, o
  `HEALTHCHECK` fica `healthy` e `docker exec <container> id` não é root. Pare e remova o container ao final.
- Navegador (claro, escuro e celular) só quando der para abrir a tela de verdade. Se depender de token, chave ou credencial que você
  não tem, diga que ficou pendente e o que falta; não invente atalho.

## 3. Buscas objetivas (front)
Em `src/`, cada uma deve voltar vazia, salvo a exceção indicada:

| Regra | Busca |
|---|---|
| `fetch` só no wrapper | `grep -rn "fetch(" src` → só `api/http.ts` |
| Sem `any`, `enum`, `forwardRef` | `grep -rnE ": any\b\|<any>\|as any\|\benum\b\|forwardRef" src` |
| Default só no `App` | `grep -rn "export default" src` → só `App.tsx` |
| Sem comentários | `grep -rnP "^\s*//(?! @ts-\|/ <ref)\|/\*" src --include=*.ts --include=*.tsx` |
| Sem hex solto | `grep -rnE "#[0-9A-Fa-f]{3,8}\b" src --include=*.tsx --include=*.ts \| grep -v theme.ts` |
| Download sem link direto | `grep -rnE "href=\{" src` revisado |
| `localStorage` num só utilitário | `grep -rln localStorage src` → só `utils/preferenciasLocais.ts` |
| Sem alias de import | `grep -rnE "from '(@/\|src/)" src` |
| Tooltip pelo componente | `grep -rn "title=" src` revisado (texto cortado e botão de ícone usam o componente de dica) |
| Retorno explícito | `grep -rnE "function \w+(<[^>]*>)?\([^)]*\)\s*\{" src` |
| Bibliotecas fora do stack | `package.json` sem roteador, estado global, cliente de consultas nem axios (ou exceção registrada) |
| Ordem dos imports | `node <pasta desta skill>/verificar-imports.mjs --verificar $(find src -name "*.ts" -o -name "*.tsx")` |

`verificar-imports.mjs` confere a pirâmide (imports de uma linha em ordem crescente de comprimento). Sem `--verificar` ele reordena;
só use assim depois do aval do usuário.

Também confira o `tsconfig` (`strict`, `noUnusedLocals`, `noUnusedParameters`, `noFallthroughCasesInSwitch`,
`verbatimModuleSyntax`, `erasableSyntaxOnly`) e se toda lógica pura em `.ts` tem `*.test.ts` ao lado (hooks com cálculo dentro
contam como desvio).

## 4. Infra e processo
- Dockerfile: multi-stage, imagem base com versão (nunca `latest`), usuário não-root (front: `nginx-unprivileged` ou `USER`),
  `HEALTHCHECK` (`/health` na API, `/` no front), `ARG VITE_API_URL` validado no build.
- nginx do SPA: `try_files $uri /index.html`, `no-cache` no `index.html`, `immutable` em `/assets/`, gzip, `server_tokens off` e os
  três cabeçalhos de segurança repetidos em cada `location`.
- `.dockerignore`, `.env.example` só com nomes, `.env` no `.gitignore` (`git check-ignore -v .env`).
- CI: lint e testes antes do build, imagem com a tag do commit, deploy e health check depois do deploy.
- `.editorconfig`/`.gitattributes` coerentes com `git ls-files --eol`.

## 5. Revisão manual de UI (04a/04b)
Toda seleção filtra digitando; filtro sem opção "Todos" (vazio = todos); todo botão e item de menu com ícone; ação só com ícone com
`aria-label` e dica; paginação 10/25/50; carregamento tudo-ou-nada com esqueleto; vazio com frase; erro visível; página sem
rolagem horizontal em 360 px.

## 6. Relatório
1. Tabela da validação (etapa e resultado), incluindo o que ficou pendente e por quê.
2. O que está dentro do padrão, em uma lista curta.
3. O que está fora, numerado e agrupado (infra e CI, interface, código), cada item com `arquivo:linha` e a regra do Argos que ele fere.
4. Separe o que é correção direta do que depende de decisão (trocar biblioteca, abrir exceção). Com várias decisões, pergunte uma por vez.

Ao corrigir com aval: rode de novo build, lint, testes e as buscas, registre no `CLAUDE.md` do projeto as exceções aceitas e as
novas regras, e termine com uma segunda revisão curta dizendo o que ainda ficou pendente.
