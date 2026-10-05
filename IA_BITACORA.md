# Bitácora auditada de uso de IA

## Criterio de auditoría

Registro consolidado al 2026-10-05 a partir del historial Git, `PLAN.md`, `DECISION_LOG.md`, `README.md`, entregables y evidencia publicable. No reproduce conversaciones completas. Distingue:

- **Verificado:** existe soporte en Git, documentos o evidencia publicable.
- **Declarado por el usuario:** decisión o acción humana informada durante el trabajo, sin verificación independiente completa.
- **No verificable:** no existe soporte suficiente en el repositorio o en la evidencia conservada.

Los horarios incluidos en entregables técnicos proceden de sus evidencias. Los tiempos máximos de `PLAN.md` son presupuestos, no horas consumidas.

## Herramientas, responsabilidades y control humano

- **Codex:** utilizado para inspección, implementación, pruebas locales, documentación, revisión de evidencias, generación y validación de PDF, y operaciones de control de versiones autorizadas. Git demuestra los cambios y commits, pero no identifica por sí solo qué herramienta produjo cada línea.
- **ChatGPT:** según declaración del usuario, se utilizó para interpretar el enunciado, revisar resultados de Codex, cuestionar decisiones técnicas, controlar alcance y preparar instrucciones. No hay conversaciones ni artefactos versionados que permitan auditar sesiones, modelo, fechas o aportes exactos; ese detalle es **no verificable**.
- **Decisión humana:** la aprobación de cada hito, costos, creación o eliminación de recursos Azure, permisos, cambios de alcance, aceptación de riesgos, commits y publicaciones correspondió al usuario. La IA propuso, ejecutó trabajo local autorizado y señaló límites; no sustituyó esas decisiones.
- **Control de datos sensibles:** según las reglas y el registro operativo, el usuario no entregó secretos ni credenciales a Codex o ChatGPT mediante prompts. La credencial conocida del BAT se trató localmente de forma redactada y solo se registraron resultados booleanos. Los escaneos documentados no hallaron su valor en archivos rastreados ni en el historial alcanzable. Esto no certifica objetos inalcanzables, remotos ni secretos desconocidos.

### Herramientas y modelos identificados

| Herramienta | Modelo exacto | Razonamiento | Etapas | Finalidad |
|---|---|---|---|---|
| Codex | GPT-6 Astra | No verificable | Inicio y H0 exclusivamente, según confirmación del usuario | Inspección inicial, protección de fuentes y planificación |
| Codex | GPT-5.6 Sol | Medium | H1–H7 anteriores a esta auditoría | Implementación, pruebas, documentación, evidencias y control de versiones |
| ChatGPT | GPT-5.6 Sol | Medium | H0–H7, según declaración del usuario | Interpretación del enunciado, revisión crítica, control de alcance y preparación de instrucciones |
| Codex | GPT-6, según la configuración de la sesión actual | No verificable | Auditoría actual y reconciliación documental | Contraste de Git/documentos, edición y validación final |

La asignación histórica de modelos procede de la confirmación del usuario y no puede demostrarse mediante Git. El usuario confirmó que la denominación es **GPT-6 Astra** y que se utilizó únicamente hasta H0. No existe evidencia conservada de su configuración de razonamiento ni del momento técnico exacto del cambio de modelo.

## Prompts clave y respuestas resumidas

### 1. H0 — Preparación

- **Herramienta principal y modelo:** Codex — GPT-6 Astra, utilizado hasta H0, con razonamiento no verificable.
- **Herramienta de revisión y modelo:** ChatGPT — GPT-5.6 Sol, Medium, según confirmación del usuario.
- **Prompt abreviado:** inspeccionar el enunciado, proteger originales y proponer el plan sin resolver todavía los retos.
- **Respuesta resumida:** inventario, exclusiones, hitos, puertas de aprobación y separación entre hechos, hipótesis y supuestos.
- **Revisión o decisión humana:** aprobación de la preparación y autorización separada del primer commit/push.
- **Evidencia o validación:** 18 originales inventariados e intactos; `aa212c5`, `dff7c62`, `PLAN.md` y `DECISION_LOG.md`.

