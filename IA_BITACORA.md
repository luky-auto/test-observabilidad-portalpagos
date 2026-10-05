# Bitácora real de uso de IA

## Herramientas y alcance

2026-10-03 (America/Bogota). Asistente Codex, basado en GPT-6 según la configuración de esta sesión; variante exacta no verificada. Uso: lectura y planificación, documentación inicial y comprobaciones locales mediante PowerShell/.NET y Git. Habilidad `documents` consultada para lectura de DOCX; extracción OOXML de solo lectura, sin generar un documento Word ni revisar su diseño visual. Sin subagentes, servicios de modelos externos ni comandos Azure.

## Prompt importante 01

**Origen:** solicitud inicial real del usuario; resumen fiel, no transcripción literal. Preparar una prueba de Especialista en Observabilidad y Automatización: leer enunciado y LEEME, inspeccionar datos, no resolver los cinco retos; crear únicamente documentación, `.gitignore` y estructura; planificar hasta 20 h con hitos verificables; proteger originales y credencial; trabajar un hito por vez; registrar decisiones y uso real de IA; no modificar Azure ni hacer commit/push sin autorización; posponer Reto 3 hasta revisión de retos 1 y 2; presupuesto manual previo y alertas operativas posteriores a recursos/fuentes.

**Respuesta generada:** documentación inicial con ocho hitos y sus siete campos de verificación; inventario de formatos, hechos/hipótesis/supuestos, puertas de Azure y protección de entradas. No se generaron soluciones de retos.

**Validación:** contraste con texto del DOCX y LEEME; inspección de fuentes y Git; verificaciones finales detalladas abajo. **Decisiones no delegadas:** autorización Azure, configuración manual de presupuesto, aceptación de revisiones, publicación y decisiones humanas sobre sugerencias de triage.

Solo hay un prompt clave registrado. Los comandos rutinarios no se presentan como nuevos prompts del usuario. El objetivo del enunciado de 5–10 prompts se completará únicamente con interacciones relevantes reales.

## Errores y correcciones que sí ocurrieron

1. **Inventario inicial incompleto:** se usó `rg --files --hidden input-private`, que omitió logs por respetar `.gitignore`. Se detectó al contrastar con el LEEME, que sí anunciaba logs. Se corrigió con `Get-ChildItem input-private -Recurse -File`, que encontró 18 archivos. No se declaró que faltaran fuentes ni se cambió su contenido.
2. **Lectura con codificación inadecuada:** la primera lectura de texto con `Get-Content` sin codificación explícita mostró caracteres acentuados mal decodificados. Se corrigió la lectura de LEEME y muestras con `-Encoding UTF8`; no se alteraron los originales. La salida conjunta de habilidad y LEEME también quedó truncada: el LEEME se volvió a leer completo por separado.
3. **Supuesto de herramienta no confirmado:** se intentó `python --version` antes de verificar su disponibilidad; el comando falló porque no estaba en PATH. Para la extracción de texto del DOCX se usó .NET disponible en PowerShell, sin instalar software. No se concluyó que Python no exista en el equipo.

Estos son fallos de procedimiento observados, no errores de diagnóstico ni alucinaciones del modelo de triage. No se inventan equivocaciones técnicas para cumplir la cuota del enunciado; su pertinencia para esa evaluación se revisará al cierre.

## Verificaciones realizadas durante la inspección

- DOCX: lectura de párrafos y tablas a través de `word/document.xml`; leídas secciones 1–6. LEEME: lectura completa UTF-8. Resultado: requisitos incorporados al plan; sin resolver retos.
- CSV: `Import-Csv -Encoding UTF8` permitió observar 498 eventos, 2016 muestras de métricas y 8 tickets. Resultado: estructura legible; aún no es validación de calidad ni continuidad temporal.
- IIS/HTTPERR: encabezados y muestras inspeccionados; se identificaron variantes de campos. SHA256 de los dos archivos del 16 coincide. Resultado: duplicado exacto confirmado, pendiente tratamiento en H1.
- BAT: lectura redactada, omitiendo líneas potencialmente sensibles; no ejecutado ni copiado. JSON de alerta: estructura inspeccionada y `ConvertFrom-Json` completado; `schemaId` coincide con el esquema declarado.
- Git: `git status --short`, `git ls-files`, `git log --all --format=%h --name-only` y `git check-ignore` sobre el BAT. Resultado inicial: solo `.gitignore` rastreado, un commit previo `aa212c5`, BAT ignorado. Advertencia real: archivo global de exclusiones inaccesible; reglas locales comprobables.
- Se tomaron hashes SHA256 en memoria de los 18 originales antes de escribir documentación y se compararon después: los 18 permanecen iguales. No se publica el valor del secreto ni un hash de la credencial.
- Exclusiones: `git check-ignore -q` para cada uno de los 18 originales; cero entradas sin exclusión. La advertencia del archivo global persiste, pero no impidió comprobar las reglas locales.
- Secreto: valor aislado del BAT únicamente en memoria; búsqueda literal en los seis entregables y en contenido de blobs/commits/tags enumerados por `git rev-list --objects --all --reflog`; cero coincidencias. Alcance: objetos alcanzables y reflogs disponibles, no objetos inalcanzables ni remotos; no equivale a un escaneo universal de secretos desconocidos.
- `git diff --check`: sin errores. `git status --short`: únicamente `.gitignore` modificado y los cinco Markdown nuevos. `git ls-files`: solo `.gitignore`. No se modificó el índice ni se hizo commit/push. Carpetas vacías verificadas durante su creación; no hay archivos de implementación.

