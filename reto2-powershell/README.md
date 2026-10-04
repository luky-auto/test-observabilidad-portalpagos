# H3: mantenimiento local comprobable

Implementación del Reto 2, pendiente de revisión humana. La [evaluación previa](H3_EVALUACION.md) ordena los problemas y decide cada paso del BAT. El reemplazo limpia únicamente temporales sintéticos autorizados y vencidos; preserva logs, dumps y archivos no autorizados. No contiene operaciones IIS, servicios, unidades de red ni credenciales.

## Compatibilidad y alcance

Objetivo Windows PowerShell **5.1**; probado realmente en **5.1.26100.9444 Desktop** y **7.6.5 Core**, Windows del equipo de laboratorio. Ambas suites usan **Pester 5.7.1**, 38/38 pruebas aprobadas por motor. No se usaron funciones exclusivas de PowerShell 7. No se ha probado Windows Server 2022, otra versión de 7 ni Linux.

Solo se aceptan subdirectorios de `work-private/h3-sandboxes/` relativos al repositorio del módulo, en volumen local fijo, con marcador `H3_SYNTHETIC_ONLY_V1`. No basta con pasar una raíz arbitraria. La política es intencional: ninguna ejecución de este entregable puede apuntar directamente a los originales o a un servidor real. La aprobación de H3 no es autorización de producción.

## Ejecución reproducible

Desde la raíz del repositorio, en Windows PowerShell 5.1 o PowerShell 7:

```powershell
# Crea exclusivamente datos sintéticos en una raíz nueva y devuelve su ruta.
$sandbox = & ./tests/fixtures/h3/New-SyntheticSandbox.ps1
$config = Join-Path $sandbox 'maintenance.routes.json'

# Planifica sin crear logs, carpetas o bloqueos.
& ./reto2-powershell/Invoke-Maintenance.ps1 -ConfigurationPath $config -SandboxRoot $sandbox -WhatIf
$LASTEXITCODE

# Ejecuta solo contra esa raíz sintética.
& ./reto2-powershell/Invoke-Maintenance.ps1 -ConfigurationPath $config -SandboxRoot $sandbox -Confirm:$false
$LASTEXITCODE

# Repetir: el temporal ya retirado se omite como already_absent.
& ./reto2-powershell/Invoke-Maintenance.ps1 -ConfigurationPath $config -SandboxRoot $sandbox -Confirm:$false
```

No dot-sourcear la entrada CLI, pues usa `exit` para comunicar el resultado al proceso invocador. Para consumo desde PowerShell, importar `SafeMaintenance.psm1` y llamar `Invoke-SafeMaintenance`: devuelve un objeto con `exitCode` sin cerrar la sesión. En programación futura, comprobar el código del proceso, no buscar un texto de éxito.

## Contrato y arquitectura

1. **Validación sin escritura:** raíz, ancestros y componentes sin junctions/symlinks/reparse points; directorios `temp` y `audit`, marcador, manifiesto y archivo `.maintenance.lock` preexistentes. Rechazo de UNC, traversal y comodines. No se crean rutas faltantes.
2. **Planificación:** solo hijos directos de `temp`, sin recursividad. Deben estar en `disposable.json`, tener nombre simple y extensión `.tmp`, y antigüedad estrictamente mayor que `RetentionDays` según `LastWriteTimeUtc`. El reloj usa UTC. Se conservan todos los demás archivos/directorios; no se recorren logs ni dumps.
3. **ShouldProcess:** puerta de transacción para bloqueo, log y limpieza, más confirmación por borrado. Si `-WhatIf` está activo, termina antes de cualquier escritura. En ese modo los candidatos se cuentan en `planned` y las operaciones se incluyen en `skipped`; `succeeded=0` no se presenta como ejecución.
4. **Exclusión mutua:** apertura del archivo de bloqueo en modo exclusivo durante toda la operación. No se elimina ni recrea el archivo de bloqueo. Otro proceso obtiene código 4. Tras una terminación del proceso el sistema libera el handle; no hace falta borrar un supuesto bloqueo obsoleto.
5. **Auditoría:** archivo nuevo por run ID en `audit`, UTF-8 sin BOM, JSON Lines. Inicio, omisiones, intención con hash/tamaño, resultado verificado y resumen. Se fuerza flush antes del borrado. Si falla el log, se detiene la ejecución y se devuelve código 5; no se continúa borrando sin trazabilidad.
6. **Ejecución:** revalidar ruta, política y metadatos inmediatamente antes de actuar; `Remove-Item -LiteralPath` solo para el candidato autorizado. Verificar su ausencia. Un fallo de archivo se registra y permite procesar otros candidatos; resultado global 3.
7. **Cierre:** resumen JSON en stdout, liberación de recursos incluso ante errores. `succeeded` cuenta eliminaciones comprobadas; `skipped`, omisiones; `failed`, errores de operación o infraestructura. El log y la adquisición del bloqueo no incrementan las eliminaciones.

