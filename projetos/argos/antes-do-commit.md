# Antes do commit — Argos

Itens específicos lidos pela skill global `antes-do-commit`. Projeto no padrão do Argos (é a origem do pacote `argos-doc/padroes/`).

## Itens específicos

1. **Documento do armazenamento** criado/renomeado/removido (`CaminhosDados`)? Atualizar juntos: `features/dados/arquivosDados.ts`,
   `ServicoIntegridadeDados`, esquema em `argos-doc/dados.md` (tabela Documentos) e a tabela de `argos-doc/arquitetura.md`.
   Mudança incompatível de formato → **novo passo** `IPassoMigracao` no fim de `MigradorDados.Passos` (`Nucleo/Migracao`; id `NNNN-...`,
   `Necessario` + `ContextoMigracao.CopiarAntesDeAlterar`; roteiro em `argos-doc/dados.md`), testado numa cópia dos dados reais.
2. **Funcionalidade visível** mudou? Seção correspondente do Manual (`argos-back/Argos.Api/Manual/*.md`). Configuração editável nova →
   aparece no **Resumo** (`features/resumo`). Regra de acesso → permissão do perfil (`PermissoesPerfil` + `tipos.ts` +
   `catalogoPermissoes.ts` com ajuda + `PerfisPadrao`), nunca pelo nome do perfil.
3. **Endpoint/DTO** mudou? `src/api/tipos.ts` espelha o record C#; tabela de endpoints no `argos-back/README.md`.
4. **Regra não óbvia**: doc certo de `argos-doc/` (índice no `CLAUDE.md`). **Padrão** novo, alterado ou revertido (camadas, dados,
   permissões, tema, componente compartilhado, infra, processo, versão de dependência)? Atualizar o pacote `argos-doc/padroes/`
   conforme "Manutenção" do `00-leia-me.md` (documento da área, `catalogo.json`, checklist `09a`/`09b` e, se obrigatório,
   `10-agents.md`), sem segredos e com todo caminho citado existindo.
5. **Padrões** (`argos-doc/padroes.md`): sem comentários; pt-BR; C# com tipo explícito e `using` ordenado; TS sem `any`/`enum`,
   imports em pirâmide (uma linha por comprimento crescente, depois multilinha, `@mui/material` por último), `import type`; nenhum hex
   fora de `theme.ts`. Em dialog **novo**, conferir o **rodapé** (dialogs existentes não são ajustados por conta própria, só quando o
   usuário pedir): o botão (Fechar/Salvar) fica à mesma distância do conteúdo acima, da direita e da base (somar `pb` do
   `DialogContent` com o `pt`/`pb` do `DialogActions`); só leitura com um botão usa `ESTILO_ACOES_EQUILIBRADAS` +
   `ESTILO_CONTEUDO_ANTES_ACOES_EQUILIBRADAS`. Em todo dialog com lista que cresce (comentários, histórico, etapas, anexos), conferir
   que o **modal nunca rola**: só a área da lista rola por dentro (`ESTILO_CONTEUDO_SEM_ROLAGEM` no `DialogContent` +
   `ESTILO_AREA_ROLAVEL` na área), com título, abas e rodapé fixos.

## Finais de linha

`.editorconfig`: CRLF em `.cs/.ts/.tsx/.json`, LF em `.md/.yml/.conf/.tf`, UTF-8 sem BOM.

## Validação

- `cd argos-back && dotnet build Argos.slnx` (0 warnings; `MSB3026/7` = API rodando, reinicie).
- `cd argos-front && npm run build` limpo.

## Progresso

Arquivos temporários em `.claude/progress-*.md`.
