# Plan inicial de trabajo

Fecha: 2026-10-03 (America/Bogota). Alcance inicial máximo: **20 horas**, incluidas preparación, pruebas, evidencia, revisión y reserva. El enunciado estima 12–16 horas y fija 5 días desde la recepción; la fecha de recepción no está confirmada, por lo que no se calcula vencimiento.

Estado: **H0–H4 completados y aprobados**; Retos 1, 2 y 3 cerrados con la evidencia disponible. H4 quedó versionado en `0244b7f`; el usuario declaró eliminados todos los recursos Azure y confirmó ausencia de costos residuales, sin verificación pública independiente posterior al borrado. **H5/Reto 4 diferido y no implementado. H6/Reto 5 terminado y aprobado**, versionado con la justificación de H5 en `2021de7`. H7 permanece como cierre documental. Los tiempos siguientes son límites planificados, no horas ejecutadas.

## Secuencia y prioridades

| Hitos | Reto correspondiente |
|---|---|
| H1 y H2 | Reto 1: ingesta/calidad y diagnóstico/post-mortem |
| H3 | Reto 2: mantenimiento |
| H4 | Reto 3: Azure |
| H5 | Reto 4: triage con IA |
| H6 | Reto 5: propuesta de 90 días |
| H0 y H7 | Preparación y cierre transversales |

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

#### Resultado verificado de H2

- Diagnóstico reproducible: `h2_analyze.py`, catálogo E-001–E-009 en `evidencias/publicables/h2-evidence.json` y `H2_DIAGNOSTICO.md`. Markdown regenerable con `h2_reports.py`.
- Post-mortem independiente: `POSTMORTEM.md` y `POSTMORTEM.pdf`, **2 páginas**, generado con `render_postmortem.py`; ambas páginas renderizadas e inspeccionadas, sin texto cortado o ilegible.
- Resultado: degradación definida desde ventana 11:50; primer 5xx de confirmación 13:23:45; AppOffline 14:38–15:04 del 18. Éxito HTTP semanal observado: APIs 98,349%, salud integrada 99,742%; no se declara disponibilidad temporal exacta.
- Causa inmediata respaldada: errores de memoria, terminaciones y pool deshabilitado. Retención de caché como hipótesis de alta confianza, pendiente de dumps/código. Disco: escenarios condicionales de 30–106 h al cierre de la muestra; sin certeza de agotamiento real.
- Validación: 33 tests (21 H1 + 12 H2) aprobados; 33 controles H1 aprobados; análisis final repetido con JSON idéntico, cotejado con la evidencia publicable. No se modifica ingestión H1.
- Python: objetivo 3.11+, ejecución comprobada 3.12.14; 3.11 no probado directamente. Análisis/pruebas estándar; generación PDF usa dependencias opcionales fijadas en `requirements-pdf.txt` y revisión con Poppler.
- Control de tiempo parcial: 2026-10-04 00:43:00–00:59:37 Bogotá (16 min 37 s observados), sin incluir cierre documental posterior. No representa una medición completa del esfuerzo ni cambia el máximo de 3 h.
- Revisión humana aprobada por el usuario. Se conservan los límites declarados: definición de APIs y denominador; hora supuesta de eventos/tickets; hipótesis de caché; umbrales analíticos y sensibilidad de disco. Cierre autorizado para commit y push; sin Azure ni inicio de H3.

### H3 Mantenimiento del Reto 2

- **Objetivo:** sustituir mantenimiento riesgoso por operaciones justificadas y comprobables.
- **Entregable:** lista de problemas ordenados por riesgo; objetivo Windows PowerShell 5.1 y compatibilidad con 7 cuando sea posible, conforme a la aprobación de H3; pruebas Pester 5 y guía; decisiones sobre pasos eliminados y reemplazos.
- **Evidencia esperada:** ejecuciones de pruebas con resultados reales; demostración de parámetros validados, `-WhatIf`, errores/códigos de salida, logs estructurados, ausencia de secretos e idempotencia.
- **Pruebas:** rutas vacías o fuera de alcance, permisos, fallo parcial, repetición, retención y preservación de evidencia, simulación sin mutaciones; Pester si está disponible o alternativa equivalente documentada.
- **Aceptación:** pruebas locales pasan, efectos limitados a sandbox/fixtures; no ejecutar BAT ni operaciones sobre el servidor real; revisión del usuario registrada antes de H4.
- **Riesgos:** borrado excesivo, pérdida de evidencia, interrupciones y éxito falso; diferencias entre versiones de PowerShell.
- **Tiempo máximo:** 3 h.

