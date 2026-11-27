---
name: igualar-ao-argos
description: Leva para outro projeto um comportamento, componente, tela ou espaçamento que já existe no Argos (repositório argos) — acha o equivalente no Argos, compara com o projeto atual, lista as diferenças, replica no mesmo padrão (componente compartilhado, back e front, tipos espelhados, permissões, CSP), aplica o mesmo ajuste em todos os lugares do projeto onde o caso se repete e fecha com build, lint, testes, documentação e checklist. Usa a configuração do projeto no repositório claude-skills (projetos/<repo>/igualar-ao-argos.md, com base comum opcional); sem ela, propõe criá-la. Use quando o usuário disser "no Argos fica melhor, ajuste", "igual ao Argos", "assim como no Argos", "replique o padrão do Argos", "verifique como o Argos faz e replique" ou chamar /igualar-ao-argos <o que igualar>.
argument-hint: "<o que igualar>"
---

# Igualar ao Argos

O Argos é a referência visual e de código dos projetos que seguem o padrão dele. Esta skill leva para o projeto atual algo que o Argos
já resolve, sem inventar outra solução. Considere como pedido o texto que o usuário escreveu junto da chamada.

## 0. Configuração do projeto

1. Na raiz do projeto, rode
   `node "$(git -C "<pasta desta skill>" rev-parse --show-toplevel)/scripts/configuracao.mjs" igualar-ao-argos` (a pasta da skill é uma
   junção para o `claude-skills`; `..` não serve). Ele mostra o `repositorio`, o `central` e a configuração do projeto, precedida da
   base quando ela começa com `Base: <nome>`. A configuração do projeto prevalece sobre a base e sobre esta skill.
2. Ela diz onde fica o Argos (`<projetos>/argos`), a correspondência de pastas e nomes entre os dois, os documentos a atualizar, os
   comandos de validação e as diferenças conhecidas (componentes que o projeto ainda não tem, exceções de propósito).
3. **`SEM CONFIGURACAO`**: confirme que o projeto segue o padrão do Argos (React + MUI com `theme.ts`, `components/estilosDialogo.ts`,
   back .NET com `Nucleo`/`Api`). Se seguir, proponha a configuração e só crie com aprovação, seguindo as regras do `claude-skills` (LF,
   `git pull --ff-only`, commit com a `texto-commit` e push). Rodando no próprio Argos, diga que não há o que igualar.
4. Antes de ler o Argos, rode `git -C <argos> status -sb` só para saber se há mudança local nele; **nunca altere o Argos** nesta skill.

## 1. Achar a referência no Argos

1. Traduza o pedido para o que procurar: componente (`AvatarUsuario`, `OpcaoSwitch`, `SobreDialog`), tela (`UsuariosView`), regra de
   tema ou espaçamento (`estilosDialogo.ts`, `theme.ts`), endpoint ou script.
2. Procure no Argos pelo nome e pelo comportamento (texto visível, ícone, prop). Leia o arquivo inteiro da referência e o que ela usa
   (utilitários, constantes de estilo, hooks, API, DTO e endpoint do back).
3. Leia a regra correspondente em `argos-doc/padroes.md` e no pacote `argos-doc/padroes/` (catálogo de componentes, checklists `09a`/
   `09b`): a regra escrita vale mais que um exemplo isolado. Se o Argos tiver mais de uma forma do mesmo caso, siga a que a regra cita
   e diga ao usuário que há variação.

## 2. Comparar com o projeto atual

1. Ache o equivalente no projeto pela correspondência da configuração (pastas, prefixos, nomes de tipos) e liste as diferenças:
   o que falta (componente, util, rota, campo no DTO, permissão), o que está diferente (estilo, texto, ordem, tamanho) e o que é
   diferença de propósito (registrada na configuração; não mexa).
2. Procure **todos os lugares** do projeto onde o mesmo caso aparece (mesmo componente do MUI, mesmo padrão de estilo, mesmo texto) —
   "replique na aplicação toda" é o normal, não a exceção. Liste-os antes de editar.
3. Se a diferença envolver decisão do usuário (mudar comportamento visível além do pedido, apagar algo, trocar regra de permissão),
   pergunte antes; o resto, faça.

## 3. Replicar

- **Componente que o projeto não tem**: copie do Argos para o mesmo caminho relativo (`components/`, `utils/`, `hooks/`), adaptando só
  imports, nomes de marca e o que a configuração listar; prefira o componente compartilhado a corrigir cada tela.
- **Back**: rota, DTO e validação no mesmo formato do projeto (`ResultadoApi`/`IResult`, checagem de permissão igual às rotas vizinhas,
  helper compartilhado em vez de duplicar). Campo novo no DTO = campo no tipo do front na mesma tarefa.
- **Recurso externo** (API de terceiros, imagem, fonte): confira a CSP do `nginx.conf` do projeto e libere só o necessário.
- **Padrões do projeto continuam valendo**: pt-BR, sem comentários, imports em pirâmide, `import type`, sem `any`, finais de linha do
  `.editorconfig` do projeto (a configuração diz quais), textos de pessoas sem gênero presumido.
- Lint que acusa arquivo misturando componente e função (`only-export-components`): mova as funções para `utils/`.

## 4. Fechar

1. Rode os comandos de validação da configuração (build do front e do back com 0 avisos, lint, testes) e corrija o que falhar.
2. Atualize a documentação que a configuração indicar (telas, componentes compartilhados, endpoints).
3. **Mexeu em arquivo do back** e o ambiente Docker local não foi atualizado depois disso: atualize com a skill
   `iniciar-ambiente-docker` (palavra da configuração do projeto) e confira a saúde dos containers. Faça também o que mais a
   configuração pedir ao terminar.
4. **Por último, rode a skill `checklist-prompt`** inteira: inclui os itens do que foi igualado (um por comportamento, com o caminho da
   tela e os casos de borda: celular, tema escuro, permissão, dado antigo) **e remove os itens já marcados `[x]`** e as seções que
   ficarem vazias.
5. Quando mexer em espaçamento ou altura, meça com a skill `medir-layout` se o usuário pedir conferência visual; sem medir, diga que
   não foi conferido no navegador.
6. Relate ao usuário: a referência usada no Argos (arquivo), o que foi replicado e onde, as diferenças que ficaram de propósito e o
   que não foi verificado. Não faça commit sem pedido (regra dos projetos).
