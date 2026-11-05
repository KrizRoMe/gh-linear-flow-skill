---
name: linear-worktree-task
description: Crea un issue nuevo en Linear asignado a ti, en estado "In Progress", y crea un worktree de git en `.trees/<branch>` desde la rama base — sin tocar la rama actual del worktree principal. Úsalo al empezar una tarea nueva y querer trabajarla en paralelo con otras.
disable-model-invocation: true
argument-hint: "[titulo-opcional — si lo omites se infiere del diff de git del WORKTREE PRINCIPAL]"
---

Ejecuta este flujo con cuidado. NUNCA uses operaciones de eliminar/archivar en Linear.

A diferencia de /linear-task y /linear-branch, este skill NO modifica la rama actual del worktree principal: crea un worktree paralelo en `.trees/<branch>` y te deja seguir haciendo lo que estés haciendo en el principal. Si preferís el flujo clásico (cambiar la rama del principal), usá /linear-task o /linear-branch.

0. Config: localiza y sigue el procedimiento en `resources/config.md` (raíz del proyecto, dos niveles arriba de este SKILL.md; si tu entorno define `${CLAUDE_SKILL_DIR}`, es `${CLAUDE_SKILL_DIR}/../../resources/config.md`). Claves requeridas para este skill: `linearTeamId`, `baseBranch`, `contentLanguage`.

1. Usa la tool MCP de Linear `whoami` para obtener el usuario autenticado en la sesión actual → <meId>. El issue se asigna siempre a este usuario, sin importar quién esté configurado en `linearEmail`/`linearUserId`.

2. Usa la tool MCP de Linear `list_issue_statuses` para el `linearTeamId` de la config. Busca el estado cuyo nombre contenga "progress" (sin distinguir mayúsculas). Extrae su id como <inProgressStateId>.

3. Título del issue: resolver en este orden y detenerse en el primer caso que aplique:
   a. Si vino como argumento ($ARGUMENTS), úsalo directo y no preguntes.
   b. Si NO vino argumento, intenta autogenerarlo a partir del diff de git del working tree del WORKTREE PRINCIPAL (donde estás parado ahora mismo; prioridad: staged → unstaged → untracked). Para ello:
      - Recolecta contexto en una sola pasada: `git status --short` + `git diff --staged` + `git diff` (limita cada diff a ~400 líneas con `| head -400` si hace falta).
      - Analiza los cambios y genera un título corto (máx. ~80 caracteres), específico y legible como título de Linear.
      - Formato: **Sentence case** — solo la primera letra en mayúscula y el resto en minúscula, salvo nombres propios/siglas (ej. `Añadir autenticación con Google OAuth`). Sin prefijo de tipo (nada de `feat:`, `fix:`, etc.).
      - Reglas: una sola línea, sin markdown, sin comillas, sin emojis, sin punto final, redactado en `contentLanguage`.
      - Muéstrame el título propuesto y espera mi confirmación ("sí" para usarlo, o indícame el cambio). Si lo confirmo, no preguntes nada más.
   c. Si NO hay argumento Y el working tree del worktree principal está limpio (sin diff staged, unstaged ni archivos untracked), entonces sí pregúntame el título (obligatorio) — no pidas nada más.

4. A partir del título (más cualquier contexto extra que yo dé voluntariamente), genera la descripción del issue en el idioma configurado en `contentLanguage` (de la config), como una User Story completa, usando exactamente estas secciones markdown `##`, en este orden, traducidas al idioma configurado:

   - Inglés (default): `## Description`, `## Scope`, `## Acceptance Criteria`, `## Business Rules`, `## Out of Scope`, `## Dependencies`, `## Mockups/Figma`
   - Español: `## Descripción`, `## Alcance (Scope)`, `## Criterios de aceptación`, `## Reglas de negocio`, `## Fuera de alcance`, `## Dependencias`, `## Mockups/Figma`
   - Cualquier otro idioma configurado: traduce estos mismos headers manteniendo el orden y el sentido.

   Contenido de cada sección (redactado también en `contentLanguage`):
   - Description/Descripción: párrafo explicando el propósito y contexto de la tarea.
   - Scope/Alcance: bullets con lo que incluye la tarea.
   - Acceptance Criteria/Criterios de aceptación: checklist `- [ ] criterio` con condiciones verificables.
   - Business Rules/Reglas de negocio: bullets con reglas de negocio relevantes inferidas del título/contexto. Si no aplica ninguna, escribe "N/A".
   - Out of Scope/Fuera de alcance: bullets con lo que explícitamente NO cubre esta tarea. Si no es evidente, escribe "N/A".
   - Dependencies/Dependencias: bullets con dependencias identificadas (otros issues, equipos, servicios). Si no hay ninguna evidente, escribe "None identified"/"Ninguna identificada" (en el idioma configurado).
   - Mockups/Figma: escribe "N/A — add if applicable"/"N/A — agregar si aplica" (en el idioma configurado) salvo que yo haya dado un link o contexto visual explícito.

   No inventes reglas de negocio, dependencias ni links de mockups que no estén fundamentados en el título o contexto dado — usa los fallbacks de N/A de arriba en su lugar. No me pidas la descripción a menos que yo la haya dado explícitamente.

