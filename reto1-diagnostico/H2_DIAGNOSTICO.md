# Diagnóstico técnico del Reto 1

## Conclusión y alcance

El viernes 18 de septiembre el portal sufrió degradación de confirmación de pagos, errores de memoria y terminaciones del proceso; el pool fue deshabilitado y HTTPERR registró rechazo de solicitudes. El mecanismo inmediato está respaldado con confianza alta. Una retención excesiva de memoria en la caché de sesiones introducida o agravada por el despliegue es una **hipótesis de alta confianza**, no un defecto de código demostrado. No hay dumps analizados, código de aplicación ni prueba controlada de reversión. [E-003, E-004, E-005]

El diagnóstico reutiliza SQLite de H1 en modo solo lectura, verifica sus conteos contra el manifiesto y se ejecuta después de `verify_h1.py`. No reingiere logs. Solo el BAT, excluido de H1, se inspecciona mediante patrones que exportan referencias y booleanos; no se ejecuta ni se copia su texto. Ninguna acción correctiva propuesta aquí está implementada.

## Catálogo y reproducción de evidencia

Fuente compacta: `evidencias/publicables/h2-evidence.json`. Los IDs son estables por pregunta, no por orden accidental de filas. Contiene reglas, resultados, timestamps y referencias a archivo/línea; las rutas de entrada son relativas al kit privado. Los detalles de cada consulta están en `h2_analyze.py`; su consulta base y el hash del resumen H1 figuran en el JSON. No se publican identidades, IP, parámetros ni mensajes completos.

| ID | Pregunta | Regla reproducible |
|---|---|---|
| E-001 | Disponibilidad observada por peticion | IIS+HTTPERR, in_week=1; APIs whitelist; success=HTTP 200..399 y Win32 0 o no disponible. No deduplicar fuentes; R10 H1 no encuentra pares. |
| E-002 | Ventanas de cinco minutos | 2016 ventanas semiabiertas; sin peticiones=unknown; todos 5xx=failed; algun 5xx=degraded; resto=no_5xx_observed. No convertir ausencia a caida. |
| E-003 | Transiciones del viernes | Confirmacion: 3 ventanas consecutivas con n>=10 y p95>2000ms; separar primer 5xx diario del primer 5xx de confirmar. AppOffline delimita evidencia de caida; primera API 2xx/3xx posterior delimita recuperacion. |
| E-004 | Eventos correlacionados | Filtros por ProviderName/Id y presencia literal OutOfMemoryException; no publicar mensajes o identidades. |
| E-005 | Memoria y señales tempranas | Min/max/cierre diario Perfmon; primer Private Bytes>=1GiB (umbral analitico); p95 nearest rank por dia confirmar. |
| E-006 | Riesgo de disco y extrapolacion condicional | OLS espacio libre MB contra horas, ultimas 24/48/72/96h; anclar proyeccion al ultimo MB observado; sin limpiezas, cambios de carga ni de logging. Sensibilidad, no intervalo probabilistico. |
| E-007 | Mantenimiento y trazabilidad | Inspeccion estatica por patrones del BAT, sin ejecutarlo ni serializar lineas. Confrontar R11 H1 y E-004 task/reset/storage_move/dump_report. |
| E-008 | Reportes humanos | Tickets conservados sin asumir que notas de cierre prueban causalidad. |
| E-009 | Sondeos de rutas ajenas a la aplicacion | Excluir estas rutas del indicador API; no inferir intrusion ni DDoS solo de peticiones. |

## Cronología en America/Bogota

IIS y HTTPERR se convierten desde UTC conforme al contrato H1. Eventos y tickets conservan el supuesto UTC-05, no confirmado por configuración de exportación. Los segundos entre fuentes no deben interpretarse como un reloj perfectamente sincronizado.

