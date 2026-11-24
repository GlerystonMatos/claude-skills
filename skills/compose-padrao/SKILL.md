---
name: compose-padrao
description: Monta ou revisa o docker-compose e as variáveis de ambiente (.env.example) de um projeto no padrão do Argos (C:\Projetos\argos) — API .NET com HTTP/HTTPS, certificado montado e healthcheck, front Vite/nginx construído com VITE_API_URL e iniciado só quando a API fica saudável, rede própria e banco externo — compara variável por variável com o Argos, iguala o possível e explica as diferenças que ficam; opcionalmente prepara o ambiente local (certificado e .env com chaves geradas). Use quando o usuário pedir "dockerizar o projeto", "incluir o front no compose", "montar o compose no padrão do Argos", "deixe o compose/as variáveis iguais ao Argos" ou revisar um compose existente contra esse padrão.
argument-hint: [caminho do front]
---

# Compose no padrão do Argos

Objetivo: um `docker-compose.yml` que sobe a API e o front juntos, igual ao do Argos, sem quebrar o que o projeto já tem.

## 1. Levantar antes de escrever
- Leia o compose atual do projeto, o `docker-compose.yml` do Argos (`C:\Projetos\argos`) e os Dockerfiles (API e front). O Argos é a
  referência de forma: indentação de 4 espaços, ordem das chaves, linhas de comando comentadas no fim do arquivo.
- Ache o repositório do front. Se o usuário não informou o caminho, procure uma pasta irmã com `package.json` + `Dockerfile` (ex.: API em
  `C:\Projetos\x-api` e front em `C:\Projetos\x`) e confirme com ele antes de usar. O `context` do build é **relativo** à pasta do compose
  (`../x`), nunca absoluto.
- Confira no Dockerfile do front o `ARG` do endereço da API (normalmente `VITE_API_URL`) e a porta do nginx (normalmente 8080).
- Confira na API: endpoint de saúde (sem `[Authorize]`), se há `UseHttpsRedirection` e a configuração de CORS.
- Mantenha os nomes de serviço, container, imagem e rede que o projeto já usa. Se a documentação (README, CLAUDE.md) divergir do
  compose, aponte a divergência ao usuário em vez de renomear por conta própria.

## 2. Serviço da API
- `image: <nome>-api:latest`, `restart: on-failure`, `container_name`, `build` com `context`/`dockerfile`.
- Portas HTTP e HTTPS (`ASPNETCORE_URLS=https://+:443;http://+:8080`, `ASPNETCORE_HTTPS_PORT=443`), certificado em `./certificado`
  montado e senha via `${KESTREL_CERTIFICATE_PASSWORD}`. Segredos só por `${VAR}` do `.env`, nunca escritos no compose.
  `/certificado/` no `.gitignore`.
- `healthcheck` explícito (o `depends_on` do front depende dele). Se a API redireciona HTTP para HTTPS, o teste usa o HTTPS interno:
  `["CMD", "wget", "--no-check-certificate", "-qO-", "https://localhost:443/<saude>"]`. Sem redirecionamento, use o HTTP como o Argos.
  A imagem precisa ter `wget` (no Alpine, `apk add wget`, ou o `wget` do busybox para HTTP).

## 3. Serviço do front
- `image: <nome>-web:latest`, `restart: on-failure`, `container_name: <nome>-web`.
- `depends_on: { <api>: { condition: service_healthy } }`.
- `build.context: ../<front>`, `build.args.VITE_API_URL: ${VITE_API_URL:-<padrão>}`. O padrão aponta para a porta da API que o navegador
  alcança **sem redirecionamento** (com `UseHttpsRedirection`, é a HTTPS; redirecionamento quebra o preflight de CORS).
- Porta `<livre>:8080`, sem colidir com outros composes da máquina (o Argos usa 3002 no front e 5003/5004 na API).
- `healthcheck` com `["CMD", "wget", "-qO-", "http://localhost:8080/"]`, intervalo 30s, timeout 3s, 3 tentativas.
- Mesma rede da API.

## 4. Variáveis de ambiente — comparar com o Argos
Monte uma tabela variável por variável juntando o `environment` do compose, o `.env.example` e o `ENV` do Dockerfile **dos dois**
projetos, e confira no código do projeto quem lê cada uma (`grep` por `GetEnvironmentVariable`, `Configuration[...]` e `"SECAO:CHAVE"`,
lembrando que `SECAO__CHAVE` no ambiente vira `SECAO:CHAVE`).
- **Igualar** o que é infraestrutura comum: HTTPS/certificado, fusos (`TZ`, `FUSO_HORARIO`, fixos como no Argos), nomes e formato
  (`AUTH__*`, `CHAVE_CRIPTOGRAFIA`), ordem no `.env.example` (senha do certificado primeiro) e portas sem aspas.
- **Não repetir no compose** o que o Dockerfile já define com `ENV`, salvo quando o Argos também repete.
- **Não copiar** variável cuja funcionalidade não existe no projeto (ex.: `COFRE__*`, `CHAVE_CRIPTOGRAFIA_ANTERIOR` sem o código de
  rotação): variável sem leitor é configuração morta. Se a funcionalidade fizer falta, proponha como evolução.
- **Manter** o que é próprio do projeto (volumes, pastas, integrações), explicado em comentário no `.env.example`.
- Tirar do `.env.example` variável que o compose deixou de ler; ela continua documentada na tabela de variáveis do README do back.
- Entregue ao usuário a tabela **Item | Projeto | Argos | Motivo** com as diferenças que ficaram.

## 5. Arquivos de apoio
- `.env.example`: inclua a variável do endereço da API com comentário explicando o padrão e que ela entra no **build** (mudou → rebuild).
- README: serviços que sobem, URLs (HTTP e HTTPS), comandos de log de cada serviço, o certificado em `./certificado` e como confiar
  nele (`dotnet dev-certs https --trust`) quando o front chama a API em HTTPS; tabela de variáveis do back e documento de portas.
- CLAUDE.md do projeto: atualize os comentários dos comandos `docker compose up/down` se mencionarem só a API.
- Finais de linha conforme o projeto (LF quando houver `.gitattributes`/`.editorconfig` pedindo).

## 6. Preparar o ambiente local (quando o usuário pedir)
- Certificado: copie `C:\Projetos\argos\certificado\certificado.pfx` para `./certificado/` do projeto (nunca para pasta versionada).
- `.env` a partir do `.env.example`, sem sobrescrever um `.env` existente sem perguntar:
  - `KESTREL_CERTIFICATE_PASSWORD` lida do `.env` do Argos, copiada **sem exibir** o valor (nem no terminal, nem na resposta).
  - Chaves novas geradas na hora (`openssl rand -base64 48` para JWT e criptografia), nunca reaproveitadas do Argos.
  - Bootstrap (`AUTH__USUARIO`/`AUTH__SENHA`): usuário `admin` e senha gerada forte; informe ao usuário onde ela está (o `.env`).
- Confira que `.env` e `certificado/` estão ignorados (`git check-ignore`) e que o compose resolve sem avisos de variável vazia
  (`docker compose config --quiet`). Não suba o ambiente se o usuário disse para não rodar.

## 7. Validar
1. `docker compose config --quiet`.
2. `docker compose build <front>` (pode demorar: tempo limite longo ou segundo plano).
3. Subir tudo (`docker compose up -d --build`) só com o aval do usuário, porque a API aplica migrations no banco configurado no `.env`.
   Subindo, confira `docker compose ps` (API `healthy` antes do front) e abra a URL do front.
4. Relate o que foi e o que não foi validado. Não commite sem pedido.
