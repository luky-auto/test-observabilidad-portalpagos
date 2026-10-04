# Calidad y evidencia observadas en H1

Resultados de ejecuciones locales del 3 de octubre de 2026, hora de Bogotá. H1 cubre únicamente ingesta, normalización y calidad de datos; **no completa el Reto 1** ni diagnostica el incidente. Fuente de cifras: [h1-summary.json](../evidencias/publicables/h1-summary.json), generado por `h1_ingest.py` y contrastado con SQLite mediante `verify_h1.py`.

El post-mortem es un entregable futuro independiente de este informe y de los README: fuente `reto1-diagnostico/POSTMORTEM.md` y versión final `reto1-diagnostico/POSTMORTEM.pdf`, con un máximo de 3 páginas verificadas. No se redacta en esta etapa.

## Conteos reconciliados

| Fuente | Registros antes | Copia excluida | Conservados | Cuarentena |
|---|---:|---:|---:|---:|
| IIS (9 archivos, 8 únicos) | 191838 | 25882 | 165956 | 0 |
| HTTPERR | 1542 | 0 | 1542 | 0 |
| Eventos | 498 | 0 | 498 | 0 |
| Perfmon | 2016 | 0 | 2016 | 0 |
| Tickets | 8 | 0 | 8 | 0 |
| Log de mantenimiento | 30 | 0 | 30 | 0 |
| **Total** | **195932** | **25882** | **170050** | **0** |

Los 170050 conservados se dividen en **170020 con fecha dentro de la semana**, **30 sin fecha** y **0 fuera de la ventana**. Comentarios, encabezados y líneas vacías se cuentan separadamente en el inventario; no se presentan como eventos de datos. Aceptado significa estructuralmente utilizable bajo el contrato, no completo ni verdadero.

## Hechos de calidad y su evidencia

Todas las rutas de origen de esta sección son relativas a `input-private/kit_prueba_portalpagos/`. El JSON incluye SHA256, tamaño, rangos y localización de los esquemas de cada archivo.

| Hecho observado | Evidencia y regla | Tratamiento |
|---|---|---|
| Copia exacta del archivo IIS del 16, con 25882 filas de datos | `logs/iis/W3SVC2/u_ex260916 - copia.log` y `u_ex260916.log`; mismo SHA256 en `files`; R02 | Se carga una vez el original canónico. La copia permanece intacta, inventariada con `duplicate_of` |
| El esquema cambia de 15 a 17 campos dentro del archivo del 17 | `logs/iis/W3SVC2/u_ex260917.log`, encabezados en líneas 4 y 2351; R03. Aparecen `cs-host` y `X-Forwarded-For` | Se interpreta cada bloque con su encabezado; no se desplazan columnas ni se rellena un host/IP inexistente |
| Hay 13 valores de memoria privada de w3wp representados por espacio | Perfmon, líneas **332, 364, 512, 813, 847, 884, 1330–1334, 1535, 1618**; R06; `quality.warning_references` | `null` con advertencia por campo; conservar las 2016 muestras y sus demás contadores |
| La cadencia de Perfmon tiene 2016 timestamps únicos, con diferencias de 300 segundos | `quality.metric_cadence`; comparación del conjunto temporal con la semana local; R08 | 0 slots ausentes y 0 inesperados. No equivale a que todos los contadores estén presentes |
| HTTPERR incluye un registro sin método, URI ni estado HTTP | `logs/httperr/httperr1.log`, línea **1546**, motivo Timer_ConnectionIdle; R06 | Conservar como registro sin petición HTTP completa; excluir únicamente del matching de peticiones, no de la carga |
| El log de mantenimiento tiene 30 líneas iguales sin timestamp | `scripts/mantenimiento.log`, líneas 1–30; R09 y R11 | Conservar 30 registros no temporales. 1 grupo repetido, 29 filas adicionales candidatas; no inferir 30 ejecuciones ni éxito |
| No hay filas normalizadas idénticas en otras fuentes tras quitar la copia | `quality.same_source_candidates_retained`; R09 | No se eliminan filas individuales |
| No hay coincidencias IIS/HTTPERR bajo la clave definida | `quality.cross_source_candidates_retained`: 0 pares; R10 | No demuestra inexistencia absoluta de duplicados; faltan identificadores globales y la clave exige el mismo segundo |
| El archivo IIS fechado el 21 aporta 1247 registros de la noche local del 20 | `files` para `u_ex260921.log`: 19:00:05–23:59:57 Bogotá; R07–R08 | Se incluye. Filtrar por nombre del archivo perdería parte de la semana |

Los tickets de líneas 5 y 6 indican en su cierre que se refieren al ticket de línea 7. Eso relaciona reportes, no demuestra duplicidad de filas ni identidad con una petición IIS; se conservan los ocho tickets. No se usa una nota de cierre como fuente de verdad del incidente.

## Contrato temporal y contraste

