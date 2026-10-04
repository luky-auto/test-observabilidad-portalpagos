# H1 Carga y contrato de datos

H1 comprende únicamente ingesta, normalización y calidad de datos; **no completa el Reto 1**. El diagnóstico y sus conclusiones pertenecen a H2, ahora entregado para revisión en [H2_DIAGNOSTICO.md](H2_DIAGNOSTICO.md). H1 no calcula disponibilidad, causa raíz, señales tempranas ni pronósticos. No ejecuta el BAT, Azure ni servicios externos. Los únicos accesos externos de H1 fueron lecturas gratuitas de documentación oficial sobre formatos.

## Reproducir

**Objetivo de compatibilidad: Python 3.11 o posterior**, con SQLite y funciones JSON. **Ejecución comprobada: Python 3.12.14. Python 3.11 no fue validado directamente**; su compatibilidad no se presenta como un hecho probado. Utiliza **únicamente la biblioteca estándar**: no hay paquetes externos, no se requiere `pip install` ni `requirements.txt`. Ejecutar desde la raíz del proyecto, con el kit en `input-private/kit_prueba_portalpagos/`.

Opción A, Windows con Python 3.11 instalado y disponible en el lanzador:

```powershell
py -3.11 -m unittest discover -s tests -p 'test_h1.py' -v
py -3.11 reto1-diagnostico/h1_ingest.py --input input-private/kit_prueba_portalpagos --output work-private/h1
py -3.11 reto1-diagnostico/verify_h1.py --output work-private/h1 --reference evidencias/publicables/h1-summary.json
```

Opción B, entorno virtual local en Windows, sin necesidad de activarlo:

```powershell
py -3.11 -m venv .venv
.\.venv\Scripts\python.exe -m unittest discover -s tests -p 'test_h1.py' -v
.\.venv\Scripts\python.exe reto1-diagnostico/h1_ingest.py --output work-private/h1
.\.venv\Scripts\python.exe reto1-diagnostico/verify_h1.py --output work-private/h1 --reference evidencias/publicables/h1-summary.json
```

Si ya existe una `.venv` con Python compatible, omitir su creación. En Linux/macOS se puede crear con `python3.11 -m venv .venv` y usar `.venv/bin/python` para los mismos argumentos. `.venv/` está excluida de Git; se recrea en cada equipo, no se distribuye ni se copia. La ejecución comprobada en esta sesión usa Python **3.12.14**; no se afirma una prueba en 3.11, que no está instalado en el lanzador de este equipo.

Cada comando debe terminar con código 0. En automatización, comprobar `$LASTEXITCODE` después de cada uno y detenerse si falla. `verify_h1.py` compara los hashes de entrada, las cuentas en SQLite, la integridad de la base y los bytes del resumen con la referencia aprobable. Si cambia el kit, la comparación con la referencia debe fallar: no actualizarla para ocultar diferencias.

Para una segunda reproducción independiente:

```powershell
py -3.11 reto1-diagnostico/h1_ingest.py --output work-private/h1-repro
py -3.11 reto1-diagnostico/verify_h1.py --output work-private/h1-repro --reference evidencias/publicables/h1-summary.json
git diff --check
git status --short --untracked-files=all
```

El cargador reconstruye sus dos archivos de salida, no agrega filas sobre una ejecución previa. No ejecutar dos procesos sobre la misma carpeta de salida. Solo permite escribir bajo `work-private/`, fuera del árbol de entrada. Un error fatal elimina el marcador `summary.json`; no usar una base parcial sin ese resumen y sin la verificación. Un error de fila recuperable queda en `issues` y en el resumen; la salida puede ser válida con cuarentena explícita, nunca con descarte silencioso.

## Cómo funciona

1. Descubre exclusivamente IIS, HTTPERR, eventos, métricas, tickets y el log textual de mantenimiento. Exige al menos un archivo de cada fuente y calcula SHA256. No lee BAT, alerta del Reto 4 ni enunciado.
2. Deduplica **archivos completos** por SHA256 dentro de una fuente. Elige primero el nombre más corto y luego el orden lexical; el nombre “copia” es solo una pista. Conserva en el inventario la referencia al archivo canónico y el número de filas excluidas.
3. Lee W3C por el `#Fields` vigente en cada línea y CSV por reglas de comillas y delimitador, incluso cuando una celda ocupa varias líneas. Exige UTF-8 válido; no sustituye caracteres ilegibles.
4. Valida fechas y números, transforma ausencias documentadas a `null`, conserva otras cadenas y no rellena huecos. Las filas no recuperables van a cuarentena con su referencia, no con contenido potencialmente sensible.
5. Conserva tiempo original, UTC y Bogotá con offset explícito. Marca pertenencia a la semana; no elimina registros por estar fuera de ella. Mantenimiento sin fecha permanece no temporal.
6. Guarda datos normalizados en SQLite **local e ignorado**. Resume esquemas, hashes, conteos, rangos, advertencias y referencias. No exporta filas de tráfico, IP, URLs, mensajes de eventos ni texto libre en el resumen publicable.

