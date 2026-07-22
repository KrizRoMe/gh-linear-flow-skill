---
name: ship
description: Encadena git status defensivo + /autocommit + /pr + /pr-notify en una sola invocación autónoma. Úsalo cuando ya terminaste de implementar y querés commitear, pushear, crear el PR y armar el mensaje de notificación de un saque. NO hace merge ni transiciona estados de Linear.
disable-model-invocation: true
argument-hint: "[--message \"<msg>\"] [--title \"<title>\"] [--body-file <path>] [--dry-run] [--no-notify]"
---

Ejecuta este flujo con cuidado. NUNCA uses operaciones de eliminar/archivar en Linear. NO hagas merge del PR. NO transiciones estados del issue. Este skill encadena lo que ya hacen las skills separadas — no expande scope.

Flags opcionales (evalúalas en este orden, todas son opt-in):
- `--dry-run`: solo imprime qué haría. No commitea, no pushea, no crea PR, no arma notify.
- `--message "<msg>"`: si está, úsalo como mensaje de commit literal y salta el paso de autogeneración del commit message.
- `--title "<title>"`: si está, úsalo como título del PR literal y salta el paso de autogeneración del título.
- `--body-file <path>`: si está, lee ese archivo y úsalo como `--body` de `gh pr create` en lugar de autogenerar la descripción.
- `--no-notify`: si está, salta el bloque de notificación al final.

0. Config: localiza y sigue el procedimiento en `resources/config.md` (raíz del proyecto, dos niveles arriba de este SKILL.md; si tu entorno define `${CLAUDE_SKILL_DIR}`, es `${CLAUDE_SKILL_DIR}/../../resources/config.md`). Claves requeridas para este skill: `baseBranch`, `contentLanguage`, `githubRepos`, `notifyRecipient`.

1. Parseo de flags: extrae de `$ARGUMENTS` los flags opcionales y guárdalos como variables. Si queda algún argumento posicional no asociado a flag, trátalo como error y aborta con "Argumento no reconocido: `<arg>`. Flags válidas: --message, --title, --body-file, --dry-run, --no-notify".

2. Validaciones defensivas iniciales:
   a. `git branch --show-current` → `<ramaActual>`. Si es `main`, `master` o `baseBranch` (de la config), aborta con: "No se puede hacer ship desde `<ramaActual>`. Cambiá de rama primero."
   b. `git status --short`. Si está vacío, aborta con: "Working tree limpio. No hay nada que commitear ni shippear."
   c. Si `--dry-run` está activo: imprime qué harías (rama actual, archivos modificados según `git status --short`, plan del commit/PR/notify) y aborta con "Dry run completado. Nada se ejecutó."

3. **Bloque commit** (encadenado desde `/autocommit`):
   a. `git add . ':(exclude)*.md'`
   b. `git add README.md 2>/dev/null || true`
   c. `git status` y `git diff --staged` para analizar.
   d. Si `--message` está activo: úsalo literal y salta a (g).
   e. Analiza SOLO los cambios en staged y genera un mensaje de commit conciso.
      Reglas conventional commit: tipos `feat`, `fix`, `refactor`, `docs`, `perf`, `test`, `build`, `ci`, `chore`. Una sola línea. Minúsculas. Sin markdown. Sin comillas. Sin emojis. Sin punto final. Formato estricto `<tipo>: <descripción>`. Máximo 100 caracteres.
   f. Imprime el mensaje generado (línea `Commit: <mensaje>`).
   g. Ejecuta `git commit -m "<mensaje>"`. Si falla (hook, etc.), aborta y reporta el error sin continuar.
   h. Imprime el hash final del commit.