#### Resultado verificado de H3

- Evaluación del BAT escrita antes del reemplazo: `reto2-powershell/H3_EVALUACION.md`, con prioridades, líneas originales y tabla conservar/rediseñar/reemplazar/eliminar. BAT leído estáticamente en memoria, nunca ejecutado ni copiado.
- Implementación: `SafeMaintenance.psm1` y entrada `Invoke-Maintenance.ps1`; guía en `reto2-powershell/README.md`. Solo temporales vencidos incluidos en manifiesto, bajo raíz exacta autorizada por configuración; pruebas exclusivamente sintéticas. Parámetros y límites, ShouldProcess/WhatIf, bloqueo exclusivo, log JSONL, verificación de eliminación y resumen. Preservación de logs/dumps y hold de investigación. Sin IIS, servicios, red o Azure.
- **38/38 pruebas Pester 5.7.1 aprobadas en cada motor**, Windows PowerShell **5.1.26100.9444** y PowerShell **7.6.5**; cero omitidas. Evidencia revisada: `evidencias/publicables/h3-tests.json`. Resultados crudos y dependencias privadas en `work-private/`.
- WhatIf del módulo y CLI: estructura, hashes y fechas de modificación iguales antes/después; sin log nuevo ni adquisición de bloqueo. Pruebas de errores parciales y permisos simulados, proceso propietario del lock, preservación, repetición, límites, rutas/enlaces y JSONL. Códigos reales de proceso 0–5 verificados.
- Integridad: 18 originales mantienen hashes iniciales; H1/H2, evidencias anteriores, diagnóstico y post-mortem sin cambios. No se repitió análisis ni se ejecutaron pruebas sobre datos reales.
- **Medición parcial:** control de reloj 2026-10-04 02:48:27.886–03:09:45.904 Bogotá: 21 min 18 s transcurridos observados. Excluye lectura previa al primer control y cierre/revisión posteriores; no es esfuerzo total. Máximo de H3 permanece en 3 h.
- **Aceptación registrada:** el usuario aprobó H3 con sus decisiones y límites. P1 adopción en producción no autorizada: ACLs, carreras con escritores ajenos, retención/archivo de logs y rotación de la credencial requieren alcance propio. Impacto: no se afirma solución del riesgo de disco ni validación en Windows Server.
- **Detención:** H3 cerrado en el commit indicado. Su aprobación no autoriza activar producción, Task Scheduler ni recursos de H4/Azure.

### H4 Laboratorio del Reto 3

- **Objetivo:** demostrar detección y auto-remediación en un escenario mínimo autorizado.
- **Entregable:** VM Windows/IIS/sitio/pool, Log Analytics y recolección de IIS/eventos/contadores; KQL de disponibilidad, 5xx, p95 y pool; dos alertas operativas con notificación; remediación con límites de intentos, exclusiones y escalamiento; tablero para dirección y NOC.
- **Evidencia esperada:** ingestión real, consultas ejecutadas, alertas y notificaciones, falla controlada y trazas de remediación; tiempos medidos de detección y recuperación; capturas o video de máximo 5 minutos. IaC y estimación de costo son deseables después de lo mínimo verificable.
- **Pruebas:** recepción de cada fuente, consultas ante datos vacíos, falla y recuperación, límite de reintentos, caso en que no se actúa, escalamiento humano y permisos mínimos.
- **Aceptación:** puertas satisfechas, dos alertas operativas verificadas después de existir las fuentes, remediación automática trazable y segura; distinguir tiempos observados de objetivos. Preservar evidencia antes de limpieza autorizada.
- **Riesgos:** costo, cuotas, demora de ingestión, permisos o proveedor no disponibles; no prometer crédito gratuito suficiente.
- **Tiempo máximo:** 5 h. Si se bloquea, registrar lo ejecutado y lo pendiente; no simular evidencia de Azure.

