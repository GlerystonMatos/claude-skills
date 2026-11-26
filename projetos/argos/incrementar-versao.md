Esquema: semver

# Incrementar versão — Argos

Configuração lida pela skill global `incrementar-versao`. A extensão do navegador acompanha a versão do Argos.

- **Arquivos de versão** (sempre iguais): `argos-front/package.json` (`version`, arquivo principal), `argos-front/package-lock.json`
  (raiz), `argos-back/Directory.Build.props` (`<Version>`, também mostrada no Swagger), `argos-extensao/package.json` e
  `argos-extensao/package-lock.json` (raiz).
- **Branch publicada**: `origin/deploy`.
- **Changelog** (O que há de novo): um arquivo por versão em `argos-front/src/features/novidades/versoes/<versão>.md`, lido pelo
  `versoesNovidades.ts`; nunca apagar os antigos. Formato (LF, sem BOM):
  ```markdown
  ---
  data: AAAA-MM-DD
  ---
  ## <Módulo ou tela>
  - Frase curta na linguagem do usuário, com o caminho de menu (Configurações → Backup e dados) e telas/botões em **negrito**.
  ```
  Seções pelos módulos do `CLAUDE.md` (Chronos, Hermes, Dédalo, Hestia, Cerberus…) ou pela tela; ajustes de layout num grupo como
  "Celular e tablet" ou "Telas e grades".
- **Acompanha a versão**: itens no checklist de validação do branch (skill `checklist-prompt`): Sobre, rodapé e Swagger com a versão
  nova, O que há de novo abrindo com ela e a extensão gerada com a versão (publicação na loja só pelo usuário).
- **Validação**: `dotnet build argos-back/Argos.slnx` (0 warnings), `dotnet test argos-back/Argos.Testes --filter
  "FullyQualifiedName~Versao"` (`VersaoBackFrontTestes` compara back e front), `npm run build` em `argos-front` e em `argos-extensao`
  (o build da extensão confere a versão e gera o `dist`).
- **Commit** (só com pedido): `feat: versão X.Y.Z com <principais mudanças>`, como no `git log`.