### 2. H1 — Ingesta y calidad

- **Herramienta principal y modelo:** Codex — GPT-5.6 Sol, Medium, según confirmación del usuario.
- **Herramienta de revisión y modelo:** ChatGPT — GPT-5.6 Sol, Medium, según confirmación del usuario.
- **Prompt abreviado:** implementar ingesta, normalización y validación reproducible.
- **Respuesta resumida:** parser, trazabilidad, reglas de calidad, verificador, fixtures y resumen publicable.
- **Revisión o decisión humana:** aceptación de supuestos y límites antes de autorizar H2.
- **Evidencia o validación:** 21/21 pruebas, 33 controles y `evidencias/publicables/h1-summary.json`; commit `a0a13c8`.

### 3. H2 — Diagnóstico y post-mortem

- **Herramienta principal y modelo:** Codex — GPT-5.6 Sol, Medium, según confirmación del usuario.
- **Herramienta de revisión y modelo:** ChatGPT — GPT-5.6 Sol, Medium, según confirmación del usuario.
- **Prompt abreviado:** correlacionar evidencia, separar hechos de hipótesis y producir diagnóstico y post-mortem ejecutivo.
- **Respuesta resumida:** cronología, indicadores, catálogo E-001–E-009, análisis causal con incertidumbre y PDF ejecutivo.
- **Revisión o decisión humana:** aprobación del diagnóstico, sus límites y el cierre del Reto 1.
- **Evidencia o validación:** 33 pruebas combinadas, evidencia reproducible y PDF de dos páginas; commits `97c4245` y `e9eba75`.

### 4. H3 — Mantenimiento seguro

- **Herramienta principal y modelo:** Codex — GPT-5.6 Sol, Medium, según confirmación del usuario.
- **Herramienta de revisión y modelo:** ChatGPT — GPT-5.6 Sol, Medium, según confirmación del usuario.
- **Prompt abreviado:** sustituir el BAT por PowerShell seguro, idempotente, sin credenciales y probado con Pester.
- **Respuesta resumida:** evaluación de riesgos, módulo y CLI, configuración cerrada, `WhatIf`, auditoría JSONL, límites y bloqueo.
- **Revisión o decisión humana:** eliminación de operaciones riesgosas, aprobación de H3 y exclusión de cualquier activación productiva.
- **Evidencia o validación:** 38/38 pruebas por motor y `evidencias/publicables/h3-tests.json`; commits `df48a58` y `e66c348`.

### 5. H4 — Preparación local

- **Herramienta principal y modelo:** Codex — GPT-5.6 Sol, Medium, según confirmación del usuario.
- **Herramienta de revisión y modelo:** ChatGPT — GPT-5.6 Sol, Medium, según confirmación del usuario.
- **Prompt abreviado:** crear scripts, KQL, runbook, permisos mínimos, guía de Portal y pruebas locales sin desplegar Azure.
- **Respuesta resumida:** artefactos locales, rol mínimo, salvaguardas, mocks, Workbook y secuencia de activación por puertas.
- **Revisión o decisión humana:** presupuesto, región, SKU, permisos y alcance se revisaron antes de cada despliegue.
- **Evidencia o validación:** artefactos de `reto3-azure/`, pruebas locales y decisiones D37–D46.

### 6. H4 — Ejecución controlada

