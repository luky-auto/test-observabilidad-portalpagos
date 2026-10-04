# Prueba técnica de Observabilidad y Automatización

Preparación del caso sintético PortalPagos. **Estado: H0 aprobado; H1 completado y aprobado; los cinco retos todavía no están completados.** H1 cubre únicamente ingesta, normalización y calidad de datos. El diagnóstico y el post-mortem del Reto 1 corresponden a H2, no iniciado. No se han ejecutado comandos contra Azure ni creado recursos.

## Cómo empezar

1. Leer [AGENTS.md](AGENTS.md), [PLAN.md](PLAN.md) y [DECISION_LOG.md](DECISION_LOG.md).
2. Mantener localmente el kit autorizado en `input-private/kit_prueba_portalpagos/` y el enunciado DOCX en `input-private/`. Esta carpeta está excluida de Git y es de solo lectura por regla de trabajo; no se han cambiado sus permisos del sistema.
3. Verificar con `git status --short` y `git check-ignore input-private/kit_prueba_portalpagos/scripts/mantenimiento_diario.bat` que las entradas no se proponen para versionar. No abrir ni ejecutar el BAT sin protección de su credencial.
4. Seguir la [guía de reproducción de H1](reto1-diagnostico/README.md): objetivo de compatibilidad Python 3.11 o posterior; ejecución comprobada en Python 3.12.14, sin validación directa de 3.11. Únicamente biblioteca estándar, comandos con `py -3.11` o `.venv` local. No requiere paquetes externos ni `requirements.txt`. H2 permanece pendiente de autorización.

El kit no se distribuye con el repositorio. La reproducción futura requerirá acceso legítimo al kit o fixtures sintéticos claramente identificados. El plazo es de cinco días desde la recepción según el enunciado; la fecha de recepción no está confirmada.

## Estructura

```text
input-private/              # Originales locales; nunca Git
reto1-diagnostico/          # Ingestión y diagnóstico futuros
reto2-powershell/           # Mantenimiento futuro
reto3-azure/                # Laboratorio futuro, sujeto a autorización
reto4-triage-ia/            # Componente de sugerencias futuro
reto5-propuesta/            # Propuesta futura de 90 días
tests/                     # Pruebas futuras
evidencias/publicables/    # Solo evidencia revisada y redactada
evidencias/private/        # Evidencia cruda; nunca Git
work-private/              # Derivados locales; nunca Git
```

Las carpetas nuevas están vacías. Git no conserva carpetas vacías: se incluyen en esta documentación y se conservarán en el repositorio cuando tengan entregables autorizados; no se crearon archivos de relleno.

## Inventario observado y formatos

Inspección de solo lectura del enunciado, LEEME, encabezados/muestras y estructura de los archivos; no constituye diagnóstico del incidente. Se encontraron **18 archivos** incluyendo el DOCX y el LEEME.

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

## Hechos, hipótesis y supuestos

- **Hechos:** los requisitos provienen de las secciones 1–6 del DOCX y del LEEME; los formatos y conteos anteriores se observaron localmente. El commit preexistente `aa212c5` contiene `.gitignore`; no fue creado en esta etapa.
- **Hipótesis de preparación:** el archivo del 21 podría ser necesario para cubrir el último día local si su tiempo está en UTC; se contrastará antes de filtrar. No se afirma ninguna causa del incidente.
- **Supuesto S1:** usar provisionalmente la semana local `[2026-09-14 00:00, 2026-09-21 00:00)` en Bogotá, según LEEME; verificar zonas de cada fuente antes de convertir.
- **Supuesto S2:** elegir lenguaje y versión al iniciar implementación según capacidades verificadas. PowerShell está disponible; `python` no se encontró en PATH en esta sesión; esto no demuestra que no esté instalado en otra ruta.
- **Supuesto S3:** acceso a suscripción Azure y proveedor de modelo aún no confirmado. No asumir cuotas, crédito ni despliegue exitoso.

## Evidencia y controles

Los resultados de preparación se registran en [IA_BITACORA.md](IA_BITACORA.md). Aún no existen resultados de disponibilidad, causa raíz, pronóstico, mantenimiento, Azure ni triage. La alerta de presupuesto se configurará manualmente antes del primer despliegue. Las alertas operativas se crearán después de contar con VM, Log Analytics y fuentes válidas. Cambios Azure, commit y push requieren autorización conforme a AGENTS.
