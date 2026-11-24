# Medir layout — Argos

Configuração lida pela skill global `medir-layout`.

- **Padrões**: `argos-doc/padroes.md` (e o pacote `argos-doc/padroes/04a-ui-tema-layouts.md`).
- **Avisos iniciais**: no acesso inicial aparecem "Nenhum dado encontrado" e "O que há de novo"; use
  `fecharAvisosIniciais(['Seguir sem importar', 'Fechar'])`.
- **Exemplo de navegação**: `irPara('Meu trabalho', 'Cronogramas')`.
- **Telas que o acesso inicial não carrega**: Cronômetro, Usuários e parte das Configurações (use o usuário de teste da `api-teste`).
- **Exceções de propósito**: chips da seleção múltipla com o rótulo na borda ficam 9/7; badges de pessoa nos campos têm 20 px, 8/8.