- **Herramienta principal y modelo:** Codex — GPT-5.6 Sol, Medium, según confirmación del usuario.
- **Herramienta de revisión y modelo:** ChatGPT — GPT-5.6 Sol, Medium, según confirmación del usuario.
- **Prompt abreviado:** avanzar mediante autorizaciones individuales, recopilar evidencia y validar alerta, remediación y recuperación.
- **Respuesta resumida:** guía paso a paso, revisión de resultados y capturas, corrección del sondeo asíncrono y cierre documentado.
- **Revisión o decisión humana:** el usuario operó Portal, autorizó recursos y falla controlada, aceptó permisos/riesgos y decidió la eliminación final.
- **Evidencia o validación:** 55/55 pruebas por motor, 13 capturas públicas, HTTP 200 y commit `0244b7f`.

### 7. Reto 4 — Diferimiento

- **Herramienta principal y modelo:** Codex — GPT-5.6 Sol, Medium, según confirmación del usuario.
- **Herramienta de revisión y modelo:** ChatGPT — GPT-5.6 Sol, Medium, según confirmación del usuario.
- **Prompt abreviado:** documentar honestamente el diferimiento y ordenar la implementación pendiente.
- **Respuesta resumida:** justificación independiente y backlog seguro, sin código ni demostración ficticia.
- **Revisión o decisión humana:** el usuario decidió priorizar entregables verificables y no afirmar una integración inexistente.
- **Evidencia o validación:** `reto4-ia/README.md`; ausencia comprobada de código, pruebas o PDF del Reto 4.

### 8. Reto 5 — Plan de 90 días

- **Herramienta principal y modelo:** Codex — GPT-5.6 Sol, Medium, según confirmación del usuario.
- **Herramienta de revisión y modelo:** ChatGPT — GPT-5.6 Sol, Medium, según confirmación del usuario.
- **Prompt abreviado:** elaborar una propuesta ejecutiva de máximo dos páginas con iniciativas, métricas, desbloqueos y límites.
- **Respuesta resumida:** cinco iniciativas, cronograma, medición, dependencias y exclusiones en Markdown/PDF.
- **Revisión o decisión humana:** evaluación de impacto, esfuerzo, riesgo y viabilidad; aprobación visual del PDF final.
- **Evidencia o validación:** PDF A4 de dos páginas, tabla final de riesgos y commit `2021de7`.

## H0 — Preparación, inventario y controles

- **Objetivo:** entender el enunciado y las fuentes, proteger originales y dividir el trabajo en hitos con puertas de aprobación.
- **IA utilizada:** Codex; ChatGPT como apoyo de interpretación y alcance por declaración del usuario.
- **Aporte de la IA:** estructura inicial de `PLAN.md`, `DECISION_LOG.md`, `IA_BITACORA.md`, `README.md`, exclusiones y criterios de hecho, hipótesis y supuesto.
- **Revisión y decisión humana:** aprobación de H0 y autorización separada de commit/push registradas en `DECISION_LOG.md`. Ningún cambio Azure fue autorizado en este hito.
- **Correcciones:** el inventario inicial omitió archivos ignorados; se repitió sin depender de `.gitignore`. Se corrigió una lectura UTF-8 defectuosa y se sustituyó el supuesto de que Python no existía por una comprobación del runtime.
- **Validaciones:** 18 originales inventariados e intactos por SHA-256; exclusión de entradas privadas; BAT no ejecutado ni copiado; revisión de Git y de la credencial conocida sin publicar su valor.
- **Limitaciones y pendientes:** la fecha de recepción del enunciado no quedó confirmada. La inspección inicial no equivalía a resolver los retos.
- **Trazabilidad Git:** `aa212c5` y `dff7c62`.

## H1 — Ingesta y calidad de datos

