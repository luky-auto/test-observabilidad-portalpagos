# Evidencias publicables de H4

Esta carpeta contiene solo capturas que pasaron revisión visual. Los originales o capturas con identificadores permanecen en `evidencias/private/h4/capturas-originales/`, excluidos de Git.

## Revisión actual

| Archivo | Estado | Qué demuestra |
|---|---|---|
| `01-workbook-direccion.png` | Aprobada | Vista sencilla para Dirección, cobertura/disponibilidad, tráfico y resultado del ensayo |
| `02-workbook-noc1.png` | Aprobada | Ingestión y rendimiento |
| `02-workbook-noc2.png` | Aprobada | Eventos del pool y estado de condición A |
| `02-workbook-noc3.png` | Aprobada | Estado de condición B y salvaguardas |
| `03-alerta-a-fired.png` | Aprobada con límite | Fired/Resolved y horas al minuto; no muestra severidad ni consulta |
| `03b-alerta-a-configuracion.png` | Aprobada | Severidad 1, frecuencia y periodo de evaluación de cinco minutos, auto-resolución y Action Group |
| `04a-runbook-completed.png` | Aprobada | Job `Completed`, creación, última actualización y runbook; Job ID cubierto |
| `04b-runbook-recovered.png` | Aprobada | Salida `Recovered`, HTTP 200 y un intento; Job ID e incidente cubiertos |
| `05-recuperacion-http.png` | Aprobada | Fallos 503 y primer sondeo sano 200 posterior |
| `06-alerta-b-correo.png` | Aprobada | Entrega humana real de la alerta B; correo cubierto |
| `07a-presupuesto.png` | Aprobada | Gasto evaluado USD 0,06, presupuesto USD 15 y umbrales; cuenta y destinatarios cubiertos |
| `08a-rbac-asignacion.png` | Aprobada | Identidad administrada, rol y alcance de la VM; Object ID cubierto |
| `08b-rbac-permisos.png` | Aprobada | Las tres acciones del rol personalizado |

## Métricas respaldadas por las capturas

- Segundo fallo: `2026-10-05 06:47:55.446Z`.
- Job creado: `2026-10-05 06:50:48Z`; despacho observado desde el segundo fallo: **2 min 52,554 s**.
- Primer sondeo sano: `2026-10-05 06:51:55.515Z`; recuperación observada desde el segundo fallo: **4 min 00,069 s**.
- Resultado interno: `Recovered` a `2026-10-05 06:52:07.210Z`, HTTP 200, un intento.
- La alerta A solo muestra `06:50Z` al minuto; por ello no se reporta detección exacta con segundos.

## Revisión antes de versionar

1. Recortar barras de direcciones y navegación de cuenta.
2. Cubrir completamente correos, GUID, Job ID, incidente, URL de webhook, IP pública, usuario y enlaces de Portal con IDs.
3. Abrir cada PNG final y comprobar visualmente que el texto cubierto no pueda inferirse por fragmentos.
4. Ejecutar revisión de secretos, rutas personales, índice e historial antes de `git add`.

No se necesita video si las capturas finales muestran la secuencia. Un video opcional no puede superar cinco minutos y exige la misma redacción.
