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

H2 queda para aceptación. Acciones correctivas son recomendaciones, no cambios ejecutados. No se autoriza ni inicia H3 y no se hace commit/push.
