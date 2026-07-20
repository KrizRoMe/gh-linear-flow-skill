---
name: prdesc
description: Genera solo la descripción del PR (sin crear el PR) a partir del contexto de Linear + git diff/commits, y la guarda en .github/generated-pr.md. Úsalo para previsualizar la descripción antes de abrir el PR.
disable-model-invocation: true
---

Ejecuta este flujo con cuidado.

1. Obtén la rama actual: `git branch --show-current`

2. Extrae el identificador de Linear del nombre de la rama.
   Los nombres siguen el patrón: usuario/EQUIPO-NUMERO-descripcion o EQUIPO-NUMERO-descripcion.
   Usa una regex para extraer el identificador en formato LETRAS-DIGITOS (ej. RC-456, ENG-123), en mayúsculas.

3. Si se encontró un identificador, usa la tool MCP `get_issue` con ese identificador para obtener: title, description, priority, state.name, labels (nombres). Guarda como contexto de Linear. Si no se encontró, omite este paso.

4. Ejecuta en paralelo:
   - `git status`
   - `git diff --staged`
   - `git diff`
   - `git log --oneline develop..HEAD 2>/dev/null || git log --oneline main..HEAD 2>/dev/null || git log --oneline -10`

5. Busca el template de PR: `find .github -type f | grep -i 'pull_request_template.md' | head -n 1`

6. Lee el template detectado: `cat $(find .github -type f | grep -i 'pull_request_template.md' | head -n 1)`

7. Genera una descripción de PR profesional siguiendo EXACTAMENTE la estructura del template detectado, cruzando el contexto de Linear con los cambios reales.

Reglas:
- Escribe TODO el contenido en inglés
- Respeta exactamente la estructura del template
- Llena todas las secciones con el contexto de Linear + los cambios reales
- No inventes features o tests que no existen
- Si una sección no aplica, escribe N/A
- Lenguaje profesional y conciso de ingeniería
- Sin bloques de código markdown envolviendo el output
- Formato amigable para reviewers
- Si hay contexto de Linear, incluye el issue como link markdown: [IDENTIFIER — Title](url)

8. Reemplaza completamente el archivo `.github/generated-pr.md` con la descripción generada.

9. Imprime la descripción final generada.