| Momento del 18 | Evidencia | Experiencia y límite |
|---|---|---|
| 00:02:09 | E-003, primer 5xx API del día | Error de fondo anterior al episodio de confirmación; no confundirlo con el comienzo causal del incidente |
| 11:50:00 | E-003, primera de tres ventanas consecutivas con p95 > 2000 ms y al menos 10 confirmaciones | Aumento sostenido de espera; detectable al cerrar la tercera ventana a 12:05:00 |
| 13:23:45 | E-003, primer 5xx de confirmar del viernes, IIS línea 24043 | Empieza evidencia HTTP de fallos de confirmación; no demuestra cobros perdidos o duplicados |
| 13:24:19 | E-004, excepción de memoria | La traza señala la operación de agregar una sesión de pago a caché |
| 13:34 | E-008, ticket T-10252 | Usuario reporta error al confirmar pago |
| 14:22:12 | E-004, primera terminación .NET por memoria | Fallos del proceso; luego hay más terminaciones y eventos WAS |
| 14:38:00 | E-003, HTTPERR línea 5 | Rechazos 503 AppOffline; la petición no llega a IIS |
| 14:38:05 | E-004, WAS 5002, línea 366 | Pool deshabilitado tras fallos. El desfase de 5 s respecto a HTTPERR impide ordenar causalmente esos segundos |
| 14:42 | E-008, ticket T-10255 | Reporte humano de Service Unavailable |
| 15:04:00 | E-003, primera API exitosa posterior, IIS línea 27229 | Recuperación observada; coincide con la hora de reinicio indicada en el ticket, no con un evento de auditoría independiente |

AppOffline abarca 1541 registros, desde 14:38:00 hasta 15:03:59; la primera respuesta API exitosa siguiente delimita un intervalo aproximado de **26 minutos**. En los 30 minutos desde la recuperación hay 1060 solicitudes API, 5 errores 5xx y p95 IIS 701 ms. Recuperación no equivale a ausencia total de errores ni corrección definitiva. [E-003]

El inicio de degradación depende de un umbral analítico, no de un SLO previamente acordado. E-003 incluye sensibilidad a 1500/2000/3000 ms; el método detecta una transición con confirmación posterior, no adivina el instante interno en que comenzó el defecto. Percentil por rango más próximo, sin interpolación; mínimo de muestra explícito.

## Disponibilidad semanal y límites

Ventana: 14 de septiembre 00:00 inclusive a 21 de septiembre 00:00 exclusiva, Bogotá. Indicador principal: **porcentaje de solicitudes observadas con respuesta HTTP 200–399 y sin error Win32 conocido**, sobre todas las solicitudes de las cinco rutas API listadas abajo. HTTPERR no suministra Win32; conserva su estado HTTP. Un 200 no certifica éxito financiero extremo a extremo. Se suman IIS y HTTPERR porque H1 no encontró candidatos bajo R10; sin ID de petición no puede probarse ausencia universal de duplicidad. [E-001]

**Operaciones API: 82617/84004 = 98.349%; 1387 fallos 5xx.** No es porcentaje de tiempo ni de usuarios afectados. Se excluyen /health, recursos estáticos, rutas de escaneo, portada y login para no inflar el resultado con tráfico que no demuestra ejecución de operaciones. La selección es una definición analítica explícita, no una medición completa de todos los recorridos de usuario.

| Operación | Solicitudes | 5xx | Éxito HTTP |
|---|---:|---:|---:|
| /api/movimientos | 25020 | 459 | 98.165% |
| /api/pagos/confirmar | 11730 | 250 | 97.869% |
| /api/pagos/iniciar | 13223 | 254 | 98.079% |
| /api/reportes/extracto | 4469 | 44 | 99.015% |
| /api/saldos | 29562 | 380 | 98.715% |

| Día | Solicitudes API | 5xx | Éxito HTTP |
|---|---:|---:|---:|
| 2026-09-14 | 13073 | 30 | 99.771% |
| 2026-09-15 | 12348 | 21 | 99.830% |
| 2026-09-16 | 13070 | 16 | 99.878% |
| 2026-09-17 | 14389 | 26 | 99.819% |
| 2026-09-18 | 21596 | 1286 | 94.045% |
| 2026-09-19 | 5833 | 5 | 99.914% |
| 2026-09-20 | 3695 | 3 | 99.919% |

