# gh-linear-flow

Suite de skills de Claude Code para el flujo GitHub (`gh`) + Linear: crear tareas, ramas, commits, PRs y notificaciones, sin repetir instrucciones ni datos personales en cada máquina.

## Prerrequisitos

- [GitHub CLI](https://cli.github.com) instalado y autenticado: `gh auth status` debe pasar.
- Servidor MCP de Linear conectado en Claude Code (las herramientas `list_users`, `list_teams`, `get_issue`, etc. deben estar disponibles en la sesión).

## Instalación

```bash
git clone git@github.com:KrizRoMe/gh-linear-flow.git
cd gh-linear-flow
./install.sh
```

Esto crea un symlink por cada skill en `~/.claude/skills/`. Abre una sesión nueva de `claude` para que los detecte.

## Configuración

Ningún dato personal está hardcodeado. La primera vez que uses cualquiera de estos skills y le falte un dato (tu correo de Linear, el equipo, los repos de GitHub, la rama base), te preguntará una sola vez y lo guardará en `~/.claude/gh-linear-flow.config.json` para las próximas veces. Ver [resources/config.md](resources/config.md) para el esquema completo y cómo reconfigurar valores puntuales sin repetir todo el bootstrap.

## Skills incluidos

| Skill | Qué hace |
|---|---|
| `/linear-task` | Crea un issue nuevo en Linear + la rama de git correspondiente |
| `/linear-branch` | Crea la rama de git para un issue de Linear que ya existe |
| `/autocommit` | Genera y ejecuta un commit (conventional commits) a partir del diff en staged |
| `/pr` | Genera la descripción del PR y lo crea en GitHub con `gh` |
| `/prdesc` | Genera solo la descripción del PR, sin crearlo (preview) |
| `/pr-notify` | Busca los PRs relacionados al issue de la rama actual y arma un mensaje para notificar |
| `/my-issues` | Lista tus issues pendientes en Linear |

Todos tienen `disable-model-invocation: true`: Claude nunca los dispara solo, siempre los invocas tú explícitamente con `/nombre`.

## Publicar en skills.sh (opcional)

Cada skill se puede publicar por separado:

```bash
npm install -g @localskills/cli
localskills login
localskills publish --name tu-usuario/linear-task
```
