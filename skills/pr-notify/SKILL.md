---
name: pr-notify
description: Busca los PRs relacionados con el issue de Linear de la rama actual en tus repos de GitHub configurados, y arma un mensaje listo para copiar y notificar. Úsalo cuando quieras avisar que tu PR ya está listo.
disable-model-invocation: true
argument-hint: "[identificador-opcional]"
---

Ejecuta este flujo con cuidado.

0. Config: localiza y sigue el procedimiento en `resources/config.md` (raíz del proyecto, dos niveles arriba de este SKILL.md; si tu entorno define `${CLAUDE_SKILL_DIR}`, es `${CLAUDE_SKILL_DIR}/../../resources/config.md`). Claves requeridas para este skill: `githubRepos`, `notifyRecipient`.

1. Obtén la rama actual: `git branch --show-current` → <ramaActual>.

2. Extrae el identificador de Linear del nombre de la rama (patrón usuario/EQUIPO-NUMERO-descripcion o EQUIPO-NUMERO-descripcion, regex LETRAS-DIGITOS, en mayúsculas) → <linearId>. Si viene como argumento ($ARGUMENTS), úsalo directo.

3. Usa la tool MCP `get_issue` con <linearId> para obtener el título → <linearTitle>. Si no hay identificador, usa el nombre de la rama como título.

4. Busca PRs relacionados en TODOS los repos listados en `githubRepos` (config), en paralelo:
   - Por cada repo: `gh pr list --repo <repo> --search "<linearId>" --state all --json number,title,url --limit 5`
   - Si algún repo no da resultados, intenta también por nombre de rama: `gh pr list --repo <repo> --head "<ramaActual>" --state all --json number,title,url --limit 5`

5. Junta las URLs de PRs encontradas, agrupadas por repo.

6. Arma el mensaje con este formato exacto:
   ```
   <linearTitle>:
   PRs:
   <url de cada PR encontrado, una por línea>
   ```

   Ejemplo:
   ```
   Eliminar redistribución errónea de saldo en aprobación:
   PRs:
   https://github.com/org/repo-api/pull/260
   https://github.com/org/repo-web/pull/405
   ```

7. Muestra el mensaje en un bloque de código para que lo copie y se lo pase manualmente a `notifyRecipient` (de la config).
