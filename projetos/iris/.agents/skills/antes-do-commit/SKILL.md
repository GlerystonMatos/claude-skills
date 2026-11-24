---
name: antes-do-commit
description: Checklist da Íris antes de commitar — confere e atualiza o que acompanha uma mudança (documentos do armazenamento, migração, permissões, tipos.ts, iris-doc, READMEs, versão), normaliza imports e finais de linha e roda builds, testes e lint. Use quando o usuário pedir "atualize o que for necessário antes do commit", "deixe pronto para commit" ou ao terminar uma funcionalidade.
---

# Antes do commit (Íris)

Escopo = `git status` + `git diff HEAD` (stage e working tree, inclusive arquivos novos). Para cada item, **corrija** o que faltar; no
fim, liste o que foi alterado e o que não se aplicava.

1. **Documento do armazenamento** criado/renomeado/removido (`CaminhosDados`)? Atualizar juntos: a classificação em
   `ServicoIntegridadeDados` (`DocumentosFixos` para nome fixo; ramo por prefixo, com checagem de órfão, para família por
   produto/página — ver `iris-doc/gotchas.md`), o cache de `ArmazenamentoComCache` (se for documento fixo lido com frequência), o resumo
   de `GET /api/dados/resumo` (`ResumoDados` nos dois lados) se o documento tiver contagem própria, a tabela Documentos de
   `iris-doc/dados.md` e a de `iris-doc/arquitetura.md`. Mudança incompatível de formato ou de nome → **novo passo** no fim de
   `MigradorDados.Passos` (`Nucleo/Migracao`; id `NNNN-descricao`, registro em `MigracaoVersao`, cópia `MigracaoCopia_<nome>` antes de
   alterar; roteiro em "Como adicionar um passo" de `iris-doc/dados.md`), com teste. Campo novo opcional com padrão não precisa de passo.
   Nunca perder dado registrado; publicações, versões e downloads só `Retirado`/`Arquivado`.
2. **Funcionalidade visível** mudou? Documento correspondente de `iris-doc/` (`front.md`, `manual.md`, `atualizadores.md`). Regra de
   acesso → permissão do perfil (`PermissoesPerfil` + `src/api/tipos.ts` + `features/auth/catalogoPermissoes.ts` com ajuda +
   `PerfisPadrao`), nunca pelo nome do perfil. Endpoint `/api/portal/*` filtra por `clienteId` e `produtosLiberados` (produto não
   liberado = 404). Nenhuma ação de escrita aparece para o usuário de cliente.
3. **Endpoint/DTO** mudou? `src/api/tipos.ts` espelha exatamente o record C#; rota nova com `WithSummary`; tabela de endpoints em
   `iris-doc/arquitetura.md`.
4. **Regra não óbvia** nova ou revertida? Registrar no documento certo de `iris-doc/` (índice no `AGENTS.md`), sucinto, sem duplicar.
   Decisão ou pendência → `iris-doc/progresso.md`. **Padrão** novo ou alterado → `iris-doc/padroes.md`; se o padrão vier do Argos,
   confira o pacote `iris-doc/padroes/` (cópia do Argos, não editar aqui — ver `iris-doc/skills.md`).
5. **Padrões** (`iris-doc/padroes.md`) nos arquivos alterados: sem comentários; pt-BR; C# com tipo explícito (nenhum `var`), `using`
   ordenado, `ResultadoApi<T>` em vez de exception, só `InvariantCulture`, hora local só por `FusoAplicacao`; TS sem `any`/`enum`,
   `import type`, imports em pirâmide (uma linha por comprimento crescente, depois multilinha, `@mui/material` por último); nenhum hex
   fora de `theme.ts`. Telas: densidade pelo tema (campos 36 px, botões 32 px, 36 px na linha de um campo; nada de `size`/altura
   sobrescritos), `CartaoCadastro` + `CabecalhoView`, todo botão com ícone, Salvar só com alteração e formulário válido, grids com
   `PaginacaoTabela` + `useGradeResponsiva`, dialogs largos `fullScreen` abaixo de `sm`, **modal nunca rola** por inteiro
   (`ESTILO_CONTEUDO_SEM_ROLAGEM` + `ESTILO_AREA_ROLAVEL`), texto com reticências com `TooltipSeCortado`. Conteúdo rico só JSON do
   Tiptap validado no back.
6. **Versão**: se o usuário pediu nova versão, `version` de `iris-front/package.json` = `<Version>` de `iris-back/Directory.Build.props`
   (o teste `VersaoBackFrontTestes` garante). Não mude a versão sem pedido.
7. **Finais de linha** (`.gitattributes`) em cada arquivo de `git diff --name-only HEAD` e nos novos: CRLF em
   `.cs/.ts/.tsx/.js/.py/.json/.html/.css/.slnx/.csproj/.props`, LF em `.md/.yml/.conf/.sh/Dockerfile/.dockerignore`, UTF-8 sem BOM.
   Converter os divergentes (o `sed -i` do Git Bash troca CRLF por LF).
8. **Builds**: `cd iris-back && dotnet build Iris.slnx` (0 warnings; `MSB3026/7` = API rodando, reinicie),
   `dotnet test Iris.Testes`, `cd iris-front && npm run build` e `npm run lint` limpos. Falhou → corrigir e repetir; reportar a saída se
   não der.
9. Não commitar; sugerir a skill `texto-commit` para a mensagem.
