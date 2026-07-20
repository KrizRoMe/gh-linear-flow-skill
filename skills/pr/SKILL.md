---
name: pr
description: Genera la descripción del PR a partir del contexto de Linear + el diff/commits, y crea el pull request en GitHub con gh. Úsalo cuando ya terminaste de implementar los cambios y quieres abrir el PR.
disable-model-invocation: true
---

Ejecuta este flujo con cuidado.

0. Config: lee y sigue el procedimiento en `${CLAUDE_SKILL_DIR}/../../resources/config.md`. Claves requeridas para este skill: `baseBranch`, `contentLanguage`.

1. Obtén la rama actual: `git branch --show-current` → <ramaActual>.

2. Extrae el identificador de Linear del nombre de la rama.
   Los nombres siguen el patrón: usuario/EQUIPO-NUMERO-descripcion o EQUIPO-NUMERO-descripcion.
   Usa una regex para extraer el identificador en formato LETRAS-DIGITOS (ej. RC-456, ENG-123).
   Es case-insensitive en la rama, pero debe ir en mayúsculas (ej. rc-456 → RC-456). Guarda como <linearId> y <linearTitle>.

3. Si se encontró un identificador, usa la tool MCP `get_issue` con ese identificador para obtener: title, description, priority, state.name, url, labels (nombres). Guarda como contexto de Linear. Si no se encontró, omite este paso.

4. Ejecuta en paralelo:
   - `git status`
   - `git diff --staged`
   - `git diff`
   - `git log --oneline <baseBranch>..HEAD 2>/dev/null || git log --oneline main..HEAD 2>/dev/null || git log --oneline -10`

5. Busca el template de PR: `find .github -type f | grep -i 'pull_request_template.md' | head -n 1`

6. Lee el template detectado: `cat $(find .github -type f | grep -i 'pull_request_template.md' | head -n 1)`

7. Genera una descripción de PR profesional siguiendo EXACTAMENTE la estructura del template detectado.
   Usa el contexto de Linear (título, descripción, criterios de aceptación) como fuente principal de intención.
   Usa el diff y los commits como fuente de lo que realmente se implementó.
   Cruza ambos para producir una descripción precisa y completa.

Reglas:
- Escribe TODO el contenido en `contentLanguage` (de la config; default inglés) — títulos, descripciones, todo
- Respeta exactamente la estructura del template
- Llena todas las secciones con el contexto de Linear + los cambios reales
- No inventes features o tests que no existen
- Si una sección no aplica, escribe N/A
- Lenguaje profesional y conciso de ingeniería
- Sin bloques de código markdown envolviendo el output
- Formato amigable para reviewers
- Incluye el issue como link markdown: [IDENTIFIER — Title](url)

8. Reemplaza completamente el archivo `.github/generated-pr.md` con la descripción generada.

9. Construye el título del PR como: <linearId> — <linearTitle> (ej. RC-404 — Corregir métrica de casos sin gestión). Si no hay contexto de Linear, usa el nombre de la rama como título.

10. Antes de hacer push, verifica que <ramaActual> NO sea `main` ni `baseBranch`. Si lo es, detente inmediatamente y dime: "No se puede crear un PR directamente desde main o `<baseBranch>`."
    De lo contrario, haz push: `git push -u origin <ramaActual>`

11. Crea el PR en GitHub usando la descripción generada:
    Ejecuta: `gh pr create --title "<título del PR>" --body "$(cat .github/generated-pr.md)" --base <baseBranch>`

12. Imprime la URL del PR devuelta por gh.
