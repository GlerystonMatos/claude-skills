# Antes do commit — Atena API

Itens específicos lidos pela skill global `antes-do-commit`. Java/Spring com Flyway; não segue o padrão do Argos.

**Relacionados**: `../painel-atena` (painel web), o app mobile (`docs/mobile.md`) e o Frota Desktop (`docs/integracao-desktop.md`).

## Itens específicos

1. **Schema** mudou (entidade nova, coluna, índice, restrição)? Nova migration `V00NN__descricao.sql` em `src/main/resources/db/migration`
   com o próximo número livre; migration já aplicada **nunca** se edita nem se renomeia (corrige-se numa nova, idempotente:
   `IF NOT EXISTS`, `ON CONFLICT`), sem `BEGIN`/`COMMIT` internos, validando duplicados antes de criar índice único. Entidade confere
   com a migration (`ddl-auto=validate`): superclasse certa (`ModelBase`/`Auditable`/`Ativavel`/nenhuma, conforme as colunas),
   `@EqualsAndHashCode(onlyExplicitlyIncluded = true)` com `@EqualsAndHashCode.Include` no `@Id`. DTO de request com `@Size` igual à
   coluna. Script de dados persistidos só com SQL aprovado pelo usuário.
2. **Multiempresa**: todo acesso por ID em endpoint autenticado filtra `empresa_id` (`findByEmpresaIdAnd...`,
   `SecurityUtils.getEmpresaIdLogada()`); nenhum `findById` solto. Unicidade de negócio (CPF, placa, e-mail etc.) é por empresa.
3. **Endpoint** novo ou alterado? `@PreAuthorize("@permissao.tem('RECURSO_ACAO')")` em toda ação (nunca só `authenticated()` nem
   `hasAuthority(...) or hasRole(...)`); lista usada como seleção aceita as permissões das telas que a consomem. Permissão nova →
   migration no roteiro de `docs/permissoes.md` (descrição legível, `modulo`, `ordem`, concedida aos perfis administradores). Swagger
   completo (`@Tag`, `@Operation`, `@ApiResponses`); rota pública anula a segurança com `@SecurityRequirement(name = "")` e entra em
   `SecurityConfig`. Tipo novo em `/cadastros/{tipo}` → `PREFIXOS_CADASTRO`. Exceção nova → só no `GlobalExceptionHandler`.
4. **Contrato com clientes** mudou (request/response, status, evento de integração)? Atualizar `docs/mobile.md` (app) ou
   `docs/integracao-desktop.md` (Frota Desktop); o aviso aos relacionados segue a skill.
5. **Documentação**: regra não óbvia no doc da área em `docs/` (índice no `CLAUDE.md`) ou no `AGENTS.md`. Comando, profile, variável ou
   camada nova → `CLAUDE.md`/`README.md`; variável de ambiente de produção → `docs/publicacao.md`.
6. **Padrões** (`CLAUDE.md`), além das regras básicas (sem comentários inclui Javadoc): DTOs como `record`, conversão manual no
   service (`converterParaResponse`), entity nunca exposta no controller; injeção com `@RequiredArgsConstructor` + `private final`;
   `PasswordEncoder` injetado. Regra nova de serviço → teste JUnit + Mockito em `src/test/.../service` (sem banco).

## Finais de linha

Exceção: os legados `.editorconfig`, `.gitignore` e `maven-wrapper.properties` em CRLF não são tocados por conta própria.

## Validação

Com JDK 17 (o `java` do PATH é o 24 e quebra o Lombok): `JAVA_HOME` = a `corretto-17.*` mais nova em `~/.jdks`.

- `./mvnw "-Dtest=*,!FrotaApplicationTests" test` (unitários);
- com migration/entidade alterada, também `FrotaApplicationTests` (exige PostgreSQL; usa o banco do profile `hom`) ou a skill
  `api-teste`, que aplica as migrations numa cópia do banco. Sem PostgreSQL, dizer que essa validação ficou pendente.
