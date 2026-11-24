---
name: sincronizar-gitconfig
description: Sincroniza o ~/.gitconfig desta máquina com o arquivo .gitconfig do repositório gitconfig (na pasta dos projetos) — descobre qual lado mudou desde a última sincronização; o que mudou na máquina vai para o repositório com commit gerado pela texto-commit e push; o que mudou no repositório atualiza a máquina (com cópia da versão anterior); mudança dos dois lados é juntada e só o conflito é perguntado. Use quando o usuário pedir "sincronizar o gitconfig", "levar meus aliases do git para o repositório", "atualizar o gitconfig desta máquina" ou depois de criar ou alterar um alias do git.
---

# Sincronizar o gitconfig

`<projetos>` = pasta dos projetos desta máquina: o conteúdo de `.pasta-projetos` na raiz do `claude-skills`
(`git -C "<pasta desta skill>" rev-parse --show-toplevel`), ou `C:\Projetos` se o arquivo não existir. Se uma pasta citada não
existir nela, pergunte ao usuário onde está.

Script: `node "<pasta desta skill>/scripts/sincronizar-gitconfig.mjs" <comando> [--repo <pasta>]`. Repositório padrão
`<projetos>\gitconfig` (o script acha sozinho); se não existir, pergunte e passe `--repo` (ou `GITCONFIG_REPO`). O registro da última sincronização (hash do
conteúdo) fica em `~/.gitconfig-sincronizado`, fora do repositório. As comparações ignoram CRLF/LF e espaços no fim.

## 1. Atualizar o repositório

`git -C <repo> fetch` e `git -C <repo> pull --ff-only` (com trabalho local no repositório, use a skill `validar-rebase`). Assim o
"mais atual" do repositório inclui o que veio de outras máquinas.

## 2. Ver a situação

`node ... estado` mostra o estado, as datas e a diferença (repositório → máquina):

| Estado | O que fazer |
|---|---|
| `igual` | Nada a fazer (o registro é atualizado sozinho). |
| `primeira-vez` | O repositório ainda não tem `.gitconfig`: leve a versão da máquina (passo 3). |
| `maquina-mais-nova` | Só a máquina mudou desde a última sincronização: passo 3. |
| `repositorio-mais-novo` | Só o repositório mudou: passo 4. |
| `conflito` | Os dois mudaram: passo 5. |
| `sem-historico` | Os dois existem, diferem e esta máquina nunca sincronizou: mostre a diferença e as datas (alteração do arquivo da máquina × último commit no repositório) e pergunte ao usuário qual vale, ou se é para juntar (passo 5). |

## 3. Da máquina para o repositório

1. `node ... para-repositorio` (copia o `~/.gitconfig` para `<repo>/.gitconfig`, em LF).
2. Confira o que vai subir (`git -C <repo> diff`): se aparecer algo que não deve ser público (token, senha, URL com credencial),
   **pare e pergunte** antes de commitar.
3. `git -C <repo> add .gitconfig`, gere a mensagem com a skill `texto-commit` (no repositório do gitconfig), `git commit` com ela e
   `git push`. Sem linhas de atribuição.
4. `node ... marcar` (registra a sincronização).

## 4. Do repositório para a máquina

`node ... para-maquina`: guarda a versão anterior em `~/.gitconfig.antes-da-sincronizacao`, grava a do repositório e registra a
sincronização. Mostre ao usuário o que mudou (a diferença do passo 2).

## 5. Conflito (os dois lados mudaram)

Junte pela estrutura do gitconfig (seção e chave): o que só existe de um lado entra; chave com valores diferentes nos dois lados →
pergunte ao usuário qual vale (mostrando os dois). Grave o resultado na máquina **e** no repositório (mantenha a ordem das seções e o
estilo do arquivo), confira com `git config --global --list` que o arquivo continua válido e siga o passo 3 a partir do item 2.

## 6. Relatório

Direção da sincronização, chaves/aliases que entraram ou mudaram, hash do commit (quando houve) e onde ficou a cópia anterior.
