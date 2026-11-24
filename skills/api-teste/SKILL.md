---
name: api-teste
description: Sobe a API (e o front, quando houver) do projeto atual em modo de teste isolado — cópia dos dados ou do banco, build no scratchpad, portas próprias, serviços externos bloqueados por proxy morto e login no navegador sem digitar nem exibir senha — seguindo a configuração do projeto guardada no repositório claude-skills (projetos/<repo>/api-teste.md, com base comum opcional) e os scripts compartilhados (usuário de teste numa cópia JSON, cópia de banco PostgreSQL). Sem configuração para o projeto, propõe criá-la. Use antes de testar endpoints, migrations ou telas de ponta a ponta, ou para conferir telas no navegador sem tocar dados reais.
argument-hint: "[instruções adicionais]"
---

# API e front de teste

Considere como instruções adicionais o texto que o usuário escreveu junto da chamada.

## Regras (valem sempre)

- **Nunca** usar os dados, o banco ou o armazenamento originais, nem homologação ou produção. Só a cópia.
- **Nunca** derrubar a API ou o front do usuário: encerre apenas processos que escutam nas portas de teste, confirmando pela porta.
- `<scratchpad>` = pasta temporária da sessão (no Claude Code, o scratchpad da sessão; no Codex, `%TEMP%\api-teste-<repositorio>`),
  nunca dentro do repositório.
- **Nunca** exibir senhas, tokens, chaves nem valores do `.env`; passe-os direto ao ambiente do processo.
- Arquivo de sessão ou token gravado em `public/` para o navegador é **apagado na mesma hora** e nunca vai para o git.
- Serviços externos bloqueados por proxy morto, salvo o que a configuração liberar.

## 0. Configuração do projeto

1. Na raiz do projeto, rode
   `node "$(git -C "<pasta desta skill>" rev-parse --show-toplevel)/scripts/configuracao.mjs" api-teste` (a pasta da skill é uma
   junção para o `claude-skills`; `..` não serve). Ele mostra o `repositorio` (nome no `origin`), o `central` (raiz do
   `claude-skills`), as pastas `scripts-globais` e `scripts` (do projeto), quando existem, e o conteúdo da configuração do projeto
   — precedido da base, quando ela começa com `Base: <nome>`. A configuração do projeto prevalece sobre a base e sobre esta skill
   quando divergirem.
   - `<scripts-globais>`: `usuario-teste.mjs` (cria o usuário `teste-validacao` numa cópia com `AppUsuarios.json` e grava a sessão do
     navegador) e `copiar-postgres.mjs` (copia um banco PostgreSQL para `<banco>_teste`; recusa destino sem "teste" no nome).
   - `<scripts>`: scripts próprios do projeto, quando houver.
   - Rode os scripts com `node` pelo caminho absoluto, a partir da raiz do projeto, salvo indicação contrária.
2. **`SEM CONFIGURACAO`**: avise e proponha criá-la a partir do que o projeto mostra (stack, `.env.example`, `appsettings`/
   `application-*.properties`, `launchSettings.json`, Docker/compose, rota de health, fluxo de login, chave do `sessionStorage`).
   Mostre o rascunho e só crie com aprovação; ao criar, siga as regras do `claude-skills` (LF, `git pull --ff-only` antes, commit
   com a `texto-commit` e push).

## 1. Dados

Copie os dados para o `<scratchpad>` **só se a cópia ainda não existir**: ela é reaproveitada entre testes. Recriar só quando o
usuário pedir ou quando uma migração precisar rodar de novo do zero. Pasta, dump ou banco informado pelo usuário vale no lugar do
padrão. Usuário de teste, quando a configuração prevê, é criado **só na cópia**.

## 2. Build

Encerre só a instância de teste anterior (confira pela porta) e gere o executável no `<scratchpad>` (publish, jar), nunca usando o
`bin`/`target` que a API do usuário pode estar travando.

## 3. Variáveis

A API rodando fora da raiz não lê o `.env`: passe no ambiente do processo, lendo do `.env` sem exibir. Chave de criptografia dos dados
tem de ser a **real** (sem ela os dados cifrados não batem); chave de JWT pode ser qualquer uma (≥ 32 bytes). Proxy morto:
`HTTPS_PROXY`/`HTTP_PROXY=http://127.0.0.1:9` (e, em Java, `JAVA_TOOL_OPTIONS` com `-Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=9
-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=9 -Dhttp.nonProxyHosts=localhost|127.0.0.1`); exceções em `NO_PROXY`.

## 4. Executar

Em segundo plano, a partir da pasta publicada no `<scratchpad>`, log em `<scratchpad>/api.log`. Confirme o health check e, no log,
que os dados/banco apontam para a **cópia**.

## 5. Front

`VITE_API_URL=http://localhost:<porta da API de teste> npx vite --port <porta do front de teste> --strictPort` em segundo plano (ou o
comando da configuração). O Vite pode escutar só em `::1`: use `localhost`, não `127.0.0.1`.

## 6. curl

JSON com acento no Git Bash: use `\uXXXX`. Token em variável (`T=$(cat <arquivo>)`), nunca impresso. Teste também o isolamento que
o projeto exigir (outra empresa/cliente → 404, sem permissão → 403).

## 7. Navegador

- Login sem digitar senha: gere o arquivo de sessão em `public/` com o script da configuração, carregue no `sessionStorage` pela
  própria página (`sessionStorage.setItem('<chave>', ... await (await fetch('/<arquivo>')).text() ...)` + `location.reload()`) e
  **apague o arquivo na hora**. O token vale até a API reiniciar.
- Abra uma aba nova na automação do navegador disponível (no Claude Code, a extensão do Chrome; no Codex, a ferramenta de navegador
  da sessão) e valide pelo DOM, executando JavaScript na página, uma ação por chamada. A captura de tela às vezes trava
  ("renderer may be frozen"): meça pelo DOM e tente de novo depois; não conclua nada sem medida.
- Confira 360–400 px (ou `iframe` fixo de 390×844 com `src='/'`, onde a sessão do `sessionStorage` vale), notebooks de 14"
  (1280×720, 1366×768, 1536×864) e os temas claro e escuro. Medidas de layout: skill `medir-layout`.

## 8. Ao terminar

Encerre os processos de teste (`netstat -ano | grep -E ":(<porta API>|<porta front>) "` → `taskkill //F //T //PID <pid>`, ou o
comando da configuração), feche a aba e confirme que nenhum arquivo de sessão ou token ficou em `public/`. A cópia dos dados ou do
banco fica para o próximo teste; apague só se o usuário pedir.
