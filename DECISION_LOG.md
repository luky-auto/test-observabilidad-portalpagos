# Registro de decisiones

Fecha inicial: 2026-10-03 (America/Bogota). Registrar hechos, hipótesis y supuestos por separado. Ninguna decisión de diseño implica autorización para desplegar.

| ID | Tipo y estado | Decisión y fundamento | Consecuencia o validación |
|---|---|---|---|
| D01 | Instrucción del usuario; vigente | Mantener `input-private/` sin cambios y fuera de Git; tratar la credencial ficticia como secreto | No copiar BAT ni valores sensibles; revisar entregables e historial sin imprimir el secreto |
| D02 | Alcance autorizado; vigente | H0 solo produce documentación, `.gitignore` y carpetas vacías | Ningún parser, script de solución, IaC, fixture ni resultado de retos en esta etapa |
| D03 | Plan; provisional | Ocho hitos secuenciales con máximo total de 20 h; priorizar retos 1 y 2 y pruebas | Revisar al cerrar cada hito; los límites no son tiempos consumidos |
| D04 | Instrucción del usuario; vigente | Reto 3 se implementa después de completar y revisar R1/R2 y autorizar Azure | Presupuesto manual previo al primer despliegue; alertas operativas después de recursos y fuentes |
| D05 | Hecho y decisión; vigente | Encabezados IIS variables y duplicado por hash observados | H1 debe conservar trazabilidad y validar deduplicación; no se modifica la entrada |
| D06 | Supuesto S1; pendiente | Semana local del LEEME como ventana provisional; no filtrar por nombre de archivo | Validar zona por fuente y cobertura antes del diagnóstico |
| D07 | Decisión de seguridad; vigente | Separar derivados y capturas sin revisar de evidencia publicable; ampliar exclusiones de estados, claves y configuraciones locales | `.gitignore` es una barrera, no un escáner ni eliminación del historial |
| D08 | Decisión de trazabilidad; vigente | Solo prompts y errores ocurridos en IA_BITACORA | El requisito de 3 errores y 5–10 prompts del enunciado sigue pendiente si no ocurren suficientes; no inventarlos |
| D09 | Supuesto S2; pendiente | No fijar todavía Python, versión PowerShell, Pester, IaC ni proveedor de IA | Verificar disponibilidad al empezar el hito pertinente; no instalar dependencias en H0 |
| D10 | Decisión de alcance; vigente | Crear carpetas vacías sin `.gitkeep` | No añadir archivos fuera de la lista solicitada; README explica que Git no conserva carpetas vacías |
| D11 | Hecho observado; limitación | Git pudo consultar estado e historial, pero advirtió falta de acceso al archivo global de exclusiones del usuario | Validar reglas locales explícitamente; no afirmar revisión de esa configuración global |

## Revisión de cierre H0

Verificación local completada: los hashes SHA256 de los 18 originales permanecen iguales; los 18 archivos están ignorados; cero coincidencias exactas de la credencial en los seis entregables y en objetos Git alcanzables desde referencias/reflogs; JSON parseable; `git diff --check` sin errores. La inspección no garantiza ausencia de otros secretos desconocidos ni cubre objetos inalcanzables o repositorios remotos. Solo `.gitignore` está rastreado y el índice no se modificó.

Diff de preparación: `.gitignore` modificado (24 inserciones y 3 eliminaciones), cinco Markdown nuevos y nueve rutas de carpetas vacías. Decisiones principales: entradas privadas, hitos secuenciales, 20 h y puertas de Azure. Supuestos pendientes: zonas temporales, herramientas y acceso a proveedores; riesgos: configuración global Git inaccesible y trabajo de retos aún no probado. Mensaje de commit sugerido para una futura autorización: `docs: preparar plan y controles de la prueba de observabilidad`.

La revisión del usuario de esta preparación aún está pendiente. No se ha solicitado ni ejercido autorización para commit, push o cambios Azure.