- **Objetivo:** cargar, normalizar y resumir las fuentes del Reto 1 de forma reproducible, conservando trazabilidad y originales.
- **IA utilizada:** Codex para implementación, pruebas y documentación; ChatGPT para revisión de alcance según declaración del usuario.
- **Aporte de la IA:** parser, verificador, pruebas sintéticas, reglas de calidad y resumen publicable.
- **Revisión y decisión humana:** el usuario aprobó y versionó H1 antes de autorizar H2, según `DECISION_LOG.md`.
- **Correcciones:** el validador inicial rechazó indebidamente 13 ausencias de memoria y un registro HTTPERR incompleto; se conservaron como valores desconocidos. Se eliminaron rutas locales no portables de las instrucciones. Se aclaró que H1 cubría ingesta/calidad y no completaba por sí solo todo el Reto 1.
- **Validaciones:** 21/21 pruebas unitarias; 33 controles independientes; dos reproducciones iguales; 195.932 entradas, 170.050 conservadas, 25.882 filas de una copia exacta excluidas y 0 rechazadas. La fuente publicable es `evidencias/publicables/h1-summary.json`.
- **Limitaciones y pendientes:** Python 3.12.14 fue ejecutado; compatibilidad objetivo 3.11 no se probó directamente. Las zonas de eventos y tickets conservaron el supuesto documentado. H1 no estableció causa raíz ni disponibilidad extremo a extremo.
- **Trazabilidad Git:** `a0a13c8`.

## H2 — Diagnóstico y post-mortem

- **Objetivo:** correlacionar las fuentes, reconstruir la cronología, separar evidencia de hipótesis y producir un informe técnico y un post-mortem ejecutivo.
- **IA utilizada:** Codex para análisis, pruebas, documentación y PDF; ChatGPT para revisar conclusiones y cuestionar decisiones técnicas, según declaración del usuario.
- **Aporte de la IA:** análisis reproducible, catálogo E-001–E-009, pruebas H2, diagnóstico, post-mortem Markdown/PDF y validaciones de formato.
- **Revisión y decisión humana:** el usuario revisó y aprobó H2; el Reto 1 quedó cerrado y versionado. Las mitigaciones siguieron siendo recomendaciones humanas, no cambios productivos.
- **Correcciones:** se hizo explícita la separación entre hechos e hipótesis; la posible retención de sesiones quedó como hipótesis de alta confianza, no defecto demostrado. Se corrigió la presentación del post-mortem: paginación, distribución y sustitución de Helvetica por Bitstream Vera TrueType incorporada. También se corrigió un `SyntaxWarning` del generador.
- **Validaciones:** 33 pruebas combinadas (21 H1 y 12 H2); 33 controles H1 previos; dos ejecuciones finales con evidencia idéntica; PDF de dos páginas renderizado e inspeccionado; texto cotejado con Markdown. Evidencia: `evidencias/publicables/h2-evidence.json`.
- **Limitaciones y pendientes:** los datos no prueban disponibilidad temporal extremo a extremo ni el defecto exacto de código. Faltan dumps, código de aplicación y una prueba controlada para cerrar causalidad.
- **Trazabilidad Git:** `97c4245` y ajuste documental `e9eba75`.

## H3 — Mantenimiento seguro

- **Objetivo:** sustituir el BAT por mantenimiento limitado, auditable e idempotente, probado solo con fixtures sintéticos.
- **IA utilizada:** Codex para evaluación estática, implementación PowerShell, pruebas y documentación; ChatGPT para revisar riesgos y alcance, según declaración del usuario.
- **Aporte de la IA:** evaluación de operaciones, módulo y CLI, configuración cerrada, `WhatIf`, JSONL, bloqueo, límites, códigos de salida y pruebas Pester.
- **Revisión y decisión humana:** el usuario decidió eliminar reinicios, operaciones de red, manejo de credenciales y borrado de evidencia; aprobó H3 y su commit. No aprobó producción ni Task Scheduler.
- **Correcciones:** la configuración fija inicial impedía desplegar el módulo sin editar código; se separó en `h3.routes.v1`, con ruta exacta y plantilla deshabilitada. Se eliminó el manejo de credenciales del BAT. También se corrigieron supuestos frágiles de orden en pruebas, propagación de stderr y configuración de Pester.
- **Validaciones:** 38/38 casos en Windows PowerShell 5.1.26100.9444 y 38/38 en PowerShell 7.6.5, Pester 5.7.1; hashes de ocho artefactos; evidencia en `evidencias/publicables/h3-tests.json`.
- **Limitaciones y pendientes:** pruebas solo en sandbox sintético; no Windows Server, ACL reales, IIS, servicios, red ni BAT original. La revocación de la credencial original y una adopción productiva requieren intervención humana independiente.
- **Trazabilidad Git:** `df48a58` y conciliación `e66c348`.

