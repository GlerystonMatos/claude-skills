---
name: antes-do-commit
description: Checklist do Portal do Cliente antes de commitar — confere e atualiza o que acompanha uma mudança (documentos do armazenamento, migração, permissões, tipos.ts, portal-doc, READMEs), normaliza imports e finais de linha e roda builds, testes e lint. Use quando o usuário pedir "atualize o que for necessário antes do commit", "deixe pronto para commit" ou ao terminar uma funcionalidade.
---

# Antes do commit (Portal do Cliente)

Escopo = `git status` + `git diff HEAD` (stage e working tree, inclusive arquivos novos). Para cada item, **corrija** o que faltar; no
fim, liste o que foi alterado e o que não se aplicava.

1. **Documento do armazenamento** criado/renomeado/removido (`CaminhosDados`)? Atualizar juntos: a classificação em
   `ServicoIntegridadeDados` (`DocumentosFixos` para nome fixo; ramo por prefixo, com checagem de órfão, para família por
   produto/página — ver `portal-doc/gotchas.md`), o resumo de `GET /api/dados/resumo` (`ResumoDados` nos dois lados) se o documento
   tiver contagem própria, a tabela Documentos de `portal-doc/dados.md` e a de `portal-doc/arquitetura.md`. Mudança incompatível de formato → **novo passo** no fim de `MigradorDados.Passos` (`Nucleo/Migracao`;
   id `NNNN-descricao`, registro em `MigracaoVersao`, cópia `MigracaoCopia_<nome>` antes de alterar; roteiro em "Como adicionar um
   passo" de `portal-doc/dados.md`), testado numa cópia dos dados. Campo novo opcional com padrão não precisa de passo. Nunca perder
   dado registrado; publicações, versões e downloads só `Retirado`/`Arquivado`.
2. **Funcionalidade visível** mudou? Documento correspondente de `portal-doc/` (`front.md`, `manual.md`, `atualizadores.md`). Regra de
   acesso → permissão do perfil (`PermissoesPerfil` + `src/api/tipos.ts` + `features/auth/catalogoPermissoes.ts` com ajuda +
   `PerfisPadrao`), nunca pelo nome do perfil. Endpoint `/api/portal/*` filtra por `clienteId` e `produtosLiberados` (produto não
   liberado = 404). Nenhuma ação de escrita aparece para o usuário de cliente.
3. **Endpoint/DTO** mudou? `src/api/tipos.ts` espelha exatamente o record C#; tabela de endpoints em `portal-doc/arquitetura.md`.
4. **Regra não óbvia** nova ou revertida? Registrar no documento certo de `portal-doc/` (índice no `AGENTS.md`), sucinto, sem duplicar.
   Decisão ou pendência de fase → `portal-doc/progresso.md`.
5. **Padrões** (`portal-doc/padroes.md`) nos arquivos alterados: sem comentários; pt-BR; C# com tipo explícito, `using` ordenado,
   `ResultadoApi<T>` em vez de exception, só `InvariantCulture`, hora local só por `FusoAplicacao`; TS sem `any`/`enum`, `import type`,
   imports em pirâmide (uma linha por comprimento crescente, depois multilinha, `@mui/material` por último); nenhum hex fora de
   `theme.ts`. Telas: `CartaoCadastro` + `CabecalhoView`, Salvar só com alteração e formulário válido, grids com `PaginacaoTabela` +
   `useGradeResponsiva`, dialogs largos `fullScreen` abaixo de `sm`, **modal nunca rola** por inteiro (`ESTILO_CONTEUDO_SEM_ROLAGEM` +
   `ESTILO_AREA_ROLAVEL`), texto com reticências com `TooltipSeCortado`. Conteúdo rico só JSON do Tiptap validado no back.
6. **Finais de linha** (`.gitattributes`) em cada arquivo de `git diff --name-only HEAD` e nos novos: CRLF em
   `.cs/.ts/.tsx/.json/.html/.css/.slnx/.csproj`, LF em `.md/.yml/.conf/.sh/Dockerfile/.dockerignore`, UTF-8 sem BOM. Converter os
   divergentes.
7. **Builds**: `cd portal-back && dotnet build PortalCliente.slnx` (0 warnings; `MSB3026/7` = API rodando, reinicie),
   `dotnet test PortalCliente.Testes`, `cd portal-front && npm run build` e `npm run lint` limpos. Falhou → corrigir e repetir;
   reportar a saída se não der.
8. Não commitar; sugerir a skill `texto-commit` para a mensagem.
