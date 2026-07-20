---
name: my-issues
description: Lista tus issues pendientes en Linear (asignados a ti, del equipo configurado, sin contar completados/cancelados). Úsalo para ver en qué deberías trabajar.
disable-model-invocation: true
---

Ejecuta este flujo con cuidado. NUNCA uses operaciones de eliminar/archivar en Linear.

0. Config: localiza y sigue el procedimiento en `resources/config.md` (raíz del proyecto, dos niveles arriba de este SKILL.md; si tu entorno define `${CLAUDE_SKILL_DIR}`, es `${CLAUDE_SKILL_DIR}/../../resources/config.md`). Claves requeridas para este skill: `linearUserId`, `linearTeamId`, `linearTeamName`, `linearTeamUrl`.

1. Usa la tool MCP `list_issues` con estos filtros por default (no me preguntes por esto):
   - assignee: `linearUserId` (de la config)
   - team: `linearTeamName` (`linearTeamId` — `linearTeamUrl`, de la config)
   - estado: solo estados pendientes (NO en un estado completado o cancelado). Trata estos tipos de estado como excluidos: completed, cancelled. Si no estás seguro del tipo, inclúyelo.
   - orden: updatedAt desc
   - límite: 50

2. Del resultado, filtra cualquier issue cuyo `state.type` sea 'completed' o 'cancelled' (segunda pasada defensiva en caso de que la API los devuelva).

3. Por cada issue restante muestra una tabla limpia con:
   - Identificador (ej. RC-123)
   - Título
   - Estado
   - Prioridad (urgente / alta / media / baja / sin prioridad)
   - Nombre de rama

4. Al final imprime este tip de uso:
   Para empezar a trabajar en un issue corre: /linear-branch <IDENTIFICADOR>

Nota: estos son los filtros DEFAULT. Si te pido explícitamente ampliar el alcance (ej. todos los equipos, todos los estados, otro assignee), sigue mi instrucción y sobrescribe los defaults.