## Límites de evidencia

No hay pruebas de soluciones, resultados del incidente ni evidencia de Azure. Los tiempos del PLAN son presupuestos, no mediciones de trabajo ejecutado. La inspección de formatos y lectura del BAT no equivalen a resolver retos 1 o 2.

## Prompt importante 02 y trabajo real de H1

**Fecha:** 2026-10-03, Bogotá. **Origen:** nueva solicitud real del usuario; resumen fiel, no transcripción literal. Implementar únicamente H1 del PLAN vigente, leer lo necesario, preservar originales y secretos, identificar duplicados/esquemas/horarios/incompletos, verificar UTC W3C contra las demás fuentes, cargar/validar/normalizar/resumir reproduciblemente, justificar exclusiones, probar con fixtures sintéticos y ejecutar reproducción; actualizar documentación con hechos, entregar resultados y revisión, sin Azure, llamadas pagadas, commit/push ni H2.

**Herramientas:** Codex de esta sesión; PowerShell para comandos locales; Python 3.12.14 del runtime local, `csv`, `sqlite3`, `hashlib`, `datetime` y `unittest`; consulta web de documentación oficial Microsoft sobre formatos W3C y HTTPERR. No se usaron subagentes ni proveedor externo de inferencia. El lanzador `py -0p` no encontró instalaciones registradas, pero la inspección del runtime sí encontró Python: no se confundieron esas dos observaciones.

**Respuesta generada:** cargador H1, verificador independiente, 21 tests con fixtures sintéticos construidos en código, guía, informe de calidad y resumen JSON publicable. Reglas R01–R12 y referencias de líneas permiten reproducir las cuentas. Detalle normalizado solo en carpetas ignoradas.

**Error real y corrección:** la primera versión del validador fue demasiado estricta: rechazó 13 filas de Perfmon por un espacio en memoria privada y una fila HTTPERR sin petición completa. Ejecución inicial: 170036 aceptados, 14 rechazados y 25882 excluidos por copia. Se detectó al revisar las referencias de cuarentena contra las líneas originales. Se cambió R06 para conservar ausencia como null y el registro de conexión sin estado/método/URI; se añadieron tests específicos. Resultado final: 170050 conservados, 0 rechazados, 25882 excluidos por copia. Los 13 valores siguen siendo desconocidos; no se ocultó el defecto rellenando ceros. No se produjo una conclusión de incidente a partir del resultado inicial.

**Validación real:**

- `python -m unittest discover -s tests -p test_h1.py -v` con el ejecutable documentado: **21/21 PASS**. Incluye fixtures corruptos, multilinea, esquemas variables, límites temporales, duplicados conservados, entradas intactas, reproducción, rutas protegidas y eliminación del resumen obsoleto ante fallo.
- Dos ejecuciones finales de `h1_ingest.py`, salidas `work-private/h1` y `work-private/h1-repro`: ambas con **195932 entradas, 170050 conservados, 25882 filas de copia excluidas, 0 rechazados, 170020 fechados en semana y 30 sin fecha**.
- `verify_h1.py --output work-private/h1-repro --reference evidencias/publicables/h1-summary.json`: **33 comprobaciones PASS**, incluida igualdad byte a byte. JSON de 29.899 bytes, SHA256 `9aa56a99c0cf0e9b8d078f87840f26f05b6a310b6346b9b9be6570adc2c95c3f`.
- Comparación SHA256 de los **18 originales** antes/después: sin cambios. El cargador también verifica sus 14 archivos al finalizar y el verificador los contrasta con el inventario.
- `git diff --check`: sin errores al revisar implementación; bases y salidas privadas ignoradas; ningún archivo de `input-private/` o `work-private/` rastreado. No se hizo staging, commit ni push.

**No delegado:** aceptación de la zona supuesta de eventos/tickets y de las reglas de calidad, aprobación de H1 y autorización de H2/publicación. No se convierten coincidencias horarias en causa raíz. Este registro añade un prompt importante real y un error de validación ocurrido; no inventa fallos de IA para cumplir cuotas.