5. Usa la tool MCP de Linear `create_issue` con:
   - title: <título dado>
   - description: <descripción generada>
   - teamId: <linearTeamId de la config>
   - priority: 3
   - assigneeId: <meId>
   - stateId: <inProgressStateId>

6. De la respuesta de `create_issue` extrae:
   - identifier (ej. RC-123)
   - branchName (ej. usuario/rc-123-titulo-del-issue)
   - url
   - title

7. Asegurate de que la rama base (`baseBranch` de la config) esté actualizada SIN cambiar la rama actual del worktree principal:
   a. La rama base default es `develop` — leela desde `baseBranch` de la config (si no está definida, asumí "develop").
   b. Si `<baseBranch>` es literalmente `develop`, continuá sin preguntar.
   c. Si `<baseBranch>` es cualquier otra rama (ej. config tiene "main", "release/x", o el usuario pidió un override en $ARGUMENTS tipo "desde feature-x"), MOSTRALE esta advertencia y esperá confirmación:
      ⚠️ Vas a crear el worktree desde `<baseBranch>`, no desde `develop` (default).
      ¿Continuar? (sí/no)
      Si responde cualquier cosa distinta de "sí" (o "s"), abortá el flujo con "Operación cancelada." y NO ejecutes el `git fetch` ni el `git worktree add`.
   d. Ejecuta: `git branch --show-current` solo para informar (no vamos a cambiarla).
   e. Ejecuta: `git fetch origin <baseBranch>` para traer la última versión.
   f. (Recomendado, no obligatorio) Verificá que la rama local `<baseBranch>` exista; si no, podés crearla con `git branch --track <baseBranch> origin/<baseBranch>` para que `git worktree add` la pueda usar de base. La alternativa es pasar `origin/<baseBranch>` directamente al worktree add.
   g. Si algún paso falla, detente y reporta el error.

8. Crea el worktree apuntando a la nueva rama, anclado en `<baseBranch>` actualizado:
   Ejecuta:
     git worktree add .trees/<branchName> -b <branchName> <baseBranch>
   (donde `<baseBranch>` puede ser el nombre local o `origin/<baseBranch>` si la local no existe todavía).

   - Si el directorio `.trees/` no existe, `git worktree add` lo crea automáticamente — no hace falta crearlo antes.
   - Si ya existe un worktree en esa ruta (porque volvés a correr el skill con el mismo branch), `git worktree add` falla con "already exists". En ese caso, listá los worktrees existentes con `git worktree list` y sugerí al usuario removerlo (`git worktree remove .trees/<branchName>`) o elegir otra rama.

9. Cambiá al worktree nuevo (la tool de Bash mantiene el `cd` entre llamadas de la misma sesión, así que las próximas invocaciones corren sobre el worktree nuevo):
   Ejecutá en una sola llamada a Bash:
     cd .trees/<branchName> && pwd && git branch --show-current && git status --short
   Verificá que el output muestre:
   - `pwd` termina en `.trees/<branchName>`
   - `git branch --show-current` devuelve `<branchName>`
   - `git status --short` no muestra nada raro

   Para tools que pidan path absoluto (Read, Edit, Glob), apuntá a `.trees/<branchName>/...` desde la raíz del repo — esos tools no heredan el `cd` del Bash.

   Nota: si el usuario sale y vuelve en otra sesión, el `cd` se pierde. En ese caso tendrá que correr `cd .trees/<branchName>` manualmente antes de seguir.

10. Imprime un resumen claro:
   - Issue de Linear: <identifier> — <title>
   - URL: <url>
   - Rama: <branchName>
   - Worktree: .trees/<branchName>
   - Working dir: ya estás en `.trees/<branchName>` dentro de esta sesión
   - Siguientes pasos: las próximas tools de Bash corren sobre este worktree automáticamente. Cuando quieras commitear + PR, corré /autocommit y /prdesc (o directo /ship). Para Read/Edit/Glob apuntá a `.trees/<branchName>/...`. Si abrís sesión nueva, primero `cd .trees/<branchName>`.