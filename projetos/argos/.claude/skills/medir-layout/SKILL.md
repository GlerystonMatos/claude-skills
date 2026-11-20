---
name: medir-layout
description: Mede no navegador o layout do Argos contra os padrões de argos-doc/padroes.md — altura dos campos (36 px) e dos botões (32 px, ou 36 na linha de um campo), folga de chips e badges dentro dos campos, texto no meio da linha (pela tinta das letras), distância do texto de ajuda ao campo de baixo, simetria da barra do editor de texto, botões sem ícone e altura do menu lateral — numa tela, num dialog ou varrendo várias telas pelo menu. Use depois de mexer no tema, em estilos de campos/botões/dialogs ou quando o usuário disser que algo está desalinhado, encostando, alto/baixo demais ou fora do centro.
---

# Medir layout (Argos)

Mede com o DOM e as métricas da fonte, sem depender de captura de tela (que às vezes trava no Chrome).

## 1. Ambiente
1. Suba a API e o front de teste com a skill `api-teste` (porta 5191) e entre pelo login de teste descrito nela.
2. No navegador (claude-in-chrome), abra uma aba nova em `http://localhost:5191/`.

## 2. Carregar o medidor
Leia `scripts/medir-layout.js` desta skill e execute o conteúdo inteiro com `javascript_tool` (uma vez por carregamento da página; um
`location.reload()` apaga). Ele cria `window.argosLayout` com:

| Função | O que faz |
|---|---|
| `await argosLayout.fecharAvisosIniciais()` | Fecha "Nenhum dado encontrado" e "O que há de novo" do acesso inicial |
| `await argosLayout.irPara('Meu trabalho', 'Cronogramas')` | Navega pelo menu lateral (abre o grupo se precisar) |
| `argosLayout.medir()` | Mede o dialog aberto (ou o `main`) e devolve `{ titulo, campos, problemas }` |
| `await argosLayout.varrer([['Meu trabalho', 'Cronogramas'], ...])` | Navega e mede cada tela |
| `argosLayout.menuLateral()` | Altura de cada grupo/item do menu |

`problemas` vazio = dentro do padrão. `campos: 0` numa tela que deveria ter campos = a tela não carregou (o acesso inicial não carrega
Cronômetro, Usuários e parte das Configurações): diga isso ao usuário em vez de concluir que está tudo certo.

## 3. O que cada problema quer dizer
- **altura N (esperado 36)**: campo fora da altura do tema (`ALTURA_CONTROLE`); procure `size`/`height`/`py` sobrescritos na tela.
- **badge/chip com folga a/b**: menos de 5 px ou diferença acima de 1,5 px entre cima e embaixo.
- **texto fora do meio (maiúscula a / base b)**: distância da borda de cima ao topo das maiúsculas e da linha de base à borda de baixo;
  devem ficar iguais (±1,5 px). O tema compensa a fonte com `AJUSTE_OPTICO_TEXTO`.
- **texto de ajuda a N px do rótulo de baixo**: menos de 3 px encosta; o padrão é ~5 px.
- **botão: N (esperado 32/36)**: 36 só quando o botão fica na linha de um campo; se um `<span>` de tooltip separa o botão da linha, o tema
  não detecta e a tela precisa ajustar.
- **botão sem ícone**: todo botão tem `startIcon` (padrões).
- **barra do editor: a em cima / b embaixo**: deve ser simétrica, contando de baixo do rótulo.

## 4. Fechar
Antes de concluir, olhe ao menos uma captura (`computer` → `zoom` na região) quando ela responder. Feche a aba, encerre a API e o front
de teste e relate as medidas (antes/depois) e o que não foi possível medir.
