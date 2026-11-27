# claude-skills

Skills do Claude Code e do Codex, versionadas num só lugar.

## Estrutura

| Pasta | Conteúdo | Instalação |
|---|---|---|
| `skills/` | Skills genéricas, usadas em qualquer projeto (`texto-commit`, `incrementar-versao`, `doc-sync`, `iniciar-ambiente-docker`, `checklist-prompt`, `validar-rebase`, `compose-padrao`, `revisar-padroes`, `infra-gcp-padrao`, `antes-do-commit`, `api-teste`, `medir-layout`, `iniciar-dashboard-frt`, `sincronizar-gitconfig`, `apagar-branch`, `igualar-ao-argos`) | Globais: `~/.claude/skills/<skill>` (Claude Code) e `~/.codex/skills/<skill>` (Codex) são junções para `skills/<skill>` |
| `scripts/` | Ferramentas do repositório: `configuracao.mjs` (lê a configuração de um projeto), `verificar-repositorio.mjs` e `testar.mjs` | Não são skills; ficam fora de `skills/` |
| `projetos/<repo>/` | Configuração de cada projeto para as skills globais: `<skill>.md` (itens, portas, comandos, variáveis) e `<skill>/scripts/` | Só aqui; os projetos não guardam skills. `<repo>` = nome do repositório no `origin` |

## Instalar ou atualizar as skills globais

```powershell
.\instalar.ps1
```

Cria uma junção em `~/.claude/skills` e em `~/.codex/skills` para cada pasta de `skills/`. Uma cópia antiga com o mesmo nome vai para
`skills-backup`, ao lado da pasta de destino. Junções de skills removidas do repositório são apagadas. As pastas `synced` (Claude) e
`.system` (Codex) não são tocadas.

Como a pasta global aponta para o repositório, editar uma skill aqui já vale no Claude Code e no Codex; basta commitar.

## Configuração por projeto

Skills como `antes-do-commit`, `api-teste` e `medir-layout` têm uma parte comum (o `SKILL.md` em `skills/`) e uma parte de cada
projeto, em `projetos/<repo>/<skill>.md` (e scripts em `projetos/<repo>/<skill>/scripts/`). A skill roda, na raiz do projeto,
`node "$(git -C "<pasta da skill>" rev-parse --show-toplevel)/scripts/configuracao.mjs" <skill>` (a pasta da skill é uma junção;
`..` não serve): o script acha o projeto pelo nome do repositório em `git remote get-url origin` (sem remote, o nome da pasta) e mostra
a base e a configuração. Sem configuração para o projeto (`SEM CONFIGURACAO`), a skill avisa e propõe criar o arquivo na hora.

- **Base comum**: a configuração que começa com `Base: <repo>` herda `projetos/<repo>/padrao/<skill>.md`, o padrão que aquele
  projeto define para os outros, e só traz o que muda. Hoje há `projetos/argos/padrao/` (projetos .NET + React/MUI com armazenamento
  em documentos), usado por argos e iris com `Base: argos`.
- **Scripts compartilhados** em `skills/<skill>/scripts/` (ex.: `api-teste/scripts/usuario-teste.mjs` e `copiar-postgres.mjs`); em
  `projetos/<repo>/<skill>/scripts/` fica só o que é de um projeto.
- A configuração traz só o que a skill e o `CLAUDE.md` do projeto não dizem: itens de domínio, espelho de tipos, repositórios
  relacionados, exceções e comandos fora do comum.

## Verificar os projetos

```powershell
.\verificar-projetos.ps1
```

Primeiro confere o próprio `claude-skills` (`scripts/verificar-repositorio.mjs`, que também roda sozinho): `name` de cada skill igual
à pasta, `description` preenchida, skills citadas que existem, `Base:` que aponta para uma base existente, arquivos de `projetos/` que
correspondem a uma skill, a lista de skills da tabela acima e finais de linha LF no índice. Em seguida roda `scripts/testar.mjs`, que testa
os scripts das skills em repositórios e pastas temporárias, sem tocar em nada real (configuração por projeto, usuário de teste, travas
da cópia do PostgreSQL, linhas perdidas no rebase, estados da sincronização do gitconfig, sintaxe dos scripts Node e PowerShell).

Depois pede a pasta dos projetos desta máquina (o local muda entre máquinas) e a guarda em `.pasta-projetos`, fora do git, para sugerir na
próxima vez. Também aceita `-PastaProjetos D:\Projetos`. Procura repositórios git até 3 níveis abaixo dela e **não copia nem remove
nada**; só avisa:

- projeto com `.claude/skills`, `.claude/commands` ou `.agents/skills`: a skill local esconde a global de mesmo nome, ou deveria vir
  para `skills/` (se servir a outros projetos) ou para `projetos/<repo>/`;
- pasta em `projetos/` sem repositório local nesta máquina (pode ser só outra máquina; se o projeto acabou, apague a pasta).

## Regras

- Toda skill fica neste repositório, nunca dentro dos projetos.
- Skill que serve para mais de um projeto vai para `skills/`; o que muda de um projeto para outro vai para `projetos/<repo>/`.
- Os arquivos usam LF (garantido pelo `.gitattributes`, qualquer que seja o `core.autocrlf` da máquina).
- Mexeu num script? Rode `node scripts/testar.mjs` (ou o `verificar-projetos.ps1`, que roda tudo); script novo ganha teste lá.
- Tudo vale para o Claude Code e para o Codex: scripts chamados pela pasta da própria skill (nunca `~/.claude/...`), em Node ou
  PowerShell (não em Python), e perguntas e automação do navegador descritas sem depender de ferramenta exclusiva de um dos dois.
- Caminhos de outros repositórios usam `<projetos>`, a pasta dos projetos da máquina (`.pasta-projetos`, ou `C:\Projetos`).

## Licença

`claude-skills` é um projeto livre e de código aberto licenciado sob a [MIT License](./LICENSE).