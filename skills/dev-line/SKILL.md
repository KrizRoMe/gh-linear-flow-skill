---
name: dev-line
description: Genera el reporte semanal de LÍNEA DE DESARROLLO (qué cambió, qué sigue, estado, qué necesitamos) a partir de tus PRs y commits de la semana en el repo actual y sus repos relacionados, más tus issues de Linear y los docs del repo. Redacta en lenguaje no técnico, listo para copiar y pegar en un solo mensaje. Úsalo el día antes de la reunión semanal.
disable-model-invocation: true
argument-hint: "[nombre de la línea] [--last-week] [--since YYYY-MM-DD]"
---

Ejecuta este flujo con cuidado. Este skill es de SOLO LECTURA: nunca crea, modifica ni archiva nada en Linear, GitHub o el repo. Solo lee y escribe el archivo de reporte en `~/.claude/gh-linear-flow/dev-line/`.

0. Config: localiza y sigue el procedimiento en `resources/config.md` (raíz del proyecto, dos niveles arriba de este SKILL.md; si tu entorno define `${CLAUDE_SKILL_DIR}`, es `${CLAUDE_SKILL_DIR}/../../resources/config.md`). Claves requeridas: `linearEmail`, `linearUserId`, `linearTeamId`, `linearTeamName`, `linearTeamUrl`, `baseBranch`, `relatedRepos`, `devLine`.

   Para `devLine`, si falta o no tiene entrada para el repo actual Y no pasé el nombre de la línea como argumento (ver paso 1.3), pregunta en una sola tanda:
   - Nombre de la LÍNEA para este repo (ej. "Blaster contact-center").
   - Nombre del proyecto de Linear que corresponde a esa línea, si lo hay — es lo que hace preciso el filtro del paso 2.g. Puede responder "ninguno".
   - Nombre del responsable, si `devLine.owner` no existe todavía.

   Guarda `devLine.owner` y `devLine.lines[<repoActual>] = { "line": <nombre>, "linearProject": <proyecto o null> }`. Si una entrada ya guardada es un string suelto, trátala como `{ "line": <ese string>, "linearProject": null }` — no la reescribas salvo que te pida configurar el proyecto. Igual que con `relatedRepos`, escribe el mismo nombre de línea para cada repo de `relatedRepos[<repoActual>]` que no tenga uno propio — la línea se comparte entre repos relacionados.

## 1. Alcance

1. Repo actual: `gh repo view --json nameWithOwner -q .nameWithOwner` → <repoActual>. Si falla, detente y avisa que hay que correr el skill parado en un repo de GitHub.
2. Repos a escanear = <repoActual> + `relatedRepos[<repoActual>]`. Si un repo relacionado no es accesible con `gh` (otra org, sin permisos), repórtalo al final como "no se pudo leer: <repo>" y continúa con los demás — nunca abortes por eso.
3. Línea de desarrollo:
   - Si $ARGUMENTS trae texto suelto (todo lo que no empiece con `--`), esa es la línea para este reporte, tal cual la escribiste (ej. `/dev-line Blaster contact-center`). No la guardes en la config ni la compares con `devLine.lines` — manda lo que te pasé.
   - Si no pasé texto, la línea sale de `devLine.lines[<repoActual>].line`. Si ese repo no tiene línea pero alguno de sus `relatedRepos` sí, usa esa.
   - Si no hay línea por ninguna de las dos vías, preguntámela (ver paso 0).

4. Ventana de tiempo:
   - Default: desde el lunes de esta semana 00:00 hasta ahora.
   - `--last-week`: lunes a domingo de la semana anterior.
   - `--since YYYY-MM-DD`: desde esa fecha hasta ahora.
   Calcula las fechas con `date` y muéstrame el rango usado en una línea antes del reporte.
5. Tu login de GitHub: `gh api user -q .login` → <login>.

## 2. Qué hiciste (actividad de la semana)

Por cada repo del alcance, junta:

a. **PRs tuyos creados o mergeados en la ventana**:
   `gh search prs --repo <repo> --author @me --created ">=<desde>" --json number,title,url,state,createdAt,closedAt`
   y además `gh search prs --repo <repo> --author @me --merged-at ">=<desde>" --json number,title,url,state,closedAt`.
   Deduplica por número. (`gh search prs --json` no expone `mergedAt`: para saber si un PR se mergeó usa `gh pr view` del paso e.)

b. **Commits de los PRs encontrados** — esta es la fuente principal, no la de abajo. `repos/<repo>/commits` solo recorre la rama por defecto, así que el trabajo que todavía vive en una rama sin mergear NO aparece ahí. Por eso, por cada PR del paso a:
   `gh pr view <n> --repo <repo> --json commits,headRefName --jq '.commits[] | {sha: .oid[0:7], msg: (.messageHeadline), authors: [.authors[].login], date: .committedDate}'`
   Quédate con los commits dentro de la ventana donde figures como autor o co-autor (los de Claude siguen teniendo tu autoría y el `Co-Authored-By` debajo, y GitHub devuelve ambos en `authors`).