**Hecho del formato:** Microsoft especifica que los timestamps de registros **IIS W3C Extended** son UTC, independientemente de `localTimeRollover`; la rotación y el nombre del archivo son otro asunto. [Documentación oficial de IIS](https://learn.microsoft.com/en-us/iis/configuration/system.applicationhost/sites/site/logfile/), consultada en esta etapa.

**Hecho del formato:** HTTP Server API documenta fechas y horas en UTC para sus logs de error. El kit además proporciona `#Fields`, que se respeta. [Documentación oficial de HTTPERR](https://learn.microsoft.com/en-us/windows/win32/http/format-of-the-http-server-api-error-logs).

**Hechos del kit:** el LEEME declara Bogotá UTC-05; Perfmon identifica `SA Pacific Standard Time(300)` en la primera columna. Eventos y tickets tienen fechas sin offset. Su zona no está codificada de forma verificable en cada registro.

**Contraste reproducible**, no línea de tiempo del incidente: `temporal_contrast` toma el primer AppOffline y compara el evento WAS 5002 más cercano bajo las dos interpretaciones. El resumen conserva referencias, sin copiar mensajes completos:

| Fuente y referencia | Tiempo original | Interpretación evaluada |
|---|---|---|
| HTTPERR línea 5 | 2026-09-18 19:38:00 | UTC por formato → 14:38:00 Bogotá |
| IIS del 18, línea 27228 | 2026-09-18 19:37:59 | UTC por formato → 14:37:59 Bogotá; registro temporal más cercano, sin afirmar identidad |
| Eventos línea 366 | 2026-09-18 14:38:05 | Si es Bogotá, queda 5 s después del ancla; si es UTC, queda 17995 s antes |
| Perfmon línea 1330 | 09/18/2026 14:40:00.000 | Zona de cabecera → 19:40 UTC; muestra más cercana, con memoria privada ausente |
| Tickets líneas 6 y 7 | 2026-09-18 14:26 y 14:42 | Bajo supuesto Bogotá quedan dentro de ±30 min del ancla |

**Supuesto operativo explícito:** eventos y tickets se interpretan provisionalmente como Bogotá, por LEEME y compatibilidad temporal. Todas sus filas llevan `timezone_assumed_bogota`. La proximidad de reportes y eventos apoya esa lectura, pero no prueba zona, sincronización del reloj, identidad de eventos ni causalidad. No se declara confirmada una caída o recuperación por esta consulta.

Se usa offset fijo **UTC-05 para la semana de septiembre de 2026**, identificado como America/Bogota. El código no depende de la zona del equipo. No es una biblioteca general para datos históricos o cambios de zona: otro periodo requiere revisar el contrato. No se ordena ni se recorta por nombre de archivo.

## Rangos observados

| Fuente | Primer registro Bogotá | Último registro Bogotá |
|---|---|---|
| IIS | 2026-09-14 00:00:01 | 2026-09-20 23:59:57 |
| HTTPERR | 2026-09-18 14:38:00 | 2026-09-19 02:02:11 |
| Eventos (zona supuesta) | 2026-09-14 01:11:24 | 2026-09-20 23:40:52 |
| Perfmon | 2026-09-14 00:00:00 | 2026-09-20 23:55:00 |
| Tickets (zona supuesta) | 2026-09-16 08:40:00 | 2026-09-20 09:15:00 |
| Mantenimiento | No determinado | No determinado |

Consulta: la agrupación por fuente emitida por `verify_h1.py`; detalle por archivo en `files.first_ref/last_ref` del JSON. Los rangos no demuestran cobertura continua de logs ni disponibilidad del portal.

## Validación real y límites

- **21 pruebas sintéticas: PASS**, ejecutadas con `python -m unittest discover -s tests -p test_h1.py -v` usando el ejecutable documentado.
- **Dos cargas completas de la versión final: PASS**, en `work-private/h1` y `work-private/h1-repro`, con los mismos conteos.
- **33 verificaciones independientes: PASS** en `verify_h1.py --output work-private/h1-repro --reference evidencias/publicables/h1-summary.json`: integridad SQLite, conteos globales y por archivo, hashes de los 14 archivos del contrato e igualdad byte a byte con la referencia.
- SHA256 del resumen reproducible: `9aa56a99c0cf0e9b8d078f87840f26f05b6a310b6346b9b9be6570adc2c95c3f`.
- No hay cuarentena en estos originales; los tests sí prueban rechazo de datos sintéticos defectuosos. No se detectaron retrocesos temporales por archivo ni errores de cardinalidad/UTF-8 bajo este contrato.

**No determinados:** zona exacta de exportación de eventos/tickets; razón de los contadores ausentes; existencia de fuentes no entregadas; correspondencia unívoca entre registros de diferentes fuentes; tiempos del mantenimiento. Las posibles explicaciones son hipótesis para H2, no resultados de H1.

No se inspeccionó ni ejecutó el BAT en H1. No se generó diagnóstico, infraestructura ni llamadas pagadas. La base privada contiene detalle de entrada necesario para trazabilidad y nunca debe agregarse a Git.
