# API e front de teste — Assistente de Pneus

Configuração lida pela skill global `api-teste`. O assistente consome a API do DVEICA, que não roda nesta máquina: o teste usa uma
**API simulada** com dados fictícios. `<scripts>` = `claude-skills/projetos/assistente-pneus/api-teste/scripts`.

- **Teste**: API simulada em 5301, front em 5312. Comparação com o `main`: cópia do `main` em `<scratchpad>/original`, front em 5311.
- Nunca apontar o `baseUrl` para um DVEICA real (homologação ou produção). O token `teste` só vale na API simulada.

1. **API simulada**: `node <scripts>/api-simulada.mjs 5301 <scratchpad>/medicoes` em segundo plano. Responde em
   `/api/assistente-pneus/*` (estabelecimentos, depósitos, realizadores, veículos, conjunto atrelado com carreta e veículo sem leiaute,
   estrutura, último hodômetro, pneus, motivos e movimentações: gravar, atualizar, excluir e obter a 3210 para edição). Exige
   `Authorization: Bearer teste`. Casos de erro: busca contendo `falha` → 500; pneu `SALDO0` → erro 25 de saldo insuficiente;
   hodômetro menor que 1000 → pede confirmação de giro; arquivo `<scratchpad>/medicoes/falhar-conjunto` → o próximo conjunto atrelado
   falha uma vez. `/registro` devolve (e esvazia) as requisições recebidas; `/dump?nome=` grava medições; `/roteiro.js` serve o
   roteiro do navegador.
2. **Front**: `npx vite --port 5312 --strictPort` na raiz do projeto.
3. **Abrir**: `http://localhost:5312/?baseUrl=http://localhost:5301#access_token=teste&modo=insercao` (edição:
   `#access_token=teste&modo=edicao&chave=3210`). O hash vai para o `sessionStorage`; para trocar de modo sem o hash, recarregue
   depois de `sessionStorage.setItem('assistente_pneus_modo', 'insercao')`.
4. **Roteiro no navegador** (pela ferramenta de JavaScript da aba): `eval(await (await fetch('http://localhost:5301/roteiro.js')).text())`
   carrega `__escolher(rotulo, texto)`, `__botao(texto)`, `__clicarPosicao(texto)`, `__dump(nome)`, `__requisicoes(nome)` e os
   fluxos prontos `__fluxoMontagem(s, hodometro?, buscaPneu?, confirmarGiro?)`, `__fluxoDesmontagem(s)`, `__fluxoEdicao(s)` e
   `__fluxoErroPneu(s)`. Use `s = 'a'` no original e `'b'` na versão nova.
5. **Comparar layout**: `node <scripts>/comparar-layout.mjs <scratchpad>/medicoes <nome>` compara `<nome>-a.json` com `<nome>-b.json`
   (posição, tamanho, cor, borda, fonte e texto de cada elemento visível; bordas de largura zero ignoradas). Diferença em `circle`
   ou cor de botão costuma ser animação capturada no meio: repita antes de concluir.
6. **Celular**: se a janela estiver maximizada e não redimensionar, carregue o app num `iframe` de 390×844 na própria aba (mesma
   origem) e conduza por `iframe.contentWindow`; confira `document.documentElement.scrollWidth <= innerWidth`.
7. **Ao terminar**: encerre os processos das portas 5301, 5311 e 5312 (confirmando pela porta) e remova a cópia com
   `git worktree remove --force <scratchpad>/original`.
