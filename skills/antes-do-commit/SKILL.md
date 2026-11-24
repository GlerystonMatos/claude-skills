---
name: antes-do-commit
description: Checklist antes de commitar em qualquer projeto — confere a origem, aplica os itens específicos do projeto (guardados no repositório claude-skills em projetos/<repo>/antes-do-commit.md, com base comum opcional), as regras básicas e os padrões, o espelho de tipos entre front e back, os repositórios relacionados, os finais de linha, os arquivos de progresso e o checklist de validação, e roda build, testes e lint, corrigindo o que faltar. Sem configuração para o projeto, propõe criá-la. Use quando o usuário pedir "antes do commit", "atualize o que for necessário antes do commit", "deixe pronto para commit" ou ao terminar uma funcionalidade.
argument-hint: "[instruções adicionais]"
---

# Antes do commit

Escopo = `git status` + `git diff HEAD` (stage e working tree, inclusive arquivos novos). Para cada item, **corrija** o que faltar;
no fim, liste o que foi alterado e o que não se aplicava. Considere como instruções adicionais o texto que o usuário escreveu junto
da chamada.

## 0. Configuração do projeto

1. Na raiz do projeto, rode
   `node "$(git -C "<pasta desta skill>" rev-parse --show-toplevel)/scripts/configuracao.mjs" antes-do-commit` (a pasta da skill é uma
   junção para o `claude-skills`; `..` não serve). Ele mostra o `repositorio` (nome no `origin`), o `central` (raiz do
   `claude-skills`), as pastas `scripts-globais` e `scripts` (do projeto), quando existem, e o conteúdo da configuração do projeto
   — precedido da base, quando ela começa com `Base: <nome>`. A configuração do projeto prevalece sobre a base e sobre esta skill
   quando divergirem.
2. **`SEM CONFIGURACAO`**: avise e proponha criar `projetos/<repositorio>/antes-do-commit.md` a partir do que o projeto mostra
   (`CLAUDE.md`/`AGENTS.md`, README, stack, scripts de build, pasta de docs, migrations, repositórios vizinhos). Só o que **não**
   está nesta skill nem no `CLAUDE.md`: itens de domínio, espelho de tipos, relacionados, exceções de finais de linha e comandos fora
   do comum; projeto no padrão do Argos usa `Base: argos`. Mostre o rascunho e só crie com aprovação; ao criar, siga as regras
   do `claude-skills` (LF, `git pull --ff-only` antes, commit com a `texto-commit` e push). Sem aprovação, rode só os itens
   genéricos abaixo e diga que os específicos ficaram de fora.

## 1. Origem

`git fetch` e `git status -sb`. Atrás do remoto? Veja o que veio (`git log HEAD..@{u}`, `git show --stat`) e os arquivos tocados
pelos dois lados antes de commitar. Se o trabalho local já incorpora o commit de fora, `git reset --soft @{u}` mantém o stage e evita
conflito; se não, use a skill `validar-rebase`. Confirme que nada do commit de fora se perdeu sem motivo.

## 2. Itens específicos do projeto

Percorra cada item da base e da configuração (documentos do armazenamento e migrações, permissões, contratos, versão etc.) e corrija o
que a mudança exigir.

## 3. Espelho de tipos e repositórios relacionados

