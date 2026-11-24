---
name: medir-layout
description: Mede no navegador o layout da Íris contra iris-doc/padroes.md — altura dos campos (36 px) e dos botões (32 px, ou 36 na linha de um campo), folga de chips e badges, texto no meio da linha (pela tinta das letras), distância do texto de ajuda, botões sem ícone, altura do menu lateral, modal que rola e página que rola na horizontal — numa tela, num dialog ou varrendo várias telas pelo menu. Use depois de mexer no tema, em estilos de campos/botões/dialogs ou quando o usuário disser que algo está desalinhado, encostando, alto/baixo demais ou fora do centro.
---

# Medir layout (Íris)

Mede com o DOM e as métricas da fonte, sem depender de captura de tela. Script adaptado do Argos (mesmas alturas).

## 1. Ambiente

1. Suba a API e o front de teste com a skill `api-teste` (porta 5291) e entre pelo login de teste descrito nela.
2. No navegador, abra uma aba nova em `http://localhost:5291/`. Para medir no celular sem redimensionar a janela, crie um `iframe` fixo
   de 390×844 com `src='/'` na própria aba (a sessão do `sessionStorage` vale nele) e carregue o medidor dentro dele.

## 2. Carregar o medidor

Leia `scripts/medir-layout.js` desta skill e execute o conteúdo inteiro na página (uma vez por carregamento; `location.reload()` apaga).
Ele cria `window.irisLayout` com:

| Função | O que faz |
|---|---|
| `await irisLayout.irPara('Cadastros', 'Clientes')` | Navega pelo menu lateral (abre o grupo se precisar) |
| `irisLayout.medir()` | Mede o dialog aberto (ou o `main`) e devolve `{ titulo, campos, problemas }` |
| `await irisLayout.varrer([['Cadastros', 'Clientes'], ...])` | Navega e mede cada tela |
| `irisLayout.menuLateral()` | Altura de cada grupo/item do menu (32 px) |
| `await irisLayout.abas()` | No dialog aberto, clica em cada aba e confere que o modal não rola (só a área interna) |
| `irisLayout.transbordo()` | Diz se a página rola na horizontal e lista os elementos que passam da largura (use em 360–400 px) |

`fecharAvisosIniciais()` existe por compatibilidade com o Argos e não encontra nada na Íris. `problemas` vazio = dentro do padrão.
`campos: 0` numa tela que deveria ter campos = a tela não carregou; diga isso em vez de concluir que está tudo certo.

## 3. O que cada problema quer dizer

- **altura N (esperado 36)**: campo fora de `ALTURA_CONTROLE`; procure `size`/`height`/`py` sobrescritos na tela.
- **botão: N (esperado 32/36)**: 36 só quando o botão fica na linha de um campo ou dentro de `.linha-controles`
  (`CLASSE_LINHA_CONTROLES`); se um `<span>` de tooltip separa o botão da linha, o tema não detecta e a tela precisa ajustar.
- **badge/chip com folga a/b**: menos de 5 px ou diferença acima de 1,5 px entre cima e embaixo.
- **texto fora do meio**: distância da borda ao topo das maiúsculas e da base à borda devem ficar iguais (±1,5 px).
- **texto de ajuda a N px do rótulo de baixo**: menos de 3 px encosta; o padrão é ~5 px.
- **botão sem ícone**: todo botão tem `startIcon`.

## 4. Fechar

Feche a aba, encerre a API e o front de teste e relate as medidas (antes/depois) e o que não foi possível medir.
