#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.claude/skills"

mkdir -p "$TARGET_DIR"

for skill_dir in "$REPO_DIR"/skills/*/; do
  name="$(basename "$skill_dir")"
  link="$TARGET_DIR/$name"

  if [ -L "$link" ] || [ -e "$link" ]; then
    echo "omitido (ya existe): $link"
    continue
  fi

  ln -s "$skill_dir" "$link"
  echo "enlazado: $link -> $skill_dir"
done

echo ""
echo "Listo. Abre una sesión nueva de 'claude' (o espera a que detecte los cambios en vivo) para que aparezcan los skills."
echo "Prerrequisitos: gh CLI autenticado (gh auth status) y el servidor MCP de Linear conectado."
