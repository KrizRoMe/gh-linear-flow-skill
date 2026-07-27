---
name: linear-worktree-branch
description: Crea un worktree de git en `.trees/<branch>` desde la rama base para un issue de Linear que ya existe, sin tocar la rama actual del worktree principal. Úsalo cuando el issue ya está creado en Linear y necesitás un worktree paralelo para trabajar.
disable-model-invocation: true
argument-hint: "[identificador]"
---

Ejecuta este flujo con cuidado. NUNCA uses operaciones de eliminar/archivar en Linear.

A diferencia de /linear-task y /linear-branch, este skill NO modifica la rama actual del worktree principal: crea un worktree paralelo en `.trees/<branch>` y te deja seguir haciendo lo que estés haciendo en el principal. Si preferís el flujo clásico (cambiar la rama del principal), usá /linear-task o /linear-branch.

0. Config: localiza y sigue el procedimiento en `resources/config.md` (raíz del proyecto, dos niveles arriba de este SKILL.md; si tu entorno define `${CLAUDE_SKILL_DIR}`, es `${CLAUDE_SKILL_DIR}/../../resources/config.md`). Clave requerida para este skill: `baseBranch`.

1. Pregúntame cuál es el identificador del issue de Linear (ej. RC-456), a menos que ya lo haya dado como argumento ($ARGUMENTS) — en ese caso úsalo directo y no preguntes.

2. Usa la tool MCP de Linear `get_issue` con el identificador para obtener:
   - identifier, title, branchName, url, description, state.name, priority

3. Muéstrame los detalles del issue para confirmar: título, estado, prioridad, resumen de la descripción.

4. Asegurate de que `baseBranch` (de la config) esté actualizada SIN cambiar la rama actual del worktree principal:
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

5. Crea el worktree apuntando a la rama del issue, anclado en `<baseBranch>` actualizado:
   Ejecuta:
     git worktree add .trees/<branchName> -b <branchName> <baseBranch>
   (donde `<baseBranch>` puede ser el nombre local o `origin/<baseBranch>` si la local no existe todavía).

   - Si el directorio `.trees/` no existe, `git worktree add` lo crea automáticamente — no hace falta crearlo antes.
   - Si ya existe un worktree en esa ruta (porque volvés a correr el skill con el mismo branch), `git worktree add` falla con "already exists". En ese caso, listá los worktrees existentes con `git worktree list` y sugerí al usuario removerlo (`git worktree remove .trees/<branchName>`) o elegir otra rama.

6. Cambiá al worktree nuevo (la tool de Bash mantiene el `cd` entre llamadas de la misma sesión, así que las próximas invocaciones corren sobre el worktree nuevo):
   Ejecutá en una sola llamada a Bash:
     cd .trees/<branchName> && pwd && git branch --show-current && git status --short
   Verificá que el output muestre:
   - `pwd` termina en `.trees/<branchName>`
   - `git branch --show-current` devuelve `<branchName>`
   - `git status --short` no muestra nada raro

   Para tools que pidan path absoluto (Read, Edit, Glob), apuntá a `.trees/<branchName>/...` desde la raíz del repo — esos tools no heredan el `cd` del Bash.

   Nota: si el usuario sale y vuelve en otra sesión, el `cd` se pierde. En ese caso tendrá que correr `cd .trees/<branchName>` manualmente antes de seguir.

7. Imprime resumen:
   - Issue de Linear: <identifier> — <title>
   - Estado: <state.name>
   - URL: <url>
   - Rama: <branchName>
   - Worktree: .trees/<branchName>
   - Working dir: ya estás en `.trees/<branchName>` dentro de esta sesión
   - Siguientes pasos: las próximas tools de Bash corren sobre este worktree automáticamente. Cuando quieras commitear + PR, corré /autocommit y /prdesc (o directo /ship). Para Read/Edit/Glob apuntá a `.trees/<branchName>/...`. Si abrís sesión nueva, primero `cd .trees/<branchName>`.