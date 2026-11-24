---
name: doc-sync
description: Atualiza a documentação-base (docs-kb) do sistema do repositório atual a partir das mudanças no código desde a última geração — pares público (suporte) e restrito (-dev), sigilo, validação — roda as ações próprias do projeto (configuradas no repositório claude-skills em projetos/<repo>/doc-sync.md e doc-sync/config.json) e lista os arquivos que preciso enviar manualmente ao Google Drive. Use quando o usuário pedir para atualizar ou sincronizar a documentação.
argument-hint: "[modulo <nome> | full]"
---

# Sincronizar a documentação (docs-kb)

Argumentos opcionais: "modulo <nome>" (só um módulo) ou "full" (regenerar tudo).

Ferramentas: `powershell -NoProfile -ExecutionPolicy Bypass -File "<pasta desta skill>/scripts/kb-tools.ps1" <acao>`, na raiz do
repositório (ações genéricas: `detectar`, `check`, `para-enviar`, `readme`, `manifest`, `finalizar`; mais as ações do projeto). Leia
`docs-kb/README.md` para a organização da pasta.

## 0. Configuração do projeto

1. Na raiz do projeto, rode
   `node "$(git -C "<pasta desta skill>" rev-parse --show-toplevel)/scripts/configuracao.mjs" doc-sync` (a pasta da skill é uma
   junção para o `claude-skills`; `..` não serve). Ele mostra o `repositorio` (nome no `origin`), o `central` (raiz do
   `claude-skills`), as pastas `scripts-globais` e `scripts` (do projeto), quando existem, e o conteúdo da configuração do projeto
   — precedido da base, quando ela começa com `Base: <nome>`. A configuração do projeto prevalece sobre a base e sobre esta skill
   quando divergirem. Ela traz os passos próprios do projeto, como ações extras e os pares que dependem delas.
2. O `kb-tools.ps1` lê sozinho `projetos/<repositorio>/doc-sync/config.json`: nome do sistema, objetivo do README, padrões proibidos
   nos públicos (`publicoProibido`), clientes que não podem aparecer (`clientesNoPublico`), URLs permitidas, exceções de par, arquivos
   de controle extras e `acoesExtras` (ação → script em `projetos/<repositorio>/doc-sync/`).
3. **`SEM CONFIGURACAO`**: o script usa padrões genéricos (sistema = nome do repositório, sem lista de clientes). Avise e proponha
   criar os dois arquivos a partir do `docs-kb/` existente (`_mapa.md`, nomes internos e de clientes que aparecem no código), seguindo
   as regras do `claude-skills` (LF, `git pull --ff-only`, commit com a `texto-commit` e push). Só crie com aprovação.

## Passos

1. Ler `docs-kb/_manifest.json`. Se não existir, parar e avisar que a documentação inicial ainda não foi gerada. O manifest registra a
   última execução (commit, data, histórico em `execucoes`) e o hash de cada arquivo de código já processado (`hashes`).
2. Detectar mudanças desde a última execução até o momento com `kb-tools.ps1 detectar`. Ele junta o histórico do git
   (`<commit da última execução>..HEAD`), os arquivos em stage, as alterações no worktree e os arquivos não rastreados, e descarta o
   que tem o mesmo hash registrado na última execução (já processado — inclusive mudanças não commitadas que já tinham sido
   documentadas). Ignora node_modules, build, dist, target, bin, obj, docs-kb, .claude e arquivos gerados. Resultado em
   `docs-kb/_mudancas.json`. Se avisar que o commit da última execução não existe mais no histórico, avisar e sugerir "full".
3. Mapear arquivos alterados para docs usando o campo "fontes" do front matter (o script já faz isso em `docsARegenerar`):
   - arquivo alterado com doc existente: regenerar o doc;
   - arquivo novo sem doc: identificar o módulo provável (`moduloProvavel`, via `docs-kb/_mapa-arquivos.csv`) e criar o doc necessário
     (módulo, tela, entidade ou processo); arquivo alterado sem doc: avaliar se precisa de doc;
   - arquivo removido: marcar os docs afetados como possivelmente obsoletos (`obsoleto: true` no front matter do par). Nunca apagar um
     doc sem minha confirmação.
4. Mostrar o plano em lista curta (a regenerar, a criar, obsoletos). Prosseguir sem esperar, exceto para exclusões. Se mais de 15 docs
   forem afetados, perguntar antes de prosseguir.
5. Regenerar apenas os docs afetados, lendo somente suas fontes e o diff. Manter os templates e as regras da geração inicial: PT-BR;
   marcar "Confirmado no código" ou "Inferido (verificar)"; citar fontes; nunca copiar segredos; nunca inventar. Preservar as seções
   que não mudaram. Atualizar o campo commit no front matter.
6. **Ações do projeto**: rode as que o `doc-sync.md` do projeto mandar (em toda execução, mesmo sem mudanças detectadas, quando ele
   disser), com `kb-tools.ps1 <acao>`, e siga as conferências dele.
7. Validar com `kb-tools.ps1 check` e corrigir o que ele apontar.
8. Rodar `kb-tools.ps1 finalizar`, que, nesta ordem: gera `docs-kb/_para-enviar.md` com três listas por pasta do Drive (arquivos
   novos, alterados e obsoletos — para eu remover no Drive manualmente), com caminho relativo a `docs-kb/upload/`; regenera
   `docs-kb/README.md` (objetivo, organização e índice de todos os arquivos); e atualiza `docs-kb/_manifest.json` (commit atual, data,
   nova entrada no histórico de execuções, fontes e hash de cada doc e de cada arquivo de código processado). Mostrar as listas de
   `_para-enviar.md` também no relatório.
9. Relatório curto: docs regenerados/criados/obsoletos e pendências "Inferido (verificar)".

## Regras

Não fazer commit nem push; não enviar nada ao Drive; não incluir segredos; aplicar o `.editorconfig` (sem `.editorconfig` na raiz:
UTF-8 sem BOM, CRLF, linha final).

## Organização e sigilo

Só vai para o Drive o que está em `docs-kb/upload/`; arquivos de controle (`_manifest.json`, `_para-enviar.md`, `_mudancas.json`,
`_mapa*`, `README.md`) ficam na raiz de docs-kb, fora de upload. Todo doc existe em par com o mesmo caminho relativo —
`upload/suporte/<pasta>/<base>.md` (público, funcional; `categoria_sugerida: Suporte`, `confidencialidade: interno`, `fontes`
apontando para o seu `-dev`) e `upload/desenvolvimento/<pasta>/<base>-dev.md` (restrito, técnico; `categoria_sugerida:
Desenvolvimento`, `confidencialidade: restrito-desenvolvimento`, `fontes` com os arquivos de código). Os arquivos de código mapeiam
para o `-dev`; ao regenerar um `-dev`, regenerar também o seu par público. Código, arquitetura, estrutura do banco, leiautes, possíveis
defeitos, riscos de segurança, permissões especiais, usuários/nomes internos e nomes de clientes ficam só no `-dev`. Públicos só linkam
públicos. Nomes de arquivo claros sobre o conhecimento contido (entidades pelo conceito de negócio, sem código de tabela).
