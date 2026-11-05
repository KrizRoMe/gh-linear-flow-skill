# Config compartida — gh-linear-flow

Todos los skills de este repo comparten un único archivo de configuración local:

`~/.claude/gh-linear-flow.config.json`

## Esquema

```json
{
  "linearEmail": "tu-correo@dominio.com",
  "linearUserId": "uuid-resuelto-via-list_users",
  "linearTeamName": "Nombre del equipo",
  "linearTeamId": "uuid-resuelto-via-list_teams",
  "linearTeamUrl": "https://linear.app/<workspace>/team/<KEY>/all",
  "baseBranch": "develop",
  "relatedRepos": {
    "org/repo1": ["org/repo2"],
    "org/repo2": ["org/repo1"]
  },
  "contentLanguage": "en"
}
```

Ningún skill necesita todas las claves — cada `SKILL.md` indica cuáles requiere en su paso 0.

`relatedRepos` mapea cada repo de GitHub (formato `org/repo`) a la lista de otros repos relacionados con él (donde se buscan PRs de un mismo issue de Linear, ej. api + web de un mismo feature). La relación es siempre bidireccional: si `repo-web` lista a `repo-api`, `repo-api` también debe listar a `repo-web`, aunque nunca se haya configurado pr-notify/ship parado en `repo-api` todavía.

`contentLanguage` es el idioma en el que se redacta TODO el contenido generado por IA en la suite: título/descripción de issues de Linear, título/descripción de PRs, y resúmenes generados (ej. `/daily-resume`). No afecta las etiquetas propias de cada skill (nombres de columnas, headers de bloque, mensajes fijos como "Operación cancelada"), solo el contenido redactado a partir de lo que el usuario pide. Acepta cualquier idioma que el usuario indique (ej. `"es"`, `"pt"`, `"fr"`).

## Procedimiento de bootstrap

Sigue esto cada vez que un skill te remita a este archivo:

1. Intenta leer `~/.claude/gh-linear-flow.config.json` con la tool Read. Si no existe, trátalo como `{}` (objeto vacío).
2. Compara las claves que el skill actual necesita contra las que ya están en el archivo. Si no falta ninguna, continúa directo con la tarea del skill usando esos valores — no preguntes nada.
3. Si faltan claves, pregúntamelas en una sola tanda, agrupadas. Usa valores por defecto razonables cuando aplique: `baseBranch` → "develop", `contentLanguage` → "en" (inglés). Para `contentLanguage`, pregunta explícitamente en qué idioma quiero que se redacte el contenido generado (descripciones de issues, títulos/descripciones de PR, resúmenes), aclarando que el default es inglés si no respondo. `relatedRepos` tiene su propio procedimiento (ver punto 4) — nunca la pidas como pregunta genérica de setup.
4. Resuelve los IDs reales ANTES de guardar nada — nunca inventes un id:
   - `linearUserId`: usa la tool MCP `list_users` con el `linearEmail` dado. Si no hay coincidencia exacta, muéstrame las opciones encontradas y pregunta cuál es.
   - `linearTeamId` / `linearTeamUrl`: usa `list_teams` para encontrar el equipo por nombre/key, y `get_team` para obtener su url real. Si no hay coincidencia exacta, muéstrame las opciones y pregunta.
   - `relatedRepos` (solo si el skill actual la requiere): determina el repo de GitHub actual con `gh repo view --json nameWithOwner -q .nameWithOwner` → `<repoActual>`.
     - Si `relatedRepos[<repoActual>]` ya existe en el archivo, úsalo directo — no preguntes nada.
     - Si NO existe, pregúntame qué otros repos de GitHub están relacionados con este (formato `org/repo`, uno o varios, separados por coma).
     - Guarda `relatedRepos[<repoActual>]` con los repos que te dé. Y por cada uno de esos repos, agrega `<repoActual>` a su propia lista `relatedRepos[<ese repo>]` (creando la entrada si no existía) — la relación siempre se guarda en ambos sentidos, nunca solo en uno.
     - Si `<repoActual>` ya aparece como relacionado dentro de la lista de otro repo (por una configuración previa hecha parada en ese otro proyecto), eso ya cuenta como relación bidireccional existente — no vuelvas a preguntar, solo usala.
5. Actualiza el archivo con Write, combinando las claves nuevas con las que ya existían — nunca borres claves que otro skill guardó antes. Para `relatedRepos`, mergea por clave de repo (nunca reemplaces el objeto completo ni borres entradas de otros repos). Si el directorio `~/.claude/` no existe (agentes distintos a Claude Code no lo crean automáticamente), créalo antes de escribir.
6. Continúa con la tarea del skill usando los valores ya resueltos.

Si en cualquier momento te pido explícitamente reconfigurar algo (ej. "cambia mi email de Linear", "agrega este repo a relatedRepos"), actualiza solo esa clave sin volver a pedir ni reconfirmar las demás. Al agregar un repo a mano, aplicá igual la regla de bidireccionalidad.