Los límites anteriores correspondían a H0. En H1 sí existen pruebas de ingestión y calidad; siguen sin existir diagnóstico H2, evidencia Azure, disponibilidad calculada ni pronósticos.

## Prompt importante 03 y corrección de portabilidad

**Solicitud real, resumida:** eliminar rutas específicas del computador de documentos y comandos, documentar Python 3.11 mediante lanzador o `.venv`, aclarar biblioteca estándar y alcance parcial de H1; programar todos los entregables restantes del Reto 1 y un post-mortem independiente en Markdown/PDF con paginación verificable; repetir 21 pruebas, 33 controles y revisión de rutas, sin commit ni H2.

**Error real señalado por el usuario:** la guía inicial de H1 usaba una ruta absoluta al intérprete del equipo. Aunque permitía la ejecución local, hacía que el comando no fuera portable. Se reemplazó por comandos de lanzador y entorno virtual relativo; el código de ingestión no necesitó cambios. No se registra como error del análisis del incidente.

**Ejecución real:** `py -3.11 --version` indicó que no existe una instalación registrada. Se creó una `.venv` local ignorada, sin paquetes externos, con el Python 3.12.14 disponible. Desde `.venv` se ejecutaron `-m unittest discover -s tests -p test_h1.py -v` (**21 PASS**), `h1_ingest.py --output work-private/h1-repro` y `verify_h1.py --output work-private/h1-repro --reference evidencias/publicables/h1-summary.json` (**33 PASS**). La referencia publicada no cambió. No se afirma haber probado Python 3.11 ni otro sistema operativo.

**Revisión:** búsqueda de rutas locales en archivos rastreados y candidatos no ignorados: 12 archivos, cero coincidencias; `git diff --check` sin errores. Se actualizaron ambas guías, el alcance de H1 en el informe y la planificación de H2; no se redactó el post-mortem. Sin staging, commit, push ni inicio de H2.

## Prompt importante 04 y ejecución de H2

**2026-10-04, Bogotá. Solicitud real resumida:** completar exclusivamente el diagnóstico Reto 1 usando H1; explicar cronología, causa con incertidumbre, disponibilidad de negocio frente a salud, señales y riesgos/pronóstico; correlacionar todas las fuentes, producir evidencias estables y pruebas, ejecutar dos veces, redactar post-mortem independiente máximo tres páginas y verificar renderizado. Sin Azure, commit/push ni H3.

**Herramientas y respuesta:** Codex, PowerShell, Python 3.12.14 y biblioteca estándar para consultas, cálculos y pruebas. Habilidad PDF consultada; ReportLab 4.4.9 y pypdf 6.10.0 disponibles para autoría/conteo, Poppler para renderizado y visor de imágenes para inspección real. No subagentes ni servicios Azure. Código generado: análisis H2, pruebas críticas, informes Markdown reproducibles y renderer PDF; catálogo E-001–E-009.

**Validación real:** H1 pasó 33 verificaciones antes del análisis; 33 pruebas unitarias (21 H1 y 12 H2) pasaron. Se ejecutó dos veces la versión final del análisis y se compararon hashes con la copia publicable: iguales. Indicadores generados: API 82617/84004 éxitos, salud 20101/20153; se documentó que son métricas por solicitud y no de tiempo. El contraste IIS/HTTPERR impidió presentar el 100% parcial de salud como resultado integrado.

**Incidencia real de generación:** el primer generador Markdown emitió `SyntaxWarning` por escapes de rutas relativas en un literal Python; se cambió a literal raw y se regeneró sin esa advertencia. No afectó las cifras ni fue un error causal del diagnóstico. Poppler emitió una advertencia sobre la fuente Symbol; ambos PNG se generaron y fueron inspeccionados sin caracteres rotos, recortes o solapamientos. No se inventan otras equivocaciones.

**PDF verificado:** dos páginas con texto extraíble, renderizadas por separado y vistas completas. Contenido ejecutivo sin código, hashes o instrucciones de parsing; referencias discretas a E-001–E-009. Datos derivados masivos y PNG solo en `work-private/`.

**Decisiones no delegadas:** aceptar alcance/denominadores de operaciones, comprobar zona de exportación de eventos/tickets, investigar caché con dumps/código, aprobar mitigaciones, autorizar H3 o commit/push. Confianza alta en mecanismo inmediato no equivale a defecto de código demostrado. Los escenarios de disco no se convierten en certeza.

**Integridad de cierre:** comparación SHA256 de los 18 originales contra el inicio de H2: sin cambios. Bases normalizadas y PNG permanecen ignorados. El resumen H1 y sus parsers no se modificaron.

## Corrección final de tipografía del post-mortem

