# Plantilla H4 — PENDIENTE de Azure

Presupuesto previsto **USD 15**, ámbito suscripción sin filtro. Capturar alertas de costo real al 10/50/80/100 % y pronosticado al 80 % (o 100 %) si está disponible; registrar indisponibilidad si aplica. Destinatario `<ALERT_EMAIL_CONFIGURED_MANUALLY>`, solo el usuario configura el real en Portal. El presupuesto no detiene consumo y los datos pueden retrasarse. Contención principal: eliminar `rg-h4-observabilidad` el mismo día tras evidencia revisada y autorización. Atribuir gasto de H4 mediante filtro de RG, separado de otros gastos.

Estado inicial: **solo preparación local**. No completar casillas ni cifras sin resultado verificable. Evidencia cruda en `evidencias/private/h4/`; copia publicable revisada aparte. Nunca webhook, credenciales, correo o suscripción sin redactar. Sustituir IDs por etiquetas estables en copias, conservar trazabilidad privada.

| ID | Captura/registro requerido | Resultado observado / ruta privada | Copia revisada / validación |
|---|---|---|---|
| AZ-01 | Presupuesto, umbrales, moneda y saldo Student; restricción regional y precio `Standard_B2als_v2` North Central US | PENDIENTE | PENDIENTE |
| AZ-02 | Inventario RG/VM/imagen/tamaño/red/identidades/horas | PENDIENTE | PENDIENTE |
| AZ-03 | IIS sitio/pool/binding/ID, HTTP baseline, ACL y tarea independiente | PENDIENTE | PENDIENTE |
| AZ-04 | AMA/DCR, tres fuentes, muestras y última ingestión; consultas exactas | PENDIENTE | PENDIENTE |
| AZ-05 | KQL disponibilidad/cobertura, 5xx, p95 y eventos pool, límites | PENDIENTE | PENDIENTE |
| AZ-06 | Rol/acciones/asignación a VM, versiones de módulos/runtime, prueba de permisos | PENDIENTE | PENDIENTE |
| AZ-07 | A y B, umbrales, dimensiones, Common Schema, notificaciones recibidas | PENDIENTE | PENDIENTE |
| AZ-08 | Webhook vigente y luego deshabilitado, **sin URL en captura** | PENDIENTE | PENDIENTE |
| AZ-09 | Falla autorizada, sondeos, alerta, job y recuperación HTTP correlacionados | PENDIENTE | PENDIENTE |
| AZ-10 | Duplicado/no-actuar/límite de intentos/Failed o Suspended y escalamiento humano B | PENDIENTE | PENDIENTE |
| AZ-11 | Dashboard dirección/NOC con caso sano/fallo/desconocido | PENDIENTE | PENDIENTE |
| AZ-12 | Recursos eliminados tras aprobación, roles pendientes y costos diferidos | PENDIENTE | PENDIENTE |

Timestamps UTC a registrar con fuente (no usar reloj de video):

- T0: parada de pool confirmada en JSON de falla; conservar además inicio de solicitud de parada.
- T1: primer sondeo fallido; T2: segundo sondeo consecutivo fallido.
- T3: firedDateTime de alerta A; T4: inicio del job.
- T5: resultado de acción/HTTP verificado; T6: primer sondeo sano posterior; T7: Resolved.
- Tiempo de detección = T3 − T0; recuperación operativa muestreada = T6 − T0; ejecución del runbook = T5 − T4. Distinguir esos intervalos; resolución de la alerta no es la hora exacta de recuperación.
- Precisión/limitaciones: muestreo de un minuto, retraso de ingestión/evaluación, reloj de VM y plataforma, ventana de disponibilidad observada, cobertura y minutos sin señal.

Pruebas negativas en Azure futuras: Resolved sin comando; payload erróneo rechazado; pool Started + HTTP fallido sin reinicio; incidente repetido; intentos agotados; conflicto de ejecución. Cada falla inducida y eventual cambio temporal de fixture operativo necesita alcance autorizado. No usar resultados sintéticos como si fueran esas pruebas.

Checklist de cierre: evidencia revisada, máximo 5 min si hay video, autorización de borrado registrada, triggers/webhook deshabilitados, jobs concluidos, recursos/roles comprobados, gasto estimado y real separado, costos aún no reflejados declarados. **No enviar secretos para revisión por chat.**
