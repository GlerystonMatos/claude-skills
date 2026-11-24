---
name: iniciar-dashboard-frt
description: Abre o Dashboard FRT (Frota) no navegador já autenticado — garante no perfil do PowerShell a função Open-DashboardFrt com o alias iniciar-dashboard-frt (que pede e-mail e senha só na primeira vez, guarda-os criptografados para o usuário do Windows, faz o login na API e abre o dashboard com o token) e em seguida executa o alias numa janela do PowerShell. Use quando o usuário pedir "iniciar o dashboard frt", "abrir o dashboard do frota", "iniciar-dashboard-frt" ou para criar/atualizar esse alias ou trocar a credencial salva.
---

# Iniciar o Dashboard FRT

O alias `iniciar-dashboard-frt` fica no perfil do PowerShell e também pode ser usado direto em qualquer janela do PowerShell.

## Regras

- E-mail e senha nunca passam pelo agente: quem digita é o usuário, na janela do PowerShell, na primeira execução (a senha com
  `Read-Host -AsSecureString`).
- Depois do primeiro login bem-sucedido, a credencial fica em `%APPDATA%iniciar-dashboard-frtcredencial.xml`, gravada com
  `Export-Clixml` (criptografada pelo DPAPI: só o mesmo usuário, na mesma máquina, consegue ler). Nunca em texto puro, nem no perfil
  nem no histórico. O agente não lê esse arquivo.
- Se a API recusar a credencial salva (erro 4xx), o arquivo é apagado e a próxima execução pede e-mail e senha de novo.
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
   Para trocar a credencial (senha nova, outro usuário), acrescente `-Redefinir` depois do caminho do `executar.ps1`; no PowerShell, é
   `iniciar-dashboard-frt -Redefinir`.
3. **Avisar o usuário**: se a credencial já estiver salva (`Test-Path "$env:APPDATAiniciar-dashboard-frtcredencial.xml"`), diga
   só que o dashboard está abrindo no navegador padrão; senão, que a janela do PowerShell está pedindo **e-mail** e **senha** (só
   desta vez) e que depois o dashboard abre. Se o login falhar, a janela mostra o erro e espera Enter para fechar.
