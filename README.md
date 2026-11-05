# gh-linear-flow

Suite de skills para el flujo GitHub (`gh`) + Linear: crear tareas, ramas, commits, PRs y notificaciones — sin repetir datos personales en cada máquina.

## Prerrequisitos

- [GitHub CLI](https://cli.github.com) autenticado: `gh auth status` debe pasar.
- Servidor MCP de Linear conectado en tu agente.

## Instalación

```bash
npx skills add KrizRoMe/gh-linear-flow-skill --skill '*'
```

¿Preferís clonar el repo en vez de usar `skills` CLI? Ver [Opción B](#opción-b-clonando-el-repo) más abajo.

## Configuración

Nada hardcodeado: todo se pregunta por chat y se guarda en `~/.claude/gh-linear-flow.config.json`.

- **`/setup`** (recomendado): configura todo de una sola tanda la primera vez. Si ya tenés todo configurado, te deja cambiar un dato puntual (`/setup baseBranch`) sin tocar el resto.
- **Lazy**: sin correr `/setup`, cualquier otro skill te pregunta lo que le falte la primera vez que lo usás.

Los repos relacionados (`relatedRepos`, para `/pr-notify` y `/ship`) se guardan por repo y en ambos sentidos: relacionar `repo-web` con `repo-api` deja a `repo-api` relacionado con `repo-web` automáticamente.

Esquema completo y cómo reconfigurar una clave sola: [resources/config.md](resources/config.md).

## Skills incluidos

| Skill | Qué hace | Argumentos |
|---|---|---|
| `/setup` | Configura o reconfigura los datos de la suite | `[clave-opcional]` |
| `/linear-task` | Crea un issue en Linear + su rama de git | `[titulo-opcional]` — se infiere del diff si lo omitís |
| `/linear-branch` | Crea la rama de git para un issue que ya existe | `[identificador]` |
| `/linear-worktree-task` | Igual que `/linear-task`, pero en un worktree (`.trees/<branch>`) | `[titulo-opcional]` |
| `/linear-worktree-branch` | Igual que `/linear-branch`, pero en un worktree | `[identificador]` |
| `/autocommit` | Genera y ejecuta un commit conventional a partir del staged | — |
| `/pr` | Genera la descripción del PR y lo crea con `gh` | — |
| `/prdesc` | Genera solo la descripción del PR (preview, sin crearlo) | — |
| `/pr-notify` | Busca los PRs del issue actual y arma el mensaje para notificar | `[identificador-opcional]` |
| `/my-issues` | Lista tus issues pendientes en Linear | — |
| `/ship` | Encadena autocommit → pr → pr-notify de un saque | `--message`, `--title`, `--body-file`, `--dry-run`, `--no-notify` |

Todos tienen `disable-model-invocation: true` — nunca se disparan solos, siempre los invocás con `/nombre`.

### `/ship`

Atajo para el final del flujo (commit + PR + notify), no un reemplazo de las skills separadas. NO hace merge ni toca estados de Linear. El modelo puede alucinar el título/descripción — usá `--message`/`--title`/`--body-file` para forzar valores literales, o corregí después con `gh pr edit`.

### Worktrees (`/linear-worktree-task`, `/linear-worktree-branch`)

Usan **git worktrees** en `.trees/<branch>` (gitignored) en vez de cambiar la rama del worktree principal — útil para trabajar varios issues en paralelo sin stashear nada. El skill te deja el `cd` hecho dentro de la misma sesión; si abrís sesión nueva, repetilo a mano. Base por default: `develop` (configurable vía `baseBranch`); si resulta otra, te pide confirmación antes de crear el worktree.

Limitación: no podés tener dos worktrees en la misma rama (git lo rechaza).

## Modelo

Estos skills no fijan modelo — usan el que ya esté activo en tu agente (`/model` en Claude Code, `opencode.json`/`/models` en OpenCode, etc.).

---

### Opción B: clonando el repo

```bash
git clone git@github.com:KrizRoMe/gh-linear-flow-skill.git
cd gh-linear-flow-skill
./install.sh
```

Crea un symlink por cada skill en `~/.claude/skills/`. Abrí una sesión nueva de `claude` para que los detecte.
