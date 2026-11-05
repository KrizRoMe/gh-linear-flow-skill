# gh-linear-flow

Suite de skills para el flujo GitHub (`gh`) + Linear: crear tareas, ramas, commits, PRs y notificaciones, sin repetir instrucciones ni datos personales en cada máquina.

## Prerrequisitos

- [GitHub CLI](https://cli.github.com) instalado y autenticado: `gh auth status` debe pasar.
- Servidor MCP de Linear conectado en Claude Code (las herramientas `list_users`, `list_teams`, `get_issue`, etc. deben estar disponibles en la sesión).

## Instalación

### Opción A: con `skills` CLI (recomendada)

Instala las 11 skills de la suite con un solo comando, sin clonar el repo:

```bash
npx skills add KrizRoMe/gh-linear-flow-skill --skill '*'
```

### Opción B: clonando el repo

```bash
git clone git@github.com:KrizRoMe/gh-linear-flow-skill.git
cd gh-linear-flow-skill
./install.sh
```

Esto crea un symlink por cada skill en `~/.claude/skills/`. Abre una sesión nueva de `claude` para que los detecte.

## Configuración

Ningún dato personal está hardcodeado. Ningún skill necesita que configures nada a mano en archivos: todo se pregunta por chat y se guarda en `~/.claude/gh-linear-flow.config.json`.

Tenés dos formas de configurar:

- **`/setup`** (recomendado): corré este skill una sola vez después de instalar la suite. Te pregunta de una sola tanda todo lo que te falte — correo de Linear, equipo, rama base, idioma de contenido, repos relacionados del repo actual — y lo deja guardado para siempre. Si ya tenías todo configurado (por ejemplo, venís del flujo lazy), `/setup` detecta que no falta nada y te pregunta si querés modificar algo puntual en vez de volver a pedirte todo; también podés ir directo con `/setup <clave>` (ej. `/setup baseBranch`) para cambiar solo esa clave sin tocar el resto.
- **Lazy (default sin `/setup`)**: la primera vez que uses cualquier otro skill y le falte un dato, te lo pregunta en el momento y lo guarda para las próximas veces.

Los repos relacionados (`relatedRepos`, usados por `/pr-notify` y `/ship` para buscar PRs en otros repos del mismo feature) se guardan por repo y de forma bidireccional: si configurás que `repo-web` está relacionado con `repo-api`, `repo-api` queda automáticamente relacionado con `repo-web` también, aunque nunca hayas corrido `/setup` o `/pr-notify` parado en ese repo.

Ver [resources/config.md](resources/config.md) para el esquema completo y cómo reconfigurar valores puntuales sin repetir todo el bootstrap.

## Modelo

Estos skills no fijan un modelo — usan el que ya esté activo en tu agente. Eso se configura por fuera del skill, en la herramienta que uses:

- **Claude Code**: `/model` en la sesión, o `model:` en el frontmatter de un skill puntual si lo quieres fijar para ese comando.
- **OpenCode**: `"model": "provider_id/model_id"` en `opencode.json`, o `/models` interactivo.
- **Codex CLI / otros**: su propia config, no leen el frontmatter de `SKILL.md`.

Si no especificas nada en ningún lado, cada agente cae a su propio default: el modelo de sesión activo (o el último usado), no un modelo fijo de esta suite.

## Skills incluidos

| Skill | Qué hace | Argumentos |
|---|---|---|
| `/setup` | Configura (o reconfigura) de una sola vez todos los datos de la suite: Linear, repos relacionados, idioma | `[clave-opcional]` — si la das (ej. `/setup baseBranch`) cambia solo esa clave; si la omites, pregunta lo que falte, o te deja elegir qué cambiar si ya está todo configurado |
| `/linear-task` | Crea un issue nuevo en Linear + la rama de git correspondiente | `[titulo-opcional]` — si lo das (ej. `/linear-task Arreglar bug de login`) se usa tal cual; si lo omites se infiere del diff de git (staged → unstaged → untracked) en formato Sentence case y te pide confirmación; si el working tree está limpio te pregunta el título |
| `/linear-branch` | Crea la rama de git para un issue de Linear que ya existe | `[identificador]` — si no lo das (ej. `/linear-branch RC-456`), te lo pregunta |
| `/linear-worktree-task` | Crea un issue nuevo en Linear + un worktree de git en `.trees/<branch>` desde la rama base (no toca la rama actual del worktree principal) | `[titulo-opcional]` — mismas reglas que `/linear-task` para inferir el título del diff o pedírtelo |
| `/linear-worktree-branch` | Crea un worktree de git en `.trees/<branch>` desde la rama base para un issue de Linear que ya existe (no toca la rama actual del worktree principal) | `[identificador]` — mismo comportamiento que `/linear-branch` |
| `/autocommit` | Genera y ejecuta un commit (conventional commits) a partir del diff en staged | Ninguno |
| `/pr` | Genera la descripción del PR y lo crea en GitHub con `gh` | Ninguno |
| `/prdesc` | Genera solo la descripción del PR, sin crearlo (preview) | Ninguno |
| `/pr-notify` | Busca los PRs relacionados al issue de la rama actual y arma un mensaje para notificar | `[identificador-opcional]` — si no lo das, lo detecta del nombre de la rama actual |
| `/my-issues` | Lista tus issues pendientes en Linear | Ninguno |
| `/ship` | Encadena `/autocommit` + `/pr` + `/pr-notify` de forma autónoma (commit → push → crear PR → armar notify) | Flags opcionales (todas combinables): `--message "<msg>"` fuerza el mensaje del commit; `--title "<title>"` fuerza el título del PR; `--body-file <path>` usa tu descripción en vez de autogenerar; `--dry-run` solo muestra qué haría sin ejecutar nada; `--no-notify` salta el bloque de notificación al final |

Todos tienen `disable-model-invocation: true`: Claude nunca los dispara solo, siempre los invocas tú explícitamente con `/nombre`.

### Sobre `/ship`

`/ship` no es un reemplazo de las skills separadas — es un atajo para el final del flujo, cuando ya implementaste y querés commitear + abrir PR + notificar de un saque. NO hace merge, NO transiciona estados de Linear, NO archiva nada. Si querés revisar la descripción del PR antes de crearlo, usá `/prdesc` + `/pr` por separado.

Riesgos aceptados al usarlo: el modelo puede alucinar el título del commit / título del PR / descripción. Si pasa, corregilo con `gh pr edit --title ...` o `gh pr edit --body ...` después. Las flags `--message`, `--title` y `--body-file` son tu escape hatch para forzar valores literales.

### Sobre `/linear-worktree-task` y `/linear-worktree-branch`

`/linear-worktree-task` y `/linear-worktree-branch` son variantes paralelas de `/linear-task` y `/linear-branch` que usan **git worktrees** en lugar de cambiar la rama del worktree principal.

**Cuándo usarlos:**
- Cuando querés arrancar una feature o fix sin perder lo que tenés a medio hacer en el worktree principal.
- Cuando querés mantener varios issues en paralelo en tu máquina (uno por worktree, todos editables al mismo tiempo).
- Cuando ya tenés cambios sin commitear en el principal y NO querés stashearlos ni commitearlos antes de arrancar la siguiente tarea.

**Convención de rutas:** cada worktree se crea en `.trees/<branch>` (carpeta relativa a la raíz del repo). El directorio `.trees/` está en `.gitignore` para que los worktrees no contaminen el tracking del repo principal.

**Flujo típico:**

1. Desde el worktree principal (en cualquier rama): corré `/linear-worktree-task` (o `/linear-worktree-branch RC-456`).
2. El skill crea el issue en Linear (si aplica), valida que la rama base sea `develop` (si no lo es, te pide confirmación), trae el último `fetch` de esa base y crea el worktree en `.trees/<branch>`.
3. Como bonus, el skill hace `cd .trees/<branch>` dentro de la misma sesión — las próximas llamadas a Bash (git status, /autocommit, /prdesc, /pr, /ship, /pr-notify) corren directamente sobre el worktree nuevo sin que tengas que cambiar de carpeta.
4. Cuando termines: corré `/autocommit`, `/prdesc`/`/pr` y `/pr-notify`. Si seguís en la misma sesión ya estás en el worktree; si abriste sesión nueva, primero `cd .trees/<branch>`.

**Sobre la rama base:**

Por default la suite usa `develop` como base (configurable vía `baseBranch` en `~/.claude/gh-linear-flow.config.json`). Si por algún motivo la base resuelta **no es `develop`** (config con otro valor, o vos pediste explícitamente otra base en la invocación), el skill te avisa y te pide confirmación antes de crear el worktree.

**Limitaciones:**
- Los worktrees comparten el `.git/` del repo, así que no podés tener dos worktrees en la misma rama (git lo rechaza con "already exists").
- El flujo asume que la rama base (`baseBranch` de la config) existe localmente o podés fetchearla. Si tu remote default no es `origin`, ajustá los comandos manualmente.