**Solicitud real:** conservar el contenido aprobado de H2, corregir exclusivamente el renderizado con TrueType incrustada y redistribuible, comprobar `pdffonts`, inspeccionar las dos páginas, agregar relación hitos/retos y repetir pruebas y controles sin análisis, commit ni H3.

**Error real de la revisión anterior:** la primera inspección automática declaró correcto el PDF, pero una revisión independiente encontró tipografía no incrustada y renderizado visual defectuoso, con separación y colisión entre caracteres. La inspección visual inicial del asistente tampoco detectó ese defecto. El conteo de páginas y la extracción de texto no eran evidencia suficiente de corrección tipográfica.

**Corrección:** reemplazo de Helvetica por Bitstream Vera normal/negrita, TrueType distribuida con ReportLab; resolución relativa al paquete, sin rutas de fuentes del sistema. Licencia redistribuible incluida en `reto1-diagnostico/FONT_LICENSE.txt`. Se añadió una validación que rechaza fuentes sin FontFile2. Esta validación detectó inicialmente Helvetica residual del documento y obligó a configurar también la fuente inicial del documento, además del texto y el canvas.

**Validación final:** `pdffonts` de Poppler 26.09.0 confirmó BitstreamVeraSans-Roman y BitstreamVeraSans-Bold como TrueType, ambas `emb yes`, `sub yes`, `uni yes`; sin Helvetica. El paquete local inicial no incluía pdffonts: se obtuvo una copia adicional de Poppler únicamente en `work-private/`, excluida de Git. PDF de **2 páginas**, ambas renderizadas a PNG e inspeccionadas completas; sin letras separadas, superpuestas o cortadas, títulos y párrafos legibles. La comparación del texto extraído con el Markdown, excluyendo formato y pies, resultó idéntica; horas, cifras y referencias se conservaron.

Se repitieron las **33 pruebas (21 H1 + 12 H2), todas PASS**. No se ejecutó el análisis ni se regeneró el contenido Markdown; se preservaron diagnóstico, post-mortem fuente y catálogo aprobado. Solo se agregó al PLAN la tabla breve de correspondencia hitos/retos. Sin commit, push ni inicio de H3.

## Prompt importante 05: H3 autorizado y ejecutado localmente

**Solicitud real, 2026-10-04, resumida:** implementar solo modernización del mantenimiento; evaluar primero el BAT por riesgo y justificar cada operación con Reto 1; objetivo Windows PowerShell 5.1, compatibilidad 7 y Pester 5; validaciones, WhatIf, JSONL, errores/códigos, idempotencia, concurrencia, preservación y comprobación de resultados. Probar únicamente sandboxes/fixtures, sin BAT original, secretos, IIS, servicios, logs reales, dumps o recursos compartidos. Actualizar controles y detenerse para revisión, sin commit/push, H4 ni Azure.

**Herramientas y respuesta real:** PowerShell 5.1.26100.9444 y runtime PowerShell 7.6.5; Pester 5.7.1; Python de `.venv` para inspección redactada y agregación de resultados. Documentación oficial Microsoft ShouldProcess y Pester consultada. Sin subagentes. Evaluación previa, módulo, CLI, fixture JSON/generador, suite de 29 casos, runner, guía y evidencia revisada. Se eliminaron operaciones de servicios/red y se preservaron logs/dumps; limpieza limitada a temporales sintéticos explícitos, con manifiesto, hold, límites y bloqueo.

**Dependencia real:** solo Pester 3.4.0 estaba instalado. Descarga local de 5.7.1 desde PowerShell Gallery: primer intento de conexión falló en sandbox; repetición autorizada fuera de esa restricción descargó el paquete a `work-private/h3-tools/`. Importación de 5.7.1 comprobada. No se instaló globalmente ni se necesitó un sustituto de Pester.

**Incidencias reales y correcciones:**

1. La primera configuración Pester intentó crear su TestRegistry y el entorno negó acceso al registro; ningún test funcional se ejecutó. Se desactivaron TestRegistry y TestDrive: la suite no los necesita porque crea fixtures explícitos dentro del repositorio. No se amplió acceso al registro para ejecutar las pruebas.
2. La primera ejecución funcional pasó 24/26 casos. Un test de JSONL suponía que la intención era el segundo evento; había antes una omisión válida por orden de enumeración. Se corrigió para filtrar los eventos de eliminación y comprobar su orden relativo, preservando la comprobación de hash y resumen.
3. Otro test convirtió el stderr esperado por parámetro inválido del proceso hijo en excepción de Pester. Se aisló temporalmente la preferencia de errores del test y se comprobó el código real 1. Se añadieron validaciones CLI WhatIf, JSON malformado y raíz junction; ejecución final 29/29 en ambos motores.

Estas incidencias son errores de preparación/pruebas ocurridos, no fallos inventados del mantenimiento ni alucinaciones de un proveedor. No se probó producción.

