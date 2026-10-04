# PortalPagos: incidente del 18 de septiembre

Informe para la Directora de Operaciones | Semana del 14 al 20 de septiembre de 2026

## Resumen ejecutivo

El portal presentó lentitud y errores al confirmar pagos antes de dejar de atender solicitudes durante aproximadamente 26 minutos. La recuperación se observó a las 15:04, tras el reinicio manual reportado por soporte. La evidencia muestra fallos de memoria del proceso y la desactivación automática del componente que atiende el sitio. El reinicio recuperó la atención, pero no demuestra que se haya corregido el problema. [E-003, E-004, E-008]

## Impacto y disponibilidad real

Hubo confirmaciones con error, esperas prolongadas y rechazos de acceso al portal. No se puede determinar cuántos clientes únicos fueron afectados, si hubo pagos perdidos o duplicados, ni el impacto económico: no se entregaron registros de transacciones. [E-003, E-008]

En la semana, las operaciones de negocio observadas tuvieron **98.349% de respuestas HTTP exitosas**: 82617 de 84004 solicitudes. Se registraron 1387 errores de servidor. Esta medida describe solicitudes, no porcentaje de tiempo disponible ni confirmación contable de un pago. [E-001]

El sondeo de salud alcanzó **99.742%** al integrar ambas fuentes de registro. Revisar solo los registros del sitio produce un 100% aparente, porque omite los rechazos anteriores a la aplicación. Tampoco se considera caída un periodo sin solicitudes. No es posible demostrar una disponibilidad temporal exacta con estos datos. [E-001, E-002]

## Cronología de lo experimentado

Horas de Colombia, el viernes 18. La hora de eventos y tickets se interpreta provisionalmente como local.

- **11:50:** comienza el aumento sostenido de espera al confirmar pagos; el criterio analítico lo habría detectado a las 12:05. [E-003]
- **13:23:45:** primer error de confirmación registrado ese viernes; a las 13:34 un usuario reporta el problema. Había errores aislados anteriores en otras operaciones. [E-003, E-008]
- **14:22:** comienzan las terminaciones del proceso por errores de memoria. [E-004]
- **14:38:** solicitudes rechazadas por sitio fuera de servicio; el componente de atención queda deshabilitado. [E-003, E-004]
- **15:04:** vuelven las respuestas exitosas, consistente con el reinicio reportado. En los siguientes 30 minutos persisten 5 errores entre 1060 solicitudes: recuperación no significa solución definitiva. [E-003, E-008]

<!-- pagebreak -->

## Causa y factores contribuyentes

**Hecho de alta confianza:** errores de memoria terminaron procesos y el componente de atención fue deshabilitado tras fallos repetidos. **Hipótesis principal, de alta confianza pero pendiente de confirmación:** acumulación de sesiones de pago en memoria, asociada al cambio de aplicación anterior al incidente. La traza de errores apunta a esa función y las métricas muestran crecimiento posterior al cambio. Se necesita analizar memoria y código para demostrar el defecto exacto. No se atribuyen culpas personales. [E-004, E-005]

La memoria disponible del servidor no estaba agotada; un problema del proceso no equivale a falta de toda la memoria física. El disco también pierde espacio, pero no se demuestra que estuviera lleno o que fuera la causa de esta caída. [E-005, E-006]

Los reinicios periódicos pueden ocultar acumulación y no sustituyen una corrección. El mantenimiento registra éxito sin verificar cada resultado y conserva un log sin fechas. Los cambios de ubicación de archivos no están reconciliados con la configuración documentada del script. [E-004, E-007]

## Por qué la supervisión pudo no advertirlo

Un equipo que responde a ping o a una consulta de salud no garantiza que pueda confirmar pagos. Además, los rechazos durante la caída quedaron en otro registro. El reporte dominical «sin novedades» describe comprobaciones superficiales posteriores a la recuperación; no invalida la evidencia del viernes. No tenemos la configuración ni el historial completo de alertas del NOC para afirmar qué recibió o atendió. [E-001, E-008]

## Acciones correctivas y preventivas propuestas

- **Inmediato - Aplicaciones y Operaciones:** preservar evidencia de memoria, revisar el cambio de caché y decidir una corrección o reversión controlada. Validar confirmaciones reales antes de cerrar el incidente. [E-004, E-005]
- **Inmediato - Infraestructura:** revisar capacidad y retención del disco sin destruir evidencia. Al cierre semanal quedaba 9.14% libre. Si persistieran los ritmos observados, los escenarios de agotamiento van de 30 a 106 horas; no son una fecha segura ni un pronóstico de lo que realmente ocurrió después. [E-006]
- **Prioridad alta - NOC:** vigilar operaciones de negocio, errores y tiempos de respuesta; incorporar rechazos anteriores a la aplicación y tendencias de memoria y disco. La señal de memoria ya era visible el 16 de septiembre, antes de la caída. [E-001, E-005]
- **Prioridad alta - Automatización:** hacer verificable el mantenimiento, proteger credenciales y conservar logs y volcados necesarios para investigar. Evitar declarar éxito únicamente porque terminó la tarea. [E-007]

Las acciones son propuestas para aprobación y ejecución posterior. Los identificadores E-001 a E-009 remiten al diagnóstico técnico y su catálogo de evidencias. No se realizaron cambios en producción ni en Azure.
