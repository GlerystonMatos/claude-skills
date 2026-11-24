---
name: incrementar-versao
description: Incrementa a versão da aplicação nos arquivos .ver (changelog XML) das aplicações Delphi — formato 2.<banco>.<release>.<build>, com o banco comum a todos os projetos do repositório — perguntando se sobe release (implementação) ou build (correção) e quais .ver atualizar, e gera o texto dos itens a partir das mudanças em stage (mesmo método da skill texto-commit). Os arquivos, módulos e scripts de banco de cada repositório ficam no claude-skills em projetos/<repo>/incrementar-versao.md. Use quando o usuário pedir "incrementar versão", "subir versão", "gerar versão", "atualizar o .ver" ou "versionar".
---

# Incrementar versão (.ver)

Formato da versão: **`2.<banco>.<release>.<build>`**
- `2` é fixo.
- `<banco>` é a versão do banco de dados (`ScriptVersion` dos scripts de update, indicados na configuração) e vale para **todos os
  projetos do repositório**: com o banco em `414`, todo `.ver` ativo usa `2.414.x.y`.
- `<release>` sobe em **implementação/melhoria** e zera o build (`2.413.0.2` → `2.413.1.0`).
- `<build>` sobe em **correção de bug** (`2.413.1.1` → `2.413.1.2`).
- Sempre sobe **ou** release **ou** build — nunca os dois.

## 0. Configuração do repositório

1. Na raiz do projeto, rode
   `node "$(git -C "<pasta desta skill>" rev-parse --show-toplevel)/scripts/configuracao.mjs" incrementar-versao` (a pasta da skill é uma
   junção para o `claude-skills`; `..` não serve). Ele mostra o `repositorio` (nome no `origin`), o `central` (raiz do
   `claude-skills`), as pastas `scripts-globais` e `scripts` (do projeto), quando existem, e o conteúdo da configuração do projeto
   — precedido da base, quando ela começa com `Base: <nome>`. A configuração do projeto prevalece sobre a base e sobre esta skill
   quando divergirem. Ela traz os scripts de update (onde está o `ScriptVersion`), os `.ver` ativos e o que não
   atualizar, o mapa de pastas → `.ver`, os módulos válidos, o que mais muda quando o banco sobe e o padrão de commit.
2. **`SEM CONFIGURACAO`**: levante pelo passo 1 abaixo e proponha a configuração ao usuário; só crie com aprovação, seguindo as regras
   do `claude-skills` (LF, `git pull --ff-only`, commit com a `texto-commit` e push).

## 1. Levantar os arquivos
1. Raiz do repositório: `git rev-parse --show-toplevel`. Liste os `.ver` com `git ls-files "*.ver"` (inclua não versionados com
   `find . -iname "*.ver"`, ignorando `Lib/`, `node_modules/`, `__history/`).
2. Para cada `.ver`, leia sem alterar:
   - a **última versão** (primeiro `<Versao id="..." data="...">` após `<Versoes>`);
   - a **codificação** da declaração XML (`UTF-8` ou `windows-1252`), o **final de linha** (CRLF/LF) e a **indentação** (tabs/espaços);
   - se os itens ficam dentro de `<Modulo nome="...">` ou direto na `<Versao>`.
3. Marque como **não atualizar**: histórico parado (nome com `Old`), cópias de saída (ex.: `bin/*.ver`) e arquivos ignorados pelo git
   que vêm de importação externa (`git check-ignore`), além dos que a configuração listar. Mostre-os, mas não os ofereça como padrão.
4. Leia `ScriptVersion` nos scripts de update da configuração (precisam ser iguais; se divergirem, avise e pare).
5. Informe também, só como aviso, a versão em `*.dproj` (`VerInfo_MinorVer`, `FileVersion`): o histórico não atualiza esses arquivos a
   cada versão — não mexa neles sem pedido.

## 2. Ler as mudanças
- Siga o método da skill **`texto-commit`** (passos 1 e 3): leia **só o stage** (`git diff --cached --stat` e `git diff --cached`,
  arquivos grandes por partes) e agrupe por **funcionalidade visível ao usuário**.
- Sem nada em stage: diga isso e pergunte se deve usar o working tree (`git diff`) ou se o usuário vai ditar o texto.
- Use o diff para **recomendar**: só correção → build; funcionalidade nova/melhoria → release. As pastas alteradas indicam o `.ver`
  pelo mapa da configuração.

## 3. Perguntar (numa pergunta só, com opções)
1. **O que incrementar**: Release (implementação) ou Build (correção) — a recomendação primeiro, com a versão resultante de cada `.ver`.
2. **Quais `.ver` atualizar** (várias escolhas), com os recomendados pelo diff primeiro.
3. **Chamado e tipo do item**: número do chamado (pode ser vazio) e tipo — `E` (correção, com chamado), `S`
   (solicitação/implementação, com chamado) ou `P` (melhoria interna, sem chamado).
4. **Módulo** (só para `.ver` com `<Modulo>`): sugira pelo diff entre os da configuração. Não invente grafias novas.

**Versão do banco**: o `<banco>` de **todo** `.ver` ativo é sempre o `ScriptVersion` atual. Se a última versão de um `.ver` tiver
`<banco>` menor, a nova versão desse arquivo é **`2.<ScriptVersion>.0.0`** em vez de release/build; nos que já estão no banco atual,
aplique release/build normalmente. Avise o usuário de cada arquivo que vai saltar de banco. Release e build continuam independentes por
arquivo. Quando o próprio `ScriptVersion` subir (script novo de banco), confirme com o usuário e atualize também o que a configuração
listar para esse caso.

## 4. Escrever os itens
- Um `<Item>` por mudança visível, em **pt-BR**, no estilo do histórico: particípio no início ("Realizado um ajuste ao...",
  "Implementada a...", "Criada a configuração..."), dizendo o que mudou para o usuário, sem nome de arquivo ou classe. Quando houver
  tela, termine com o caminho de menu entre aspas: `"Movimentos > Abastecimento"`.
- Escape XML no texto: `&` → `&amp;` e `<` → `&lt;`. Mantenha `>` literal nos caminhos de menu, como no histórico; aspas duplas no
  texto também são aceitas.
- Bloco novo **no topo**, logo após `<Versoes>`, com a data de hoje (`dd/mm/aaaa`) e a indentação do arquivo:
  ```xml
  	<Versao id="2.414.2.0" data="11/11/2026">
  		<Modulo nome="Abastecimento">
  			<Item S="1700">Implementada a ... "Movimentos > Abastecimento"</Item>
  		</Modulo>
  	</Versao>
  ```
  Sem `<Modulo>` no arquivo: itens direto dentro da `<Versao>`.

## 5. Gravar sem estragar o arquivo
- Preserve **codificação, final de linha e indentação** de cada arquivo. Para `windows-1252`/Latin-1 não use ferramenta de edição de
  texto: grave com `perl`/PowerShell escrevendo bytes na codificação do arquivo. UTF-8 pode ser editado normalmente.
- Confira depois: `file <arquivo>` (codificação e CRLF iguais aos de antes), XML bem formado
  (`[xml](Get-Content -Raw -Encoding <cod> <arquivo>)` no PowerShell) e `git diff` mostrando só o bloco novo.

## 6. Entregar
- Mostre a versão anterior → nova de cada arquivo e os itens gravados.
- **Não** faça commit nem altere o stage, a menos que o usuário peça. Se pedir, a mensagem sai da skill `texto-commit` (padrão do
  repositório, sem linhas de atribuição).