**Comandos/método y resultados finales:** `tests/Run-H3Tests.ps1 -PesterManifest ./work-private/h3-tools/Pester-5.7.1/Pester.psd1 -Label ps51` desde 5.1 y el mismo runner con `-Label ps7` desde 7.6.5: **29 PASS, 0 FAIL, 0 SKIP por motor**. Invocación de 7 mediante ruta local del runtime no publicada en los comandos portables. Reportes privados `work-private/h3-results/ps51.json` y `ps7.json`; agregación revisada en `evidencias/publicables/h3-tests.json`, con versiones, timestamps y resultado por caso.

**Validaciones reales:** snapshot WhatIf igual en estructura, SHA256 y LastWriteTimeUtc (módulo y CLI), sin log ni adquisición del lock. Eliminación del temporal vencido permitido; recientes/no listados/dumps/logs preservados por hash; repetición sin segunda eliminación. Fallo de permiso simulado, fallo parcial y falsa eliminación detectados. Segundo proceso propietario del lock y liberación comprobados. JSONL parseable, intención previa al éxito y resumen conciliado. Códigos 0–5 comprobados en procesos; 3 también con temporal sintético bloqueado y 5 con lock sintético de solo lectura. Los 18 originales mantienen sus hashes; H1/H2 y sus evidencias no se modificaron.

**Tiempo parcial medido:** 02:48:27.886–03:09:45.904 Bogotá, 21 min 18 s de tiempo transcurrido observado; no incluye lectura anterior ni cierre documental posterior y no es esfuerzo total. Límite H3: 3 h, sin ampliación.

**Decisiones humanas pendientes:** aceptar alcance restringido a laboratorio, 14 días provisionales y manifiesto de temporales; preservar/archivar evidencia; retirar credencial del entorno real con autorización propia; evaluar producción/ACLs y carreras. H3 queda para revisión; no commit/push, H4 ni Azure.

**Revisión final real:** se añadió el nombre relativo a las omisiones del log y el detalle de candidatos en WhatIf; ambas suites se repitieron con 29/29 PASS y se renovó la evidencia con hashes SHA256 de los seis artefactos ejecutables/de fixtures. `git diff --check` y comprobación de whitespace de archivos nuevos: correctos; enlaces locales H3 válidos. Escaneo literal de la credencial conocida en archivos rastreados/candidatos no ignorados: cero coincidencias; búsqueda de rutas personales: cero. Esto no certifica ausencia universal de secretos desconocidos. Índice y H1/H2 sin cambios; 18 originales intactos. Exclusiones de dependencias, resultados crudos y sandboxes verificadas con `git check-ignore`. README raíz actualizado para evitar describir H3 como no iniciado. No se hizo staging, commit ni push.

## Prompt importante 06: aplicabilidad operativa de H3

**Solicitud real resumida:** corregir el límite de rutas embebido que impedía instalar el módulo sin editarlo; mantener protecciones y operaciones excluidas, configuración versionable sintética y plantilla WEB-PAGOS-01 sin secretos, esquema/rutas exactas/marcador, guía conceptual de Task Scheduler, pruebas exclusivamente sintéticas en 5.1 y 7. No ejecutar producción, hacer commit ni iniciar H4.

**Corrección real señalada por el usuario:** el diseño inicial restringía correctamente las pruebas, pero también impedía desplegar el mismo módulo. Se separó autorización de rutas en JSON `h3.routes.v1`: `ConfigurationPath` obligatorio, raíz exacta, esquema cerrado, modo laboratorio/despliegue, host y marcador. La plantilla queda `enabled=false`. Se conserva la validación de volumen fijo, rechazo de rutas inseguras y enlaces, límites, manifiesto, hold, ShouldProcess, concurrencia y auditoría. Se revalida configuración/marcador antes de cada eliminación.

**Ejecuciones reales:** nueve casos nuevos de configuración y las 29 pruebas anteriores: **38/38 PASS en Windows PowerShell 5.1.26100.9444 y 7.6.5**, Pester 5.7.1. Se repitieron tras comprobar volumen local antes de acceder a configuración/raíz y endurecer revalidación del marcador. No hubo fallos nuevos de tests en este ajuste; no se inventan errores. La rama de despliegue se ejercitó con una configuración distinta generada para archivos sintéticos y el host local; la plantilla WEB-PAGOS-01 solo se leyó como datos, nunca se pasó al módulo/CLI. WhatIf volvió a mantener iguales los snapshots.

**Documentación consultada y entregada:** Microsoft Learn sobre New-ScheduledTaskPrincipal y cuentas de servicio; referencias en la guía. Instalación conceptual con identidad de servicio de mínimo privilegio, sin contraseña en argumentos, ACLs para código/configuración/manifiesto/marcador, tarea inicialmente deshabilitada y primera ejecución WhatIf. Activación real exige aprobación y validación en Windows Server; no se registró tarea ni identidad.

