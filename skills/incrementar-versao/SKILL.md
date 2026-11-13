---
name: incrementar-versao
description: Incrementa a versão da aplicação nos arquivos .ver (changelog XML) do Frota e demais aplicações Delphi — formato 2.<banco>.<release>.<build> — perguntando se sobe release (implementação) ou build (correção) e quais .ver atualizar, e gera o texto dos itens a partir das mudanças em stage (mesmo método da skill texto-commit). Use quando o usuário pedir "incrementar versão", "subir versão", "gerar versão", "atualizar o .ver" ou "versionar".
---

# Incrementar versão (.ver)

Formato da versão: **`2.<banco>.<release>.<build>`**
- `2` é fixo.
- `<banco>` é a versão do banco de dados (`.set ScriptVersion=N` em `Scripts/Update.sql` e `Scripts/UpdateMSSQL.sql`).
- `<release>` sobe em **implementação/melhoria** e zera o build (`2.413.0.2` → `2.413.1.0`).
- `<build>` sobe em **correção de bug** (`2.413.1.1` → `2.413.1.2`).
- Sempre sobe **ou** release **ou** build — nunca os dois.

## 1. Levantar os arquivos
1. Raiz do repositório: `git rev-parse --show-toplevel`. Liste os `.ver` com `git ls-files "*.ver"` (inclua não versionados com `find . -iname "*.ver"`, ignorando `Lib/`, `node_modules/`, `__history/`).
2. Para cada `.ver`, leia sem alterar:
   - a **última versão** (primeiro `<Versao id="..." data="...">` após `<Versoes>`);
   - a **codificação** da declaração XML (`UTF-8` ou `windows-1252`), o **final de linha** (CRLF/LF) e a **indentação** (tabs/espaços);
   - se os itens ficam dentro de `<Modulo nome="...">` (ex.: `Scripts/Frota.ver`) ou direto na `<Versao>` (ex.: `CaAbastecimento.ver`).
3. Marque como **histórico, não atualizar** o que estiver parado: nome com `Old` (ex.: `FrotaOld.ver`) ou última versão muito atrás do arquivo principal (ex.: `bin/Frota.ver`). Mostre-os, mas não os ofereça como padrão.
4. Leia `ScriptVersion` nos dois scripts de update (precisam ser iguais; se divergirem, avise e pare).
5. Informe também, só como aviso, a versão em `*.dproj` (`VerInfo_MinorVer`, `FileVersion`): o histórico não atualiza esses arquivos a cada versão — não mexa neles sem pedido.

## 2. Ler as mudanças
- Siga o método da skill **`texto-commit`** (skill global, passos 1 e 3): leia **só o stage** (`git diff --cached --stat` e `git diff --cached`, arquivos grandes por partes) e agrupe por **funcionalidade visível ao usuário**.
- Sem nada em stage: diga isso e pergunte se deve usar o working tree (`git diff`) ou se o usuário vai ditar o texto.
- Use o diff para **recomendar**: só correção → build; funcionalidade nova/melhoria → release. Pastas alteradas indicam o `.ver` (fontes do Frota → `Scripts/Frota.ver`; `ApiSOAPAbastecimento/**` → `CaAbastecimento.ver`; `IntegraMovidesk/**` → `IntegraMovidesk.ver`).

## 3. Perguntar (AskUserQuestion, numa chamada só)
1. **O que incrementar**: Release (implementação) ou Build (correção) — a recomendação primeiro, com a versão resultante de cada `.ver` na descrição.
2. **Quais `.ver` atualizar** (multiSelect), com os recomendados pelo diff primeiro.
3. **Chamado e tipo do item**: número do chamado (TEL/ticket; pode ser vazio) e tipo — `E` (correção, com chamado), `S` (solicitação/implementação, com chamado) ou `P` (melhoria interna, sem chamado).
4. **Módulo** (só para `.ver` com `<Modulo>`): sugira pelo diff entre os já usados — `Geral`, `Abastecimento`, `Manutenção`, `Material`, `Pneu`, `Administração`, `Veículo`. Não invente grafias novas.

**Versão do banco**: se `ScriptVersion` for maior que o `<banco>` da última versão de um `.ver` que acompanha o banco (mesmo número de banco do arquivo principal), a nova versão desse arquivo é **`2.<ScriptVersion>.0.0`** em vez de release/build. Confirme com o usuário e, se aceitar, atualize também `INSERT INTO INFO (... VERSAOBD, ... VERSAOEXE ...)` em `Scripts/Frota.sql` e `Scripts/Frota_SqlServer.sql` e `update INFO set INFO.VERSAOEXE = '...'` em `Scripts/Update.sql` e `Scripts/UpdateMSSQL.sql`. `.ver` com numeração própria (ex.: `CaAbastecimento.ver`, `IntegraMovidesk.ver`) incrementam a partir da própria última versão.

## 4. Escrever os itens
- Um `<Item>` por mudança visível, em **pt-BR**, no estilo do histórico: particípio no início ("Realizado um ajuste ao...", "Implementada a...", "Criada a configuração..."), dizendo o que mudou para o usuário, sem nome de arquivo ou classe. Quando houver tela, termine com o caminho de menu entre aspas: `"Movimentos > Abastecimento"`.
- Escape XML no texto: `&` → `&amp;` e `<` → `&lt;`. Mantenha `>` literal nos caminhos de menu (`"Movimentos > Abastecimento"`), como no histórico; aspas duplas no texto também são aceitas.
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
- Preserve **codificação, final de linha e indentação** de cada arquivo. Para `windows-1252`/Latin-1 (ex.: `bin/Frota.ver`) não use a ferramenta Edit: grave com `perl`/PowerShell escrevendo bytes na codificação do arquivo. UTF-8 pode usar Edit.
- Confira depois: `file <arquivo>` (codificação e CRLF iguais aos de antes), XML bem formado (`[xml](Get-Content -Raw -Encoding <cod> <arquivo>)` no PowerShell) e `git diff` mostrando só o bloco novo.

## 6. Entregar
- Mostre a versão anterior → nova de cada arquivo e os itens gravados.
- **Não** faça commit nem altere o stage, a menos que o usuário peça. Se pedir, a mensagem segue o padrão do repositório (`TEL - <chamado> - <resumo>`; veja `git log --oneline -10`) e leva as linhas de atribuição exigidas pelo ambiente.

