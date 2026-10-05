# Prueba técnica de Observabilidad y Automatización

Caso sintético PortalPagos. **Estado: Retos 1, 2, 3 y 5 terminados; Reto 4 diferido y no implementado.** H4 validó ingestión, KQL, alertas, notificación humana, auto-remediación, HTTP 200 y un Workbook para Dirección/NOC. El usuario declaró eliminados todos los recursos de Azure y confirmó que no existen costos residuales; el agente no hizo llamadas Azure ni verificó esa eliminación de forma independiente.

H2 fue revisado y aprobado; el cierre del Reto 1 se registró el 2026-10-04 a las 02:29:13 (America/Bogota). Sus entregables quedaron versionados en el commit `97c4245` y enviados a GitHub.

H3/Reto 2: [evaluación del BAT](reto2-powershell/H3_EVALUACION.md), [guía y script de mantenimiento](reto2-powershell/README.md) y [pruebas revisadas](evidencias/publicables/h3-tests.json). Pester 5.7.1: 38/38 casos en Windows PowerShell 5.1 y PowerShell 7.6.5. Pruebas solo en sandbox sintético; política de rutas configurable, sin cambios en servicios, IIS o red. H3 aprobado y versionado en `df48a5851bcb54c6309b321f1c4125bfa7af8d36`; esto no autoriza uso en producción.

Entregables H2: [diagnóstico técnico](reto1-diagnostico/H2_DIAGNOSTICO.md), [post-mortem fuente](reto1-diagnostico/POSTMORTEM.md), [PDF ejecutivo](reto1-diagnostico/POSTMORTEM.pdf) y [evidencias](evidencias/publicables/h2-evidence.json). Los comandos de análisis están en el diagnóstico. H1/H2 analíticos usan biblioteca estándar; únicamente la creación/verificación de PDF requiere paquetes opcionales:

```powershell
py -3.11 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r reto1-diagnostico/requirements-pdf.txt
.\.venv\Scripts\python.exe reto1-diagnostico/h2_reports.py
.\.venv\Scripts\python.exe reto1-diagnostico/render_postmortem.py
```

Omitir la creación si `.venv` ya existe; si no tiene pip, ejecutar `python -m ensurepip` con ese entorno. Las versiones fijadas son las usadas para verificar el PDF, no requisitos del parser. Para inspección visual instalar Poppler y ejecutar `pdftoppm -png reto1-diagnostico/POSTMORTEM.pdf work-private/h2/page` (crear antes `work-private/h2/`). Revisar cada imagen; el conteo automático no reemplaza la revisión. Objetivo de compatibilidad Python 3.11+; ejecución real en 3.12.14, sin validación directa de 3.11.

H4/Reto 3: [resultado y artefactos](reto3-azure/README.md), [pasos de Azure Portal](reto3-azure/PORTAL.md), [permisos y salvaguardas](reto3-azure/SEGURIDAD.md) y [evidencias revisadas](evidencias/publicables/h4/README.md). **55/55** pruebas sintéticas aprobadas por motor (5.1 y 7.6.5), además de la comprobación real del laboratorio realizada por el usuario en Portal. Portal obligó a usar North Central US y `Standard_B2als_v2`; el workspace fue `law-h4-test`. Costo observado USD 0,06 y presupuesto preventivo USD 15. El usuario confirmó la eliminación posterior de los recursos.

[Reto 4](reto4-ia/README.md) está **no implementado**: quedó diferido, no completado. No existe ni se afirma una integración de IA. Al alcanzar el límite de tiempo se priorizaron entregables terminados, probados y sustentables, siguiendo la recomendación del enunciado de entregar menos componentes bien hechos y probados en vez de presentar todo a medias. No se entrega código demostrativo sin pruebas.

