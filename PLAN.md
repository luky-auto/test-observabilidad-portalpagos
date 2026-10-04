# Plan inicial de trabajo

Fecha: 2026-10-03 (America/Bogota). Alcance inicial máximo: **20 horas**, incluidas preparación, pruebas, evidencia, revisión y reserva. El enunciado estima 12–16 horas y fija 5 días desde la recepción; la fecha de recepción no está confirmada, por lo que no se calcula vencimiento.

Estado: **H0 completado y aprobado por el usuario**, con cierre registrado el **2026-10-03 a las 20:37:32 (America/Bogota, UTC-05:00)**. **H1 completado y aprobado por el usuario**, con cierre registrado el **2026-10-03 a las 21:47:09 (America/Bogota, UTC-05:00)** según el reloj consultado en esta revisión (cierre técnico anterior: 20:59:53); H2–H7 pendientes y no iniciados. Ninguno de los cinco retos está resuelto. Los tiempos siguientes son límites planificados, no horas ejecutadas. Un único hito activo. Esperas externas no habilitan trabajo simultáneo ni extensión del presupuesto de esfuerzo.

## Secuencia y prioridades

| Hito | Prioridad | Máximo | Dependencia |
|---|---|---:|---|
| H0 Preparación y protección | P0 | 1 h | Solicitud inicial |
| H1 Contrato de datos del Reto 1 | P0 | 2 h | H0 revisado |
| H2 Diagnóstico del Reto 1 | P0 | 3 h | H1 aceptado |
| H3 Mantenimiento del Reto 2 | P0 | 3 h | H2 aceptado |
| H4 Laboratorio del Reto 3 | P1 | 5 h | H2 y H3 completos y revisados; puertas de Azure |
| H5 Triage del Reto 4 | P1 | 2,5 h | H4 cerrado o bloqueo registrado y secuencia acordada |
| H6 Propuesta del Reto 5 | P1 | 1 h | Resultados y limitaciones anteriores registrados |
| H7 Revisión, entrega y reserva | P0 | 2,5 h | Hitos previos cerrados o pendientes declarados |
| **Total** | | **20 h** | |

### H0 Preparación y protección

- **Objetivo:** comprender requisitos y formatos, proteger entradas y definir el trabajo sin implementar retos.
- **Entregable:** AGENTS, PLAN, DECISION_LOG, IA_BITACORA, README, `.gitignore` y estructura vacía.
- **Evidencia esperada:** inventario y contratos observados en README; verificaciones de exclusión, secreto e integridad en la bitácora.
- **Pruebas:** leer DOCX y LEEME; inspeccionar encabezados y parseo básico; comparar hashes del duplicado; revisar Git y cambios; comprobar hashes de originales antes/después de la escritura.
- **Aceptación:** solo los archivos autorizados cambian, fuentes intactas, entradas ignoradas, secreto ausente de entregables e historial inspeccionado, presupuesto de 20 h y puertas explícitas.
- **Riesgos:** exclusiones ocultan archivos al inventariar; exposición accidental del BAT; ignorar no equivale a desversionar.
- **Tiempo máximo:** 1 h.

### H1 Contrato de datos del Reto 1

**Alcance:** únicamente ingesta, normalización y calidad de datos. Completar H1 no significa completar el Reto 1; los entregables de diagnóstico y comunicación ejecutiva quedan en H2.

- **Objetivo:** producir ingestión reproducible y trazable sin confundir formatos, duplicados ni periodos.
- **Entregable:** parsers y validaciones locales; inventario con hashes; reglas de normalización temporal, calidad y deduplicación; fixtures sintéticos.
- **Evidencia esperada:** conteos de entrada/aceptados/rechazados/duplicados y referencias a líneas originales; cobertura de la semana local.
- **Pruebas:** variantes `#Fields`, filas inválidas, faltantes, decimales, CSV entrecomillado, duplicados de archivo frente a eventos legítimos repetidos, límites de día y zona horaria.
- **Aceptación:** procesar todas las fuentes relevantes sin descartes silenciosos; documentar supuestos temporales y reconciliar conteos; originales intactos.
- **Riesgos:** doble conteo; confundir nombre del archivo con fecha local; atribuir zona horaria sin validarla.
- **Tiempo máximo:** 2 h.

#### Resultado verificado de H1

