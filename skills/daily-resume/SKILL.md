---
name: daily-resume
description: Resume lo que trabajaste hoy en Linear (con o sin PR asociado) y genera un bloque para copiar al daily standup. Úsalo al final del día o antes de tu daily.
disable-model-invocation: true
---

Ejecuta este flujo con cuidado. NUNCA uses operaciones de eliminar/archivar en Linear.

0. Config: lee y sigue el procedimiento en `${CLAUDE_SKILL_DIR}/../../resources/config.md`. Clave requerida para este skill: `linearUserId`.

La fecha de hoy está disponible en el contexto (currentDate). Úsala como referencia para "hoy".

1. Usa la tool MCP `list_issues` filtrado por `assigneeId` = `linearUserId` (de la config), y obtén issues actualizados hoy (`updatedAt` >= hoy 00:00:00 UTC). Incluye: identifier, title, state.name, url, updatedAt, branchName.

2. Por cada issue encontrado, usa `get_issue` para obtener detalles completos incluyendo:
   - identifier, title, state.name, url, description
   - Cualquier attachment o comentario que referencie un Pull Request (busca links de GitHub PR o menciones de "PR" en la descripción o comentarios).

3. Filtra y organiza en dos grupos:
   a. Issues con PR relacionado hoy: tienen un link de PR de GitHub en attachments, descripción, o comentarios recientes de hoy.
   b. Issues trabajados hoy (sin PR aún): actualizados hoy pero sin PR asociado.

4. Por cada issue, genera un resumen de 2-3 oraciones en español de lo implementado, basado en el título y descripción del issue, la descripción del PR o commits vinculados si hay, y el estado actual. Mantenlo conversacional y conciso, como si lo explicaras verbalmente en un daily.

5. Imprime el output en dos bloques:

   --- BLOQUE 1: DETALLE TÉCNICO ---

   ## 📋 Resumen Diario — <fecha de hoy>

   ### ✅ Tareas con PR asociado hoy
   Por cada issue del grupo (a):
   - **<identifier>** — <title>
     - Estado: <state.name>
     - PR: <pr_url>
     - Linear: <url>

   ### 🔧 Tareas trabajadas hoy (sin PR aún)
   Por cada issue del grupo (b):
   - **<identifier>** — <title>
     - Estado: <state.name>
     - Linear: <url>

   ### 📊 Resumen
   - Total de tareas trabajadas hoy: <count>
   - Con PR: <count_con_pr>
   - Sin PR: <count_sin_pr>

   --- BLOQUE 2: PARA COPIAR Y PEGAR EN EL DAILY ---

   Imprime este bloque dentro de un bloque de código plano (```) para que se pueda copiar y pegar fácil.
   Formato de standup hablado en español, un bullet por issue:

   Ayer:
   • <identifier> — <title>: <resumen de 2-3 oraciones en español natural>
   • <identifier> — <title>: <resumen de 2-3 oraciones en español natural>

   Hoy:
   • (déjalo en blanco para que yo lo llene)

   Impedimentos:
   • Ninguno

6. Si no se encontraron issues para hoy, imprime: "No se encontraron tareas asignadas actualizadas el día de hoy."