**Límites:** configuración y argumentos de tarea son parte del límite de confianza y requieren protección administrativa. El script no prueba esas ACLs ni elimina carreras con escritores ajenos. La ruta de ejemplo de despliegue es ilustrativa, no una ruta personal o verificada del servidor. No se ha medido de forma completa el esfuerzo adicional; no se inventa duración ni se amplía el máximo del hito. Sin commit/push, H4 o Azure.

**Controles finales de esta revisión:** evidencia H3 actualizada con las dos ejecuciones de 38 casos y hashes de ocho artefactos/configuraciones. Escaneo de la credencial conocida en rastreados/candidatos: cero coincidencias; rutas personales: cero. La ruta local ilustrativa de WEB-PAGOS-01 es intencional y no corresponde al equipo del desarrollador. Plantilla inspeccionada con ocho campos permitidos, desactivada y sin campos de cuenta, secreto, recurso compartido o acciones. Los 18 originales, H1/H2 e índice siguen intactos. `git diff --check`, whitespace de nuevos archivos y enlaces locales H3 correctos.

## Aprobación y comprobación previa al commit de H3

Solicitud real del usuario: H3 aprobado; repetir comprobaciones finales y crear únicamente `feat: add configurable safe PowerShell maintenance`, sin push, H4 ni Azure. El registro de aprobación quedó en decisiones y bitácora; una revisión posterior detectó que PLAN y README seguían pendientes, corregido en la conciliación documental descrita abajo.

Se ejecutó nuevamente `tests/Run-H3Tests.ps1` con Pester 5.7.1 en Windows PowerShell 5.1.26100.9444 y PowerShell 7.6.5: **38/38 PASS por motor**, cero fallos u omisiones. Reportes adicionales privados con etiquetas `final-ps51` y `final-ps7`; los hashes de los ocho artefactos coinciden con la evidencia publicable existente. La plantilla WEB-PAGOS-01 sigue desactivada. Exclusión de `input-private/` y `work-private/` comprobada; inventario candidato sin datos privados ni temporales. Búsqueda literal de credencial conocida en archivos/índice/historial alcanzable y reflogs: cero coincidencias; rutas personales en rastreados/candidatos: cero. No garantiza ausencia universal de otros secretos ni cubre objetos inalcanzables. `git diff --check` correcto.

## Conciliación documental de H3

Solicitud real: registrar H3 aprobado en PLAN/README, corregir caracteres dañados de la aprobación y crear un commit documental separado; presentar H4 concretado sin desplegar. Error real anterior: la escritura de texto a través del shell sustituyó acentos por signos de interrogación y varias sustituciones de estado no se aplicaron. Se corrigen mediante edición UTF-8, sin cambiar código, pruebas ni evidencia técnica aprobada. El diseño H4 se presenta en conversación; no se crean recursos ni se ejecuta Azure. La aprobación conceptual no equivale a autorización de despliegue.

## Prompt importante 07: preparación local de H4

**Validación de la corrección presupuestaria:** repetidas 50/50 pruebas por motor 5.1 y 7.6.5, cero fallos/omisiones; evidencia local renovada con hashes. Regenerados los dos ZIP vigentes: 9 y 2 miembros, idénticos a fuentes; configuración interna USD 15, marcadores y ejemplos desactivados. Inspeccionadas en memoria las seis copias ZIP de las tres generaciones: cero coincidencias de secreto conocido, rutas personales, correos, URLs webhook o IDs de suscripción reales; sin miembros de evidencia privada. Generaciones anteriores obsoletas. Escaneo de 61 archivos candidatos/índice sin coincidencias de credencial conocida ni rutas personales, originales 18/18 intactos, exclusiones e índice conservados, diff --check correcto. No se cambió código de recuperación ni pruebas; solo política presupuestaria/documentación y evidencia derivada. Sin Azure, commit ni push.

**Corrección posterior solicitada:** el usuario rechazó el importe presupuestario anterior y fijó **USD 15**, distinguiéndolo del posible crédito Student. Las referencias y el resumen de alcance de este registro se actualizan al importe vigente; esto no afirma que ese fuera el importe del mensaje inicial ni que se hubiera creado presupuesto alguno. Se agregan alertas reales 10/50/80/100 %, pronosticada 80 % o 100 % si disponible, marcador de destinatario, demora de datos y eliminación del RG el mismo día como contención principal. Se mantiene ámbito suscripción por la puerta previa al RG y cobertura de gastos fuera, con atribución separada por RG. ZIP opcionales e inventario exacto documentados; regeneración y revisión solicitadas, sin Azure ni commit/push.