## H4 — Observabilidad y remediación en Azure

- **Objetivo:** demostrar ingestión, monitoreo, alertas, remediación limitada, validación HTTP, seguridad y vistas separadas para Dirección y NOC.
- **IA utilizada:** Codex para diseño, artefactos, pruebas locales, consultas, runbook, documentación, Workbook y control de versiones. ChatGPT apoyó la interpretación, revisión de resultados, cuestionamiento de permisos y preparación de instrucciones, según declaración del usuario.
- **Aporte de la IA:** scripts, módulo, KQL, plantillas ARM, rol mínimo, runbook, salvaguardas, pruebas, guías y revisión de capturas. Codex no ejecutó CLI/SDK Azure; el usuario operó Portal.
- **Revisión y decisión humana:** fueron humanas la corrección presupuestaria, región/SKU, creación y eliminación de recursos, permisos, activación progresiva, falla controlada, aceptación de riesgos y evidencia. El presupuesto vigente fue USD 15. El cambio solicitado de USD 100 a USD 15 se registra como decisión humana; el valor previo de USD 100 no aparece en el historial Git alcanzable y por ello ese antecedente exacto es **no verificable** desde el repositorio.
- **Correcciones:** se reemplazaron región y SKU iniciales por opciones permitidas; se redujo el presupuesto; se limitaron permisos a tres acciones y alcance de VM; la activación avanzó por puertas. En pruebas se corrigieron errores del harness, compatibilidad de timestamps y persistencia. En el ensayo, `StopNotVerified` reveló una comprobación prematura del apagado asíncrono; se añadió espera acotada.
- **Validaciones:** 55/55 casos Pester en cada motor; 13 capturas públicas revisadas; ingestión en cuatro tablas, alerta A, job, salida `Recovered`, HTTP 200, alerta B, RBAC y Workbook documentados. El segundo fallo hasta el job fue 2 min 52,554 s y hasta el primer sondeo sano 4 min 00,069 s. Costo observado durante la evidencia: USD 0,06. Fuentes: `evidencias/publicables/h4-local-tests.json` y `evidencias/publicables/h4/`.
- **Limitaciones y pendientes:** las pruebas locales usan mocks y no sustituyen Azure. El usuario confirmó finalmente que eliminó todos los recursos y que no hay costos residuales; no existe evidencia pública posterior al borrado ni verificación independiente del agente, por lo que ese estado final es **declarado por el usuario**.
- **Trazabilidad Git:** `0244b7f`.

## H5 — Reto 4, triage con IA

- **Objetivo:** evaluar un triage estructurado y seguro; finalmente se priorizó no implementarlo.
- **IA utilizada:** Codex para organizar el backlog y documentar límites; ChatGPT para controlar alcance y preparar instrucciones, según declaración del usuario.
- **Aporte de la IA:** orden de implementación pendiente: contrato JSON, catálogo permitido, minimización, respuesta estructurada, validación, fallos, casos, evaluación y revisión humana.
- **Revisión y decisión humana:** el usuario decidió diferir el Reto 4 por límite de tiempo y priorización. No se afirmará que fue implementado.
- **Correcciones o resultados:** se rechazó presentar una integración superficial, no evaluada o capaz de recomendar acciones sin controles.
- **Validaciones:** existe únicamente la justificación y backlog en `reto4-ia/README.md`; se comprobó que no hay código, integración, prueba ni PDF del Reto 4.
- **Limitaciones y pendientes:** todo el componente permanece pendiente. La primera versión prevista no ejecutaría cambios automáticamente.
- **Trazabilidad Git:** `2021de7`.

