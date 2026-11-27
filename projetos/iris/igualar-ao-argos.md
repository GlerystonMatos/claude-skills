Base: argos

# Igualar ao Argos — Íris

- **Correspondência**: `argos-front/src` ↔ `iris-front/src` (telas de cadastro em `features/admin/<cadastro>/`, layout interno em
  `features/interno/LayoutInterno.tsx`, portal em `features/portal/`), `argos-back/Argos.*` ↔ `iris-back/Iris.*` (`Iris.slnx`,
  `Iris.Testes`), `argos-doc/` ↔ `iris-doc/`.
- **Diferenças conhecidas**: o tema não exporta `tema` (use `useMediaQuery((tema) => ...)`); o menu do usuário tem avatar próprio
  (transparente, borda só nas iniciais); o Sobre é só da Íris e só na área interna (textos em `components/sobreIris.ts`, iguais aos da
  aba Íris do Argos); o Autor mostra os dois coautores (`api/githubApi.ts`); foto de usuário vem como `fotoUrl` assinada no DTO, não por
  download autenticado como no Argos.
- **CSP**: `iris-front/nginx.conf` tem três blocos `Content-Security-Policy`; recurso externo novo entra nos três.
- **Finais de linha**: CRLF em `.cs`, `.ts`, `.tsx`, `.json`, `.html`, `.css`; LF em `.md`, `.yml`, `.conf` (`.editorconfig`).
- **Validação**: `npm run build` e `npx oxlint src` em `iris-front`; `dotnet build Iris.slnx` (0 avisos) e `dotnet test Iris.Testes` em
  `iris-back`.
- **Documentação**: `iris-doc/front.md` (telas, componentes e seção "Sobre, autores e opções dos cadastros"), `iris-doc/arquitetura.md`
  (endpoints) e `iris-doc/padroes.md` quando o padrão mudar.
- **Ao terminar**: com arquivo de `iris-back` alterado e o Docker local ainda não atualizado depois disso, rodar a skill
  `iniciar-ambiente-docker` (palavra `iris`; preserva `dados/` e `arquivos/`, nunca `down -v`) e conferir a saúde de `iris-api` e
  `iris-web`; por último, a skill `checklist-prompt` no `checklist-validacao-<branch>.md` da raiz, removendo os itens `[x]`.
