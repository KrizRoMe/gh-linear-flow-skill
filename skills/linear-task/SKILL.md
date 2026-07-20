---
name: linear-task
description: Crea un issue nuevo en Linear asignado a ti, en estado "In Progress", y crea la rama de git correspondiente desde la rama base. Úsalo al empezar una tarea nueva que todavía no existe en Linear.
disable-model-invocation: true
---

Ejecuta este flujo con cuidado. NUNCA uses operaciones de eliminar/archivar en Linear.

0. Config: lee y sigue el procedimiento en `${CLAUDE_SKILL_DIR}/../../resources/config.md`. Claves requeridas para este skill: `linearEmail`, `linearUserId`, `linearTeamId`, `baseBranch`.

1. Usa la tool MCP de Linear `list_issue_statuses` para el `linearTeamId` de la config. Busca el estado cuyo nombre contenga "progress" (sin distinguir mayúsculas). Extrae su id como <inProgressStateId>.

2. Pregúntame el título del issue en español (obligatorio). No pidas nada más.

3. A partir del título (más cualquier contexto extra que yo dé voluntariamente), genera la descripción del issue en español como una User Story completa, usando exactamente estas secciones markdown `##`, en este orden:

   ## Descripción
   Párrafo explicando el propósito y contexto de la tarea.

   ## Alcance (Scope)
   Qué incluye esta tarea, en bullets.

   ## Criterios de aceptación
   Checklist en formato `- [ ] criterio` con condiciones verificables.

   ## Reglas de negocio
   Bullets con reglas de negocio relevantes inferidas del título/contexto. Si no aplica ninguna, escribe "N/A".

   ## Fuera de alcance
   Bullets con lo que explícitamente NO cubre esta tarea. Si no es evidente, escribe "N/A".

   ## Dependencias
   Bullets con dependencias identificadas (otros issues, equipos, servicios). Si no hay ninguna evidente, escribe "Ninguna identificada".

   ## Mockups/Figma
   Escribe "N/A — agregar si aplica" salvo que yo haya dado un link o contexto visual explícito.

   No inventes reglas de negocio, dependencias ni links de mockups que no estén fundamentados en el título o contexto dado — usa los fallbacks "N/A" de arriba en su lugar. No me pidas la descripción a menos que yo la haya dado explícitamente.

4. Usa la tool MCP de Linear `create_issue` con:
   - title: <título dado>
   - description: <descripción generada>
   - teamId: <linearTeamId de la config>
   - priority: 3
   - assigneeId: <linearUserId de la config>
   - stateId: <inProgressStateId>

5. De la respuesta de `create_issue` extrae:
   - identifier (ej. RC-123)
   - branchName (ej. usuario/rc-123-titulo-del-issue)
   - url
   - title

6. Antes de crear la rama, asegura que la rama base (`baseBranch` de la config) esté actualizada:
   a. Ejecuta: `git branch --show-current` para obtener la rama actual.
   b. Si la rama actual NO es `baseBranch`:
      - DETENTE el flujo inmediatamente.
      - Muéstrame esta advertencia:
        ⚠️ ADVERTENCIA: Estás en la rama `<ramaActual>`, no en `<baseBranch>`.
        La nueva rama se creará desde `<baseBranch>`. ¿Deseas continuar? (sí/no)
      - Espera mi respuesta antes de hacer cualquier otra cosa.
      - Si respondo cualquier cosa distinta de "sí" (ej. "no", "cancelar", "n"), aborta el flujo e imprime: "Operación cancelada."
      - Solo si confirmo con "sí" (o "s"), continúa.
   c. Ejecuta: `git checkout <baseBranch>`.
   d. Ejecuta: `git pull`.
   e. Si algún paso falla, detente y reporta el error.

7. Crea la rama de git desde `<baseBranch>` usando el `branchName` de Linear:
   Ejecuta: `git checkout -b <branchName>`

8. Imprime un resumen claro:
   - Issue de Linear: <identifier> — <title>
   - URL: <url>
   - Rama: <branchName>
   - Siguientes pasos: implementa los cambios, luego corre /autocommit y /prdesc
