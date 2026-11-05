---
name: setup
description: Configura de una sola vez todos los datos que necesita la suite (Linear, repos relacionados, idioma) en vez de que cada skill te los pida de a uno la primera vez que lo usás. Si ya está todo configurado, te deja modificar solo lo que quieras cambiar. Úsalo justo después de instalar la suite, o cuando quieras reconfigurar algo.
disable-model-invocation: true
argument-hint: "[clave-opcional-a-cambiar, ej. baseBranch o relatedRepos]"
---

Ejecuta este flujo con cuidado. Este skill NUNCA crea ni modifica nada en Linear o GitHub — solo lee y escribe tu archivo de config local.

1. Intenta leer `~/.claude/gh-linear-flow.config.json` con la tool Read. Si no existe, trátalo como `{}` (objeto vacío).

2. Determina el repo de GitHub actual: `gh repo view --json nameWithOwner -q .nameWithOwner` → <repoActual>. Si el comando falla (no es un repo de GitHub o `gh` no está autenticado), continúa sin <repoActual> y salta todo lo relacionado a `relatedRepos` en los pasos siguientes.

3. Revisa qué falta en la config, agrupado:
   a. `linearEmail`
   b. `linearTeamName` (y por lo tanto `linearTeamId`/`linearTeamUrl`)
   c. `baseBranch`
   d. `contentLanguage`
   e. Si hay <repoActual>: si `relatedRepos[<repoActual>]` no existe todavía en el archivo.

4. Si vino un argumento ($ARGUMENTS, ej. "baseBranch", "idioma", "repos relacionados", "equipo", "email"), interpretalo como la(s) clave(s) que quiero cambiar puntualmente: tratalas como "faltantes" para los pasos siguientes (aunque ya tengan valor en el archivo) y saltá directo al paso 6 preguntando solo por esas, sin tocar el resto.

5. Si NO vino argumento:
   a. Si nada falta (ver paso 3), avisa que la config ya está completa, muestra un resumen legible (email, equipo, rama base, idioma, repos relacionados del repo actual — sin exponer uuids crudos) y preguntame si quiero modificar algo puntual (dando el nombre del dato, ej. "cambiá la rama base a main") o si está todo bien así. Si respondo que no quiero cambiar nada, termina ahí sin escribir el archivo.
   b. Si respondo que sí quiero cambiar algo, tratá esa(s) clave(s) igual que en el paso 4 (como "faltantes") y seguí al paso 6 preguntando solo por esas.
   c. Si falta algo (primera configuración), pregúntamelo TODO de una sola vez, en una sola tanda agrupada (no esperes confirmaciones intermedias entre preguntas), solo por lo que falte:
      - Correo de Linear (si falta `linearEmail`).
      - Nombre del equipo de Linear (si falta `linearTeamName`).
      - Rama base — aclará que el default es "develop" si no respondo (si falta `baseBranch`).
      - Idioma del contenido generado (issues, PRs, resúmenes) — aclará que el default es inglés si no respondo (si falta `contentLanguage`).
      - Repos de GitHub relacionados con <repoActual> (ej. el repo del backend si este es el del frontend de un mismo feature) — aclará que puede responder "ninguno" (solo si hay <repoActual> y `relatedRepos[<repoActual>]` no existe).

En todos los casos, pregunta SOLO por las claves identificadas como faltantes o a cambiar en este paso — nunca reconfirmes claves que ya estaban bien y no fueron pedidas.

6. Con las respuestas, resuelve los IDs reales ANTES de guardar nada — nunca inventes un id:
   - `linearUserId`: usa `list_users` con el `linearEmail` dado. Si no hay coincidencia exacta, muéstrame las opciones encontradas y pregunta cuál es.
   - `linearTeamId` / `linearTeamUrl`: usa `list_teams` para encontrar el equipo por nombre/key, y `get_team` para su url real. Si no hay coincidencia exacta, muéstrame las opciones y pregunta.
   - `relatedRepos`: normaliza cada repo dado al formato `org/repo`. Guarda `relatedRepos[<repoActual>]` con esos repos (o `[]` si respondí "ninguno"). Por cada repo listado, agrega también `<repoActual>` a su propia lista `relatedRepos[<ese repo>]` (creando la entrada si no existía) — la relación siempre se guarda en ambos sentidos.

7. Actualiza `~/.claude/gh-linear-flow.config.json` con Write, combinando las claves nuevas/cambiadas con las que ya existían — nunca borres claves ni entradas de `relatedRepos` de otros repos que no pediste cambiar. Si estabas reconfigurando una clave puntual (pasos 4 o 5b), solo esa clave cambia de valor; el resto queda intacto. Crea `~/.claude/` si no existe.

8. Muestra un resumen final de la config guardada (email, equipo, rama base, idioma, repos relacionados del repo actual — sin uuids crudos) y cierra con: "Listo. Ya podés usar /linear-task, /pr-notify, /ship, etc. sin que te vuelvan a preguntar esto."
