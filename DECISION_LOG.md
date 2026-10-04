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