Parámetros: `SandboxRoot` obligatorio y no vacío; `RetentionDays` 1–3650, predeterminado 14; `MaxFiles` 1–100, predeterminado 100 (límite tanto del manifiesto como de hijos inmediatos); `MaxFileBytes` 1–10485760, predeterminado 10 MiB. Límite adicional fijo de candidatos: 50 MiB totales. Manifiesto: máximo 64 KiB. Los límites excedidos abortan antes de mutar archivos.

El manifiesto contiene `schema: h3.disposable.v1`, `hold` booleano y `files` como lista explícita de nombres. Un manifiesto vacío preserva todo. `hold: true` suspende toda limpieza por investigación. La lista no admite subrutas, duplicados, extensiones distintas o nombres interpretables como patrones. El generador entrega ejemplos exclusivamente sintéticos, nunca copias de originales.

## Códigos de salida

| Código | Significado | Tratamiento |
|---|---|---|
| 0 | Ejecución sin errores, simulación o acción declinada | Revisar `mode`, `reason`, `planned` y conteos para distinguir lo ocurrido |
| 1 | PowerShell rechaza parámetros antes de entrar al script | Corregir invocación; el host puede emitir su propio error, sin JSON del script |
| 2 | Validación de raíz, estructura, política o límites fallida | No se inició transacción ni se creó log |
| 3 | Fallo de uno o más candidatos, posiblemente parcial | Revisar eventos y conteos; no interpretar como éxito total |
| 4 | Archivo de bloqueo no disponible por error de E/S | Puede indicar concurrencia; no se afirma que todo error de E/S sea otro proceso |
| 5 | Fallo de auditoría, permisos de infraestructura, importación o cierre | Detener/revisar. stdout es esencial si no pudo persistirse el log |

Los códigos 0, 1, 2, 3, 4 y 5 se verificaron como códigos reales de procesos hijos. Los permisos insuficientes de eliminación se simularon con mocks; el código 3 también se verificó con un archivo sintético abierto sin permitir borrado. El código 5 de proceso se comprobó con el bloqueo sintético de solo lectura. No se cambiaron ACLs del sistema.

## Pruebas

Pester 5 no estaba preinstalado (se encontró 3.4.0). Se descargó la versión 5.7.1 desde PowerShell Gallery, exclusivamente en `work-private/h3-tools/`. No se instaló globalmente. Para reproducir con Pester 5 disponible:

```powershell
./tests/Run-H3Tests.ps1 -Label ps51
# Ejecutar desde PowerShell 7 para validar ese motor, o:
pwsh -NoProfile -File ./tests/Run-H3Tests.ps1 -Label ps7
```

Con una copia privada del módulo, el comando realmente usado en cada motor fue:

```powershell
./tests/Run-H3Tests.ps1 -PesterManifest ./work-private/h3-tools/Pester-5.7.1/Pester.psd1 -Label ps51
pwsh -NoProfile -File ./tests/Run-H3Tests.ps1 -PesterManifest ./work-private/h3-tools/Pester-5.7.1/Pester.psd1 -Label ps7
```