4. **Bloque descripción de PR** (encadenado desde `/prdesc`):
   a. Extrae el identificador de Linear de `<ramaActual>`. Patrones válidos: `usuario/EQUIPO-NUMERO-descripcion` o `EQUIPO-NUMERO-descripcion`. Regex `LETRAS-DIGITOS` case-insensitive en la rama, output en mayúsculas (ej. `rc-456` → `RC-456`). Guarda como `<linearId>` y `<linearTitle>`. Si no hay match, deja `<linearId>` vacío y usa `<ramaActual>` como título de fallback.
   b. Si `<linearId>` existe, usa la tool MCP de Linear `get_issue` para obtener: `title`, `description`, `priority`, `state.name`, `url`, `labels (nombres)`. Guarda como contexto de Linear. Si la tool falla, loguea el error y continúa sin contexto de Linear (no abortes).
   c. Si `<linearId>` existe, sobrescribe `<linearTitle>` con el `title` que devuelve Linear (más confiable que derivarlo de la rama).
   d. Si `--body-file` está activo: salta a (i) usando ese archivo como descripción.
   e. Ejecuta en paralelo:
      - `git status`
      - `git diff --staged`
      - `git diff`
      - `git log --oneline <baseBranch>..HEAD 2>/dev/null || git log --oneline main..HEAD 2>/dev/null || git log --oneline -10`
   f. Busca template: `find .github -type f | grep -i 'pull_request_template.md' | head -n 1`. Si no hay, usa estructura default profesional.
   g. Lee el template (si existe) con `cat <ruta>`.
   h. Genera descripción profesional en `contentLanguage` (de la config), siguiendo exactamente la estructura del template detectado. Si no hay template, usa esta estructura default:
      - `## Summary` — 1-3 bullets con lo que cambia.
      - `## Changes` — bullets agrupados por área/archivo.
      - `## Test plan` — checklist `- [ ]` con cómo verificar.
      - `## Linear` — si hay contexto de Linear: `[<linearId> — <linearTitle>](<url>)`. Si no: "N/A".
      - `## Notes` — caveats, breaking changes, follow-ups. Si nada: "N/A".
      Reglas: respeta exactamente la estructura del template (si existe). Llena todas las secciones con contexto de Linear + diff real. No inventes features o tests. Si una sección no aplica, escribe N/A. Lenguaje profesional conciso. Sin bloques de código envolviendo el output.
   i. Escribe `.github/generated-pr.md` con la descripción (overwrite completo). Si `--body-file` está activo, copia ese archivo a `.github/generated-pr.md` primero.
   j. Imprime `Descripción del PR:` seguido del contenido de `.github/generated-pr.md`.

5. Título del PR:
   - Si `--title` está activo: úsalo literal.
   - Si no, construye `<linearId> — <linearTitle>` si hay contexto de Linear, o usa `<ramaActual>` como título.

6. Push:
   - `git push -u origin <ramaActual>`. Si falla, aborta y reporta el error (no intentes PR sin push exitoso).

7. Crear PR:
   - `gh pr create --title "<título>" --body "$(cat .github/generated-pr.md)" --base <baseBranch>`.
   - Si falla (auth, permisos, conflict), aborta y reporta. La rama queda pusheada sin PR — el humano puede crearlo manual o reintentar.

8. Imprime `PR creado: <url>`.

9. **Bloque notificación** (encadenado desde `/pr-notify`) — solo si `--no-notify` NO está activo:
   a. Si `<linearId>` existe, usa `get_issue` con `<linearId>` para refrescar `<linearTitle>`.
   b. Por cada repo en `githubRepos` (de la config), ejecuta en paralelo:
      - `gh pr list --repo <repo> --search "<linearId>" --state all --json number,title,url --limit 5`
      - Si el resultado está vacío, intenta fallback: `gh pr list --repo <repo> --head "<ramaActual>" --state all --json number,title,url --limit 5`
   c. Junta las URLs de PRs encontradas, agrupadas por repo.
   d. Arma el mensaje con este formato exacto:
      ```
      <linearTitle>:
      PRs:
      <url de cada PR encontrado, una por línea>
      ```
      Si no se encontró ningún PR, usa:
      ```
      <linearTitle>:
      PRs:
      (no se encontraron PRs aún — puede haber delay de indexación de GitHub; reintentá /pr-notify en unos minutos)
      ```
   e. Muestra el mensaje en un bloque de código para que lo copies y se lo pases manualmente a `notifyRecipient` (de la config).

10. Resumen final:
    ```
    ✅ Ship completo
    - Rama: <ramaActual>
    - Commit: <hash corto> — <mensaje>
    - PR: <url>
    - Notify: mensaje listo arriba (copiá y mandalo a <notifyRecipient>)
    ```

Notas operativas:
- Si CUALQUIER paso falla antes del push, aborta limpio — nada llega a remoto.
- Si el push sale pero `gh pr create` falla, la rama queda en remoto pero sin PR. Reportalo y sugerí `gh pr create --fill` o el reintento manual.
- Si `get_issue` falla en el bloque de notificación, usa `<ramaActual>` como `<linearTitle>` fallback.