- Código: `reto1-diagnostico/h1_ingest.py` y `verify_h1.py`; guía de reproducción y `H1_CALIDAD.md` en la misma carpeta.
- Evidencia: `evidencias/publicables/h1-summary.json` (29.899 bytes), con reglas, hashes, referencias, rangos y cuentas. SQLite detallado solo en `work-private/`.
- 195932 registros de entrada = 170050 conservados + 25882 filas de una copia exacta excluida; 0 rechazados. Conservados: 170020 en semana y 30 sin fecha. Ausencias se mantienen como nulos, no ceros.
- 21 pruebas sintéticas aprobadas; dos cargas completas finales con resumen idéntico byte a byte; 33 verificaciones independientes aprobadas. Los 18 originales mantienen sus hashes de inicio. No se cambió el índice ni se hizo commit/push.
- Aceptado en H1, con límites aún vigentes: supuesto Bogotá para eventos/tickets sin offset; conservación de HTTPERR sin petición, valores de memoria ausentes y registros sin fecha; límites del matching entre fuentes. Ver detalles y referencias en `H1_CALIDAD.md`.
- Medición parcial real: reloj de control entre 20:44:53 y 20:59:53 Bogotá, 15 minutos de ejecución observada; no incluye la lectura inicial anterior al primer control ni el cierre documental posterior. No se presenta como duración total del hito. Máximo autorizado sin cambios: 2 h.
- **Detención:** no iniciar H2 hasta aprobación explícita del usuario; esta implementación no autoriza commit/push.

### H2 Diagnóstico del Reto 1

- **Objetivo:** responder con evidencia a cronología, causa y factores, disponibilidad, señales tempranas y otros riesgos pronosticables.
- **Entregables posteriores del Reto 1:** diagnóstico técnico reproducible del incidente; línea de tiempo en `America/Bogota`; disponibilidad semanal con método y denominador; causa raíz y factores contribuyentes; señales tempranas; riesgos y pronóstico con método, números y límites (o imposibilidad justificada); post-mortem ejecutivo sin culpables de máximo 3 páginas.
- **Post-mortem independiente:** fuente `reto1-diagnostico/POSTMORTEM.md`; versión final `reto1-diagnostico/POSTMORTEM.pdf`. Ambos serán distintos de `H1_CALIDAD.md` y los README. No crearlos ni redactarlos hasta H2 autorizado y con conclusiones respaldadas por las ejecuciones.
- **Evidencia esperada:** cada afirmación con archivo/línea o consulta; cronología en Colombia; método y números de disponibilidad y pronóstico, o límites explícitos si no son estimables.
- **Pruebas:** denominadores y ventanas, casos manuales de control, separación del sondeo y tráfico relevante, conciliación IIS/HTTPERR/eventos/Perfmon/tickets; sensibilidad a supuestos y datos ausentes.
- **Aceptación:** cubrir las cinco preguntas del reto sin equiparar tasa de éxito por petición a disponibilidad temporal; separar hechos, hipótesis y supuestos; exportar el post-mortem a PDF, verificar mediante herramienta el total de páginas (máximo 3), revisar visualmente cada página y registrar el resultado. Markdown no demuestra paginación. Revisión del usuario registrada.
- **Riesgos:** correlación presentada como causalidad; ausencia de logs presentada como salud; falsa precisión del pronóstico.
- **Tiempo máximo:** 3 h.

### H3 Mantenimiento del Reto 2

- **Objetivo:** sustituir mantenimiento riesgoso por operaciones justificadas y comprobables.
- **Entregable:** lista de problemas ordenados por riesgo; PowerShell 5.1 o 7 (versión elegida y justificada), pruebas y guía; decisiones sobre pasos eliminados y reemplazos.
- **Evidencia esperada:** ejecuciones de pruebas con resultados reales; demostración de parámetros validados, `-WhatIf`, errores/códigos de salida, logs estructurados, ausencia de secretos e idempotencia.
- **Pruebas:** rutas vacías o fuera de alcance, permisos, fallo parcial, repetición, retención y preservación de evidencia, simulación sin mutaciones; Pester si está disponible o alternativa equivalente documentada.
- **Aceptación:** pruebas locales pasan, efectos limitados a sandbox/fixtures; no ejecutar BAT ni operaciones sobre el servidor real; revisión del usuario registrada antes de H4.
- **Riesgos:** borrado excesivo, pérdida de evidencia, interrupciones y éxito falso; diferencias entre versiones de PowerShell.
- **Tiempo máximo:** 3 h.

### H4 Laboratorio del Reto 3

