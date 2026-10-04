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