#### Preparación local de H4, autorizada el 2026-10-04

Corrección presupuestaria vigente: **USD 15**, independiente del crédito Student. Alertas de costo real 10/50/80/100 % y pronosticado al 80 % (o 100 %) si está disponible; destinatario `<ALERT_EMAIL_CONFIGURED_MANUALLY>`, solo usuario en Portal. Ámbito suscripción como control previo y conservador; atribución H4 mediante filtro del RG. No detiene consumo, admite retraso de datos. Contención principal: eliminar `rg-h4-observabilidad` el mismo día tras evidencia revisada y autorización. ZIP opcionales descritos en `reto3-azure/ZIP_CONTENTS.md`.

- Diseño inicial East US/B2s sustituido tras comprobación real: la política rechazó East US y B2s no estuvo disponible para la suscripción. Alcance vigente: North Central US, Windows Server 2022 Azure Edition y `Standard_B2als_v2`; techo preventivo USD 15, laboratorio eliminado el mismo día tras evidencia revisada y autorización de borrado. Webhook temporal aceptado; correo manual; sin datos reales ni secretos en Git/chat.
- Entregables locales en `reto3-azure/`: módulo, runbook, scripts de instalación futura/sondeo/falla/empaquetado, rol personalizado, seis archivos KQL, guía Portal, diseño de Workbook y plantilla de evidencias. Fixtures y pruebas separados en `tests/`.
- **55/55 pruebas Pester 5.7.1 PASS por motor**, Windows PowerShell 5.1.26100.9444 y PowerShell 7.6.5. Incluyen la espera acotada que corrige la verificación prematura del apagado del pool. Stubs/mocks sustituyen cmdlets Az; estas pruebas locales no sustituyen la evidencia real de Azure.
- Alerta A: workspace exacto y dimensiones VM/sitio/pool. Rol de tres acciones explícitas asignado solo a la VM; catálogo no agregado. Permisos efectivos pendientes, sin ampliación automática.
- **Estado real del laboratorio:** VM/IIS, tarea, ingestión, KQL, runtime/RBAC, alertas A/B, correo, falla controlada, recuperación HTTP y Workbook Dirección/NOC fueron comprobados. Desde el segundo 503 hasta el job: 2 min 52,554 s; hasta el primer 200: 4 min 00,069 s. El Fired solo se conserva al minuto, así que no se declara precisión de segundos para detección.
- **Cierre H4:** trece capturas públicas revisadas y commit `0244b7f`. El usuario declaró eliminados los recursos Azure después de preservar la evidencia. No hubo verificación independiente mediante Portal/CLI desde el agente; esa limitación permanece explícita.
- Máximo H4: 5 h sin ampliación; medición parcial y errores reales en IA_BITACORA. Reto 3 cerrado en `0244b7f`; la limpieza final de Azure fue declarada por el usuario.

### H5 Triage del Reto 4

**Estado del hito: diferido, no completado.**

- **Objetivo:** resumir alerta y contexto mediante un modelo, sin ejecutar acciones.
- **Entregable:** componente, esquema JSON, catálogo cerrado de runbooks, validación de referencias y manejo de timeout/error/respuesta inválida; proveedor y manejo de secretos documentados.
- **Evidencia esperada:** mínimo tres casos con entradas sintéticas identificadas y resultados; al menos una respuesta errónea o alucinada detectada. Distinguir respuesta defectuosa inyectada para prueba de un error real del proveedor.
- **Pruebas:** caso válido, hipótesis o cita inventada, salida inválida/timeout; acción fuera de catálogo e instrucciones maliciosas en contexto; ninguna ejecución autónoma.
- **Aceptación:** schema y referencias validados, confianza explícita, fallo seguro y decisión humana; demostrar integración real con modelo o declarar esa parte pendiente. Conexión al Reto 3 es opcional.
- **Riesgos:** exfiltración, inyección de instrucciones, falsa confianza; acceso al proveedor no confirmado.
- **Tiempo máximo:** 2,5 h.

#### Priorización formal

