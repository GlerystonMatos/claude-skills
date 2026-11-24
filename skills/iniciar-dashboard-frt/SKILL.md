---
name: iniciar-dashboard-frt
description: Abre o Dashboard FRT (Frota) no navegador já autenticado — garante no perfil do PowerShell a função Open-DashboardFrt com o alias iniciar-dashboard-frt (que pede e-mail e senha na hora, sem gravá-los, faz o login na API e abre o dashboard com o token) e em seguida executa o alias numa janela do PowerShell. Use quando o usuário pedir "iniciar o dashboard frt", "abrir o dashboard do frota", "iniciar-dashboard-frt" ou para criar/atualizar esse alias.
---

# Iniciar o Dashboard FRT

O alias `iniciar-dashboard-frt` fica no perfil do PowerShell e também pode ser usado direto em qualquer janela do PowerShell.

## Regras

- E-mail e senha **nunca** são gravados (nem no perfil, nem em arquivo, nem no histórico) e nunca passam pelo agente: quem digita é o
  usuário, na janela do PowerShell. A senha é lida com `Read-Host -AsSecureString`.
- Nunca exiba o token nem a URL com `?token=`.

## Passos

1. **Garantir o alias**: rode `scripts/instalar-alias.ps1` desta skill com o PowerShell:
   `powershell -NoProfile -ExecutionPolicy Bypass -File "<pasta desta skill>/scripts/instalar-alias.ps1"`.
   Ele grava a função entre os marcadores `# >>> iniciar-dashboard-frt` e `# <<< iniciar-dashboard-frt` no perfil do Windows
   PowerShell (e do PowerShell 7, se instalado), substituindo uma versão antiga do mesmo alias — inclusive a que tinha e-mail e senha
   fixos — e não toca no resto do perfil. Saída: `instalado`, `atualizado`, `substituido` ou `ok` por perfil.
2. **Executar o alias**: o terminal do agente não é interativo, então abra uma janela própria do PowerShell, que carrega o perfil e
   chama o alias:
   `Start-Process powershell -ArgumentList '-NoLogo -ExecutionPolicy Bypass -File "<pasta desta skill>\scripts\executar.ps1"'`.
   (Use o caminho absoluto da pasta da skill; ele pode ter espaços.)
3. **Avisar o usuário**: diga que a janela do PowerShell está pedindo **e-mail** e **senha** e que, depois do login, o dashboard abre
   no navegador padrão. Se o login falhar, a janela mostra o erro e espera Enter para fechar.