c. **Commits en la rama base** (lo que ya se mergeó y commits directos):
   `gh api "repos/<repo>/commits?author=<login>&since=<desdeISO>&until=<hastaISO>" --jq '.[] | {sha: .sha[0:7], msg: (.commit.message | split("\n")[0]), date: .commit.author.date}'`
   Si trabajás con una rama base distinta a la default (ej. `develop`), agrega `&sha=<baseBranch>` a esa URL. Deduplica contra el paso b por sha.

d. **Commits donde figuras como co-autor pero no como autor** (opcional, best-effort):
   `gh search commits --repo <repo> --author-date ">=<desde>" "Co-authored-by: <linearEmail>" --json sha,commit,repository`
   Si este comando falla o no devuelve nada, ignóralo en silencio — es solo un complemento.

e. Para los PRs encontrados, lee `gh pr view <n> --repo <repo> --json title,body,labels,baseRefName,headRefName,state,mergedAt`. La descripción tiene más contexto de negocio que el título, y `headRefName` es lo que te deja vincular el PR con su issue de Linear.

f. **Vincula cada PR con su issue de Linear**: saca el identificador (ej. `RC-123`) del `headRefName`, del título o del cuerpo del PR. Con `get_issue` leé el issue: su **descripción y su proyecto** son la mejor materia prima del reporte — están escritos en términos de necesidad de negocio, no de implementación. Si un PR no matchea con ningún issue, no lo descartes: trabajalo desde el cuerpo del PR y marcalo como "sin issue" en el detalle final.

g. **Filtro por línea**: si la línea vino como argumento (paso 1.3), quédate SOLO con la actividad de ese módulo. Aplica estas señales en orden y usa la primera que resuelva:
   1. **Proyecto de Linear** (señal confiable): si `devLine.lines[<repo>].linearProject` está configurado, pertenece a la línea todo PR cuyo issue vinculado (paso f) esté en ese proyecto. Esto es determinista — un PR titulado "add contact upload endpoint" en `cc-api` no dice "Blaster" por ningún lado, pero su issue sí está en el proyecto.
   2. **Palabras clave** (respaldo, solo si no hay proyecto configurado o el PR no tiene issue): el nombre de la línea o alguna de sus palabras clave, ignorando mayúsculas y acentos, aparece en el nombre de la rama, el título o cuerpo del PR, sus etiquetas, o el mensaje del commit.
   Todo lo demás queda fuera del reporte.
   - Lista aparte, después del reporte, cuántos PRs/commits descartaste por no pertenecer a la línea, para que veas si el filtro se pasó de estricto.
   - Si un ítem es dudoso, no lo descartes en silencio: inclúyelo marcado como dudoso al final para que decidas.
   - Si la línea salió de la config (no la pasaste como argumento), no filtres: toda la actividad de los repos de esa línea cuenta.

Si entre todos los repos no hay NADA en la ventana, detente y avísame: "No encontré PRs ni commits tuyos en <repos> entre <desde> y <hasta>." No inventes actividad.

## 3. Qué sigue (Linear primero, docs como complemento)

1. **Linear**: usa `list_issues` con `assignee: linearUserId`, `team: linearTeamId`, estados NO completados ni cancelados, orden `updatedAt desc`, límite 50.
2. Filtra a los issues relacionados con esta línea (y si la línea vino como argumento, aplica además el filtro por línea del paso 2.g): que su identificador o nombre de rama aparezca en los PRs/commits de la ventana, o que su proyecto/título coincida con el nombre de la línea. Si queda ambiguo, inclúyelo y márcalo.
3. Toma la fecha de cada issue en este orden: `dueDate` → fecha del milestone → fecha del ciclo.
4. **Docs**: busca en el repo actual archivos de planificación — `TODO.md`, `ROADMAP.md`, `odd/tasks/*.md`, `docs/**/*.md` — con `rg` limitado a esos paths. Extrae ítems pendientes y sus fechas.
5. **Match entre ambas fuentes**: cruza issue ↔ ítem de doc por identificador de Linear (ej. `RC-123`), por nombre de rama, o por coincidencia clara de título.
   - Si el issue tiene fecha, esa gana.
   - Si el issue no tiene fecha pero su ítem en docs sí, usa la del doc.
   - Si un ítem de doc no matchea con ningún issue pero está claramente pendiente y dentro de la línea, inclúyelo igual.
   - Si un pendiente no tiene fecha en ninguna fuente, NO inventes una: listámelo aparte al final y preguntame la fecha en una sola tanda antes de imprimir el reporte.

