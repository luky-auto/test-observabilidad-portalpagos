# Workbook para dirección y NOC

Artefacto de diseño local; no existe dashboard desplegado. En Portal → Monitor → Workbooks → New, seleccionar exclusivamente `law-h4-test`, ventana una hora y mostrar UTC. Guardar como `wb-h4-observabilidad` en RG del laboratorio. Agregar título visible **Laboratorio / disponibilidad desde la VM, no extremo a extremo**.

| Público | Panel / consulta | Interpretación |
|---|---|---|
| Dirección | Tiles de KQL 01: disponibilidad observada, cobertura, minutos fallidos y desconocidos | Publicar disponibilidad junto con cobertura; si no hay muestras, null y Unknown |
| Dirección | Tendencia de 5xx y p95 de KQL 02 | Son peticiones del sitio sintético, no transacciones de pagos |
| Dirección | Texto de último ensayo y estado de recuperación | Completar con medición de evidencia; no precargar éxito |
| NOC | KQL 06: última ingestión por fuente y CPU/memoria/disco | Señalar fuente ausente o atrasada; distinguir muestra de sondeo de log IIS |
| NOC | KQL 03: cronología de eventos del pool | Abrir detalle para corroborar evento, no inferir causa solo por correlación |
| NOC | KQL 04 y 05: condición A, jobs fallidos/intentos agotados | JobId y timestamp para correlación, sin URL de webhook |
| NOC | Texto de runbook y salvaguardas | Pool exacto, dos intentos, cuándo detenerse y escalar |

En cada panel, ejecutar consulta en Logs primero, guardar visualización adecuada (tiles, timechart, tabla) y registrar ventana, filtros y estado sin datos. Probar tablero antes/durante/después del fallo; exportar JSON del Workbook a carpeta privada, revisar identificadores y recursos y después redactar copia publicable. No afirmar Workbook probado por tener esta especificación.
