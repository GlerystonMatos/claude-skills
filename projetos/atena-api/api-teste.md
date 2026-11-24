# API de teste — Atena API

Configuração lida pela skill global `api-teste`. Só API (o front é o `painel-atena`).

- **Do usuário (não derrubar)**: API na 3000. **Teste**: API na 3190.
- **Nunca** usar o banco `atena_api_local` original, homologação nem produção.

1. **JDK 17**: `JAVA_HOME` = a `corretto-17.*` mais nova em `~/.jdks` (o `java` do PATH é o 24). Ferramentas do PostgreSQL em
   `C:\Program Files\PostgreSQL\<versão>\bin` (`psql`, `pg_dump`, `createdb`), senha do `.env` (`ATENA_HOM_DATABASE_PASSWORD`) via
   `PGPASSWORD`, sem exibir o valor.
2. **Banco**: se `atena_api_teste` ainda não existir, `createdb -U postgres atena_api_teste` e
   `pg_dump -U postgres atena_api_local | psql -q -U postgres atena_api_teste`. Recriar (drop + cópia) só quando o usuário pedir ou
   quando uma migration nova precisar rodar de novo do zero. Dump informado pelo usuário (ex. `../dump-atena_homologacao-*.sql`) vale
   no lugar do local.
3. **Empacotar**: encerrar só a instância de teste (processo `java` escutando na 3190 — nunca a 3000) e `./mvnw -q -DskipTests package`;
   copiar `target/frota-*.jar` (sem o `.original`) para `<scratchpad>/api/atena-api.jar`.
4. **Variáveis** (o jar roda fora da raiz, então o `.env` não é importado):
   - `SPRING_PROFILES_ACTIVE=hom`, `SERVER_PORT=3190`;
   - `ATENA_HOM_DATABASE_URL=jdbc:postgresql://localhost:5432/atena_api_teste`, `ATENA_HOM_DATABASE_USERNAME`/`_PASSWORD` do `.env`;
   - `ATENA_FIREBASE_ENABLED=false`;
   - proxy morto, inclusive o `JAVA_TOOL_OPTIONS` (o PostgreSQL local não passa por proxy).
5. **Executar** a partir de `<scratchpad>/api` (`java -jar atena-api.jar`). Health: `GET http://localhost:3190/api/v1/integridade`; no
   log, a URL `atena_api_teste` e as migrations aplicadas pelo Flyway. Falha de `validate` no startup = entidade sem coluna
   correspondente na migration.
6. **Login**: `POST /api/v1/auth/login` com `{ "login", "senha" }` → `Authorization: Bearer <token>`. Peça um usuário de teste ao
   usuário; sem ele, redefina a senha de um usuário **só na cópia**:
   `CREATE EXTENSION IF NOT EXISTS pgcrypto; UPDATE usuarios SET senha_hash = crypt('<senha>', gen_salt('bf', 10)) WHERE ...`.
   5 falhas de login bloqueiam o par login/IP por 15 min (HTTP 429): reinicie a API de teste para zerar.
7. **Isolamento**: ID de outra empresa deve dar 404, e usuário sem a permissão da ação deve dar 403.
8. **Navegador**: Swagger em `http://localhost:3190/swagger`. Para testar pelo painel, use a configuração `api-teste` do
   `painel-atena` e suba a API com `APP_CORS_ALLOWED_ORIGINS=http://localhost:3191`.
9. **Ao terminar**: o banco `atena_api_teste` fica para o próximo teste.