## 4. Qué necesitamos

Sale de, en este orden: issues de Linear bloqueados o con etiqueta de bloqueo, PRs abiertos esperando review desde hace más de 3 días, y líneas de los docs que mencionen bloqueos o dependencias externas. Cada ítem debe decir **de quién** y **para cuándo**. Si no encuentras nada, pregúntame si hay algún bloqueo antes de escribir el bloque — no lo inventes ni lo dejes vacío.

## 5. Estado

Elige UNO del vocabulario cerrado, aplicando la primera regla que se cumpla:

| Condición | Estado |
|---|---|
| Hay un bloqueo abierto que detiene el avance | Bloqueado |
| El trabajo ya está liberado a producción | En producción |
| Mergeado a la rama base pero sin liberar | Listo para liberar |
| PR abierto en review / con etiqueta de QA | En QA |
| Hay trabajo terminado y funcionando, sin liberar ni en review | Construido |

Si la línea tiene dos frentes con estados distintos, imprime una línea por frente (como en el ejemplo del usuario) — pero cada una debe usar una palabra del vocabulario, nunca una inventada como "En desarrollo".

## 6. Fechas que cambiaron

1. Busca el reporte anterior más reciente en `~/.claude/gh-linear-flow/dev-line/`.
2. Compara las fechas del bloque "QUÉ SIGUE" con las de hoy.
3. Si alguna se movió, escribe el motivo en UNA línea, en lenguaje llano. Si no hay reporte anterior o ninguna fecha cambió, omite el bloque 5 por completo.

## 7. Redacción: lenguaje no técnico (lo más importante)

El lector no es técnico. Escribe por **impacto**, no por feature ni por implementación. Máximo 3 bullets en "QUÉ CAMBIÓ".

**Cómo agrupar**: un bullet por **issue de Linear**, no por PR ni por repositorio. Un mismo trabajo suele tener tres PRs (panel, api, cc-api) y los tres son UN solo bullet: el resultado que ve el negocio, no las tres piezas que lo hacen posible. Los PRs sin issue se agrupan por el resultado que comparten. Si quedan más de 3 grupos, junta los más chicos en un bullet o deja fuera lo que no tenga impacto explicable.

**De dónde sale el texto**: redacta cada bullet desde la **descripción del issue de Linear** (paso 2.f), que ya está escrita en términos de necesidad. El título del PR es tu última opción — es técnico por naturaleza y arrastra jerga al reporte.

Reglas duras:

- Prohibido en el texto: endpoint, API, repo, branch, commit, merge, deploy, refactor, backend, frontend, PR, wizard, payload, token, query, bug fix, hotfix.
- Traducciones a usar:

| No escribas | Escribe |
|---|---|
| "Agregué el endpoint X en cc-api" | "Ya se pueden cargar los contactos desde el sistema, sin hacerlo a mano" |
| "Mergeé el PR #42" | "Quedó terminado y disponible" |
| "Refactoricé el módulo de auth" | "El acceso al sistema quedó más estable" |
| "Integré la API de MyCC" | "El sistema ya se conecta con MyCC" |
| "Está en el wizard del panel" | "En la pantalla donde se crea la campaña" |

- Nombra los sistemas por su nombre de negocio (MyCC, el panel, el marcador), no por el nombre del repositorio.
- Una frase por bullet. Sin jerga, sin siglas sin explicar, sin números de PR ni enlaces.
- Si un cambio no tiene impacto explicable para alguien no técnico, no va en el reporte.

## 8. Salida

Imprime EXACTAMENTE este bloque, listo para copiar y pegar en un solo mensaje (sin audio, sin capturas):

```
LÍNEA: <nombre de la línea>
RESPONSABLE: <devLine.owner>

1. QUÉ CAMBIÓ
   - ...
   - ...

2. QUÉ SIGUE
   - ... → <día> <mes abreviado>
   - ... → <día> <mes abreviado>

3. ESTADO
   - <Construido | En QA | Listo para liberar | En producción | Bloqueado>

4. QUÉ NECESITAMOS
   - ...

5. SI CAMBIÓ UNA FECHA
   - ...
```

Reglas de formato: máximo 3 bullets en el bloque 1; toda fecha en formato `13 nov`; el bloque 5 se omite entero si ninguna fecha cambió.

Después del bloque, y separado de él, imprime:
- El rango de fechas usado y los repos escaneados (y los que no se pudieron leer).
- Qué PRs/commits respaldan cada bullet del bloque 1, para que puedas verificar antes de enviarlo.

Guarda el reporte en `~/.claude/gh-linear-flow/dev-line/<linea-en-kebab-case>-<YYYY-MM-DD>.md` (crea el directorio si no existe) — es lo que el paso 6 compara la próxima semana.
