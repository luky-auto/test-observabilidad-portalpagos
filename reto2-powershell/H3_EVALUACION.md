# H3: evaluación previa del mantenimiento

2026-10-04. Evaluación escrita antes del reemplazo. Inspección estática del BAT en memoria, sin ejecutarlo, copiarlo ni publicar su credencial. Fuente: `input-private/kit_prueba_portalpagos/scripts/mantenimiento_diario.bat`; números de línea originales. Referencias E-004, E-006 y E-007: `evidencias/publicables/h2-evidence.json` y diagnóstico H2 aprobado.

## Problemas priorizados y decisión por paso

| Prioridad | Paso / líneas | Hecho y riesgo | Decisión y necesidad operativa |
|---|---|---|---|
| Crítica | Autenticación, 31 | Credencial incrustada; exposición y reutilización insegura | **Eliminar** credencial y conexión de red. No existe necesidad de acceso remoto demostrada para limpieza local. Revisar personalmente su revocación fuera de H3; no ejecutada. |
| Crítica | Dumps, 21 | Borrado indiscriminado; destruye posible evidencia de memoria | **Eliminar**. Preservar todos los dumps. H2 necesita dumps/código para contrastar la hipótesis de caché; E-007 además señala diferencia entre carpeta del BAT y WER. |
| Alta | Parámetros y rutas, 8–10, 15–21 | Rutas sin validación; expansión y recursividad amplían efectos | **Rediseñar** con raíz local restringida, sin enlaces/reparse points, manifiesto explícito, nombres simples y límites de cantidad/tamaño. E-007 no permite asumir que la unidad usada siga disponible. |
| Alta | Logs, 15 | Retención por antigüedad sin confirmar preservación ni resultado | **Reemplazar** por conservación. Una política de archivo y capacidad requiere propietario, destino y retención acordados. E-006 demuestra riesgo de disco, no autoriza destruir registros del incidente. |
| Alta | Temporales, 18 | Borrado recursivo de todos los temporales, sin antigüedad ni exclusiones | **Rediseñar**: solo archivos `.tmp` expresamente declarados desechables, vencidos y fuera de investigación; no recursividad. Hash y tamaño registrados antes de borrar, comprobación posterior. |
| Alta | IIS, 24 | Reinicio completo indiscriminado; interrumpe aplicaciones y oculta tendencia | **Eliminar** del mantenimiento. H2 relaciona reinicios con interrupción de la señal de memoria, sin demostrar corrección definitiva. Un runbook de recuperación requiere autorización propia. |
| Alta | Servicio, 27–28 | Detención/inicio sin precondición ni comprobación de recuperación | **Eliminar**. No hay evidencia de que ese servicio causara el incidente ni necesidad demostrada de reiniciarlo diariamente. |
| Alta | Unidad de red/copia/desconexión, 31–33 | Estado compartido, copia no comprobada, credencial y efectos de desconexión | **Eliminar** mapeo y desconexión; **reemplazar** la intención de trazabilidad por JSON Lines local. No se presenta ese log como backup. Exportación futura requiere diseño y permisos propios. |
| Alta | Resultado, 15–36 | No hay comprobaciones de error; éxito escrito en 35 y salida cero en 36 | **Reemplazar** por errores terminantes, verificación real y códigos diferenciados; nunca declarar eliminado sin comprobar ausencia. E-007: siete terminaciones cero no certifican éxito. |
| Alta | Concurrencia, archivo completo | No se observa exclusión mutua; carreras sobre archivos y recursos | **Rediseñar** con archivo de bloqueo preexistente abierto en exclusiva durante toda ejecución efectiva; no borrar el bloqueo. |
| Media | Registro, 12 y 35 | Inicio en consola; mensaje final sin fecha ni estructura en archivo | **Reemplazar** con UTC, run ID, acción, estado, motivo, nombre relativo, hash/tamaño y resumen JSONL. E-007: 30 líneas del log original sin fecha no certifican operaciones. |
| Media | Repetición, 15–33 | Cada ejecución puede repetir interrupciones y borrar nuevos archivos; no demuestra idempotencia | **Rediseñar**: segunda ejecución omite archivos ya ausentes; conserva recientes, no autorizados y protegidos. Logs por ejecución son una variación intencional. |

No se conserva automáticamente ningún paso destructivo. Se conserva la **intención** de mantenimiento local y observabilidad, con alcance más estrecho y verificable.

## Hechos, hipótesis y supuestos

- **Hecho:** el código observado contiene estas operaciones; no demuestra que todas se ejecutaran ni que causaran el incidente. El BAT nunca se ejecuta en H3.
- **Hipótesis de H2:** retención de caché como origen del crecimiento de memoria; no se convierte en justificación para reinicios periódicos.
- **Supuesto provisional:** temporales explícitamente listados como desechables, mayores de 14 días, pueden retirarse en un sandbox sintético. Un manifiesto vacío o `hold=true` impide limpieza; no se infiere que un `.tmp` real sea prescindible por extensión.
- **Límite deliberado:** la entrega solo admite sandboxes bajo `work-private/h3-sandboxes/`, con marcador sintético. No es autorización ni certificación de uso en producción. Adaptar raíces/ACL/retención y resolver capacidad de logs requiere revisión humana posterior. No se promete que limpiar temporales resuelva E-006.

## Diseño aprobado para implementar y validar

Módulo compatible con 5.1, entrada CLI con `SupportsShouldProcess`, validación previa sin escritura, planificación limitada, bloqueo exclusivo, bitácora durable antes y después de cada borrado, comprobación de ausencia y resumen. `-WhatIf` produce solo salida en memoria/consola: no crea log, bloqueo ni carpetas. Los fixtures crean por adelantado la estructura y el archivo de bloqueo. Ninguna función de servicios, IIS o red forma parte del reemplazo.

Referencias oficiales consultadas: [Microsoft: ShouldProcess](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-shouldprocess) y [Pester: instalación](https://pester.dev/docs/v5/introduction/installation). Dependencias de pruebas locales, fuera de Git; sin instalación global.

## Revisión posterior de aplicabilidad operativa

El usuario detectó que el límite de rutas embebido impedía instalar el reemplazo sin modificar el módulo. El diseño inicial anterior se conserva como antecedente; queda sustituido únicamente en ese punto por una configuración `h3.routes.v1` explícita, cerrada y sin secretos. La configuración sintética conserva el límite y marcador del laboratorio, y autoriza una raíz exacta por fixture. La plantilla WEB-PAGOS-01 permanece desactivada; permite preparar posteriormente una raíz local exacta y un marcador administrado sin editar código. La coincidencia de host se exige en modo despliegue.

No se reintroducen operaciones eliminadas. La política de rutas y los argumentos de la tarea deben protegerse mediante ACLs y revisión humana: configurar una raíz no acredita por sí mismo aprobación de producción. Todas las ejecuciones de prueba siguen usando archivos sintéticos; la plantilla de producción solo se inspecciona como datos. Instalación conceptual y puertas de Windows Server en la guía.
