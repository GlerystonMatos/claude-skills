Base: argos

# Antes do commit — Argos

Itens do Argos além da base. `<doc>` = `argos-doc`, `<back>` = `argos-back` (`Argos.slnx`), `<front>` = `argos-front`. O Argos é a
origem do pacote de padrões `argos-doc/padroes/`.

1. **Documento do armazenamento**: atualizar também `features/dados/arquivosDados.ts` (descrição na tela Backup e dados). Passo de
   migração implementa `IPassoMigracao` (`Necessario` + `ContextoMigracao.CopiarAntesDeAlterar`).
2. **Funcionalidade visível** mudou? Seção correspondente do Manual (`argos-back/Argos.Api/Manual/*.md`, também lida pelo assistente).
   Configuração editável nova → aparece no **Resumo** (`features/resumo`).
3. **Espelho de tipos**: tabela de endpoints no `argos-back/README.md`.
4. **Padrão** novo, alterado ou revertido (camadas, dados, permissões, tema, componente compartilhado, infra, processo, versão de
   dependência)? Atualizar o pacote `argos-doc/padroes/` conforme "Manutenção" do `00-leia-me.md` (documento da área, `catalogo.json`,
   checklist `09a`/`09b` e, se obrigatório, `10-agents.md`), sem segredos e com todo caminho citado existindo.
5. **Dialog novo**: conferir o **rodapé** (dialogs existentes só quando o usuário pedir): o botão (Fechar/Salvar) fica à mesma
   distância do conteúdo acima, da direita e da base (somar `pb` do `DialogContent` com o `pt`/`pb` do `DialogActions`); só leitura com
   um botão usa `ESTILO_ACOES_EQUILIBRADAS` + `ESTILO_CONTEUDO_ANTES_ACOES_EQUILIBRADAS`.

## Validação

Só `dotnet build Argos.slnx` e `npm run build` (o front não tem lint obrigatório no commit; não há projeto de testes no build).
