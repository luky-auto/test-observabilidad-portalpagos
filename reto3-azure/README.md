# Reto 3 — observabilidad y remediación en Azure

El laboratorio H4 demostró la cadena VM Windows/IIS → Azure Monitor Agent → Log Analytics → alerta A → Action Group → Azure Automation → Run Command → recuperación del application pool. La comprobación final fue HTTP 200 con cuerpo `H4_OK`. La política de remediación y el webhook quedaron deshabilitados después del ensayo; las alertas operativas permanecen activas hasta eliminar el laboratorio.

## Resultado observado

- VM: `vm-h4-iis`, Windows Server 2022 Azure Edition, `Standard_B2als_v2`, North Central US.
- Sitio y pool: `H4LabSite` / `H4LabPool`, endpoint local `127.0.0.1:8080`.
- Workspace: `law-h4-test`; ingestión comprobada en `Heartbeat`, `Event`, `Perf` y `W3CIISLog`.
- Alerta A: dos sondeos HTTP fallidos consecutivos; frecuencia y ventana reales de cinco minutos porque Portal rechazó la frecuencia de un minuto para esa consulta.
- Remediación: job `Completed`; salida `h4.result.v1` con `Recovered`, HTTP 200 y un intento.
- Alerta B: notificación humana comprobada por correo mediante un caso real de alerta; no inicia remediación.
- Workbook `wb-h4-observabilidad`: pestañas separadas para Dirección y NOC.
- Seguridad: identidad administrada con rol personalizado limitado a tres acciones de Run Command y alcance de la VM.
- Costo observado en el presupuesto al tomar la evidencia: USD 0,06; presupuesto preventivo: USD 15. El presupuesto avisa y no detiene el consumo.

## Tiempos del ensayo controlado

| Evento | UTC |
|---|---|
| Primer sondeo fallido | 2026-10-05 06:46:55.452 |
| Segundo sondeo fallido | 2026-10-05 06:47:55.446 |
| Job creado | 2026-10-05 06:50:48 |
| Primer sondeo sano posterior | 2026-10-05 06:51:55.515 |
| Resultado interno `Recovered` | 2026-10-05 06:52:07.210 |

Desde el segundo fallo hasta la creación del job transcurrieron **2 min 52,554 s**. Se reporta como tiempo observado hasta el despacho de remediación, no como tiempo exacto de disparo, porque la captura de la alerta solo conserva el minuto `06:50Z`. Desde el segundo fallo hasta el primer sondeo sano transcurrieron **4 min 00,069 s**. El job duró aproximadamente **1 min 19 s** y su resultado interno se produjo **4 min 11,764 s** después del segundo fallo.

El script de falla emitió `StopNotVerified` porque verificaba el estado inmediatamente después de solicitar la detención. Una comprobación posterior confirmó `Stopped` y HTTP 503, por lo que la falla sí ocurrió, pero no existe un `faultStartedUtc` confiable producido por el script. La versión local ahora espera hasta 15 segundos, con sondeo cada 250 ms y fallo cerrado si no observa `Stopped`.

## Artefactos

| Ruta | Contenido |
|---|---|
| `modules/H4SafeAutomation/` | Validación de Common Alert Schema, deduplicación, bloqueo, intentos y recuperación segura |
| `runbooks/Invoke-H4Remediation.ps1` | Runbook con identidad administrada y Run Command limitado |
| `scripts/` | Instalación del invitado, sondeo, recuperación, falla controlada y empaquetado |
| `kql/` | Disponibilidad/cobertura, IIS, eventos del pool, alertas A/B e ingestión/rendimiento |
| `workbooks/wb-h4-observabilidad.workbook.json` | Workbook importable con vistas Dirección y NOC |
| `roles/H4-RunCommand-LabVM.example.json` | Rol personalizado de tres acciones |
| `arm/` | Plantillas ARM usadas como apoyo; no equivalen al bono específico de Bicep/Terraform |
| `../evidencias/publicables/h4/` | Capturas revisadas y guía de evidencia |

## Validación local

Pester 5.7.1 aprobó **55/55** casos, sin fallos ni omisiones, en Windows PowerShell 5.1.26100.9444 y PowerShell 7.6.5. La evidencia reproducible está en `evidencias/publicables/h4-local-tests.json`. Las pruebas usan fixtures y mocks; no vuelven a ejecutar Azure, IIS real ni correo.

```powershell
powershell.exe -NoProfile -File tests/Run-H4Tests.ps1 -PesterManifest ./work-private/h3-tools/Pester-5.7.1/Pester.psd1 -Label ps51
pwsh -NoProfile -File tests/Run-H4Tests.ps1 -PesterManifest ./work-private/h3-tools/Pester-5.7.1/Pester.psd1 -Label ps7
```

## Límites y cierre

La disponibilidad del workbook es observada desde la VM y no representa experiencia extremo a extremo ni transacciones reales. Minutos sin sondeo son `Unknown`. Un job `Completed` no demuestra recuperación sin el HTTP 200 y `H4_OK`.

Las trece capturas públicas pasaron revisión visual y la documentación registra los resultados y límites. Para cerrar H4 falta eliminar y verificar los recursos cuando el usuario autorice el alcance. Bicep o Terraform es un bono opcional y no forma parte del mínimo funcional ya demostrado. No se hará commit, push ni eliminación sin autorización explícita.