**/health integrado: 20101/20153 = 99.742%.** IIS solo muestra 20101 éxitos, equivalente a 100% de sus registros; HTTPERR añade 52 fallos. Frente a un sondeo hipotético cada 30 s faltan 7 de 20160 observaciones; son desconocidas, no éxitos ni fallos asumidos. No se dispone del histórico de ping. [E-001, E-008]

En cinco minutos, de 2016 ventanas API: 1846 no tienen 5xx observados, 145 mezclan respuestas con algún 5xx, 4 tienen solo 5xx y 21 no contienen peticiones API. Las últimas se clasifican **desconocidas**, no caídas. El porcentaje de ventanas observadas sin 5xx es 92.531%; depende de la regla estricta «ningún 5xx», no es el SLI por petición. [E-002]

Contar únicamente los 26 minutos documentados de caída y suponer saludable todo el resto daría 99.742% del tiempo semanal. Se presenta solo como **escenario incompleto**, no como disponibilidad real demostrada: ignora degradación, errores parciales, reinicios y tiempo sin observación. Los logs no permiten un porcentaje exacto de disponibilidad temporal extremo a extremo.

## Causa raíz, factores y alternativas

**Hechos:** 45 eventos contienen OutOfMemoryException; 5 son terminaciones .NET; WAS registra 1 deshabilitación del pool y 5 errores de comunicación. El máximo de memoria privada es 1.444 GiB a 14:20:00; simultáneamente quedan 4733 MB de memoria disponible. Esto no prueba agotamiento de toda la RAM del servidor. [E-004, E-005]

**Hipótesis principal, confianza alta cualitativa:** crecimiento o retención de la caché de sesiones en el flujo de confirmación tras el despliegue del 2026-09-15 a 22:03:00. Hay cambio declarado de caché, crecimiento de memoria posterior y trazas en esa función. Falta probar fuga, arquitectura de proceso, límites de memoria, fragmentación o configuración; no se atribuye la causa a una persona. Un volcado y perfil de memoria, revisión del cambio y prueba controlada son necesarios para cerrar causa de código.

**Factores contribuyentes o riesgos correlacionados:** supervisión superficial; reinicios diarios que pueden ocultar acumulación; cambios de almacenamiento sin trazabilidad efectiva del mantenimiento; logging Debug declarado por el despliegue, compatible con más consumo de disco pero sin inventario de tamaños para atribuirle todos los MB. La advertencia de disco ocurre después del fallo de memoria: no se demuestra que disco lleno causara la caída. Los DCOM repetidos tampoco demuestran causalidad por su volumen; no hay cadena explicativa equivalente a OOM/WAS. [E-004, E-006, E-007, E-008]

## Señales tempranas

La memoria privada supera 1 GiB por primera vez el **2026-09-16T19:25**, frente a máximos diarios anteriores mucho menores recogidos en E-005. Es un umbral retrospectivo propuesto, no una alerta que existiera. El ticket del 17 a las 16:10 ya reportaba lentitud. El viernes el criterio de latencia habría dado aviso al cierre de la tercera ventana, antes del primer error de confirmación. Era posible anticipar riesgo y degradación, no predecir con certeza la hora de caída. [E-003, E-005, E-008]

## Riesgos ordenados por urgencia

1. **Inmediato: recurrencia de fallos de pago.** Restauración por reinicio sin defecto confirmado. Preservar evidencia, revisar caché y evaluar reversión controlada; no pronosticar otra hora de caída con una sola secuencia y reinicios que interrumpen la tendencia.
2. **Inmediato: capacidad de disco.** Al cierre quedan 11172 MB (9.137%). Primer cruce bajo 20%: 2026-09-18T14:35; bajo 10%: 2026-09-20T12:20. Actuar sobre capacidad/retención antes de agotamiento, preservando datos útiles. [E-005, E-006]
3. **Alta: falsa confianza en mantenimiento.** El BAT termina siempre con código cero y escribe éxito sin comprobar resultados; Task Scheduler registra 7 terminaciones con cero. El log tiene 30 líneas sin fecha, insuficientes para certificar trabajos. La invocación documentada apunta a una unidad retirada según el evento; la carpeta configurada para dumps no coincide con la de WER. No se demuestra qué archivos se borraron ni si la tarea real usaba exactamente ese argumento. [E-004, E-007]
4. **Alta: detección incompleta.** /health no prueba pagos; no se integra el rechazo HTTPERR. Alertar por operaciones, latencia, memoria y disco, y usar prueba sintética de negocio segura. Son propuestas, no cambios ejecutados. [E-001, E-003, E-008]
5. **Seguridad: revisión prioritaria de secretos y exploración externa.** El BAT privado requiere retirar su credencial de la automatización en el reto correspondiente; su valor nunca se publica. E-009 cuantifica solicitudes a rutas ajenas. No hay evidencia suficiente de compromiso o de ataque como causa del incidente.