Reto 5 **terminado y aprobado**: [fuente del plan de 90 días](reto5-90-dias/PLAN_90_DIAS.md) y [entregable ejecutivo PDF](reto5-90-dias/PLAN_90_DIAS.pdf). El PDF tiene exactamente dos páginas A4 y presenta cinco iniciativas, cronograma, métricas, desbloqueos y límites operativos.

## Cómo empezar

1. Leer [AGENTS.md](AGENTS.md), [PLAN.md](PLAN.md) y [DECISION_LOG.md](DECISION_LOG.md).
2. Mantener localmente el kit autorizado en `input-private/kit_prueba_portalpagos/` y el enunciado DOCX en `input-private/`. Esta carpeta está excluida de Git y es de solo lectura por regla de trabajo; no se han cambiado sus permisos del sistema.
3. Verificar con `git status --short` y `git check-ignore input-private/kit_prueba_portalpagos/scripts/mantenimiento_diario.bat` que las entradas no se proponen para versionar. No abrir ni ejecutar el BAT sin protección de su credencial.
4. Seguir la [guía de reproducción de H1](reto1-diagnostico/README.md): objetivo de compatibilidad Python 3.11 o posterior; ejecución comprobada en Python 3.12.14, sin validación directa de 3.11. Ingestión y análisis usan biblioteca estándar; los paquetes opcionales anteriores son solo para PDF. Los Retos 1, 2, 3 y 5 están cerrados; el Reto 4 quedó diferido.

El kit no se distribuye con el repositorio. La reproducción futura requerirá acceso legítimo al kit o fixtures sintéticos claramente identificados. El plazo es de cinco días desde la recepción según el enunciado; la fecha de recepción no está confirmada.

## Estructura

```text
input-private/              # Originales locales; nunca Git
reto1-diagnostico/          # Ingestión, diagnóstico y post-mortem completados
reto2-powershell/           # Mantenimiento sintético y evaluación del BAT
reto3-azure/                # Laboratorio H4, consultas, automatización y Workbook
reto4-ia/                   # Justificación y backlog; no implementado
reto5-90-dias/              # Propuesta ejecutiva de 90 días
tests/                     # Pruebas H1–H3 y sintéticas H4
evidencias/publicables/    # Solo evidencia revisada y redactada
evidencias/private/        # Evidencia cruda; nunca Git
work-private/              # Derivados locales; nunca Git
```

Las carpetas de los retos 4–5 contienen sus entregables finales: justificación y backlog del Reto 4 diferido, y propuesta ejecutiva Markdown/PDF del Reto 5 terminado.

## Inventario observado y formatos

Inventario histórico de H0: inspección de solo lectura del enunciado, LEEME, encabezados/muestras y estructura de los archivos. Se encontraron **18 archivos** incluyendo el DOCX y el LEEME. Las validaciones entonces pendientes y los supuestos de preparación siguientes se contrastaron posteriormente en H1/H2; su resultado y sus límites vigentes están en [H1_CALIDAD.md](reto1-diagnostico/H1_CALIDAD.md) y [H2_DIAGNOSTICO.md](reto1-diagnostico/H2_DIAGNOSTICO.md).