En esta sesión `pwsh` se invocó mediante el ejecutable del runtime local porque no estaba en PATH; no se necesita esa ruta personal para reproducir. Pester `TestRegistry` y `TestDrive` están desactivados: la suite utiliza sus propios fixtures dentro del repositorio. No requiere acceso al registro. No hay alternativa de pruebas simulada: Pester 5 sí se ejecutó.

Resultados detallados revisados: [evidencia publicable](../evidencias/publicables/h3-tests.json). Datos crudos, dependencias y sandboxes quedan ignorados en `work-private/`. Los tests incluyen WhatIf del módulo y CLI, rutas inválidas, enlaces, manifiestos malformados, retención, preservación por hash, idempotencia, errores parciales, falsa eliminación, fallo de auditoría, concurrencia entre procesos y códigos de salida. No hay pruebas con datos de producción.

## Límites y revisión humana

- La limpieza no corrige el defecto de memoria, no recicla pools y no asegura resolver el riesgo de disco de E-006. Se preservan logs/dumps; su archivado/retención y crecimiento requieren una política aparte.
- JSONL es auditoría local, no backup ni registro inmutable. Su crecimiento no se purga automáticamente. No hay envío a redes ni Azure.
- El lock coordina participantes de este script. No protege contra administradores u otros procesos hostiles que cambien archivos/rutas entre comprobación y borrado. Para un uso futuro real, exigir ACLs de raíz y manifiesto, propietario operativo, control de cambios y análisis de carreras. La comprobación previa reduce el riesgo, no elimina TOCTOU.
- Un fallo de disco o terminación abrupta puede dejar una intención sin resultado final; nunca deducir éxito de una intención. Si falla el cierre del log, stdout/código del proceso prevalecen. No hay rollback del temporal borrado.
- Solo se aprobará un manifiesto real después de determinar qué temporales son prescindibles y qué evidencia está bajo retención. Los 14 días son un supuesto de laboratorio, no una política acordada para producción.
- Revisar personalmente las operaciones eliminadas, la restricción a sandbox, los límites, la retención y la suspensión por investigación. La rotación/revocación de la credencial original es una acción humana pendiente, fuera de esta implementación.
- H4/Azure permanecen sin iniciar. Commit de H3 autorizado; push y activaci?n en producci?n no autorizados.


## Pol?tica de rutas versionable

[Configuraci?n sint?tica](../tests/fixtures/h3/routes.synthetic.json): el generador sustituye `FIXTURE_NAME` por el nombre del sandbox reci?n creado y guarda una configuraci?n exacta en ?l. No autoriza todos los hermanos ni sus descendientes. Las rutas del modo laboratorio son relativas al repositorio, no al directorio de trabajo del proceso.

[Plantilla WEB-PAGOS-01](config/WEB-PAGOS-01.example.json): ejemplo local `D:\PortalPagos\Maintenance`, no una ruta observada ni validada del servidor. `enabled=false` bloquea incluso WhatIf hasta que un responsable prepare una copia revisada. No contiene identidades de usuario, contrase?as, tokens, recursos compartidos ni acciones de servicios. `computerName` identifica el host, no una cuenta.

El esquema cerrado se valida en `Get-AuthorizedRoot`, compatible con 5.1 sin dependencias. Se exigen exactamente estos ocho campos; se rechazan duplicados, campos desconocidos y tipos incorrectos:

| Campo | Contrato |
|---|---|
| `schema` | Literal `h3.routes.v1` |
| `mode` | `laboratory` o `deployment` |
| `enabled` | Booleano; debe ser true para cualquier ejecuci?n |
| `computerName` | null en laboratorio; host exacto actual en despliegue |
| `managedRoot` | Una ?nica ra?z exacta: relativa al repositorio en laboratorio, absoluta en despliegue |
| `laboratoryBoundary` | L?mite relativo expl?cito que contiene estrictamente la ra?z del laboratorio; null en despliegue |
| `markerName` | Nombre de archivo simple que comienza por punto, sin subrutas; fijo en laboratorio |
| `markerValue` | Valor no secreto que debe coincidir con el archivo marcador; fijo en laboratorio |