### Pronóstico condicional de disco al cierre del 20

Regresión lineal por mínimos cuadrados de MB libres contra horas, con ventanas alternativas y proyección anclada a los 11172 MB finales. Horizonte obtenido: **30.0 a 106.1 horas**. Evaluación retrospectiva con datos hasta el 20; no afirma que el disco realmente se agotó en las fechas siguientes.

| Historia (h) | Muestras | Pendiente MB/h | Error RMSE MB | Horas hasta cero | Fecha condicional Bogotá |
|---|---:|---:|---:|---:|---|
| 24 | 289 | -105.29 | 178.1 | 106.1 | 2026-09-25T10:01 |
| 48 | 577 | -113.16 | 353.0 | 98.7 | 2026-09-25T02:38 |
| 72 | 865 | -305.77 | 3862.5 | 36.5 | 2026-09-22T12:27 |
| 96 | 1153 | -372.28 | 3714.5 | 30.0 | 2026-09-22T05:55 |

La variación de carga y los saltos del viernes hacen inestable la extrapolación. Los escenarios de fin de semana no representan necesariamente un lunes de pagos. Este rango es sensibilidad al periodo, **no intervalo de confianza ni fecha prometida**. R² y error de ajuste están en E-006; no garantizan capacidad predictiva. No se pronostican incidentes de memoria ni ataques con estos datos.

## Por qué pudo informar el NOC sin novedades

El ticket dominical describe ping y /health; no hay prueba de que comprobara operaciones. IIS solo ofrece un 100% aparente de /health, mientras los rechazos del kernel están en otra fuente. Además, el reporte posterior a la recuperación no caracteriza la tarde del viernes. Son explicaciones compatibles con evidencia; la configuración exacta del NOC, umbrales, notificaciones y atención humana no están disponibles. No se atribuye negligencia personal. [E-001, E-008]

## Reproducción y revisión

Objetivo Python 3.11+; ejecución comprobada en 3.12.14; 3.11 no validado directamente. Análisis y pruebas: biblioteca estándar. Desde la raíz, usar `.venv/Scripts/python.exe` en Windows o `py -3.11` si está instalado:

```powershell
.\.venv\Scripts\python.exe reto1-diagnostico/verify_h1.py --reference evidencias/publicables/h1-summary.json
.\.venv\Scripts\python.exe -m unittest discover -s tests -p 'test_h*.py' -v
.\.venv\Scripts\python.exe reto1-diagnostico/h2_analyze.py --output work-private/h2/evidence.json
.\.venv\Scripts\python.exe reto1-diagnostico/h2_analyze.py --output work-private/h2-repro/evidence.json
Get-FileHash work-private/h2/evidence.json,work-private/h2-repro/evidence.json
```

Comparar también con `evidencias/publicables/h2-evidence.json`; copiar solo después de revisar contenido. `h2_reports.py` regenera este diagnóstico y POSTMORTEM.md a partir de esa evidencia revisada. `render_postmortem.py` produce el PDF desde POSTMORTEM.md; dependencias opcionales en requirements-pdf.txt, separadas del análisis.

Revisar personalmente: selección de cinco APIs y denominador; supuesto horario de eventos/tickets; umbral retrospectivo de latencia; causalidad de caché todavía no probada; escenarios de disco; coherencia del post-mortem. H2 queda para aceptación, sin commit ni inicio de H3.