## H6 — Reto 5, plan de 90 días

- **Objetivo:** convertir hallazgos en cinco iniciativas ejecutivas con cronograma, métricas y límites.
- **IA utilizada:** Codex para estructurar, condensar, generar y validar el PDF; ChatGPT para revisar resultados y preparar instrucciones, según declaración del usuario.
- **Aporte de la IA:** propuesta, tablas, métricas, diseño PDF y comprobaciones de contenido y formato.
- **Revisión y decisión humana:** el usuario revisó impacto, esfuerzo, riesgo y viabilidad; solicitó la columna explícita de riesgo y aprobó la versión final de dos páginas.
- **Correcciones:** se equilibraron páginas, se eliminaron fuentes no incorporadas y se calificaron los riesgos como Bajo, Bajo, Medio, Bajo y Medio. La justificación del Reto 4 quedó fuera del PDF.
- **Validaciones:** PDF A4 de dos páginas; contenido sustantivo cotejado con Markdown; cero elementos fuera de página; Vera Roman/Bold incorporadas; render inspeccionado. Entregables: `reto5-90-dias/PLAN_90_DIAS.md` y `PLAN_90_DIAS.pdf`.
- **Limitaciones y pendientes:** las metas porcentuales son objetivos sujetos a línea base, no resultados históricos.
- **Trazabilidad Git:** `2021de7`.

## Errores o propuestas riesgosas de la IA

| Caso | Error o riesgo | Cómo se detectó | Corrección humana | Validación posterior |
|---|---|---|---|---|
| H1: ausencias y HTTPERR | El validador rechazó 13 ausencias válidas de memoria y un registro parcial de HTTPERR. | La revisión de cuarentena se contrastó con las líneas originales. | Se decidió conservar ausencias como `null` y aceptar el registro de conexión sin inventar campos HTTP. | 21/21 pruebas, 33 controles, 170.050 registros conservados y 0 rechazados. |
| H2: sesiones/caché | La correlación podía convertirse indebidamente en una causa de código demostrada. | La revisión evidenció que no existían dumps, código ni prueba controlada de reversión. | Se separó el mecanismo inmediato verificado de la hipótesis de retención de sesiones/caché. | Catálogo E-001–E-009, 12 pruebas H2 y revisión humana del diagnóstico/post-mortem. |
| H3: rutas fijas | La primera solución estaba segura para el laboratorio, pero no podía desplegarse sin editar el módulo. | El usuario cuestionó su aplicabilidad operativa. | Se autorizó una configuración `h3.routes.v1`, cerrada, versionable, con raíz exacta y plantilla deshabilitada. | 38/38 pruebas en PowerShell 5.1 y 38/38 en PowerShell 7.6.5. |
| H4: presupuesto | La propuesta inicial usó USD 100, superior al límite aceptado. | El usuario revisó costo, crédito disponible y alcance. | El usuario fijó USD 15 como techo preventivo y exigió activación progresiva. | Documentación unificada en USD 15 y captura pública del presupuesto; el valor previo de USD 100 no es verificable en Git. |
| H4: `StopNotVerified` | El script verificó demasiado pronto una operación asíncrona y reportó fallo aunque el pool terminó detenido. | La comprobación posterior mostró estado detenido y HTTP 503. | Se aprobó una espera acotada de 15 segundos con sondeo cada 250 ms y fallo cerrado. | 55/55 pruebas por motor y evidencia posterior de recuperación HTTP. |
| PDF ejecutivo | Una versión introdujo una fuente no incorporada y otra distribución desequilibró las páginas. | `pdffonts`, render PNG y revisión visual humana. | Se exigió Bitstream Vera incorporada y redistribución del contenido. | PDF final de dos páginas, fuentes incorporadas, contenido cotejado y aprobación visual. |

