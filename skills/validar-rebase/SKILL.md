---
name: validar-rebase
description: Traz commits da origem para um branch com trabalho local (git pull --rebase ou rebase) sem perder nada e prova que nada se perdeu — resolve conflitos mantendo as duas mudanças, procura linhas que o commit de fora adicionou e o local removeu, lista os arquivos tocados pelos dois lados, confere padrões que viram regressão (layout, assinaturas, migrações, lock de pacotes) e roda builds e testes. Use quando o usuário pedir "atualize com a origem", "faça pull --rebase", "traga o commit da outra máquina", "resolva os conflitos sem regressão" ou "valide o que veio no commit".
argument-hint: [commit ou branch de origem]
---

# Validar rebase

Objetivo: o commit que veio de fora entra inteiro, o trabalho local continua inteiro, e isso fica **provado** com evidência, não suposto.

## 1. Antes de trazer
1. `git status` e `git log --oneline -5`. Alteração não commitada: mostre ao usuário e pergunte se commita (WIP) ou faz `git stash`.
   Nunca descarte nada.
2. `git fetch origin` e liste o que vem: `git log --oneline HEAD..origin/<branch>` e, para cada commit, `git show --stat <sha>`.
3. Se o usuário passou um roteiro de validação (lista de itens do commit), guarde-o: ele vira a tabela do passo 4.

## 2. Rebase e conflitos
1. `git pull --rebase origin <branch>` (ou `git rebase origin/<branch>`). Leia a saída inteira: o resumo pode cortar conflitos; confira
   com `git diff --name-only --diff-filter=U`.
2. Em cada conflito, leia os dois lados e **mantenha as duas mudanças**. Para comparar trechos longos, faça um diff por palavra entre
   os lados (é comum um lado só trocar números ou um termo). Nunca use `--ours`/`--theirs` em bloco nem `reset --hard`. Decisão não
   óbvia → pergunte.
3. Arquivos de controle (checklist, changelog, lista de migrações): junte as seções dos dois lados; renumere as locais se colidirem.
   Itens que o usuário marcou como concluídos localmente continuam fora.
4. Lock de pacotes em conflito: regenere (`npm install` etc.), nunca edite à mão.
5. `git add` nos resolvidos e `GIT_EDITOR=true git rebase --continue` até terminar.

## 3. Provar que nada se perdeu
Rode `scripts/linhas-perdidas.mjs` (Node) na raiz do repositório:

```bash
node "<pasta desta skill>/scripts/linhas-perdidas.mjs" <commit-de-fora> <base> <commit-local-rebaseado>
```

- `<commit-de-fora>`: o commit que veio da origem; `<base>`: o pai dele; `<commit-local-rebaseado>`: o seu commit depois do rebase
  (ou `HEAD`).
- Ele lista, por arquivo, as linhas que o commit de fora **adicionou** e o local **removeu** (possível perda). Cada uma precisa de
  explicação: troca intencional sua (ex.: você alterou aquela linha) ou perda real → restaure a partir do commit de fora, integrando com
  o seu trabalho.
- Também mostra `git diff --stat <de-fora> <local> -- <arquivos do commit de fora>`: só podem aparecer mudanças suas.

## 4. Regressões que o diff não mostra
O código de fora foi escrito sem as suas regras novas, e o seu sem as dele. Confira:
- **Assinaturas**: construtores, records, DTOs e tipos que o commit de fora mudou e que o seu código usa (e o contrário). O build pega a
  maioria; leia os que compilam por valor padrão.
- **Regras globais** que você criou (tema, estilos, padrões, migrações): componentes novos do commit de fora seguem a regra? (ex.: um
  seletor CSS global que achata um campo novo, botão novo sem o ícone exigido).
- **Migrações**: passos dos dois lados existem, com ids sequenciais e diferentes, registrados no fim da lista, com documentação.
- **Itens do roteiro do usuário**: confira cada um com Grep/Read e monte a tabela **item → OK / perdido → corrigido**.

## 5. Builds e testes
Rode tudo o que o projeto tem (ex.: `dotnet build` com 0 warnings, `dotnet test`, `npm install && npm run build`, testes do front). Se
mexeu em visual, valide no navegador o que o commit de fora trouxe de tela.

## 6. Relatório
Tabela de verificação, conflitos e como foram resolvidos, o que foi restaurado ou ajustado, resultado dos builds/testes. Não faça commit
das correções nem push sem o usuário pedir; diga quantos commits o branch está à frente da origem.
