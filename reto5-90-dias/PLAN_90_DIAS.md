# Plan ejecutivo de observabilidad y automatización - 90 días

**PortalPagos | Propuesta para Dirección**

## Enfoque general

El objetivo es pasar de una supervisión reactiva y fragmentada a una operación con disponibilidad medible, alertas accionables, responsables claros y automatizaciones limitadas por controles. El descubrimiento y el inventario serán incrementales: permitirán entregar valor desde la primera semana sin esperar un mapa perfecto de toda la organización.

La IA acelerará análisis, documentación, consultas, pruebas y desarrollo. No sustituirá permisos, conocimiento operativo, validación humana, observación de datos reales ni decisiones de riesgo, costo o producción.

## Iniciativas priorizadas

| Prioridad e iniciativa | Impacto | Esfuerzo | Riesgo |
|---|---|---|---|
| 1. Observabilidad y disponibilidad real (vacíos y detección tardía) | Muy alto | Medio | Bajo |
| 2. Alertas accionables y runbooks (fatiga y responsables) | Alto | Medio | Bajo |
| 3. Remediación automática limitada (cambios, reintentos y verificación) | Alto | Medio-alto | Medio |
| 4. Capacidad y recurrencia (saturación y tendencias débiles) | Alto | Medio | Bajo |
| 5. Triage asistido por IA (recomendaciones inventadas y exposición de datos) | Medio | Medio | Medio |

## Cronograma y resultados tempranos

| Periodo | Resultado verificable |
|---|---|
| Días 1-5 | Confirmar accesos, responsables, criticidad, dependencias y rutas de escalamiento. Elegir el primer servicio prioritario. |
| Días 6-15 | Entregar para ese servicio sondeo de disponibilidad, telemetría esencial, dashboard inicial y primeras alertas de alto valor. |
| Días 16-30 | Establecer líneas base de MTTD, MTTR, disponibilidad y calidad de alertas. Afinar reglas y asignar responsables a los runbooks. |
| Días 31-60 | Modernizar una tarea manual prioritaria e implementar un piloto de remediación limitada con identidad administrada, validación, máximo de intentos, rollback o escalamiento humano. |
| Días 61-90 | Extender el modelo a otros servicios priorizados, reducir recurrencia, gestionar capacidad y probar triage asistido por IA con catálogo cerrado y revisión humana. |

El primer mes establece líneas base; los resultados posteriores se compararán contra ellas. Cada ampliación exige evidencia de utilidad, costo y operación sostenible.

## Desbloqueos requeridos del líder

- Accesos mínimos a Azure, servidores, repositorios y monitoreo.
- Inventario y criticidad de servicios.
- Matriz de responsables técnicos, funcionales y de negocio.
- Tiempos esperados de respuesta y ruta de escalamiento.
- Presupuesto y límites de consumo.
- Políticas de retención y tratamiento de información.
- Ventanas autorizadas de pruebas y mantenimiento.
- Aprobación para automatizaciones con efectos productivos.

Con estas definiciones, el trabajo continuará de manera autónoma. El líder participará en decisiones de riesgo, costo, prioridad o bloqueos que la matriz de responsables no pueda resolver.

<!-- pagebreak -->

## Medición de éxito

| Indicador | Definición operativa | Uso al día 90 |
|---|---|---|
| MTTD | Tiempo entre inicio observable y alerta | Meta inicial: reducir al menos 50 % frente a la línea base |
| MTTR | Tiempo entre detección y recuperación validada | Meta inicial: reducir al menos 30 % |
| Detección preventiva | Incidentes detectados antes del primer reporte / total de incidentes | Aumentar la proporción; fijar meta numérica tras la línea base |
| Calidad de alertas | Alertas que requieren acción real / total de alertas | Alcanzar al menos 80 % |
| Automatización segura | Remediaciones exitosas sin intervención / remediaciones intentadas | Medir éxito, fallos, escalamiento y efectos evitados |
| Horas manuales eliminadas | Tiempo anterior menos tiempo posterior, por frecuencia mensual | Cuantificar ahorro verificable, sin estimaciones retrospectivas inventadas |
| Recurrencia | Incidentes repetidos por la misma causa dentro de 30 días | Reducir casos repetidos después de acciones correctivas |
| Cobertura | Servicios críticos con telemetría, responsable, alerta y runbook / total priorizado | Ampliar por oleadas según criticidad |

Durante los primeros 30 días se obtendrá la línea base. Las metas porcentuales son objetivos iniciales sujetos a esa medición; no se atribuyen mejoras históricas inexistentes.

## Qué no haría y por qué

- No incorporaría herramientas antes de conocer capacidades y necesidad real: evita costo y duplicación.
- No intentaría monitorear todo simultáneamente: priorizar servicios críticos acelera resultados útiles.
- No guardaría credenciales en código o configuración: reduce exposición y facilita rotación.
- No borraría logs, dumps o evidencia: preserva investigación y trazabilidad.
- No reiniciaría IIS, servidores o servicios indiscriminadamente: protege continuidad y limita impacto.
- No desplegaría remediaciones productivas sin límites, validación, responsable, ventana y escalamiento: evita automatizar daño.
- No presentaría un health check o éxito por solicitud como disponibilidad real ante vacíos de telemetría: evita conclusiones falsas.
- No afirmaría una causa raíz que siga siendo hipótesis: protege la calidad de decisiones.
- No permitiría inicialmente que la IA ejecute cambios en producción: solo clasificará, resumirá y recomendará runbooks bajo revisión humana.
- No crearía recursos sin presupuesto, responsable y plan de retiro: contiene costo y recursos abandonados.