## Validación y decisiones no delegadas

| Categoría | Decisión reservada a una persona | Razón |
|---|---|---|
| Credenciales | Introducción, rotación, revocación y manejo de credenciales | La IA no necesita conocer valores y no debe ampliar exposición. |
| Costos | Aprobación de presupuesto, SKU, duración y consumo | Generan impacto financiero y dependen de la cuenta real. |
| Recursos Azure | Creación, modificación y eliminación | Son acciones externas, facturables y potencialmente irreversibles. |
| Permisos y riesgos | Aceptación de RBAC, privilegio efectivo y salvaguardas | El propietario debe aceptar el riesgo residual y el alcance operativo. |
| Causa raíz | Conclusión final y cierre de hipótesis | La correlación disponible no sustituye dumps, código o prueba controlada. |
| Evidencias | Selección, redacción y publicación | Pueden exponer identificadores o información personal; requieren revisión visual humana. |
| Reto 4 | Decisión de diferirlo | Es una priorización de tiempo, calidad y riesgo, no una decisión técnica automática. |
| Repositorio | Autorización de commit, push y publicación | Cambia el historial o divulga artefactos; requiere consentimiento explícito. |

Las validaciones técnicas ejecutadas por Codex sirvieron como evidencia para la decisión; no concedieron autorización automática para ninguna de estas categorías.

## H7 — Cierre, control de versiones y estado actual

- **Objetivo:** preservar evidencia revisada, mantener límites honestos y versionar solo con aprobación humana.
- **IA utilizada:** Codex para auditoría, revisión del índice, escaneo redactado, commits autorizados y verificación posterior. ChatGPT apoyó el control de alcance por declaración del usuario.
- **Aporte de la IA:** nueve commits locales trazables desde `aa212c5` hasta `2021de7`, comprobaciones previas y documentación de lo pendiente.
- **Revisión y decisión humana:** cada commit/push y cada cambio Azure requirió autorización separada. El commit final de Retos 4–5 fue aprobado por el usuario. No hay autorización vigente de push.
- **Correcciones o resultados:** Esta auditoría complementó el registro por hitos con ocho prompts clave, sus respuestas resumidas, la revisión humana aplicada y la evidencia correspondiente.
- **Validaciones de esta auditoría:** historial y archivos de los nueve commits; 18 evidencias publicables rastreadas; ninguna ruta de `input-private/`, `work-private/` o `evidencias/private/` rastreada; codificación UTF-8 de esta bitácora; contraste con PLAN, decisiones, README y entregables.
- **Limitaciones y pendientes:** Git no demuestra por sí solo la herramienta que produjo cada cambio ni las aprobaciones humanas. El commit local final continúa pendiente de publicación y esta auditoría requiere revisión humana.
- **Trabajo actual no confirmado:** antes de esta auditoría el árbol estaba limpio; `main` estaba un commit delante de `origin/main`. Esta actualización de `IA_BITACORA.md` queda sin commit ni push hasta revisión humana.

## Inconsistencias y hechos no verificables detectados

- Git y los documentos no permiten reconstruir las sesiones exactas de ChatGPT/Codex ni su configuración histórica; la asignación de GPT-6 Astra hasta H0 y GPT-5.6 Sol Medium se registra por confirmación del usuario.
- El cambio de presupuesto de USD 100 a USD 15 fue solicitado por el usuario, pero el historial alcanzable conserva USD 15 y no demuestra el importe anterior.
- La eliminación definitiva de Azure y la ausencia de costos residuales fueron confirmadas nuevamente por el usuario, sin captura o consulta pública posterior al borrado.
- La advertencia de Git sobre el archivo global de exclusiones inaccesible persiste; las exclusiones locales y el conjunto rastreado sí se pudieron comprobar.
