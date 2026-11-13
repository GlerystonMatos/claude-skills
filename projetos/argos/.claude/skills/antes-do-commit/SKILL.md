---
name: antes-do-commit
description: Checklist do Argos antes de commitar — confere e atualiza o que acompanha uma mudança (Manual, Resumo, tela Backup e dados, esquema em argos-doc/dados.md, argos-doc, READMEs), normaliza imports e finais de linha e roda os builds. Use quando o usuário pedir "atualize o que for necessário antes do commit", "deixe pronto para commit" ou ao terminar uma funcionalidade.
---

# Antes do commit (Argos)

Escopo = `git status` + `git diff HEAD` (stage e working tree). Para cada item, **corrija** o que faltar; no fim, liste o que foi
alterado e o que não se aplicava.

1. **Documento do armazenamento** criado/renomeado/removido (`CaminhosDados`)? Atualizar juntos: `features/dados/arquivosDados.ts`,
   `ServicoIntegridadeDados`, esquema em `argos-doc/dados.md` (tabela Documentos) e a tabela de `argos-doc/arquitetura.md`.
   Mudança incompatível de formato → **novo passo** `IPassoMigracao` no fim de `MigradorDados.Passos` (`Nucleo/Migracao`; id `NNNN-...`,
   `Necessario` + `ContextoMigracao.CopiarAntesDeAlterar`; roteiro em `argos-doc/dados.md`), testado numa cópia dos dados reais.
2. **Funcionalidade visível** mudou? Seção correspondente do Manual (`argos-back/Argos.Api/Manual/*.md`). Configuração editável nova →
   aparece no **Resumo** (`features/resumo`). Regra de acesso → permissão do perfil (`PermissoesPerfil` + `tipos.ts` + `catalogoPermissoes.ts` com ajuda + `PerfisPadrao`),
   nunca pelo nome do perfil.
3. **Endpoint/DTO** mudou? `src/api/tipos.ts` espelha o record C#; tabela de endpoints no `argos-back/README.md`.
4. **Regra não óbvia** nova ou revertida? Registrar no doc certo de `argos-doc/` (ver índice no `CLAUDE.md`), sucinto, sem duplicar.
5. **Padrões** (`argos-doc/padroes.md`): sem comentários; pt-BR; C# com tipo explícito e `using` ordenado; TS sem `any`/`enum`, imports em
   pirâmide (uma linha por comprimento crescente, depois multilinha, `@mui/material` por último), `import type`; nenhum hex fora de
   `theme.ts`. Em dialog **novo**, conferir o **rodapé** (dialogs existentes não são ajustados por conta própria, só quando o usuário pedir): o botão (Fechar/Salvar) fica à mesma distância do conteúdo acima, da
   direita e da base (somar `pb` do `DialogContent` com o `pt`/`pb` do `DialogActions`); só leitura com um botão usa
   `ESTILO_ACOES_EQUILIBRADAS` + `ESTILO_CONTEUDO_ANTES_ACOES_EQUILIBRADAS`. Em todo dialog com lista que cresce (comentários,
   histórico, etapas, anexos), conferir que o **modal nunca rola**: só a área da lista rola por dentro (`ESTILO_CONTEUDO_SEM_ROLAGEM` no
   `DialogContent` + `ESTILO_AREA_ROLAVEL` na área), com título, abas e rodapé fixos.
6. **Finais de linha** (`.editorconfig`): CRLF em `.cs/.ts/.tsx/.json`, LF em `.md/.yml/.conf/.tf`, UTF-8 sem BOM. Conferir os arquivos
   alterados (`git diff --name-only HEAD`) e corrigir os divergentes.
7. **Builds**: `cd argos-back && dotnet build Argos.slnx` (0 warnings; `MSB3026/7` = API rodando, reinicie) e
   `cd argos-front && npm run build` limpo. Falhou → corrigir e repetir; reportar a saída se não der.
8. Não commitar; sugerir a skill `texto-commit` para a mensagem.
