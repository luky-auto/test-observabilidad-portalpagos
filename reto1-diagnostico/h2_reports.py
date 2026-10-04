"""Regenerate technical report and executive Markdown from reviewed H2 evidence."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parent


def build():
    e=json.loads((ROOT.parent/'evidencias/publicables/h2-evidence.json').read_text(encoding='utf-8'))['evidence']
    r={k:v['result'] for k,v in e.items()}
    a,h=r['E-001']['api'],r['E-001']['health']
    timeline=r['E-003']; off=timeline['offline']; rec=timeline['recovery_30m']
    met=r['E-005']; disk=r['E-006']; ev=r['E-004']
    time=lambda value:value[11:19]
    start=time(timeline['degradation']['onset_window'])
    first=time(timeline['first_confirm_5xx_friday']['bogota'])
    down=time(off['first_503']['bogota']); up=time(off['first_api_success_after']['bogota'])
    duration=off['bracket_seconds']/60
    pct=lambda n:f'{n:.3f}%'
    scenarios=disk['scenarios']
    low=min(x['hours_to_zero_from_last'] for x in scenarios); high=max(x['hours_to_zero_from_last'] for x in scenarios)
    catalog='\n'.join(f"| {id} | {v['title']} | {v['rule']} |" for id,v in e.items())
    daily='\n'.join(f"| {day} | {s['requests']} | {s['classification'].get('server_error',0)} | {pct(s['http_success_pct'])} |" for day,s in r['E-001']['daily_api'].items())
    forecast='\n'.join(f"| {s['lookback_hours']} | {s['samples']} | {s['mb_per_hour']:.2f} | {s['rmse_mb']:.1f} | {s['hours_to_zero_from_last']:.1f} | {s['conditional_zero_bogota'][:16]} |" for s in scenarios)
    endpoints='\n'.join(f"| {p} | {s['requests']} | {s['classification'].get('server_error',0)} | {pct(s['http_success_pct'])} |" for p,s in r['E-001']['per_endpoint'].items())
    technical=fr'''# Diagnóstico técnico del Reto 1

## Conclusión y alcance

El viernes 18 de septiembre el portal sufrió degradación de confirmación de pagos, errores de memoria y terminaciones del proceso; el pool fue deshabilitado y HTTPERR registró rechazo de solicitudes. El mecanismo inmediato está respaldado con confianza alta. Una retención excesiva de memoria en la caché de sesiones introducida o agravada por el despliegue es una **hipótesis de alta confianza**, no un defecto de código demostrado. No hay dumps analizados, código de aplicación ni prueba controlada de reversión. [E-003, E-004, E-005]

El diagnóstico reutiliza SQLite de H1 en modo solo lectura, verifica sus conteos contra el manifiesto y se ejecuta después de `verify_h1.py`. No reingiere logs. Solo el BAT, excluido de H1, se inspecciona mediante patrones que exportan referencias y booleanos; no se ejecuta ni se copia su texto. Ninguna acción correctiva propuesta aquí está implementada.

## Catálogo y reproducción de evidencia

Fuente compacta: `evidencias/publicables/h2-evidence.json`. Los IDs son estables por pregunta, no por orden accidental de filas. Contiene reglas, resultados, timestamps y referencias a archivo/línea; las rutas de entrada son relativas al kit privado. Los detalles de cada consulta están en `h2_analyze.py`; su consulta base y el hash del resumen H1 figuran en el JSON. No se publican identidades, IP, parámetros ni mensajes completos.

| ID | Pregunta | Regla reproducible |
|---|---|---|
{catalog}

## Cronología en America/Bogota

IIS y HTTPERR se convierten desde UTC conforme al contrato H1. Eventos y tickets conservan el supuesto UTC-05, no confirmado por configuración de exportación. Los segundos entre fuentes no deben interpretarse como un reloj perfectamente sincronizado.

| Momento del 18 | Evidencia | Experiencia y límite |
|---|---|---|
| {time(timeline['first_api_5xx_friday']['bogota'])} | E-003, primer 5xx API del día | Error de fondo anterior al episodio de confirmación; no confundirlo con el comienzo causal del incidente |
| {start} | E-003, primera de tres ventanas consecutivas con p95 > 2000 ms y al menos 10 confirmaciones | Aumento sostenido de espera; detectable al cerrar la tercera ventana a {time(timeline['degradation']['confirmed_at'])} |
| {first} | E-003, primer 5xx de confirmar del viernes, IIS línea {timeline['first_confirm_5xx_friday']['line_start']} | Empieza evidencia HTTP de fallos de confirmación; no demuestra cobros perdidos o duplicados |
| {time(ev['oom']['first']['bogota'])} | E-004, excepción de memoria | La traza señala la operación de agregar una sesión de pago a caché |
| 13:34 | E-008, ticket T-10252 | Usuario reporta error al confirmar pago |
| {time(ev['runtime_termination']['first']['bogota'])} | E-004, primera terminación .NET por memoria | Fallos del proceso; luego hay más terminaciones y eventos WAS |
| {down} | E-003, HTTPERR línea {off['first_503']['line_start']} | Rechazos 503 AppOffline; la petición no llega a IIS |
| {time(ev['pool_disabled']['first']['bogota'])} | E-004, WAS 5002, línea {ev['pool_disabled']['first']['line_start']} | Pool deshabilitado tras fallos. El desfase de 5 s respecto a HTTPERR impide ordenar causalmente esos segundos |
| 14:42 | E-008, ticket T-10255 | Reporte humano de Service Unavailable |
| {up} | E-003, primera API exitosa posterior, IIS línea {off['first_api_success_after']['line_start']} | Recuperación observada; coincide con la hora de reinicio indicada en el ticket, no con un evento de auditoría independiente |

AppOffline abarca {off['observed_503_records']} registros, desde {down} hasta {time(off['last_503']['bogota'])}; la primera respuesta API exitosa siguiente delimita un intervalo aproximado de **{duration:.0f} minutos**. En los 30 minutos desde la recuperación hay {rec['requests']} solicitudes API, {rec['classification'].get('server_error',0)} errores 5xx y p95 IIS {rec['p95_iis_ms']} ms. Recuperación no equivale a ausencia total de errores ni corrección definitiva. [E-003]

El inicio de degradación depende de un umbral analítico, no de un SLO previamente acordado. E-003 incluye sensibilidad a 1500/2000/3000 ms; el método detecta una transición con confirmación posterior, no adivina el instante interno en que comenzó el defecto. Percentil por rango más próximo, sin interpolación; mínimo de muestra explícito.

## Disponibilidad semanal y límites

Ventana: 14 de septiembre 00:00 inclusive a 21 de septiembre 00:00 exclusiva, Bogotá. Indicador principal: **porcentaje de solicitudes observadas con respuesta HTTP 200–399 y sin error Win32 conocido**, sobre todas las solicitudes de las cinco rutas API listadas abajo. HTTPERR no suministra Win32; conserva su estado HTTP. Un 200 no certifica éxito financiero extremo a extremo. Se suman IIS y HTTPERR porque H1 no encontró candidatos bajo R10; sin ID de petición no puede probarse ausencia universal de duplicidad. [E-001]

**Operaciones API: {a['classification']['http_success']}/{a['requests']} = {pct(a['http_success_pct'])}; {a['classification']['server_error']} fallos 5xx.** No es porcentaje de tiempo ni de usuarios afectados. Se excluyen /health, recursos estáticos, rutas de escaneo, portada y login para no inflar el resultado con tráfico que no demuestra ejecución de operaciones. La selección es una definición analítica explícita, no una medición completa de todos los recorridos de usuario.

| Operación | Solicitudes | 5xx | Éxito HTTP |
|---|---:|---:|---:|
{endpoints}

| Día | Solicitudes API | 5xx | Éxito HTTP |
|---|---:|---:|---:|
{daily}

**/health integrado: {h['classification']['http_success']}/{h['requests']} = {pct(h['http_success_pct'])}.** IIS solo muestra {r['E-001']['health_by_source']['iis']['requests']} éxitos, equivalente a 100% de sus registros; HTTPERR añade {r['E-001']['health_by_source']['httperr']['requests']} fallos. Frente a un sondeo hipotético cada 30 s faltan {r['E-001']['health_missing_vs_30s']} de {r['E-001']['health_expected_30s']} observaciones; son desconocidas, no éxitos ni fallos asumidos. No se dispone del histórico de ping. [E-001, E-008]

En cinco minutos, de 2016 ventanas API: {r['E-002']['api_states']['no_5xx_observed']} no tienen 5xx observados, {r['E-002']['api_states']['degraded']} mezclan respuestas con algún 5xx, {r['E-002']['api_states']['failed']} tienen solo 5xx y {r['E-002']['api_states']['unknown']} no contienen peticiones API. Las últimas se clasifican **desconocidas**, no caídas. El porcentaje de ventanas observadas sin 5xx es {pct(r['E-002']['observed_windows_without_5xx_pct'])}; depende de la regla estricta «ningún 5xx», no es el SLI por petición. [E-002]

Contar únicamente los {duration:.0f} minutos documentados de caída y suponer saludable todo el resto daría {pct(timeline['confirmed_only_outage_complement_week_pct'])} del tiempo semanal. Se presenta solo como **escenario incompleto**, no como disponibilidad real demostrada: ignora degradación, errores parciales, reinicios y tiempo sin observación. Los logs no permiten un porcentaje exacto de disponibilidad temporal extremo a extremo.

## Causa raíz, factores y alternativas

**Hechos:** {ev['oom']['count']} eventos contienen OutOfMemoryException; {ev['runtime_termination']['count']} son terminaciones .NET; WAS registra {ev['pool_disabled']['count']} deshabilitación del pool y {ev['was_failure']['count']} errores de comunicación. El máximo de memoria privada es {met['peak_memory']['bytes']/1024**3:.3f} GiB a {time(met['peak_memory']['bogota'])}; simultáneamente quedan {met['peak_memory']['available_mb']:.0f} MB de memoria disponible. Esto no prueba agotamiento de toda la RAM del servidor. [E-004, E-005]

**Hipótesis principal, confianza alta cualitativa:** crecimiento o retención de la caché de sesiones en el flujo de confirmación tras el despliegue del {ev['deployment']['first']['bogota'][:10]} a {time(ev['deployment']['first']['bogota'])}. Hay cambio declarado de caché, crecimiento de memoria posterior y trazas en esa función. Falta probar fuga, arquitectura de proceso, límites de memoria, fragmentación o configuración; no se atribuye la causa a una persona. Un volcado y perfil de memoria, revisión del cambio y prueba controlada son necesarios para cerrar causa de código.

**Factores contribuyentes o riesgos correlacionados:** supervisión superficial; reinicios diarios que pueden ocultar acumulación; cambios de almacenamiento sin trazabilidad efectiva del mantenimiento; logging Debug declarado por el despliegue, compatible con más consumo de disco pero sin inventario de tamaños para atribuirle todos los MB. La advertencia de disco ocurre después del fallo de memoria: no se demuestra que disco lleno causara la caída. Los DCOM repetidos tampoco demuestran causalidad por su volumen; no hay cadena explicativa equivalente a OOM/WAS. [E-004, E-006, E-007, E-008]

## Señales tempranas

La memoria privada supera 1 GiB por primera vez el **{met['first_memory_ge_1GiB']['bogota'][:16]}**, frente a máximos diarios anteriores mucho menores recogidos en E-005. Es un umbral retrospectivo propuesto, no una alerta que existiera. El ticket del 17 a las 16:10 ya reportaba lentitud. El viernes el criterio de latencia habría dado aviso al cierre de la tercera ventana, antes del primer error de confirmación. Era posible anticipar riesgo y degradación, no predecir con certeza la hora de caída. [E-003, E-005, E-008]

## Riesgos ordenados por urgencia

1. **Inmediato: recurrencia de fallos de pago.** Restauración por reinicio sin defecto confirmado. Preservar evidencia, revisar caché y evaluar reversión controlada; no pronosticar otra hora de caída con una sola secuencia y reinicios que interrumpen la tendencia.
2. **Inmediato: capacidad de disco.** Al cierre quedan {disk['last']['free_mb']:.0f} MB ({disk['last']['free_pct']:.3f}%). Primer cruce bajo 20%: {met['first_disk_below_20pct']['bogota'][:16]}; bajo 10%: {met['first_disk_below_10pct']['bogota'][:16]}. Actuar sobre capacidad/retención antes de agotamiento, preservando datos útiles. [E-005, E-006]
3. **Alta: falsa confianza en mantenimiento.** El BAT termina siempre con código cero y escribe éxito sin comprobar resultados; Task Scheduler registra {ev['task_completed']['count']} terminaciones con cero. El log tiene {r['E-007']['undated_log_records']} líneas sin fecha, insuficientes para certificar trabajos. La invocación documentada apunta a una unidad retirada según el evento; la carpeta configurada para dumps no coincide con la de WER. No se demuestra qué archivos se borraron ni si la tarea real usaba exactamente ese argumento. [E-004, E-007]
4. **Alta: detección incompleta.** /health no prueba pagos; no se integra el rechazo HTTPERR. Alertar por operaciones, latencia, memoria y disco, y usar prueba sintética de negocio segura. Son propuestas, no cambios ejecutados. [E-001, E-003, E-008]
5. **Seguridad: revisión prioritaria de secretos y exploración externa.** El BAT privado requiere retirar su credencial de la automatización en el reto correspondiente; su valor nunca se publica. E-009 cuantifica solicitudes a rutas ajenas. No hay evidencia suficiente de compromiso o de ataque como causa del incidente.

### Pronóstico condicional de disco al cierre del 20

Regresión lineal por mínimos cuadrados de MB libres contra horas, con ventanas alternativas y proyección anclada a los {disk['last']['free_mb']:.0f} MB finales. Horizonte obtenido: **{low:.1f} a {high:.1f} horas**. Evaluación retrospectiva con datos hasta el 20; no afirma que el disco realmente se agotó en las fechas siguientes.

| Historia (h) | Muestras | Pendiente MB/h | Error RMSE MB | Horas hasta cero | Fecha condicional Bogotá |
|---|---:|---:|---:|---:|---|
{forecast}

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
'''
    post=f'''# PortalPagos: incidente del 18 de septiembre

Informe para la Directora de Operaciones | Semana del 14 al 20 de septiembre de 2026

## Resumen ejecutivo

El portal presentó lentitud y errores al confirmar pagos antes de dejar de atender solicitudes durante aproximadamente {duration:.0f} minutos. La recuperación se observó a las {up[:5]}, tras el reinicio manual reportado por soporte. La evidencia muestra fallos de memoria del proceso y la desactivación automática del componente que atiende el sitio. El reinicio recuperó la atención, pero no demuestra que se haya corregido el problema. [E-003, E-004, E-008]

## Impacto y disponibilidad real

Hubo confirmaciones con error, esperas prolongadas y rechazos de acceso al portal. No se puede determinar cuántos clientes únicos fueron afectados, si hubo pagos perdidos o duplicados, ni el impacto económico: no se entregaron registros de transacciones. [E-003, E-008]

En la semana, las operaciones de negocio observadas tuvieron **{pct(a['http_success_pct'])} de respuestas HTTP exitosas**: {a['classification']['http_success']} de {a['requests']} solicitudes. Se registraron {a['classification']['server_error']} errores de servidor. Esta medida describe solicitudes, no porcentaje de tiempo disponible ni confirmación contable de un pago. [E-001]

El sondeo de salud alcanzó **{pct(h['http_success_pct'])}** al integrar ambas fuentes de registro. Revisar solo los registros del sitio produce un 100% aparente, porque omite los rechazos anteriores a la aplicación. Tampoco se considera caída un periodo sin solicitudes. No es posible demostrar una disponibilidad temporal exacta con estos datos. [E-001, E-002]

## Cronología de lo experimentado

Horas de Colombia, el viernes 18. La hora de eventos y tickets se interpreta provisionalmente como local.

- **{start[:5]}:** comienza el aumento sostenido de espera al confirmar pagos; el criterio analítico lo habría detectado a las {time(timeline['degradation']['confirmed_at'])[:5]}. [E-003]
- **{first}:** primer error de confirmación registrado ese viernes; a las 13:34 un usuario reporta el problema. Había errores aislados anteriores en otras operaciones. [E-003, E-008]
- **{time(ev['runtime_termination']['first']['bogota'])[:5]}:** comienzan las terminaciones del proceso por errores de memoria. [E-004]
- **{down[:5]}:** solicitudes rechazadas por sitio fuera de servicio; el componente de atención queda deshabilitado. [E-003, E-004]
- **{up[:5]}:** vuelven las respuestas exitosas, consistente con el reinicio reportado. En los siguientes 30 minutos persisten {rec['classification'].get('server_error',0)} errores entre {rec['requests']} solicitudes: recuperación no significa solución definitiva. [E-003, E-008]

<!-- pagebreak -->

## Causa y factores contribuyentes

**Hecho de alta confianza:** errores de memoria terminaron procesos y el componente de atención fue deshabilitado tras fallos repetidos. **Hipótesis principal, de alta confianza pero pendiente de confirmación:** acumulación de sesiones de pago en memoria, asociada al cambio de aplicación anterior al incidente. La traza de errores apunta a esa función y las métricas muestran crecimiento posterior al cambio. Se necesita analizar memoria y código para demostrar el defecto exacto. No se atribuyen culpas personales. [E-004, E-005]

La memoria disponible del servidor no estaba agotada; un problema del proceso no equivale a falta de toda la memoria física. El disco también pierde espacio, pero no se demuestra que estuviera lleno o que fuera la causa de esta caída. [E-005, E-006]

Los reinicios periódicos pueden ocultar acumulación y no sustituyen una corrección. El mantenimiento registra éxito sin verificar cada resultado y conserva un log sin fechas. Los cambios de ubicación de archivos no están reconciliados con la configuración documentada del script. [E-004, E-007]

## Por qué la supervisión pudo no advertirlo

Un equipo que responde a ping o a una consulta de salud no garantiza que pueda confirmar pagos. Además, los rechazos durante la caída quedaron en otro registro. El reporte dominical «sin novedades» describe comprobaciones superficiales posteriores a la recuperación; no invalida la evidencia del viernes. No tenemos la configuración ni el historial completo de alertas del NOC para afirmar qué recibió o atendió. [E-001, E-008]

## Acciones correctivas y preventivas propuestas

- **Inmediato - Aplicaciones y Operaciones:** preservar evidencia de memoria, revisar el cambio de caché y decidir una corrección o reversión controlada. Validar confirmaciones reales antes de cerrar el incidente. [E-004, E-005]
- **Inmediato - Infraestructura:** revisar capacidad y retención del disco sin destruir evidencia. Al cierre semanal quedaba {disk['last']['free_pct']:.2f}% libre. Si persistieran los ritmos observados, los escenarios de agotamiento van de {low:.0f} a {high:.0f} horas; no son una fecha segura ni un pronóstico de lo que realmente ocurrió después. [E-006]
- **Prioridad alta - NOC:** vigilar operaciones de negocio, errores y tiempos de respuesta; incorporar rechazos anteriores a la aplicación y tendencias de memoria y disco. La señal de memoria ya era visible el {met['first_memory_ge_1GiB']['bogota'][8:10]} de septiembre, antes de la caída. [E-001, E-005]
- **Prioridad alta - Automatización:** hacer verificable el mantenimiento, proteger credenciales y conservar logs y volcados necesarios para investigar. Evitar declarar éxito únicamente porque terminó la tarea. [E-007]

Las acciones son propuestas para aprobación y ejecución posterior. Los identificadores E-001 a E-009 remiten al diagnóstico técnico y su catálogo de evidencias. No se realizaron cambios en producción ni en Azure.
'''
    (ROOT/'H2_DIAGNOSTICO.md').write_text(technical,encoding='utf-8')
    (ROOT/'POSTMORTEM.md').write_text(post,encoding='utf-8')


if __name__=='__main__':build()