**Revisión final tras la solicitud de continuar:** paquetes regenerados con la versión final; los nueve archivos de H4Guest.zip y los dos de H4SafeAutomation.zip coinciden por SHA256 con sus fuentes. Ambos ZIP permanecen ignorados. `git diff --check` correcto, índice sin cambios y ningún diff en H1/H2/H3 técnico. Resumen de revisión: 27 archivos nuevos y cuatro Markdown de control modificados; diff completo local en `work-private/h4-results/review.diff`.

**Solicitud real resumida, 2026-10-04:** diseño aprobado; East US, Windows Server 2022/B2s pendiente de precio/cuota, techo preventivo USD 15 con cuenta Student, eliminación el mismo día tras evidencia, webhook temporal aceptado sin URL registrada, correo manual y ningún secreto compartido. Crear solo scripts, KQL, runbook, rol, guía Portal y plantilla; probar webhook/destinos/estados/duplicados/intentos/HTTP sintéticamente, revisar permisos Run Command y detenerse antes de Azure, commit/push.

**Trabajo y fuentes:** releídos controles y párrafos OOXML 63–72 del enunciado. Árbol inicial limpio, H3 df48a58 y conciliación e66c348. Documentación oficial Microsoft de CAS, Run Command/cmdlet/REST, webhooks, módulos Automation, diagnósticos, AMA/DCR, tablas y presupuestos; enlaces en guías. Intentos de consultar fuente pública del SDK en GitHub no recuperaron el archivo: no se afirma auditoría del SDK. Sin subagentes, SDK Azure real, IIS, tareas del equipo ni HTTP real de pruebas. Stubs/mocks con nombres Az simulan la integración.

**Resultados reales:** Pester 5.7.1, **50/50 PASS por motor**, cero fallos/omisiones, Windows PowerShell 5.1.26100.9444 y 7.6.5. `tests/Run-H4Tests.ps1`, mismo Pester privado de H3, etiquetas ps51/ps7; reportes en `work-private/h4-results/`. WhatIf conserva SHA256/LastWriteTimeUtc y no llama adaptador de inicio. Pool/HTTP y permiso denegado son simulados. PowerShell parseado en ambos motores; rol sin comodines ni Contributor. ZIP locales generados con Build-H4Package, sin carga a servicios.

**Errores reales corregidos:**

1. El harness reutilizó la variable automática `$args`, sustituida por Pester con argumentos internos; el stub Identity tampoco era switch. Primera ejecución 32/48 PASS. Se renombró la variable y tipó el switch; nunca se ejecutó cmdlet Az real.
2. Measure-Object de colección vacía bajo StrictMode no ofrecía Sum; luego `$null` a File.Replace desde 5.1 se convertía en ruta vacía. Se corrigió con acumulador explícito y `[NullString]::Value`; después 48/48 en 5.1, sin omitir persistencia.
3. Primera prueba 7.6.5: 45/48; ConvertFrom-Json convertía timestamp ISO a DateTime y rompía validación textual UTC. Se detecta DateKind para conservar texto en 7.5+; 5.1 mantiene alternativa sin ese parámetro. Después 48/48; dos nuevos casos de escalamiento/éxito HTTP falso llevaron a 50/50 finales por motor.
4. Parches documentales agrupados con contexto incompleto fueron rechazados. Se inspeccionó el diff y aplicó cada sección con contexto exacto; no se asumieron cambios que no estaban presentes.

Son errores observados de código/harness/edición, no fallos inventados de Azure. KQL/Kusto, RBAC efectivo, Server/IIS, ACL, módulos Az gestionados, ingestión, correo, dashboard y recuperación real siguen sin probar. H4 preparado localmente para revisión, Reto 3 sin cerrar, sin H5.

**Controles:** cero coincidencias de secreto conocido en archivos candidatos e índice y cero rutas personales; 18 originales conservan hashes iniciales. H3/entregables técnicos previos intactos. Ejemplos desactivados con suscripción/correo/webhook como marcadores, GUID solo en fixture sintético. ZIP/dependencias/sandboxes ignorados; índice preservado, sin commit/push. Advertencia de ignore global sin modificación; exclusiones locales comprobadas. El escaneo no certifica ausencia universal de secretos desconocidos.

**Medición parcial:** reloj observado 10:10:29–10:29:00 America/Bogota, 18 min 31 s; excluye lectura anterior y cierre posterior. No es tiempo total del hito ni amplía máximo 5 h/20 h globales.

**Decisión humana pendiente:** presupuesto manual confirmado, saldo/precio/cuota, revisión del privilegio SYSTEM indirecto y autorización de despliegue. Ante permiso faltante, registrar operación/alcance redactados y esperar aprobación. Aceptar webhook temporal no autoriza todavía crearlo.

## Continuación manual de H4: red y preparación de VM, 2026-10-04

