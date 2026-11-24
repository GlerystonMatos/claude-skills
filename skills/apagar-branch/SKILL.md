---
name: apagar-branch
description: Apaga um ou mais branches do git na máquina e na origem sem perder trabalho — confere se os commits do branch local e do remoto já estão no branch principal da origem, mostra o que ainda não foi integrado e pede confirmação antes de cada ação (atualizar as referências, trocar de branch, apagar o local, apagar o remoto). Também lista os branches já integrados para limpar vários de uma vez. Use quando o usuário pedir "apague o branch X local e na origem", "delete o branch X", "remova o branch remoto" ou "limpe os branches já integrados".
argument-hint: "[branch ...]"
---

# Apagar branch

Apaga branches na máquina e na origem só depois de provar que nada se perde e com **confirmação do usuário antes de cada ação** que
muda algo. Perguntar é escrever a pergunta e esperar a resposta (no Claude Code, pode usar a ferramenta de pergunta; no Codex, pergunte
na conversa). Sem resposta afirmativa clara, não execute; "não" ou silêncio encerra aquela ação e a skill segue para a próxima ou para.

## 1. Levantar (só leitura, sem confirmação)

Na raiz do repositório atual:

- **Branches pedidos**: o argumento da chamada ou o que o usuário disse. Sem nenhum, vá para o modo de limpeza (seção 4).
- **Branch principal**: `git symbolic-ref --short refs/remotes/origin/HEAD` (ex.: `origin/main`); sem ele, `origin/main` ou
  `origin/master`, o que existir. Não descobriu → pergunte qual é e pare até a resposta.
- **Branch atual**: `git branch --show-current`.
- Situação de cada branch, pelas referências que já existem: `git branch --list <b>` e `git branch -r --list origin/<b>`.

Nunca apague o branch principal, `main`, `master`, `develop` ou `HEAD`, nem branch que não foi pedido (no modo de limpeza, só os que o
usuário escolher). Pedido assim → recuse e explique.

## 2. Atualizar as referências da origem (confirmar)

Mostre o comando e pergunte: "Posso rodar `git fetch --prune origin` para atualizar as referências da origem? (o `--prune` remove da
máquina as referências de branches que já não existem na origem)". Sim → rode. Não → siga com as referências que estão na máquina e
avise que a verificação pode estar desatualizada.

## 3. Verificar e apagar cada branch

Para cada branch pedido:

1. **Verificar** (só leitura): para o local e para o remoto que existirem, `git rev-parse` de cada um e
   `git merge-base --is-ancestor <ref> <principal>`. Não integrado → liste o que falta com `git log --oneline <principal>..<ref>`.
   O branch não existe em nenhum dos dois lugares → avise e passe para o próximo.
2. **Mostrar o plano** numa tabela curta: branch, último commit local e remoto, se cada um está no principal, quantos commits faltam e
   as ações previstas.
3. **Branch atual** é o que será apagado → pergunte: "O branch `<b>` está em uso. Posso trocar para `<principal sem origin/>` com
   `git switch <principal>`?". Antes, se `git status --porcelain` tiver alterações, mostre-as e pare: trocar levaria ou travaria o
   trabalho pendente; o usuário decide (commit, stash) antes de tentar de novo. Não → pule este branch.
4. **Apagar o local** (se existir) → pergunte: "Posso apagar o branch local `<b>` (commit `<hash>`) com `git branch -d <b>`?".
   - Integrado: use `-d`. Se o `-d` recusar por estar à frente do upstream, mesmo integrado no principal da origem, explique e pergunte
     de novo antes de usar `-D`.
   - Não integrado: avise que **os commits listados se perdem** (ficam só no reflog por um tempo) e só use `-D` com confirmação
     explícita para esse caso, separada da pergunta normal.
5. **Apagar o remoto** (se existir) → pergunte: "Posso apagar o branch `<b>` da origem com `git push origin --delete <b>`? Isso vale para
   todo mundo que usa o repositório.". Não integrado → mesma regra do passo anterior: liste os commits e peça confirmação explícita de
   que eles podem sumir da origem.
6. Relate o que foi feito com a saída do git (`Deleted branch ... (was <hash>)`, `- [deleted]`). Se o push falhar (branch protegido,
   sem permissão), mostre o erro; não tente contornar.

Pode juntar as perguntas dos passos 4 e 5 numa só quando o usuário pedir explicitamente "local e na origem" e o branch estiver integrado
nos dois lugares, desde que a pergunta cite as duas ações e os dois comandos. Nos outros casos, uma pergunta por ação.

## 4. Modo de limpeza (sem branch informado)

1. Depois do passo 2, liste os candidatos (exceto os protegidos da seção 1):
   - locais integrados: `git branch --merged <principal>`;
   - remotos integrados: `git branch -r --merged <principal>` (sem `origin/HEAD` e sem o principal);
   - locais cujo upstream sumiu da origem (`git branch -vv`, marcados `: gone]`), com a verificação do passo 3.1, já que podem ter
     commits que nunca foram integrados.
2. Mostre a lista numerada com o último commit e a data (`git log -1 --format='%h %cs %s' <ref>`) e pergunte quais apagar e onde (local,
   origem ou os dois). Só os escolhidos seguem.
3. Antes de executar, mostre a lista final de comandos e peça uma confirmação para o lote; depois siga a seção 3 para cada um (o que não
   estiver integrado continua exigindo a confirmação própria).

Nunca use `git push --force`, `git push origin :<b>` com curinga, nem apague várias referências com um padrão sem mostrar a lista antes.
