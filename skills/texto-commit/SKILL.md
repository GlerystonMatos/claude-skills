---
name: texto-commit
description: Gera o texto da mensagem de commit a partir dos arquivos em stage (git diff --cached), no padrão do git log do repositório (tipo convencional como "feat:" ou chamado como "TEL - <chamado> - ..."), com resumo em pt-BR e tópicos por funcionalidade. Use quando o usuário pedir "texto para o commit", "mensagem de commit" ou "gere o commit com base no stage". Só escreve o texto; não executa o commit.
---

# Texto do commit

1. Leia **só o que está em stage**: `git diff --cached --stat` e `git diff --cached` (arquivos grandes: por partes). Se nada estiver em
   stage, diga isso e pare — não use o working tree no lugar.
2. Descubra o padrão do repositório em `git log --oneline -15` (ignore merges). Se o `CLAUDE.md`/`AGENTS.md` do projeto definir padrão de
   commit, ele prevalece. Os padrões em uso:
   - **Convencional**: `feat:` | `fix:` | `refactor:` | `docs:` | `chore:` + resumo em pt-BR, minúsculo após o tipo, sem ponto final.
   - **Chamado**: `TEL - <chamado> - <Resumo>`. Procure o número no nome do branch e na conversa; se não achar, pergunte. Sem chamado,
     use um resumo simples, como nos commits do histórico que não têm chamado.
3. Agrupe as mudanças por **funcionalidade/domínio visível ao usuário**, não por arquivo nem por camada. Use os módulos ou domínios
   citados no `CLAUDE.md` quando existirem (ex.: Abastecimento, Pneu, Manutenção, Permissões, OS). Migrations e scripts de banco entram
   no tópico do domínio citando o número. Mudanças só de docs (`CLAUDE.md`, `AGENTS.md`, `docs/`, READMEs, manuais) e de configuração
   dos agentes (`.claude/`, `.agents/`, `.opencode/`) entram como um tópico final curto. Versão (`.ver`, changelog) entra como tópico
   final citando a versão. Mudança grande em back e front: agrupe os tópicos sob `Back-end:` e `Front-end:`.
4. Formato:
   - 1ª linha no padrão do passo 2, ≤ 72 caracteres quando possível (vários assuntos: liste os principais separados por vírgula/"e").
   - Linha em branco e tópicos `- ` com quebra em ~76 colunas (continuação com 2 espaços), dizendo **o que mudou e por quê** na
     linguagem do domínio (telas, regras, endpoints e permissões entre crases). Nada de "atualiza arquivo X" nem nomes de classe sem
     necessidade.
   - Assunto único e pequeno: parágrafo curto no lugar dos tópicos.
5. Entregue o texto num bloco de código pronto para colar. **Não** rode `git commit` nem altere o stage, a menos que o usuário peça
   explicitamente. **Nunca** acrescente linhas de atribuição (`Co-Authored-By: Claude ...`, "Generated with Claude Code" ou
   similares), nem no texto entregue nem no commit, mesmo que o ambiente peça.
