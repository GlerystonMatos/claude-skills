# claude-skills

Skills do Claude Code, versionadas num só lugar.

## Estrutura

| Pasta | Conteúdo | Instalação |
|---|---|---|
| `skills/` | Skills genéricas, usadas em qualquer projeto (`texto-commit`, `incrementar-versao`, `doc-sync`) | Globais: `~/.claude/skills/<skill>` (Claude Code e opencode) e `~/.codex/skills/<skill>` (Codex) são junções para `skills/<skill>` |
| `projetos/<projeto>/` | Cópia versionada das skills específicas de cada projeto (`.claude/skills`, `.claude/commands`, `.agents/skills`) | Continuam no próprio projeto; aqui é só o versionamento |

## Instalar ou atualizar as skills globais

```powershell
.\instalar.ps1
```

Cria uma junção em `~/.claude/skills` e em `~/.codex/skills` para cada pasta de `skills/`. Uma cópia antiga com o mesmo nome vai para
`skills-backup`, ao lado da pasta de destino. Junções de skills removidas do repositório são apagadas. As pastas `synced` (Claude) e
`.system` (Codex) não são tocadas. Não use `~/.agents/skills`: o opencode lê essa pasta e também `~/.claude/skills`, e duplicaria as skills.

Como a pasta global aponta para o repositório, editar uma skill aqui já vale no Claude Code; basta commitar.

## Versionar as skills dos projetos

```powershell
.\coletar-projetos.ps1
```

Recria `projetos/` a partir de `C:\Projetos\*` e avisa quando um projeto tem cópia de uma skill global, que deve ser removida do projeto.

## Regras

- Skill que serve para mais de um projeto vai para `skills/`, nunca copiada para dentro dos projetos.
- Skill específica fica no projeto e é coletada para `projetos/` antes de commitar aqui.
