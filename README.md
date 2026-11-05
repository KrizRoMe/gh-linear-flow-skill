# gh-linear-flow

Skill suite for the GitHub (`gh`) + Linear workflow: creating tasks, branches, commits, PRs, and notifications — without repeating personal data on every machine.

## Prerequisites

- [GitHub CLI](https://cli.github.com) authenticated: `gh auth status` must pass.
- Linear MCP server connected in your agent.

## Installation

```bash
npx skills add KrizRoMe/gh-linear-flow-skill --skill '*'
```

Prefer cloning the repo instead of the `skills` CLI? See [Option B](#option-b-cloning-the-repo) below.

## Configuration

Nothing is hardcoded: everything is asked through chat and saved to `~/.claude/gh-linear-flow.config.json`.

- **`/setup`** (recommended): configures everything in one go the first time. If you already have everything configured, it lets you change a single value (`/setup baseBranch`) without touching the rest.
- **Lazy**: without running `/setup`, any other skill asks for whatever it's missing the first time you use it.

Related repos (`relatedRepos`, used by `/pr-notify` and `/ship`) are saved per repo and in both directions: linking `repo-web` to `repo-api` automatically links `repo-api` back to `repo-web`.

Full schema and how to reconfigure a single key: [resources/config.md](resources/config.md).

## Included skills

| Skill | What it does | Arguments |
|---|---|---|
| `/setup` | Sets up or reconfigures the suite's data | `[optional-key]` |
| `/linear-task` | Creates a Linear issue + its git branch | `[optional-title]` — inferred from the diff if omitted |
| `/linear-branch` | Creates the git branch for an existing issue | `[identifier]` |
| `/linear-worktree-task` | Same as `/linear-task`, but in a worktree (`.trees/<branch>`) | `[optional-title]` |
| `/linear-worktree-branch` | Same as `/linear-branch`, but in a worktree | `[identifier]` |
| `/autocommit` | Generates and runs a conventional commit from staged changes | — |
| `/pr` | Generates the PR description and creates it with `gh` | — |
| `/prdesc` | Generates only the PR description (preview, no PR created) | — |
| `/pr-notify` | Finds the PRs for the current issue and builds the notification message | `[optional-identifier]` |
| `/my-issues` | Lists your pending Linear issues | — |
| `/ship` | Chains autocommit → pr → pr-notify in one go | `--message`, `--title`, `--body-file`, `--dry-run`, `--no-notify` |

All of them have `disable-model-invocation: true` — they never trigger on their own, you always call them with `/name`.

### `/ship`

A shortcut for the end of the workflow (commit + PR + notify), not a replacement for the separate skills. It does NOT merge or touch Linear states. The model can hallucinate the title/description — use `--message`/`--title`/`--body-file` to force literal values, or fix it afterward with `gh pr edit`.

### Worktrees (`/linear-worktree-task`, `/linear-worktree-branch`)

These use **git worktrees** in `.trees/<branch>` (gitignored) instead of switching the main worktree's branch — handy for working on several issues in parallel without stashing anything. The skill leaves you `cd`'d into it within the same session; if you open a new session, repeat the `cd` manually. Default base branch: `develop` (configurable via `baseBranch`); if it resolves to something else, it asks for confirmation before creating the worktree.

Limitation: you can't have two worktrees on the same branch (git rejects it).

## Model

These skills don't pin a model — they use whatever is already active in your agent (`/model` in Claude Code, `opencode.json`/`/models` in OpenCode, etc.).

---

### Option B: cloning the repo

```bash
git clone git@github.com:KrizRoMe/gh-linear-flow-skill.git
cd gh-linear-flow-skill
./install.sh
```

Creates a symlink for each skill in `~/.claude/skills/`. Open a new `claude` session so it picks them up.