Reto 4 **diferido, no completado** por límite de tiempo. No existe código, integración ni prueba de IA y no se entrega una demostración sin pruebas. La decisión protege calidad, seguridad y verificabilidad, conforme a la indicación del enunciado de preferir menos componentes bien hechos y probados frente a una entrega incompleta.

Orden futuro: (1) contrato JSON cerrado; (2) catálogo versionado de runbooks; (3) preparación y minimización de evidencia; (4) clasificación y recomendación estructurada; (5) validación estricta de respuestas; (6) timeout, indisponibilidad y JSON inválido; (7) pruebas de memoria, pool/503 y disco; (8) evaluación de precisión y utilidad; (9) revisión humana obligatoria; (10) IA inicialmente sin permisos para ejecutar cambios.

### H6 Propuesta del Reto 5

- **Objetivo:** traducir hallazgos en prioridades de los primeros 90 días.
- **Entregable:** máximo 2 páginas con 3–5 iniciativas, impacto/esfuerzo/riesgo, fases, métricas, apoyos del líder y exclusiones justificadas.
- **Evidencia esperada:** relación de cada iniciativa con hallazgos verificados; definición de indicadores y de las líneas base aún no medidas.
- **Pruebas:** cobertura de requisitos, lectura ejecutiva, revisión de coherencia con resultados y límite de páginas.
- **Aceptación:** métricas medibles sin inventar mejoras ni líneas base; priorización defendible.
- **Riesgos:** propuesta genérica o metas sin sustento.
- **Tiempo máximo:** 1 h.

#### Resultado verificado

- Fuente única: `reto5-90-dias/PLAN_90_DIAS.md`; entregable oficial: `PLAN_90_DIAS.pdf`.
- Cinco iniciativas con impacto, esfuerzo y riesgo; entregas incrementales de días 1-5 a 61-90; métricas con líneas base durante los primeros 30 días; desbloqueos y límites explícitos.
- PDF A4 de exactamente dos páginas, renderizado e inspeccionado visualmente: texto legible, tablas y márgenes sin cortes o colisiones, páginas equilibradas y fuentes Bitstream Vera TrueType incorporadas.
- Sin Azure, llamadas pagadas ni cambios en entregables técnicos H1-H4. PDF aprobado por el usuario y versionado en `2021de7`; push no autorizado.

### H7 Revisión, entrega y reserva

- **Objetivo:** entrega reproducible y segura; usar la reserva para defectos prioritarios, no funciones nuevas.
- **Entregable:** README final, bitácora real, decisiones y pendientes actualizados, evidencias revisadas; paquete previo a commit para autorización. Eliminación de recursos solo dentro del alcance autorizado.
- **Evidencia esperada:** reproducción local, resultados de pruebas, revisión de secretos en archivos/índice/historial, verificación real de limpieza de Azure cuando corresponda.
- **Pruebas:** regresión pertinente, enlaces, comandos documentados, límites de páginas/video, secretos y diferencias de Git.
- **Aceptación:** estado de cada reto honesto, sin originales ni secretos; pendientes priorizados; no commit/push sin permiso. La bitácora aspira a los 5–10 prompts y 3 errores del enunciado únicamente si ocurrieron; declarar brechas sin inventar.
- **Riesgos:** falta de tiempo, recursos facturando, capturas sensibles, evidencia no reproducible.
- **Tiempo máximo:** 2,5 h.

## Diseño preliminar histórico de Azure

Antecedente ya sustituido por H4: se propuso VM con sitio/pool de laboratorio → agente y reglas de recolección → Log Analytics → consultas/alertas y tablero; alerta → remediación con identidad limitada y trazas. La región, tamaño, umbrales, permisos, costo y resultados finales están documentados en `reto3-azure/` y en la evidencia publicable. Se conserva este párrafo solo como trazabilidad del diseño inicial.

## Control de alcance

Priorizar corrección, seguridad y evidencia de retos 1 y 2. Reducir primero extras (IaC si retrasa lo mínimo, integración R4–R3 y acabado visual). No recortar pruebas de seguridad para aparentar cobertura. Un requisito obligatorio incompleto se registra como pendiente, nunca como logrado. Si Azure requiere esperar, cerrar formalmente el bloqueo y acordar la secuencia antes de iniciar otro hito.
