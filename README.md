# claude-skills

Skills do Claude Code, versionadas num só lugar.

## Estrutura

| Pasta | Conteúdo | Instalação |
|---|---|---|
| `skills/` | Skills genéricas, usadas em qualquer projeto (`texto-commit`, `incrementar-versao`, `doc-sync`, `iniciar-ambiente-docker`, `checklist-prompt`, `validar-rebase`, `compose-padrao-argos`, `revisar-padroes-argos`, `infra-gcp-padrao-argos`, `antes-do-commit`, `api-teste`, `medir-layout`) | Globais: `~/.claude/skills/<skill>` (Claude Code e opencode) e `~/.codex/skills/<skill>` (Codex) são junções para `skills/<skill>` |
| `projetos/<repo>/` | Configuração de cada projeto para as skills globais: `<skill>.md` (itens, portas, comandos, variáveis) e `<skill>/scripts/` | Só aqui; os projetos não guardam skills. `<repo>` = nome do repositório no `origin` |

## Instalar ou atualizar as skills globais

```powershell
.\instalar.ps1
```

Cria uma junção em `~/.claude/skills` e em `~/.codex/skills` para cada pasta de `skills/`. Uma cópia antiga com o mesmo nome vai para
`skills-backup`, ao lado da pasta de destino. Junções de skills removidas do repositório são apagadas. As pastas `synced` (Claude) e
`.system` (Codex) não são tocadas. Não use `~/.agents/skills`: o opencode lê essa pasta e também `~/.claude/skills`, e duplicaria as skills.

Como a pasta global aponta para o repositório, editar uma skill aqui já vale no Claude Code; basta commitar.

## Configuração por projeto

Skills como `antes-do-commit`, `api-teste` e `medir-layout` têm uma parte comum (o `SKILL.md` em `skills/`) e uma parte de cada
projeto, em `projetos/<repo>/<skill>.md` (e scripts em `projetos/<repo>/<skill>/scripts/`). A skill descobre o repositório central por
`git -C "<pasta da skill>" rev-parse --show-toplevel` (a pasta é uma junção; `..` não serve) e o projeto pelo nome do repositório em
`git remote get-url origin` (sem remote, o nome da pasta). Sem configuração para o projeto, ela avisa e propõe criar o arquivo na hora.

- **Base comum**: a configuração que começa com `Base: <nome>` herda `projetos/_<nome>/<skill>.md` e só traz o que muda. Hoje há
  `_padrao-argos` (projetos .NET + React/MUI com armazenamento em documentos, como argos e iris).
- **Scripts compartilhados** em `skills/<skill>/scripts/` (ex.: `api-teste/scripts/usuario-teste.mjs` e `copiar-postgres.mjs`); em
  `projetos/<repo>/<skill>/scripts/` fica só o que é de um projeto.
- A configuração traz só o que a skill e o `CLAUDE.md` do projeto não dizem: itens de domínio, espelho de tipos, repositórios
  relacionados, exceções e comandos fora do comum.

## Verificar os projetos

```powershell
.\verificar-projetos.ps1
```

Pede a pasta dos projetos desta máquina (o local muda entre máquinas) e a guarda em `.pasta-projetos`, fora do git, para sugerir na
próxima vez. Também aceita `-PastaProjetos D:\Projetos`. Procura repositórios git até 3 níveis abaixo dela e **não copia nem remove
nada**; só avisa:

- projeto com `.claude/skills`, `.claude/commands` ou `.agents/skills`: a skill local esconde a global de mesmo nome, ou deveria vir
  para `skills/` (se servir a outros projetos) ou para `projetos/<repo>/`;
- pasta em `projetos/` sem repositório local nesta máquina (pode ser só outra máquina; se o projeto acabou, apague a pasta).

## Regras

- Toda skill fica neste repositório, nunca dentro dos projetos.
- Skill que serve para mais de um projeto vai para `skills/`; o que muda de um projeto para outro vai para `projetos/<repo>/`.
- Os arquivos usam LF.

## Licença

`claude-skills` é um projeto livre e de código aberto licenciado sob a [MIT License](./LICENSE).