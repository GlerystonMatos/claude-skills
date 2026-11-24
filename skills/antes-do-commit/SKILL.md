---
name: antes-do-commit
description: Checklist antes de commitar em qualquer projeto — confere a origem, aplica os itens específicos do projeto (guardados no repositório claude-skills em projetos/<repo>/antes-do-commit.md), os padrões, os finais de linha, os arquivos de progresso e o checklist de validação, e roda build, testes e lint, corrigindo o que faltar. Sem configuração para o projeto, propõe criá-la. Use quando o usuário pedir "antes do commit", "atualize o que for necessário antes do commit", "deixe pronto para commit" ou ao terminar uma funcionalidade.
argument-hint: "[instruções adicionais]"
---

# Antes do commit

Escopo = `git status` + `git diff HEAD` (stage e working tree, inclusive arquivos novos). Para cada item, **corrija** o que faltar;
no fim, liste o que foi alterado e o que não se aplicava. Considere como instruções adicionais o texto que o usuário escreveu junto
da chamada.

## 0. Configuração do projeto

1. Repositório central: `CENTRAL=$(git -C "<pasta desta skill>" rev-parse --show-toplevel)` (a pasta da skill é uma junção para
   `claude-skills/skills/antes-do-commit`; `..` não serve).
2. Projeto: `REPO=$(basename -s .git "$(git remote get-url origin)")`; sem remote, o nome da pasta raiz do git.
3. Leia `$CENTRAL/projetos/$REPO/antes-do-commit.md`. Os itens dele valem junto com os desta skill e, quando divergirem (comandos,
   finais de linha, exceções), prevalecem.
4. **Sem o arquivo**: avise e proponha criá-lo a partir do que o projeto mostra (`CLAUDE.md`/`AGENTS.md`, README, stack, scripts de
   build, `.editorconfig`/`.gitattributes`, pasta de docs, migrations). Mostre o rascunho e só crie com aprovação; ao criar, siga as
   regras do `claude-skills` (LF, `git pull --ff-only` antes, commit com a `texto-commit` e push). Sem aprovação, rode só os itens
   genéricos abaixo e diga que os específicos ficaram de fora.

## 1. Origem

`git fetch` e `git status -sb`. Atrás do remoto? Veja o que veio (`git log HEAD..@{u}`, `git show --stat`) e os arquivos tocados
pelos dois lados antes de commitar. Se o trabalho local já incorpora o commit de fora, `git reset --soft @{u}` mantém o stage e evita
conflito; se não, use a skill `validar-rebase`. Confirme que nada do commit de fora se perdeu sem motivo.

## 2. Itens específicos do projeto

Percorra cada item do arquivo de configuração (documentos do armazenamento e migrações, permissões, espelho de tipos com os DTOs,
contratos com outros clientes, versão etc.) e corrija o que a mudança exigir.

## 3. Documentação

- **Regra não óbvia** nova ou revertida: registrar no documento certo (índice no `CLAUDE.md`/`AGENTS.md` ou o indicado na
  configuração), sucinto, só o estado atual, sem duplicar nem criar nota solta.
- Comando, variável de ambiente, estrutura ou fluxo mudou: `README.md` e `.env.example`. Regra que vale sempre mudou: `CLAUDE.md`/
  `AGENTS.md`.

## 4. Padrões

- Aplique as regras do `CLAUDE.md`/`AGENTS.md` e do documento de padrões do projeto nos arquivos alterados.
- Projeto no padrão do Argos (a configuração diz, ou o `CLAUDE.md` cita `argos-doc/padroes`): rode as **buscas objetivas** da skill
  `revisar-padroes-argos` (`$CENTRAL/skills/revisar-padroes-argos/SKILL.md`, seção "Buscas objetivas") restritas aos arquivos
  alterados, em vez de repetir as regras aqui. Adaptações registradas no `CLAUDE.md` do projeto valem.

## 5. Finais de linha

Regras em `.gitattributes`/`.editorconfig` (ou na configuração). Para cada arquivo de `git diff --name-only HEAD` e os novos:

- `git ls-files --eol -- <arquivos>`: coluna `i/` = índice, `w/` = pasta; BOM pelos primeiros bytes (`head -c3 <arquivo> | od -c`).
- CRLF que falta: `perl -pi -e 's/(?<!\r)\n/\r\n/' <arquivo>` (respeita arquivo sem quebra no fim). LF: `perl -pi -e 's/\r\n/\n/'`.
  O `sed -i` do Git Bash troca CRLF por LF sem avisar; confira depois de usá-lo.
- Com `text=auto`/`eol` no `.gitattributes`, confirme que `git add` não muda o conteúdo além do esperado.
- UTF-8 sem BOM e newline no fim, salvo regra contrária do projeto. Arquivos legados citados na configuração não são tocados.

## 6. Arquivos de progresso

Arquivos de progresso e pendências do projeto (`.claude/progress-*.md`, `progresso.md` e os que a configuração citar): confira no
código cada item marcado como concluído e remova os concluídos (frentes, decisões e fases já entregues), deixando só as pendências
reais com o mínimo para retomar. Sem pendência num arquivo temporário (`.claude/progress-*.md`), apague-o (`git rm`). Item que o
código não confirma continua no arquivo. Documento permanente de progresso só é atualizado, nunca apagado.

## 7. Checklist de validação

Pedido implementado e o projeto tem checklist de validação: inclua os itens com a skill `checklist-prompt`.

## 8. Validação

Rode os comandos da configuração; sem eles, os que o projeto tiver (`dotnet build` + `dotnet test`, `npm run build` + `lint` +
`test`, `./mvnw compile` + `test`). Tudo limpo, sem warnings novos. Falhou → corrigir e repetir; reportar a saída se não der.
Validação que depende de algo indisponível (banco, Docker, navegador) fica como pendente no relatório, dita com clareza. Tela mexida
→ conferir no navegador com a skill `api-teste` quando der.

## 9. Fim

Não commitar por conta própria; sugerir a skill `texto-commit` para a mensagem. Relatório: o que foi alterado em cada item, o que não
se aplicava e o que ficou pendente.