Reglas exactas: `R01`–`R12` en `h1_ingest.py` y en [el resumen reproducible](../evidencias/publicables/h1-summary.json). La única exclusión real del kit es la copia completa del log del 16. No se deduplican filas por parecido ni se fusionan fuentes.

## Archivos de salida y trazabilidad

- `work-private/h1/normalized.sqlite`: tabla `records` con `source`, `file`, `line_start`, `line_end`, `schema_line`, `raw_timestamp`, `utc`, `bogota`, `in_week`, `data_json`, `warnings_json`, `signature`, `http_key`. Las líneas son físicas, numeradas desde 1. Conserva mensajes y atributos solo localmente para futuras consultas autorizadas; **no versionar** la base.
- Tabla `issues`: archivo, rango de líneas, regla y motivo. En el kit actual tiene cero registros, pero se verifica con fixtures defectuosos.
- `work-private/h1/summary.json`: resultado determinista de la carga. Contiene 14 entradas de inventario (13 archivos únicos), rangos y referencias. No depende de la hora de ejecución.
- `evidencias/publicables/h1-summary.json`: copia **revisada** del resumen, 29.899 bytes al cerrar H1; único derivado propuesto para Git. El cargador no publica automáticamente. Para refrescarla en otra etapa se requiere revisar las diferencias y copiar únicamente este resumen.
- [H1_CALIDAD.md](H1_CALIDAD.md): lectura humana de los resultados, límites y fuentes técnicas. Los hashes del inventario corresponden a archivos completos, no a credenciales.

Consultas reproducibles incluidas en el código:

| Pregunta de H1 | Función o consulta |
|---|---|
| Conteos y rangos por fuente | `verify_h1.py`: `GROUP BY source`, conteo y `min/max(bogota)` |
| Filas con advertencias | `aggregate`: `json_each(warnings_json)` y referencias |
| Repeticiones dentro de una fuente | `aggregate`: agrupar por `source, signature`, conservar todas |
| Candidatos IIS/HTTPERR | `aggregate`: unión por `http_key` según R10, conservar todos |
| Cobertura de Perfmon | `aggregate`: comparar conjunto temporal con 2016 instantes esperados y diferencias de 300 segundos |
| Contraste de relojes | `temporal_contrast`: primer AppOffline, WAS 5002 cercano, muestra métrica y tickets cercanos; dos interpretaciones del evento |

La firma de una fila no incluye su ubicación, pero sí todos sus valores normalizados. Una repetición no se elimina porque puede ser legítima. R10 utiliza segundo UTC, método, ruta sin query, estado e IP del servidor; no es un identificador de petición. Cero coincidencias no descarta duplicados con diferencias de tiempo, ruta o proxy.

## Pruebas y revisión personal

`tests/test_h1.py` construye fixtures sintéticos pequeños en una carpeta temporal bajo `work-private/` y los elimina al terminar. No abre el kit ni utiliza sus 44 MB como fixtures. Sus 21 pruebas incluyen límites de semana, comillas/multilínea, cambios internos y reordenamiento de esquema, UTF-8 inválido, campos ausentes, números/fechas inválidos, repetición de filas legítimas, copias completas, matching entre fuentes, reconciliación, reproducción e integridad de entradas sintéticas.

Revisar personalmente antes de aceptar H1:

- La zona provisional de eventos/tickets y los límites del contraste: no disponemos del comando de exportación con configuración horaria ni del XML original de eventos.
- La distinción entre timestamp presente y contador disponible: 13 valores de memoria son desconocidos; las muestras no se deben interpretar como cero.
- La conservación del registro HTTPERR sin petición y de las 30 líneas sin fecha de mantenimiento.
- La regla de deduplicar solo archivos completos y la limitación del matching entre fuentes.
- Ejecutar los tres comandos principales y comprobar que el resumen coincide. La integridad de los originales no prueba que los datos sintéticos representen la realidad de un servicio.

H1 está aprobado y versionado. H2 fue autorizado posteriormente y está implementado para revisión; su aprobación no se presume. H3 no está autorizado.

El post-mortem posterior tendrá fuente independiente `reto1-diagnostico/POSTMORTEM.md` y versión final paginada `reto1-diagnostico/POSTMORTEM.pdf`, con un máximo verificable de 3 páginas. No es este README ni H1_CALIDAD.md; no se redacta en H1.
