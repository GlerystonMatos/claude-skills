---
name: medir-layout
description: Mede no navegador o layout de um projeto no padrão do Argos (tema MUI) — altura dos campos (36 px) e dos botões (32 px, ou 36 na linha de um campo), folga de chips e badges, texto no meio da linha (pela tinta das letras), distância do texto de ajuda, botões sem ícone, altura do menu lateral, modal que rola e página que rola na horizontal — numa tela, num dialog ou varrendo várias telas pelo menu. Usa a configuração do projeto no repositório claude-skills (projetos/<repo>/medir-layout.md); sem ela, propõe criá-la. Use depois de mexer no tema, em estilos de campos/botões/dialogs ou quando o usuário disser que algo está desalinhado, encostando, alto/baixo demais ou fora do centro.
argument-hint: "[tela ou instruções adicionais]"
---

# Medir layout (padrão do Argos)

Mede com o DOM e as métricas da fonte, sem depender de captura de tela (que às vezes trava no Chrome). Considere como instruções
adicionais o texto que o usuário escreveu junto da chamada.

## 0. Configuração do projeto

1. Na raiz do projeto, rode
   `node "$(git -C "<pasta desta skill>" rev-parse --show-toplevel)/scripts/configuracao.mjs" medir-layout` (a pasta da skill é uma
   junção para o `claude-skills`; `..` não serve). Ele mostra o `repositorio` (nome no `origin`), o `central` (raiz do
   `claude-skills`), as pastas `scripts-globais` e `scripts` (do projeto), quando existem, e o conteúdo da configuração do projeto
   — precedido da base, quando ela começa com `Base: <nome>`. A configuração do projeto prevalece sobre a base e sobre esta skill
   quando divergirem. Ela traz o documento de padrões, exemplos de telas para `irPara`/`varrer`, avisos iniciais e
   exceções de propósito.
2. **`SEM CONFIGURACAO`**: confirme que o projeto segue o tema do Argos (`theme.ts` com `ALTURA_CONTROLE`, `CLASSE_LINHA_CONTROLES`,
   menu lateral com `MuiListItemButton`). Se seguir, proponha a configuração (padrões, grupos e itens do menu, textos dos avisos
   iniciais) e só crie com aprovação, seguindo as regras do `claude-skills` (LF, `git pull --ff-only`, commit com a `texto-commit`
   e push). Se não seguir, diga que as alturas esperadas não se aplicam e meça só `transbordo()` e `abas()`.

## 1. Ambiente

1. Suba a API e o front de teste com a skill `api-teste` e entre pelo login de teste descrito nela.
2. No navegador (claude-in-chrome), abra uma aba nova no front de teste. Para medir no celular sem redimensionar a janela (o Chrome às
   vezes ignora), crie um `iframe` fixo de 390×844 com `src='/'` na própria aba (a sessão do `sessionStorage` vale nele), carregue o
   medidor dentro dele (`iframe.contentWindow.eval(...)`) e navegue pelo botão "abrir menu" do cabeçalho.

## 2. Carregar o medidor

Leia `scripts/medir-layout.js` desta skill e execute o conteúdo inteiro com `javascript_tool` (uma vez por carregamento da página; um
`location.reload()` apaga). Ele cria `window.medirLayout` com:

| Função | O que faz |
|---|---|
| `await medirLayout.fecharAvisosIniciais()` | Fecha avisos do acesso inicial ("Seguir sem importar", "Fechar"), quando o projeto tiver |
| `await medirLayout.irPara('Grupo', 'Item')` | Navega pelo menu lateral (abre o grupo se precisar) |
| `medirLayout.medir()` | Mede o dialog aberto (ou o `main`) e devolve `{ titulo, campos, problemas }` |
| `await medirLayout.varrer([['Grupo', 'Item'], ...])` | Navega e mede cada tela |
| `medirLayout.menuLateral()` | Altura de cada grupo/item do menu |
| `await medirLayout.abas()` | No dialog aberto, clica em cada aba e mede a altura do modal, a folga até o rodapé e se o modal rola (deve ser `false`; só a área interna rola). A altura deve ser a da maior aba |
| `medirLayout.transbordo()` | Diz se a página rola na horizontal e lista elementos que passam da largura da janela (fora de tabelas). Use com a janela em 360–400 px |

`problemas` vazio = dentro do padrão. `campos: 0` numa tela que deveria ter campos = a tela não carregou (o acesso inicial costuma não
carregar todas as telas; use o usuário de teste da `api-teste`): diga isso ao usuário em vez de concluir que está tudo certo.

## 3. O que cada problema quer dizer

- **altura N (esperado 36)**: campo fora da altura do tema (`ALTURA_CONTROLE`); procure `size`/`height`/`py` sobrescritos na tela.
- **badge/chip com folga a/b**: menos de 5 px ou diferença acima de 1,5 px entre cima e embaixo (exceções de propósito ficam na
  configuração do projeto).
- **texto fora do meio (maiúscula a / base b)**: distância da borda de cima ao topo das maiúsculas e da linha de base à borda de baixo;
  devem ficar iguais (±1,5 px); com o rótulo na borda o texto fica 2 px mais baixo de propósito (`AJUSTE_ROTULO_NA_BORDA`). O tema
  compensa a fonte com `AJUSTE_OPTICO_TEXTO`.
- **texto de ajuda a N px do rótulo de baixo**: menos de 3 px encosta; o padrão é ~5 px.
- **botão: N (esperado 32/36)**: 36 só quando o botão fica na linha de um campo (mesmo centro vertical) ou dentro de
  `.linha-controles` (`CLASSE_LINHA_CONTROLES`); no celular, botão que quebrou para a linha de baixo continua com 36 (o tema detecta
  pelo DOM) — só aponte se destoar; se um `<span>` de tooltip separa o botão da linha, o tema não detecta e a tela precisa ajustar.
- **botão sem ícone**: todo botão tem `startIcon`.
- **barra do editor: a em cima / b embaixo**: deve ser simétrica, contando de baixo do rótulo.

## 4. Fechar

Antes de concluir, olhe ao menos uma captura (`computer` → `zoom` na região) quando ela responder. Feche a aba, encerre a API e o front
de teste e relate as medidas (antes/depois) e o que não foi possível medir.