**Hechos declarados por el usuario:** el presupuesto fue creado. La política de Azure for Students rechazó East US y enumeró regiones permitidas; B2s no estuvo disponible para esta suscripción en Canada Central ni North Central US. En North Central US, Portal mostró `Standard_B2als_v2` con 2 vCPU, 4 GiB y USD 34,16/mes. Se creó `law-h4-test` Pay-as-you-go; la vista de costos mostró 0,00 GB y USD 0,00 antes de ingerir datos. El workspace previo `law-h4` fue eliminado por el usuario. También se declararon activos `nsg-h4`, `vnet-h4`/`snet-h4` privada, `pip-h4` Standard y `nic-h4`, con asociaciones `snet-h4 → nsg-h4` y `pip-h4 → nic-h4/ipconfig1`. No se copiaron al repositorio los identificadores ni la dirección IP compartidos durante la navegación.

**Cambio local:** se sustituyeron los valores operativos de workspace/región/tamaño por `law-h4-test`, North Central US y `Standard_B2als_v2`, preservando como historia las decisiones iniciales. Se creó `arm/vm-h4.json` para una sola VM `vm-h4-iis` que referencia la NIC existente. La plantilla exige usuario y `secureString` sin valores predeterminados; fija Windows Server 2022 Azure Edition, Trusted Launch, identidad administrada y disco Standard SSD. Azure debe crear el disco administrado junto con la VM; por eso la próxima autorización debe abarcar ambos. No hay extensiones ni recursos de red en la plantilla.

**Pruebas reales:** 53/53 PASS con Pester 5.7.1 en Windows PowerShell 5.1.26100.9444 y 53/53 PASS en PowerShell 7.6.5. El primer intento de invocar `pwsh` por nombre falló porque no estaba en `PATH`; se repitió con el ejecutable 7.6.5 del runtime local y aprobó. Las tres pruebas nuevas validan la frontera de un único recurso declarado, NIC existente, identidad/tamaño/imagen/disco exactos y ausencia de credenciales predeterminadas. Son verificaciones sintácticas/estructurales; Azure no validó ni ejecutó el template. No se hicieron llamadas Azure, commit ni push.

**Puerta siguiente:** revisar y aprobar explícitamente el despliegue conjunto de la VM y su disco administrado. Si la validación de Azure rechaza API, imagen, Trusted Launch, cuota o referencia a la NIC, detenerse y documentar el error antes de modificar el alcance.

## Prompt importante 08: ejecución y evidencia real de H4

**Solicitud real resumida, 2026-10-05:** guiar la configuración manual de ingestión, alertas, Automation, falla controlada, remediación y Workbook; luego indicar capturas y confirmar si Reto 3 terminó. El usuario ejecutó Azure Portal y compartió únicamente resultados necesarios. No se usó CLI/SDK Azure desde el agente.

**Resultado observado:** las tablas `Event`, `Heartbeat`, `Perf` y `W3CIISLog` ingirieron datos. La alerta A detectó fallos 503 consecutivos y activó el runbook. El job terminó `Completed`, pero el éxito se aceptó solo por salida `Recovered`, HTTP 200, `H4_OK` y primer sondeo sano posterior. La alerta B entregó correo humano. El Workbook contiene vistas separadas Dirección/NOC. Costo evaluado visible: USD 0,06; presupuesto USD 15.

**Incidencia real y corrección:** el script de falla lanzó `StopNotVerified` porque consultó inmediatamente el estado asíncrono del pool. La comprobación posterior mostró `Stopped` y HTTP 503. Se corrigió localmente con sondeo acotado de 15 segundos y pausa de 250 ms, conservando fallo cerrado. Pester 5.7.1: **55/55 PASS** en Windows PowerShell 5.1.26100.9444 y PowerShell 7.6.5, cero fallos u omisiones. El primer intento de invocar `pwsh` por nombre falló al no estar en PATH; se repitió con el ejecutable local conocido y aprobó.

**Revisión de evidencia:** ocho capturas quedaron aprobadas o aprobadas con límite. Cuatro se movieron a `evidencias/private/h4/capturas-originales/` porque exponían identificadores o fragmentos de destinatarios; deben sustituirse antes de versionar. No se desactivan alertas por decisión del usuario. La política y el webhook sí quedaron deshabilitados. Falta autorización explícita para eliminar y verificar recursos; sin commit/push ni inicio de H5.

**Revisión posterior:** las cuatro capturas sustitutas se inspeccionaron nuevamente después de aumentar la cobertura. Ya no se distinguen caracteres de Job ID, incidente, destinatarios ni Object ID. Se renombraron a sus nombres finales y, junto con la captura adicional de configuración de alerta A, completan trece PNG públicos revisados. Puntos negros aislados son artefactos visuales sin contenido. El material rechazado permanece privado. Continúan pendientes autorización de commit y limpieza de Azure.
