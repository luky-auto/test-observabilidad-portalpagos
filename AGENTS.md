# Reglas de trabajo

## Alcance y seguridad

- `input-private/` es entrada de solo lectura. No modificar, mover, borrar ni versionar sus archivos. No usar `git add -f` para eludir exclusiones.
- La credencial del BAT es un secreto aunque sea ficticia. No reproducirla en código, documentos, salidas, prompts, pruebas, capturas ni historial. Inspeccionar contenido sensible en memoria y emitir únicamente resultados redactados o booleanos.
- No ejecutar el BAT original. No copiar originales al proyecto. Crear posteriormente fixtures mínimos sintéticos sin secretos, identificados como tales.
- `.gitignore` no elimina datos ya rastreados ni garantiza ausencia de secretos. Revisar archivos, índice e historial antes de cada commit. Si aparece una filtración, detener la publicación y comunicarla sin mostrar el valor; no reescribir historial sin autorización.
- No ejecutar comandos contra Azure durante la etapa inicial. Todo cambio posterior en Azure requiere autorización explícita del usuario para su alcance, incluida la eliminación de recursos.
- No hacer commit ni push sin autorización explícita. No enviar mensajes a terceros.

## Flujo por hitos

1. Trabajar un solo hito por vez siguiendo `PLAN.md`; no iniciar otro hasta cerrar o registrar el bloqueo del actual. La primera etapa solo crea los cinco Markdown solicitados, `.gitignore` y carpetas vacías.
2. Distinguir **hecho** (fuente verificable), **hipótesis** (explicación por contrastar) y **supuesto** (decisión provisional con impacto y validación pendiente).
3. Ejecutar las pruebas relacionadas con cada cambio. Registrar comandos o método, resultado real y límites. Una prueba planificada o simulada no es evidencia de producción.
4. Actualizar `PLAN.md` y `DECISION_LOG.md`. Registrar en `IA_BITACORA.md` prompts importantes realmente usados, respuesta resumida, validación y correcciones reales; nunca completar cuotas inventando errores.
5. Al alcanzar el máximo del hito, registrar pendientes, impacto y prioridad; no ampliar las 20 horas sin acuerdo. No inventar tiempos consumidos: registrar solo tiempos medidos.
6. Antes de cualquier commit, detenerse y presentar archivos modificados, decisiones, pruebas y resultados, supuestos, riesgos pendientes, diff resumido y mensaje sugerido. Esperar autorización; el permiso para commit no implica permiso para push.

## Puertas de Azure

- Reto 3: solo diseño preliminar hasta completar y revisar retos 1 y 2.
- Antes del primer despliegue: autorización explícita, alcance y costo revisados, y confirmación de que el usuario configuró manualmente la alerta de presupuesto. No asumir que una alerta limita el gasto.
- Crear alertas operativas de Azure Monitor cuando existan VM, Log Analytics y fuentes de datos con ingestión validada.
- Fallos inducidos y auto-remediación solo en el laboratorio autorizado, con salvaguardas y trazabilidad. El triage con IA únicamente sugiere acciones para decisión humana.
- Conservar evidencia revisada antes de la eliminación autorizada de recursos; verificar el resultado real y registrar recursos pendientes.

## Evidencia y entrega

- Mantener datos derivados y capturas sin revisar en `work-private/` o `evidencias/private/`, excluidos de Git. Solo material redactado y revisado puede ir a `evidencias/publicables/`.
- Citar ruta relativa, línea original o consulta reproducible. Preservar trazabilidad al normalizar, deduplicar o filtrar; no alterar fuentes.
- No afirmar causa raíz, disponibilidad, pronósticos, despliegues o tiempos de recuperación sin evidencia. Verificar documentación oficial vigente antes de implementar integraciones.
- Post-mortem: máximo 3 páginas; propuesta de 90 días: máximo 2; video opcional: máximo 5 minutos. No publicar originales con la entrega.