## Decisiones de H1 del 2026-10-03

El cierre anterior conserva el estado histórico de preparación de H0. Posteriormente el usuario aprobó H0 y autorizó su commit/push; esa operación ya terminó. La autorización actual es únicamente implementar H1 sin commit/push ni H2.

| ID | Tipo y estado | Decisión y fundamento | Consecuencia o validación |
|---|---|---|---|
| D12 | Hecho y decisión; implementada | Python 3.12.14 encontrado en el runtime local, aunque no está en PATH ni registrado en `py`. Usar biblioteca estándar, requisito Python 3.11+ | Sin instalación ni llamadas pagadas; rutas y comandos en `reto1-diagnostico/README.md` |
| D13 | Alcance H1; implementada | Leer IIS, HTTPERR, eventos, Perfmon, tickets y log textual de mantenimiento; no BAT ni alerta R4 | 14 archivos inventariados, 13 únicos; entradas en solo lectura |
| D14 | Decisión de calidad; implementada | Excluir únicamente archivos completos idénticos por SHA256 dentro de fuente; ordenar por longitud de nombre y orden lexical para elegir canónico | 25882 filas de la copia excluidas; no deduplicar filas o fuentes por semejanza |
| D15 | Hecho normativo y supuesto; explícitos | UTC para IIS W3C/HTTPERR según Microsoft; UTC-05 para Perfmon por cabecera. Bogotá para eventos/tickets es supuesto contrastado, no hecho probado | Conservar timestamp original y advertencia `timezone_assumed_bogota`; R07 y referencias en H1_CALIDAD. Offset fijo limitado a la semana del kit |
| D16 | Corrección real de contrato; implementada | Los espacios en contadores son ausencia, no decimal inválido. HTTPERR puede registrar conexiones sin petición HTTP | Conservar 13 valores de memoria como null y el registro de línea 1546 sin método/URI/estado; tests específicos. No imputar ceros ni inventar estado HTTP |
| D17 | Decisión de trazabilidad; implementada | SQLite privado con rangos de líneas físicas y esquema vigente; resumen determinista pequeño como único derivado publicable | Resumen de 29.899 bytes, dos ejecuciones idénticas; 33 controles independientes aprobados |
| D18 | Decisión de límites; vigente | Matching por segundo/método/ruta/estado/IP servidor detecta candidatos, no identidad. Mantener 30 registros sin fecha de mantenimiento y todos los tickets | Cero pares IIS/HTTPERR bajo R10 no prueba ausencia absoluta de duplicados. No inferir disponibilidad, ejecuciones de mantenimiento ni causa raíz |
| D19 | Decisión de errores; implementada | Filas recuperablemente inválidas a cuarentena; codificación/comillas irrecuperables abortan. Quitar resumen previo antes de reconstruir | 21 tests aprobados; cero cuarentena en el kit final. No usar salidas parciales ni correr dos cargas sobre el mismo destino |

H1 queda implementado y verificado, pendiente de aceptación. La evidencia describe solo resultados ejecutados; no se aprobaron nuevas acciones Azure, commits o publicaciones.

## Revisión de portabilidad y planificación de H1

- **D20 — Corrección solicitada por el usuario:** sustituir la ruta del intérprete propia del equipo por instrucciones con `py -3.11` o `.venv` local recreable. H1 usa solo biblioteca estándar; no se añade `requirements.txt` sin dependencias externas. La nueva validación se ejecutó en `.venv` con Python 3.12.14; Python 3.11 no está disponible en el lanzador local y no se declara probado.
- **D21 — Alcance y entrega posterior:** H1 es ingesta, normalización y calidad; no completa el Reto 1. H2 conserva diagnóstico, cronología en America/Bogota, disponibilidad semanal, causa y factores, señales tempranas, riesgos y pronóstico. El post-mortem tendrá fuente independiente `reto1-diagnostico/POSTMORTEM.md` y PDF `reto1-diagnostico/POSTMORTEM.pdf`, máximo 3 páginas contadas y revisadas visualmente. No se crean ni redactan todavía.
- **Validación de esta revisión:** 21 pruebas PASS, 33 controles PASS, resumen sin diferencias, búsqueda de rutas locales en los 12 archivos rastreados/candidatos sin coincidencias y `git diff --check` sin errores. `.venv` y bases privadas ignoradas. H2 no iniciado; sin commit/push.