- **Objetivo:** demostrar detección y auto-remediación en un escenario mínimo autorizado.
- **Entregable:** VM Windows/IIS/sitio/pool, Log Analytics y recolección de IIS/eventos/contadores; KQL de disponibilidad, 5xx, p95 y pool; dos alertas operativas con notificación; remediación con límites de intentos, exclusiones y escalamiento; tablero para dirección y NOC.
- **Evidencia esperada:** ingestión real, consultas ejecutadas, alertas y notificaciones, falla controlada y trazas de remediación; tiempos medidos de detección y recuperación; capturas o video de máximo 5 minutos. IaC y estimación de costo son deseables después de lo mínimo verificable.
- **Pruebas:** recepción de cada fuente, consultas ante datos vacíos, falla y recuperación, límite de reintentos, caso en que no se actúa, escalamiento humano y permisos mínimos.
- **Aceptación:** puertas satisfechas, dos alertas operativas verificadas después de existir las fuentes, remediación automática trazable y segura; distinguir tiempos observados de objetivos. Preservar evidencia antes de limpieza autorizada.
- **Riesgos:** costo, cuotas, demora de ingestión, permisos o proveedor no disponibles; no prometer crédito gratuito suficiente.
- **Tiempo máximo:** 5 h. Si se bloquea, registrar lo ejecutado y lo pendiente; no simular evidencia de Azure.

### H5 Triage del Reto 4

- **Objetivo:** resumir alerta y contexto mediante un modelo, sin ejecutar acciones.
- **Entregable:** componente, esquema JSON, catálogo cerrado de runbooks, validación de referencias y manejo de timeout/error/respuesta inválida; proveedor y manejo de secretos documentados.
- **Evidencia esperada:** mínimo tres casos con entradas sintéticas identificadas y resultados; al menos una respuesta errónea o alucinada detectada. Distinguir respuesta defectuosa inyectada para prueba de un error real del proveedor.
- **Pruebas:** caso válido, hipótesis o cita inventada, salida inválida/timeout; acción fuera de catálogo e instrucciones maliciosas en contexto; ninguna ejecución autónoma.
- **Aceptación:** schema y referencias validados, confianza explícita, fallo seguro y decisión humana; demostrar integración real con modelo o declarar esa parte pendiente. Conexión al Reto 3 es opcional.
- **Riesgos:** exfiltración, inyección de instrucciones, falsa confianza; acceso al proveedor no confirmado.
- **Tiempo máximo:** 2,5 h.

### H6 Propuesta del Reto 5

- **Objetivo:** traducir hallazgos en prioridades de los primeros 90 días.
- **Entregable:** máximo 2 páginas con 3–5 iniciativas, impacto/esfuerzo/riesgo, fases, métricas, apoyos del líder y exclusiones justificadas.
- **Evidencia esperada:** relación de cada iniciativa con hallazgos verificados; definición de indicadores y de las líneas base aún no medidas.
- **Pruebas:** cobertura de requisitos, lectura ejecutiva, revisión de coherencia con resultados y límite de páginas.
- **Aceptación:** métricas medibles sin inventar mejoras ni líneas base; priorización defendible.
- **Riesgos:** propuesta genérica o metas sin sustento.
- **Tiempo máximo:** 1 h.

### H7 Revisión, entrega y reserva

- **Objetivo:** entrega reproducible y segura; usar la reserva para defectos prioritarios, no funciones nuevas.
- **Entregable:** README final, bitácora real, decisiones y pendientes actualizados, evidencias revisadas; paquete previo a commit para autorización. Eliminación de recursos solo dentro del alcance autorizado.
- **Evidencia esperada:** reproducción local, resultados de pruebas, revisión de secretos en archivos/índice/historial, verificación real de limpieza de Azure cuando corresponda.
- **Pruebas:** regresión pertinente, enlaces, comandos documentados, límites de páginas/video, secretos y diferencias de Git.
- **Aceptación:** estado de cada reto honesto, sin originales ni secretos; pendientes priorizados; no commit/push sin permiso. La bitácora aspira a los 5–10 prompts y 3 errores del enunciado únicamente si ocurrieron; declarar brechas sin inventar.
- **Riesgos:** falta de tiempo, recursos facturando, capturas sensibles, evidencia no reproducible.
- **Tiempo máximo:** 2,5 h.

## Diseño preliminar permitido para Azure

Hipótesis de arquitectura por evaluar en H4: VM con sitio/pool de laboratorio → agente y reglas de recolección → Log Analytics → consultas/alertas y tablero; alerta → mecanismo de remediación con identidad limitada y trazas. La herramienta concreta, región, tamaño, umbrales y costos siguen sin decidirse. Confirmar compatibilidad y precios oficiales al implementar. La alerta manual de presupuesto es previa al despliegue y distinta de las alertas operativas.

## Control de alcance

Priorizar corrección, seguridad y evidencia de retos 1 y 2. Reducir primero extras (IaC si retrasa lo mínimo, integración R4–R3 y acabado visual). No recortar pruebas de seguridad para aparentar cobertura. Un requisito obligatorio incompleto se registra como pendiente, nunca como logrado. Si Azure requiere esperar, cerrar formalmente el bloqueo y acordar la secuencia antes de iniciar otro hito.
