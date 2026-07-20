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
  "githubRepos": ["org/repo1", "org/repo2"],
  "notifyRecipient": "el equipo",
  "contentLanguage": "en"
}
```

Ningún skill necesita todas las claves — cada `SKILL.md` indica cuáles requiere en su paso 0.

`contentLanguage` es el idioma en el que se redacta TODO el contenido generado por IA en la suite: título/descripción de issues de Linear, título/descripción de PRs, y resúmenes generados (ej. `/daily-resume`). No afecta las etiquetas propias de cada skill (nombres de columnas, headers de bloque, mensajes fijos como "Operación cancelada"), solo el contenido redactado a partir de lo que el usuario pide. Acepta cualquier idioma que el usuario indique (ej. `"es"`, `"pt"`, `"fr"`).

## Procedimiento de bootstrap

Sigue esto cada vez que un skill te remita a este archivo:

1. Intenta leer `~/.claude/gh-linear-flow.config.json` con la tool Read. Si no existe, trátalo como `{}` (objeto vacío).
2. Compara las claves que el skill actual necesita contra las que ya están en el archivo. Si no falta ninguna, continúa directo con la tarea del skill usando esos valores — no preguntes nada.
3. Si faltan claves, pregúntamelas en una sola tanda, agrupadas. Usa valores por defecto razonables cuando aplique: `baseBranch` → "develop", `notifyRecipient` → "el equipo", `contentLanguage` → "en" (inglés). Para `contentLanguage`, pregunta explícitamente en qué idioma quiero que se redacte el contenido generado (descripciones de issues, títulos/descripciones de PR, resúmenes), aclarando que el default es inglés si no respondo.
4. Resuelve los IDs reales ANTES de guardar nada — nunca inventes un id:
   - `linearUserId`: usa la tool MCP `list_users` con el `linearEmail` dado. Si no hay coincidencia exacta, muéstrame las opciones encontradas y pregunta cuál es.
   - `linearTeamId` / `linearTeamUrl`: usa `list_teams` para encontrar el equipo por nombre/key, y `get_team` para obtener su url real. Si no hay coincidencia exacta, muéstrame las opciones y pregunta.
   - `githubRepos`: no requiere resolución, solo normaliza al formato `org/repo`.
5. Actualiza el archivo con Write, combinando las claves nuevas con las que ya existían — nunca borres claves que otro skill guardó antes. El directorio `~/.claude/` ya debería existir.
6. Continúa con la tarea del skill usando los valores ya resueltos.

Si en cualquier momento te pido explícitamente reconfigurar algo (ej. "cambia mi email de Linear", "agrega este repo a githubRepos"), actualiza solo esa clave sin volver a pedir ni reconfirmar las demás.
