---
name: antes-do-commit
description: Checklist da Atena API antes de commitar — confere e atualiza o que acompanha uma mudança (migration Flyway e superclasse da entidade, multiempresa, permissões por ação, Swagger, docs/ e AGENTS.md), aplica os padrões (sem comentários, pt-BR, records, Lombok), normaliza finais de linha e roda compilação e testes com JDK 17. Use quando o usuário pedir "atualize o que for necessário antes do commit", "deixe pronto para commit" ou ao terminar uma funcionalidade.
---

# Antes do commit (Atena API)

Escopo = `git status` + `git diff HEAD` (stage e working tree). Para cada item, **corrija** o que faltar; no fim, liste o que foi
alterado e o que não se aplicava.

1. **Schema** mudou (entidade nova, coluna, índice, restrição)? Nova migration `V00NN__descricao.sql` em `src/main/resources/db/migration`
   com o próximo número livre; migration já aplicada **nunca** se edita nem se renomeia (corrige-se numa nova, idempotente:
   `IF NOT EXISTS`, `ON CONFLICT`), sem `BEGIN`/`COMMIT` internos, validando duplicados antes de criar índice único. Entidade confere
   com a migration (`ddl-auto=validate`): superclasse certa (`ModelBase`/`Auditable`/`Ativavel`/nenhuma, conforme as colunas),
   `@EqualsAndHashCode(onlyExplicitlyIncluded = true)` com `@EqualsAndHashCode.Include` no `@Id`. DTO de request com `@Size` igual à
   coluna. Script de dados persistidos só com SQL aprovado pelo usuário.
2. **Multiempresa**: todo acesso por ID em endpoint autenticado filtra `empresa_id` (`findByEmpresaIdAnd...`, `SecurityUtils.getEmpresaIdLogada()`);
   nenhum `findById` solto. Unicidade de negócio (CPF, placa, e-mail etc.) é por empresa.
3. **Endpoint** novo ou alterado? `@PreAuthorize("@permissao.tem('RECURSO_ACAO')")` em toda ação (nunca só `authenticated()` nem
   `hasAuthority(...) or hasRole(...)`); lista usada como seleção aceita as permissões das telas que a consomem. Permissão nova →
   migration no roteiro de `docs/permissoes.md` (descrição legível, `modulo`, `ordem`, concedida aos perfis administradores). Swagger
   completo (`@Tag`, `@Operation`, `@ApiResponses`); rota pública anula a segurança com `@SecurityRequirement(name = "")` e entra em
   `SecurityConfig`. Tipo novo em `/cadastros/{tipo}` → `PREFIXOS_CADASTRO`. Exceção nova → só no `GlobalExceptionHandler`.
4. **Contrato com clientes** mudou (request/response, status, evento de integração)? Atualizar `docs/mobile.md` (app) ou
   `docs/integracao-desktop.md` (Frota Desktop) e **avisar no resumo final** que o painel (`../painel-atena`) e/ou o app precisam
   acompanhar — não alterar outros repositórios por conta própria.
5. **Regra não óbvia** nova ou revertida? Registrar no doc da área em `docs/` (índice no `CLAUDE.md`) ou no `AGENTS.md`, sucinto, só o
   estado atual, sem duplicar nem criar nota solta. Comando, profile, variável ou camada nova → `CLAUDE.md`/`README.md`; variável de
   ambiente de produção → `docs/publicacao.md`.
6. **Padrões** (`CLAUDE.md`): **nenhum comentário** (`//`, `/* */`, Javadoc, inclusive testes); nomes e mensagens em pt-BR; DTOs como
   `record`, conversão manual no service (`converterParaResponse`), entity nunca exposta no controller; injeção com
   `@RequiredArgsConstructor` + `private final`; `PasswordEncoder` injetado; sem imports não usados nem código morto. Regra nova de
   serviço → teste JUnit + Mockito em `src/test/.../service` (sem banco).
7. **Finais de linha** (`.editorconfig` + `core.autocrlf`): no índice LF em tudo, CRLF só em `*.cmd`; UTF-8 sem BOM; newline no fim.
   Conferir os alterados com `git ls-files --eol -- <arquivos>` (coluna `i/`) e os primeiros bytes (`head -c3 | od -c`), e corrigir os
   divergentes. Os legados `.editorconfig`, `.gitignore` e `maven-wrapper.properties` em CRLF não são tocados por conta própria.
8. **Build e testes** com JDK 17 (o `java` do PATH é o 24 e quebra o Lombok): `JAVA_HOME` = a `corretto-17.*` mais nova em `~/.jdks`.
   - `./mvnw -q clean compile` sem erros nem warnings novos;
   - `./mvnw "-Dtest=*,!FrotaApplicationTests" test` (unitários);
   - com migration/entidade alterada, também `FrotaApplicationTests` (exige PostgreSQL; usa o banco do profile `hom`) ou a skill
     `api-teste`, que aplica as migrations numa cópia do banco. Sem PostgreSQL, dizer que essa validação ficou pendente.
   Falhou → corrigir e repetir; reportar a saída se não der.
9. Não commitar; sugerir a skill `texto-commit` para a mensagem.
