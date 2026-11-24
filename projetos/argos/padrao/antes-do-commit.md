# Antes do commit — base do padrão do Argos

Base comum lida pela skill global `antes-do-commit` quando a configuração do projeto começa com `Base: argos`. Vale para
projetos .NET + React/MUI com armazenamento em documentos (JSON/Firestore) no padrão do Argos. `<doc>` = pasta de documentação do
projeto (`argos-doc`, `iris-doc`…), `<back>`/`<front>` = pastas da API e do front; a configuração do projeto diz quais são.

1. **Documento do armazenamento** criado/renomeado/removido (`CaminhosDados`)? Atualizar juntos: a classificação em
   `ServicoIntegridadeDados` (`DocumentosFixos` para nome fixo; ramo por prefixo, com checagem de órfão, para família de documentos),
   a tabela Documentos de `<doc>/dados.md` e a de `<doc>/arquitetura.md`, mais o que a configuração do projeto acrescentar. Mudança
   incompatível de formato ou de nome → **novo passo** no fim de `MigradorDados.Passos` (`Nucleo/Migracao`; id `NNNN-descricao`, cópia
   do documento antes de alterar; roteiro em `<doc>/dados.md`), testado numa cópia dos dados (skill `api-teste`). Campo novo opcional
   com padrão não precisa de passo. Nunca perder dado registrado.
2. **Regra de acesso** nova → permissão do perfil (`PermissoesPerfil` + `src/api/tipos.ts` + `catalogoPermissoes.ts` com texto de
   ajuda + `PerfisPadrao`), nunca pelo nome do perfil.
3. **Espelho de tipos**: `<front>/src/api/tipos.ts` × records C# da API; tabela de endpoints no documento indicado pela configuração.
4. **Padrões** (`<doc>/padroes.md`), além das regras básicas da skill: só `InvariantCulture` onde o projeto exige; nenhum hex fora de
   `theme.ts`; densidade pelo tema (campos 36 px, botões 32 px, 36 px na linha de um campo; nada de `size`/altura sobrescritos); todo
   botão com ícone. Em todo dialog com lista que cresce (comentários, histórico, etapas, anexos), o **modal nunca rola**: só a área da
   lista rola por dentro (`ESTILO_CONTEUDO_SEM_ROLAGEM` no `DialogContent` + `ESTILO_AREA_ROLAVEL` na área), com título, abas e rodapé
   fixos. Mudou o tema ou estilos de campos/botões/dialogs → medir com a skill `medir-layout`.
5. **Validação**: `dotnet build <back>/<solução>.slnx` (0 warnings) e, se houver, `dotnet test` do projeto de testes; no `<front>`,
   `npm run build` e `npm run lint` quando existir.