| Fuente relativa a `input-private/` | Hecho observado | Validación pendiente en H1 |
|---|---|---|
| `Prueba_Tecnica_Especialista_Observabilidad_Automatizacion.docx` | Documento OOXML; leídas reglas, cinco retos, evaluación y entrega mediante extracción del texto | No se evaluó maquetación visual; no se modifica ni entrega una copia |
| `kit_prueba_portalpagos/LEEME.md` | Datos declarados sintéticos; Windows Server 2022/IIS 10, sitio ID 2, semana 14–20 septiembre 2026 y zona Bogotá | Contrastar cobertura efectiva por fuente |
| `logs/iis/W3SVC2/` dentro del kit | 9 archivos W3C; nombres 14–21 septiembre y una copia del 16. SHA256 confirma que la copia es idéntica. Encabezados de 15 campos en muestras del 14–17 y 17 desde el 18, con `cs-host` y `X-Forwarded-For` | Parsear cada `#Fields`, verificar cambios internos, anomalías, límites temporales y deduplicación |
| `logs/httperr/httperr1.log` | Texto con `#Fields` de 14 campos, incluyendo estado, motivo y cola | Conciliación temporal y semántica con IIS sin doble conteo |
| `eventos/eventos_WEB-PAGOS-01.csv` | CSV con coma; 498 registros parseados; 7 columnas: TimeCreated, LogName, ProviderName, Id, LevelDisplayName, MachineName, Message | Zona horaria, severidad, valores y filas multilínea |
| `metricas/perfmon_WEB-PAGOS-01.csv` | CSV entrecomillado con coma; 2016 registros parseados y 7 columnas: tiempo, CPU, memoria disponible, disco libre porcentual/MB, memoria privada w3wp, conexiones. Cabecera PDH con SA Pacific y `(300)`; muestra de fecha mes/día/año y decimales con punto | Cadencia efectiva, huecos, tipos y unidades; conteo no demuestra continuidad |
| `tickets/tickets_mesa_servicio.csv` | CSV con coma; 8 registros, columnas Id, FechaHoraReporte, Prioridad, Grupo, Descripcion, Estado, NotaCierre | Relevancia, zona horaria y confiabilidad de cada reporte |
| `scripts/mantenimiento_diario.bat` y `mantenimiento.log` | BAT con operaciones de mantenimiento y credencial que se trata como secreto; log textual cuya muestra contiene mensajes sin marca temporal | Auditoría de riesgos en H3; no ejecutado |
| `alertas/alerta_ejemplo.json` | JSON parseable, `schemaId` del esquema común, `data.essentials` y `data.alertContext`; timestamp con `Z` | Contrato de entrada, evidencia contextual y variaciones de alertas en H5 |

Las rutas abreviadas de datos en la tabla pertenecen a `kit_prueba_portalpagos/`. CSV leídos con UTF-8 e `Import-Csv`; no se ha completado una auditoría de codificación de todo el kit. Los logs ignorados por Git se inventariaron con `Get-ChildItem -Recurse -File`, pues una búsqueda que respete `.gitignore` los omite.

## Hechos, hipótesis y supuestos de preparación (H0)

- **Hechos:** los requisitos provienen de las secciones 1–6 del DOCX y del LEEME; los formatos y conteos anteriores se observaron localmente. El commit preexistente `aa212c5` contiene `.gitignore`; no fue creado en esta etapa.
- **Hipótesis de preparación:** el archivo del 21 podría ser necesario para cubrir el último día local si su tiempo está en UTC; se contrastará antes de filtrar. No se afirma ninguna causa del incidente.
- **Supuesto S1:** usar provisionalmente la semana local `[2026-09-14 00:00, 2026-09-21 00:00)` en Bogotá, según LEEME; verificar zonas de cada fuente antes de convertir.
- **Supuesto S2:** elegir lenguaje y versión al iniciar implementación según capacidades verificadas. PowerShell está disponible; `python` no se encontró en PATH en esta sesión; esto no demuestra que no esté instalado en otra ruta.
- **Supuesto S3:** acceso a suscripción Azure y proveedor de modelo aún no confirmado. No asumir cuotas, crédito ni despliegue exitoso.

## Evidencia y controles

Los resultados de H0–H4 se registran en [IA_BITACORA.md](IA_BITACORA.md). El Reto 1 está cerrado con diagnóstico, cronología, indicadores de éxito HTTP, análisis causal con incertidumbre, escenarios condicionales de disco y post-mortem de dos páginas. H3 añade 38 pruebas aprobadas en cada motor PowerShell. H4 añade 55 pruebas por motor y evidencia real de Azure, con los límites temporales descritos en su README. Capturas públicas, eliminación, commit y push se someten a las puertas de AGENTS.
