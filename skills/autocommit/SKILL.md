---
name: autocommit
description: Analiza los cambios en staged/working tree y genera un commit con conventional commits. Úsalo para crear un commit automático a partir de tus cambios locales.
disable-model-invocation: true
---

Ejecuta este flujo con cuidado:

1. Agrega todos los archivos excepto markdown:
   Ejecuta: `git add . ':(exclude)*.md'`

2. Vuelve a agregar README.md si fue modificado:
   Ejecuta: `git add README.md 2>/dev/null || true`

3. Muestra el status: `git status`

4. Muestra el diff en staged: `git diff --staged`

5. Analiza SOLO los cambios en staged.

6. Genera un mensaje de commit conciso.

Reglas:
- Formato conventional commits
- Tipos permitidos: feat, fix, refactor, chore, docs, perf, test, build, ci
- Máximo 100 caracteres en total
- Una sola línea
- Solo minúsculas
- Sin markdown
- Sin comillas
- Sin emojis
- Sin punto final
- Formato estricto: `<tipo>: <descripción corta>`

Ejemplos:
- feat: add multi-session whatsapp manager
- fix: resolve scheduler race condition
- refactor: simplify storage session isolation

7. Ejecuta el commit automáticamente: `git commit -m "<mensaje_generado>"`

8. Imprime el hash final del commit y el mensaje.
