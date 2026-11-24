Base: argos

# Antes do commit — Íris

Itens da Íris além da base. `<doc>` = `iris-doc` (índice no `AGENTS.md`), `<back>` = `iris-back` (`Iris.slnx`, testes em
`Iris.Testes`), `<front>` = `iris-front`. O pacote `iris-doc/padroes/` é cópia do Argos: não editar aqui (ver `iris-doc/skills.md`).

1. **Documento do armazenamento**: atualizar também o cache de `ArmazenamentoComCache` (se for documento fixo lido com frequência) e o
   resumo de `GET /api/dados/resumo` (`ResumoDados` nos dois lados) se o documento tiver contagem própria; família por produto/página
   segue `iris-doc/gotchas.md`. Passo de migração registra em `MigracaoVersao` e copia para `MigracaoCopia_<nome>`; sempre com teste.
   Publicações, versões e downloads só `Retirado`/`Arquivado`.
2. **Funcionalidade visível** mudou? Documento de `iris-doc/` (`front.md`, `manual.md`, `atualizadores.md`). Endpoint `/api/portal/*`
   filtra por `clienteId` e `produtosLiberados` (produto não liberado = 404). Nenhuma ação de escrita aparece para o usuário de cliente.
3. **Espelho de tipos**: rota nova com `WithSummary`; tabela de endpoints em `iris-doc/arquitetura.md`.
4. **Documentação**: decisão ou pendência → `iris-doc/progresso.md` (documento permanente, só atualizar). Padrão novo ou alterado →
   `iris-doc/padroes.md`.
5. **Padrões** próprios: `ResultadoApi<T>` em vez de exception, só `InvariantCulture`, hora local só por `FusoAplicacao`; telas com
   `CartaoCadastro` + `CabecalhoView`, Salvar só com alteração e formulário válido, grids com `PaginacaoTabela` + `useGradeResponsiva`,
   dialogs largos `fullScreen` abaixo de `sm`, texto com reticências com `TooltipSeCortado`. Conteúdo rico só JSON do Tiptap validado no
   back.
6. **Versão**: se o usuário pediu nova versão, `version` de `iris-front/package.json` = `<Version>` de `iris-back/Directory.Build.props`
   (o teste `VersaoBackFrontTestes` garante). Não mude a versão sem pedido.