## H2 del 2026-10-04

- **D22 — Alcance autorizado:** usuario confirmó H1 aprobado/versionado y pidió solo H2. Reusar H1 en modo SQLite de solo lectura, verificar conteos/manifiesto y leer BAT únicamente por patrones estáticos seguros para correlación. No implementar modernización de mantenimiento, otros retos o Azure.
- **D23 — Indicadores:** cinco rutas API explícitas; porcentaje de éxito HTTP por solicitud, separado de salud. Integrar HTTPERR: IIS solo no registra sus rechazos. Ventanas sin tráfico son desconocidas. La cifra temporal basada solo en caída conocida es un escenario incompleto, no disponibilidad real demostrada.
- **D24 — Transiciones:** p95 nearest-rank, tres ventanas consecutivas de cinco minutos con al menos diez confirmaciones y p95 superior a 2000 ms; análisis de sensibilidad 1500/3000 ms. Separar error de fondo del primer error de confirmación. Recuperación exige respuesta exitosa observada, no solo nota de ticket.
- **D25 — Causalidad:** mecanismo de fallo de memoria/proceso/pool con confianza alta; retención de caché asociada al cambio es hipótesis alta, no prueba de defecto. No culpar a personas ni equiparar OOM a RAM física agotada. Conservar supuesto de zona de eventos/tickets y desfase entre fuentes.
- **D26 — Pronóstico:** OLS de espacio libre con cuatro ventanas; mostrar sensibilidad, horizonte, error residual y condiciones. No inferir agotamiento ocurrido después de la muestra ni predecir otro fallo de memoria. Disco, logging y mantenimiento se correlacionan sin atribuir todos los MB a una causa no medida.
- **D27 — Entrega:** E-001–E-009 y tablas pequeñas; generador de informes desde JSON revisado. Post-mortem Markdown independiente y PDF de dos páginas visualmente verificado. Análisis estándar; dependencias opcionales PDF fijadas a versiones efectivamente disponibles y probadas (ReportLab 4.4.9, pypdf 6.10.0), sin rutas personales en instrucciones.

H2 fue revisado y aprobado por el usuario; el Reto 1 quedó cerrado el 2026-10-04 a las 02:29:13 (America/Bogota). Los entregables fueron versionados en el commit `97c4245` y enviados a GitHub. Acciones correctivas son recomendaciones, no cambios ejecutados. En ese cierre H3 permanecía pendiente y no iniciado; la autorización posterior se registra a continuación. Este cierre no autoriza acciones en Azure.

## H3 del 2026-10-04: implementación para revisión

