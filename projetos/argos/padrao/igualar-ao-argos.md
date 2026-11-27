# Igualar ao Argos — base dos projetos no padrão do Argos

Base lida pela skill global `igualar-ao-argos` nos projetos com `Base: argos`.

- **Referência**: `<projetos>/argos` (front `argos-front/src`, back `argos-back`, documentação `argos-doc/`). Nunca alterar o Argos.
- **Regras escritas**: `argos-doc/padroes.md` (importado pelo `CLAUDE.md` do Argos) e o pacote `argos-doc/padroes/` (`04a` tema e
  layouts, `04b` catálogo de componentes, `catalogo.json`, checklists `09a`/`09b`).
- **Onde costuma estar a referência** (front): componentes compartilhados em `components/` (`AvatarUsuario`, `OpcaoSwitch`,
  `RotuloComAjuda`, `SobreDialog`, `AutorDialog`, `RodapeApp`, `BadgeRelacionamento`, `BadgeSituacao`, `estilosDialogo.ts`), telas de
  cadastro em `features/<cadastro>/<Nome>View.tsx` + `<Nome>FormDialog.tsx` (ex.: `features/usuarios/UsuariosView.tsx` para grade
  com foto e coluna Ações fixa, `features/clientes/ClientesView.tsx` para grade de cadastro com `tableLayout: 'fixed'`), utilitários em
  `utils/` (`imagemUsuario.ts`) e API em `api/` (`githubApi.ts`).
- **Grades do Argos**: nome e textos na fonte normal (sem negrito nem monoespaçada), relacionamento com `BadgeRelacionamento`, situação
  com `BadgeSituacao`, colunas com prioridade (`grade.mostrar`) e o que some vira segunda linha (`caption`) da célula principal.
- **Opções com switch**: `OpcaoSwitch` (compensa os 9 px de recuo do switch, `ESTILO_OPCAO_SWITCH`), com o `Stack` pai em `useFlexGap`.
- **Validação padrão**: `npm run build` no front, `dotnet build <solução>` com 0 avisos e `dotnet test` no projeto de testes.
