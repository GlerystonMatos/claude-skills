---
name: api-teste
description: Sobe a Atena API em modo de teste isolado (jar no scratchpad, cópia do banco local em atena_api_teste, porta 3190, Firebase desligado e serviços externos bloqueados por proxy morto), aplicando as migrations pendentes na cópia, para validar endpoints via curl ou Swagger sem tocar o banco local nem serviços externos. Use antes de testar endpoints ou migrations de ponta a ponta.
---

# API de teste (Atena API)

Regras: **nunca** usar o banco `atena_api_local` original, homologação nem produção; a API do usuário usa a porta 3000 e não é derrubada.

1. **JDK 17**: `JAVA_HOME` = a `corretto-17.*` mais nova em `~/.jdks` (o `java` do PATH é o 24). Ferramentas do PostgreSQL em
   `C:\Program Files\PostgreSQL\<versão>\bin` (`psql`, `pg_dump`, `createdb`), senha do `.env` (`ATENA_HOM_DATABASE_PASSWORD`) via
   `PGPASSWORD`, sem exibir o valor.
2. **Banco**: se `atena_api_teste` ainda não existir, `createdb -U postgres atena_api_teste` e
   `pg_dump -U postgres atena_api_local | psql -q -U postgres atena_api_teste` — a cópia é reaproveitada entre testes. Recriar (drop +
   cópia) só quando o usuário pedir ou quando uma migration nova precisar rodar de novo do zero. Dump informado pelo usuário
   (ex. `../dump-atena_homologacao-*.sql`) vale no lugar do local.
3. **Empacotar**: encerrar só a instância de teste anterior (processo `java` escutando na 3190 — confirme pela porta, nunca a 3000) e
   `./mvnw -q -DskipTests package`; copiar `target/frota-*.jar` (sem o `.original`) para `<scratchpad>/api/atena-api.jar`.
4. **Variáveis** no ambiente do processo (o jar roda fora da raiz, então o `.env` não é importado):
   - `SPRING_PROFILES_ACTIVE=hom`, `SERVER_PORT=3190`;
   - `ATENA_HOM_DATABASE_URL=jdbc:postgresql://localhost:5432/atena_api_teste`, `ATENA_HOM_DATABASE_USERNAME`/`_PASSWORD` do `.env`;
   - `ATENA_FIREBASE_ENABLED=false`;
   - `HTTPS_PROXY`/`HTTP_PROXY=http://127.0.0.1:9` e `JAVA_TOOL_OPTIONS="-Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=9 -Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=9 -Dhttp.nonProxyHosts=localhost|127.0.0.1"`
     (chamadas externas falham rápido; o PostgreSQL local não passa por proxy).
5. **Executar** em segundo plano a partir de `<scratchpad>/api` (`java -jar atena-api.jar`), log em `<scratchpad>/api.log`; confirme
   `GET http://localhost:3190/api/v1/integridade`, a URL `atena_api_teste` e as migrations aplicadas pelo Flyway no log. Falha de
   `validate` no startup = entidade sem coluna correspondente na migration.
6. **Login**: `POST /api/v1/auth/login` com `{ "login", "senha" }` → `Authorization: Bearer <token>`. Peça um usuário de teste ao
   usuário; sem ele, redefina a senha de um usuário **só na cópia**:
   `CREATE EXTENSION IF NOT EXISTS pgcrypto; UPDATE usuarios SET senha_hash = crypt('<senha>', gen_salt('bf', 10)) WHERE ...`.
   5 falhas de login bloqueiam o par login/IP por 15 min (HTTP 429): reinicie a API de teste para zerar.
7. **curl** com acento no Git Bash: JSON com `\uXXXX`. Testar também o isolamento: ID de outra empresa deve dar 404, e usuário sem a
   permissão da ação deve dar 403.
8. **Navegador** (claude-in-chrome): Swagger em `http://localhost:3190/swagger`; com a aba oculta, validar pelo DOM (`javascript_tool`),
   uma ação por chamada. O painel (`../painel-atena`) aponta fixo para a porta 3000 em `environment.ts`: não alterar; testar por ele só
   se o usuário pedir.
9. Ao terminar: encerre o processo de teste (o banco `atena_api_teste` fica para o próximo teste).