- **Espelho de tipos** (a configuração diz quais são os dois lados, ex.: `src/api/tipos.ts` × records C#): endpoint, request ou
  response mudou → o outro lado acompanha na mesma tarefa, com os mesmos nomes e propriedades; endpoint usado pelo front existe na API.
- **Relacionados** (a configuração lista os repositórios vizinhos, ex.: a API de um front): contrato mudou (rota, DTO, status, regra
  de cálculo exibida) → confira o outro repositório, se estiver na máquina, e **avise no relatório** o que precisa acompanhar. Não
  altere outro repositório por conta própria.

## 4. Documentação

- **Regra não óbvia** nova ou revertida: registrar no documento certo (índice no `CLAUDE.md`/`AGENTS.md` ou o indicado na
  configuração), sucinto, só o estado atual, sem duplicar nem criar nota solta.
- Comando, variável de ambiente, estrutura ou fluxo mudou: `README.md` e `.env.example`. Regra que vale sempre mudou: `CLAUDE.md`/
  `AGENTS.md`.

## 5. Regras básicas e padrões

Nos arquivos alterados, aplique as regras do `CLAUDE.md`/`AGENTS.md` e do documento de padrões do projeto. As **regras básicas**
abaixo valem quando o projeto as adota (o `CLAUDE.md`, o documento de padrões ou a configuração dizem; na dúvida, confira o código
existente):

- **sem comentários** no código (inclusive testes; diretivas técnicas e arquivos de configuração são exceção);
- nomes, mensagens e interface em **pt-BR**;
- TypeScript: sem `any` nem `enum`, `import type` para tipos, imports em **pirâmide** (uma linha por comprimento crescente, depois os
  multilinha; no MUI, `@mui/material` por último), nenhuma cor hex fora do arquivo de tema/estilos globais;
- C#: tipo explícito no lugar de `var`, `using` em ordem alfabética;
- sem imports não usados nem código morto.

Projeto no padrão do Argos (`Base: argos`, ou o `CLAUDE.md` cita `argos-doc/padroes`): rode também as **buscas objetivas** da
skill `revisar-padroes` (`<central>/skills/revisar-padroes/SKILL.md`, seção "Buscas objetivas") restritas aos arquivos alterados.
Adaptações registradas no `CLAUDE.md` do projeto valem.

## 6. Finais de linha

Regras em `.gitattributes`/`.editorconfig`; a configuração só traz exceções. Para cada arquivo de `git diff --name-only HEAD` e os
novos:

- `git ls-files --eol -- <arquivos>`: coluna `i/` = índice, `w/` = pasta; BOM pelos primeiros bytes (`head -c3 <arquivo> | od -c`).
- CRLF que falta: `perl -pi -e 's/(?<!\r)\n/\r\n/' <arquivo>` (respeita arquivo sem quebra no fim). LF: `perl -pi -e 's/\r\n/\n/'`.
  O `sed -i` do Git Bash troca CRLF por LF sem avisar; confira depois de usá-lo.
- Com `text=auto`/`eol` no `.gitattributes`, o índice fica em LF; confirme que a conversão não mudou o conteúdo (`git add` +
  `git diff --cached --ignore-cr-at-eol` vazio, ou `git write-tree` igual).
- UTF-8 sem BOM e newline no fim, salvo regra contrária do projeto.

## 7. Arquivos de progresso

Arquivos de progresso e pendências do projeto (`.claude/progress-*.md`, `progresso.md` e os que a configuração citar): confira no
código cada item marcado como concluído e remova os concluídos (frentes, decisões e fases já entregues), deixando só as pendências
reais com o mínimo para retomar. Sem pendência num arquivo temporário (`.claude/progress-*.md`), apague-o (`git rm`). Item que o
código não confirma continua no arquivo. Documento permanente de progresso só é atualizado, nunca apagado.

## 8. Checklist de validação

Pedido implementado e o projeto tem checklist de validação: inclua os itens com a skill `checklist-prompt`.

## 9. Validação

Rode os comandos da configuração; sem eles, os que o projeto tiver:

- **.NET**: `dotnet build <solução>` com **0 warnings** (`MSB3026`/`MSB3027` = a API está rodando e travando a dll: reinicie) e
  `dotnet test` no projeto de testes, se houver;
- **Node**: os scripts do `package.json` que existirem — `npm run build`, `npm run lint`, `npm test`;
- **Maven**: `./mvnw -q clean compile` e `./mvnw test`.

Tudo limpo, sem warnings novos. Falhou → corrigir e repetir; reportar a saída se não der. Validação que depende de algo indisponível
(banco, Docker, navegador) fica como pendente no relatório, dita com clareza. Tela mexida → conferir no navegador com a skill
`api-teste` quando der.

## 10. Fim

Não commitar por conta própria; sugerir a skill `texto-commit` para a mensagem. Relatório: o que foi alterado em cada item, o que não
se aplicava, o que ficou pendente e o que os repositórios relacionados precisam acompanhar.
