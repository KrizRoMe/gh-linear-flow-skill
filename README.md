# gh-linear-flow

Suite de skills para el flujo GitHub (`gh`) + Linear: crear tareas, ramas, commits, PRs y notificaciones, sin repetir instrucciones ni datos personales en cada máquina.

## Prerrequisitos

- [GitHub CLI](https://cli.github.com) instalado y autenticado: `gh auth status` debe pasar.
- Servidor MCP de Linear conectado en Claude Code (las herramientas `list_users`, `list_teams`, `get_issue`, etc. deben estar disponibles en la sesión).

## Instalación

### Opción A: con `skills` CLI (recomendada)

Instala las 8 skills de la suite con un solo comando, sin clonar el repo:

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

Ningún dato personal está hardcodeado. La primera vez que uses cualquiera de estos skills y le falte un dato (tu correo de Linear, el equipo, los repos de GitHub, la rama base), te preguntará una sola vez y lo guardará en `~/.claude/gh-linear-flow.config.json` para las próximas veces. Ver [resources/config.md](resources/config.md) para el esquema completo y cómo reconfigurar valores puntuales sin repetir todo el bootstrap.

## Modelo

Estos skills no fijan un modelo — usan el que ya esté activo en tu agente. Eso se configura por fuera del skill, en la herramienta que uses:

- **Claude Code**: `/model` en la sesión, o `model:` en el frontmatter de un skill puntual si lo quieres fijar para ese comando.
- **OpenCode**: `"model": "provider_id/model_id"` en `opencode.json`, o `/models` interactivo.
- **Codex CLI / otros**: su propia config, no leen el frontmatter de `SKILL.md`.

Si no especificas nada en ningún lado, cada agente cae a su propio default: el modelo de sesión activo (o el último usado), no un modelo fijo de esta suite.

## Skills incluidos

| Skill | Qué hace | Argumentos |
|---|---|---|
| `/linear-task` | Crea un issue nuevo en Linear + la rama de git correspondiente | `[titulo-opcional]` — si lo das (ej. `/linear-task Arreglar bug de login`) se usa tal cual; si lo omites se infiere del diff de git (staged → unstaged → untracked) y te pide confirmación; si el working tree está limpio te pregunta el título |
| `/linear-branch` | Crea la rama de git para un issue de Linear que ya existe | `[identificador]` — si no lo das (ej. `/linear-branch RC-456`), te lo pregunta |
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
