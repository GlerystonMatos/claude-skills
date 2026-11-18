---
name: checklist-prompt
description: Mantém o checklist de validação dos pedidos do usuário — a cada pedido implementado, inclui os itens no padrão do checklist do projeto (seção por data, subseções por funcionalidade, itens "- [ ]" verificáveis) e remove os itens já totalmente verificados. Use sempre que terminar de implementar algo pedido pelo usuário, quando ele pedir "inclua no checklist", "atualize o checklist" ou "remova os itens concluídos do checklist".
---

# Checklist dos pedidos

Objetivo: o usuário sempre tem, num arquivo só, a lista do que pediu e ainda precisa conferir, sem itens já verificados.

## 1. Achar o arquivo
- Procure na raiz do repositório um `checklist-validacao-*.md` (ex.: `checklist-validacao-gm-projeto.md`). Havendo mais de um, use o do
  branch atual (`git branch --show-current`, com `/` trocada por `-`).
- Sem arquivo, crie `checklist-validacao-<branch>.md` na raiz, com o título `# Checklist de validação (<branch>)` e uma linha explicando o
  uso: marcar `[x]` ao conferir no ambiente real.
- Finais de linha **LF**, UTF-8 sem BOM.

## 2. Padrão dos itens (copie o do arquivo, se já existir)
- **Seção por leva de pedidos**: `## <N>. Validação dos pedidos de <dd/mm/aaaa>` (N = próximo número das seções existentes), com uma
  frase dizendo que é a lista do que foi pedido na sessão.
- **Subseção por funcionalidade**: `### <N>.<k> <Módulo — assunto>` (ex.: `### 24.3 Sino do Hermes`).
- **Itens**: `- [ ] <o que conferir e onde>` — verificável, com o caminho da tela (ex.: "Cadastros → Usuários: switch **Ativo**…"), o
  comportamento esperado e os casos de borda (permissão, celular, dado antigo). Linhas longas quebradas em ~140 colunas com 2 espaços de
  recuo na continuação.
- Marcadores no fim do item quando couber:
  - `(conferido no ambiente de teste)` — já validado por você no ambiente isolado; o usuário ainda confere no real.
  - `**(só você)**` — só o usuário consegue validar (conta Google, loja, produção, dado real).
- Opcional, quando ajuda a validar: blocos **Como operar** (passos numerados) e **Exemplo numérico** antes dos itens.
- Um item por comportamento; nada de "funciona tudo". Inclua também documentação, versão (O que há de novo), migração e builds quando
  fizerem parte do pedido.

## 3. Ao terminar cada pedido
1. Inclua os itens do que foi implementado na seção da leva atual (crie a seção se for a primeira entrega da sessão). Pedido ajustado
   depois → atualize o item existente, sem duplicar.
2. Só marque `[x]` o que **você** verificou de fato (teste automatizado, build ou navegador); o resto fica `[ ]`.
3. **Limpe**: remova todo item `[x]` e toda subseção/seção que ficar sem itens `[ ]` (seção só com texto de apoio e sem itens também sai).
   Itens `[ ]` antigos ficam, mesmo de outras datas. Renumere só se o usuário pedir.
4. Nunca apague item `[ ]` por conta própria nem marque `[x]` por suposição. Se um pedido foi desfeito, troque o item pelo comportamento
   atual.
5. Diga ao usuário, em uma linha, quantos itens entraram e quantos saíram (verificados).

## 4. Não fazer
- Não commitar o checklist por conta própria (só quando o usuário pedir o commit).
- Não colocar senhas, tokens, e-mails reais nem dados de clientes nos itens.
