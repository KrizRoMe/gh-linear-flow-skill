---
name: linear-branch
description: Crea la rama de git para un issue de Linear que ya existe, dado su identificador (ej. RC-456). Úsalo cuando el issue ya está creado en Linear y solo necesitas la rama.
disable-model-invocation: true
argument-hint: "[identificador]"
---

Ejecuta este flujo con cuidado. NUNCA uses operaciones de eliminar/archivar en Linear.

0. Config: localiza y sigue el procedimiento en `resources/config.md` (raíz del proyecto, dos niveles arriba de este SKILL.md; si tu entorno define `${CLAUDE_SKILL_DIR}`, es `${CLAUDE_SKILL_DIR}/../../resources/config.md`). Clave requerida para este skill: `baseBranch`.

1. Pregúntame cuál es el identificador del issue de Linear (ej. RC-456), a menos que ya lo haya dado como argumento ($ARGUMENTS) — en ese caso úsalo directo y no preguntes.

2. Usa la tool MCP de Linear `get_issue` con el identificador para obtener:
   - identifier, title, branchName, url, description, state.name, priority, assignee.id

3. Muéstrame los detalles del issue para confirmar: título, estado, prioridad, resumen de la descripción.

4. Usa la tool MCP de Linear `whoami` para obtener el usuario autenticado en la sesión actual → <meId>. Si `assignee.id` del issue no coincide con <meId> (o el issue no tiene assignee), usa `save_issue` con `id: <identifier>` y `assigneeId: <meId>` para asignártelo — el issue debe terminar siempre asignado a quien está logueado en Linear ahora.

5. Antes de crear la rama, asegura que `baseBranch` (de la config) esté actualizada:
   a. Ejecuta: `git branch --show-current` para obtener la rama actual.
   b. Si la rama actual NO es `baseBranch`:
      - DETENTE el flujo inmediatamente.
      - Muéstrame esta advertencia:
        ⚠️ ADVERTENCIA: Estás en la rama `<ramaActual>`, no en `<baseBranch>`.
        La nueva rama se creará desde `<baseBranch>`. ¿Deseas continuar? (sí/no)
      - Espera mi respuesta. Si no respondo "sí" o "s", aborta el flujo e imprime: "Operación cancelada."
   c. Ejecuta: `git checkout <baseBranch>`.
   d. Ejecuta: `git pull`.
   e. Si algún paso falla, detente y reporta el error.

6. Crea la rama de git desde `<baseBranch>` usando el `branchName` de Linear:
   Ejecuta: `git checkout -b <branchName>`

7. Imprime resumen:
   - Issue de Linear: <identifier> — <title>
   - Estado: <state.name>
   - URL: <url>
   - Rama: <branchName>
   - Siguientes pasos: implementa los cambios, luego corre /autocommit y /prdesc (o directo /pr si ya quieres crear el PR, o /ship para encadenar todo en un solo paso)
