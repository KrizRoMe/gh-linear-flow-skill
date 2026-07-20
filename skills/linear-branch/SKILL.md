---
name: linear-branch
description: Crea la rama de git para un issue de Linear que ya existe, dado su identificador (ej. RC-456). Úsalo cuando el issue ya está creado en Linear y solo necesitas la rama.
disable-model-invocation: true
argument-hint: "[identificador]"
---

Ejecuta este flujo con cuidado. NUNCA uses operaciones de eliminar/archivar en Linear.

0. Config: lee y sigue el procedimiento en `${CLAUDE_SKILL_DIR}/../../resources/config.md`. Clave requerida para este skill: `baseBranch`.

1. Pregúntame cuál es el identificador del issue de Linear (ej. RC-456), a menos que ya lo haya dado como argumento ($ARGUMENTS) — en ese caso úsalo directo y no preguntes.

2. Usa la tool MCP de Linear `get_issue` con el identificador para obtener:
   - identifier, title, branchName, url, description, state.name, priority

3. Muéstrame los detalles del issue para confirmar: título, estado, prioridad, resumen de la descripción.

4. Antes de crear la rama, asegura que `baseBranch` (de la config) esté actualizada:
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

5. Crea la rama de git desde `<baseBranch>` usando el `branchName` de Linear:
   Ejecuta: `git checkout -b <branchName>`

6. Imprime resumen:
   - Issue de Linear: <identifier> — <title>
   - Estado: <state.name>
   - URL: <url>
   - Rama: <branchName>
   - Siguientes pasos: implementa los cambios, luego corre /autocommit y /prdesc
