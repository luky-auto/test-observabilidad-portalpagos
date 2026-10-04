# Bitácora real de uso de IA

## Herramientas y alcance

2026-10-03 (America/Bogota). Asistente Codex, basado en GPT-6 según la configuración de esta sesión; variante exacta no verificada. Uso: lectura y planificación, documentación inicial y comprobaciones locales mediante PowerShell/.NET y Git. Habilidad `documents` consultada para lectura de DOCX; extracción OOXML de solo lectura, sin generar un documento Word ni revisar su diseño visual. Sin subagentes, servicios de modelos externos ni comandos Azure.

## Prompt importante 01

**Origen:** solicitud inicial real del usuario; resumen fiel, no transcripción literal. Preparar una prueba de Especialista en Observabilidad y Automatización: leer enunciado y LEEME, inspeccionar datos, no resolver los cinco retos; crear únicamente documentación, `.gitignore` y estructura; planificar hasta 20 h con hitos verificables; proteger originales y credencial; trabajar un hito por vez; registrar decisiones y uso real de IA; no modificar Azure ni hacer commit/push sin autorización; posponer Reto 3 hasta revisión de retos 1 y 2; presupuesto manual previo y alertas operativas posteriores a recursos/fuentes.

**Respuesta generada:** documentación inicial con ocho hitos y sus siete campos de verificación; inventario de formatos, hechos/hipótesis/supuestos, puertas de Azure y protección de entradas. No se generaron soluciones de retos.

**Validación:** contraste con texto del DOCX y LEEME; inspección de fuentes y Git; verificaciones finales detalladas abajo. **Decisiones no delegadas:** autorización Azure, configuración manual de presupuesto, aceptación de revisiones, publicación y decisiones humanas sobre sugerencias de triage.

Solo hay un prompt clave registrado. Los comandos rutinarios no se presentan como nuevos prompts del usuario. El objetivo del enunciado de 5–10 prompts se completará únicamente con interacciones relevantes reales.

## Errores y correcciones que sí ocurrieron

1. **Inventario inicial incompleto:** se usó `rg --files --hidden input-private`, que omitió logs por respetar `.gitignore`. Se detectó al contrastar con el LEEME, que sí anunciaba logs. Se corrigió con `Get-ChildItem input-private -Recurse -File`, que encontró 18 archivos. No se declaró que faltaran fuentes ni se cambió su contenido.
2. **Lectura con codificación inadecuada:** la primera lectura de texto con `Get-Content` sin codificación explícita mostró caracteres acentuados mal decodificados. Se corrigió la lectura de LEEME y muestras con `-Encoding UTF8`; no se alteraron los originales. La salida conjunta de habilidad y LEEME también quedó truncada: el LEEME se volvió a leer completo por separado.
3. **Supuesto de herramienta no confirmado:** se intentó `python --version` antes de verificar su disponibilidad; el comando falló porque no estaba en PATH. Para la extracción de texto del DOCX se usó .NET disponible en PowerShell, sin instalar software. No se concluyó que Python no exista en el equipo.

Estos son fallos de procedimiento observados, no errores de diagnóstico ni alucinaciones del modelo de triage. No se inventan equivocaciones técnicas para cumplir la cuota del enunciado; su pertinencia para esa evaluación se revisará al cierre.

## Verificaciones realizadas durante la inspección

- DOCX: lectura de párrafos y tablas a través de `word/document.xml`; leídas secciones 1–6. LEEME: lectura completa UTF-8. Resultado: requisitos incorporados al plan; sin resolver retos.
- CSV: `Import-Csv -Encoding UTF8` permitió observar 498 eventos, 2016 muestras de métricas y 8 tickets. Resultado: estructura legible; aún no es validación de calidad ni continuidad temporal.
- IIS/HTTPERR: encabezados y muestras inspeccionados; se identificaron variantes de campos. SHA256 de los dos archivos del 16 coincide. Resultado: duplicado exacto confirmado, pendiente tratamiento en H1.
- BAT: lectura redactada, omitiendo líneas potencialmente sensibles; no ejecutado ni copiado. JSON de alerta: estructura inspeccionada y `ConvertFrom-Json` completado; `schemaId` coincide con el esquema declarado.
- Git: `git status --short`, `git ls-files`, `git log --all --format=%h --name-only` y `git check-ignore` sobre el BAT. Resultado inicial: solo `.gitignore` rastreado, un commit previo `aa212c5`, BAT ignorado. Advertencia real: archivo global de exclusiones inaccesible; reglas locales comprobables.
- Se tomaron hashes SHA256 en memoria de los 18 originales antes de escribir documentación y se compararon después: los 18 permanecen iguales. No se publica el valor del secreto ni un hash de la credencial.
- Exclusiones: `git check-ignore -q` para cada uno de los 18 originales; cero entradas sin exclusión. La advertencia del archivo global persiste, pero no impidió comprobar las reglas locales.
- Secreto: valor aislado del BAT únicamente en memoria; búsqueda literal en los seis entregables y en contenido de blobs/commits/tags enumerados por `git rev-list --objects --all --reflog`; cero coincidencias. Alcance: objetos alcanzables y reflogs disponibles, no objetos inalcanzables ni remotos; no equivale a un escaneo universal de secretos desconocidos.
- `git diff --check`: sin errores. `git status --short`: únicamente `.gitignore` modificado y los cinco Markdown nuevos. `git ls-files`: solo `.gitignore`. No se modificó el índice ni se hizo commit/push. Carpetas vacías verificadas durante su creación; no hay archivos de implementación.

## Límites de evidencia

No hay pruebas de soluciones, resultados del incidente ni evidencia de Azure. Los tiempos del PLAN son presupuestos, no mediciones de trabajo ejecutado. La inspección de formatos y lectura del BAT no equivalen a resolver retos 1 o 2.