- **D28 — Alcance autorizado:** usuario aprobó exclusivamente Reto 2/H3, con objetivo Windows PowerShell 5.1, pruebas sintéticas y sin commit/push, H4 o Azure. Evaluación estática y tabla de decisiones redactadas antes del código, en `reto2-powershell/H3_EVALUACION.md`.
- **D29 — Compatibilidad comprobada:** 5.1.26100.9444 Desktop y 7.6.5 Core en Windows local; 29/29 casos Pester 5.7.1 aprobados en ambos. Pester 3.4.0 preinstalado no satisface la versión solicitada; 5.7.1 descargado en carpeta privada, sin instalación global. TestRegistry/TestDrive desactivados para usar solo fixtures explícitos. No se declara Windows Server 2022 probado.
- **D30 — Reducción de efectos:** eliminar reinicios de IIS/servicio, conexión/unidad de red, credencial y borrado de dumps; preservar logs. Reemplazar trazabilidad por JSONL local. E-004/E-007 no justifican reinicios periódicos; E-006 no autoriza destruir evidencia. El log nuevo no sustituye una copia de seguridad de logs históricos.
- **D31 — Supuesto explícito de retención:** 14 días por defecto, únicamente `.tmp` listados como desechables, hijos directos de `temp`, con límites y sin enlaces; hold de investigación preserva todo. Raíces restringidas al laboratorio sintético del repositorio. No trasladar esta política a producción sin validar necesidad, ACLs, retención y carreras.
- **D32 — Seguridad y resultados:** ShouldProcess gobierna la transacción y cada borrado; WhatIf no escribe ni bloquea. Archivo de bloqueo exclusivo, intención durable antes de borrar, ausencia comprobada después, salida 3 ante fallo parcial y 5 ante fallo de auditoría/infraestructura. Log por run ID y resumen distinguible de una simulación. Segunda ejecución omite lo ya ausente; crear un nuevo log es efecto intencional, no una nueva eliminación.
- **D33 — Evidencia y límites:** fixtures sintéticos y Pester; hashes y timestamps antes/después de WhatIf; concurrencia entre procesos; códigos reales 0–5. Permisos de eliminación simulados mediante mock, sin cambios de ACL. 18 originales intactos; pruebas previas/diagnóstico/post-mortem sin cambios. No existe evidencia de producción ni garantía frente a escritores ajenos al lock.

H3 implementado y probado, pendiente de revisión humana. Revisar especialmente la política de temporales, conservación de evidencia, eliminación de reinicios/red y límite a sandbox. Pendientes operativos de producción no se presentan como logrados. No se autoriza ni inicia H4 y no se hace commit/push.

## Revisión de aplicabilidad de H3, solicitada antes de aceptación

- **D34 — Corrección operativa autorizada:** separar rutas del módulo. `ConfigurationPath` obligatorio, esquema cerrado `h3.routes.v1`, raíz exacta autorizada, marcador y revalidación previa al borrado. La configuración sintética conserva límite y marcador; plantilla WEB-PAGOS-01 con ejemplo local, host exacto y `enabled=false`. D31 se actualiza solo respecto a rutas: el código ya puede instalarse sin editar el módulo, pero la producción sigue sin autorizarse.
- **D35 — Límite de confianza explícito:** configuración/código/argumentos de tarea solo modificables por responsables autorizados; ejecución con permisos mínimos y sin contraseña en argumentos. No se certifican ACLs desde el script. Conservación de bloqueos, WhatIf, manifiesto, hold, límites y evidencia; ninguna operación de red, servicios, IIS, logs o dumps reintroducida.
- **D36 — Validación:** 38/38 pruebas Pester por motor (5.1.26100.9444 y 7.6.5), incluidas las 29 anteriores y nueve casos de configuración. Plantilla de despliegue inspeccionada solo como datos; rama de despliegue probada exclusivamente con otra configuración generada para el sandbox y su host local. Task Scheduler solo documentado, no creado. Activación real requiere aprobación y pruebas en Windows Server.

## Aprobación y cierre de H3

2026-10-04: el usuario aprobó H3/Reto 2 y autorizó únicamente el commit `feat: add configurable safe PowerShell maintenance`, creado como `df48a5851bcb54c6309b321f1c4125bfa7af8d36`. Se repitieron las 38 pruebas en ambos motores, todas aprobadas. Plantilla desactivada, entradas y trabajo privado excluidos, sin evidencia privada ni temporales candidatos. Revisión de credencial conocida en archivos, índice e historial alcanzable: sin coincidencias; sin rutas personales en archivos revisados. Se mantienen límites de producción y carreras documentados. Esa aprobación no autorizó push, H4, Azure ni activación de Task Scheduler.