La configuraci?n se limita a 16 KiB. Tanto configuraci?n como directorio administrado deben estar en un volumen local fijo. Se rechazan ra?ces de unidad, UNC, traversal, comodines, streams alternos y reparse points/symlinks en rutas o ancestros. Se exige igualdad de ruta normalizada, no coincidencia por prefijo. La configuraci?n y el marcador se revalidan antes de cada borrado. El contenido del marcador identifica el directorio; no constituye autenticaci?n ni reemplaza ACLs.

**L?mite de confianza:** quien pueda modificar c?digo, configuraci?n o el argumento `ConfigurationPath` de la tarea puede cambiar la pol?tica. La seguridad del despliegue requiere que solo administradores autorizados puedan hacerlo; la identidad de ejecuci?n debe tener solo lectura sobre ellos. El m?dulo no certifica autom?ticamente dichas ACLs. Pasar otra configuraci?n escrita por el invocador no demuestra aprobaci?n operativa.

## Instalaci?n futura conceptual en Task Scheduler

No se ha instalado una tarea ni ejecutado la plantilla de despliegue. Procedimiento para una futura aprobaci?n en Windows Server:

1. Instalar m?dulo y CLI en un directorio local administrado, separado de datos temporales, con escritura exclusiva de administradores. Preparar una copia revisada de la plantilla y sustituir la ruta de ejemplo por el directorio realmente autorizado. No hace falta editar el m?dulo.
2. Preparar previamente la ra?z, `temp`, `audit`, `disposable.json`, `.maintenance.lock` y el marcador indicado. Empezar con manifiesto vac?o o `hold=true`; aprobar expl?citamente qu? temporales son desechables. No mover originales, logs o dumps para hacerlos candidatos.
3. Asignar una identidad de servicio de m?nimo privilegio: lectura/ejecuci?n del c?digo; solo lectura de configuraci?n, marcador y manifiesto; lectura/borrado limitado a temporales autorizados; escritura de logs en `audit` y apertura del lock. Sin administrador local, privilegios de reinicio ni permisos de red. Si el entorno permite una gMSA, Windows gestiona su contrase?a; la identidad se configura en Task Scheduler y nunca dentro del JSON o argumentos del script.
4. Mantener la tarea deshabilitada. Tras autorizar la validaci?n en Windows Server, habilitar ?nicamente la copia de configuraci?n revisada (`enabled=true`) y ejecutar manualmente con `-WhatIf` bajo la misma identidad. Verificar candidatos, esquema, marcador y ausencia de mutaciones; WhatIf no demuestra que los permisos de escritura sean suficientes. Validar esos permisos y fallos con fixtures sint?ticos en ese servidor antes de la activaci?n.
5. Configurar como acci?n Windows PowerShell 5.1 con `-NoProfile -NonInteractive -File "<ruta local de Invoke-Maintenance.ps1>" -ConfigurationPath "<configuraci?n aprobada>" -ManagedRoot "<ra?z exacta aprobada>" -WhatIf`. Todos los marcadores entre ?ngulos son valores a resolver, no comandos ejecutados. Nunca pasar contrase?a, usuario o token al script; respetar la pol?tica de ejecuci?n/firma del entorno, sin bypass.
6. Tras aprobaci?n expl?cita de activaci?n real y validaci?n en Windows Server, retirar WhatIf y habilitar la tarea en horario acordado. Configurar no iniciar otra instancia si ya est? en ejecuci?n, adem?s del lock del script. Supervisar Last Run Result/c?digo de proceso, stdout y JSONL; ante 3?5, investigar sin reintentos ciegos. Para detener la automatizaci?n, deshabilitar la tarea y revisar ejecuciones ya iniciadas.

Referencias oficiales consultadas: [principal y nivel de privilegio de tareas](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtaskprincipal) y [cuentas de servicio administradas](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-service-accounts). Son opciones de instalaci?n futura; no se ha creado ninguna identidad ni tarea.
