# Paquetes locales opcionales

Los ZIP no son un entregable obligatorio del enunciado del Reto 3. Son derivados reproducibles de archivos públicos del repositorio, ignorados por Git. El entregable revisable son las fuentes, consultas, pruebas y documentación. La ruta de importación de módulo elegida en Automation utiliza un ZIP; eso no obliga a adjuntarlo a la entrega académica. H4Guest.zip es solo comodidad de transporte y puede sustituirse por transferencia de los archivos revisados individualmente.

`H4SafeAutomation.zip` contiene exactamente:

```text
H4SafeAutomation/H4SafeAutomation.psd1
H4SafeAutomation/H4SafeAutomation.psm1
```

`H4Guest.zip` contiene exactamente:

```text
modules/H4SafeAutomation/H4SafeAutomation.psd1
modules/H4SafeAutomation/H4SafeAutomation.psm1
scripts/Build-H4Package.ps1
scripts/Install-H4Guest.ps1
scripts/Invoke-H4GuestRecovery.ps1
scripts/Invoke-H4LabFault.ps1
scripts/Invoke-H4Probe.ps1
config/H4.example.json
config/collection-and-alerts.example.json
```

No incluyen runbook, rol, KQL, documentación, pruebas, fixtures, resultados ni evidencia privada. Esos artefactos están separados en el repositorio. Tampoco incluyen dependencias Az/Pester ni archivos originales. Las entradas pueden usar separadores Windows dentro del ZIP; el inventario anterior los normaliza a `/`.

Las configuraciones mantienen suscripción, correo y webhook como **marcadores**, no valores reales, y políticas/alertas desactivadas. No existe URL de webhook, destinatario real, credencial ni ID real de Azure. El GUID del manifiesto identifica el módulo de software; no es un ID de cuenta o recurso Azure. Las rutas como `C:\ProgramData\H4Lab` son destinos genéricos de instalación, no rutas personales. Nombres de sitio/VM/RG son nombres previstos, no evidencia de recursos existentes.

Tras cada cambio, regenerar con `scripts/Build-H4Package.ps1`. Usar únicamente la generación recién comprobada bajo `work-private/h4-packages/`, con presupuesto USD 15. Las generaciones anteriores son históricas/obsoletas, no se despliegan ni se entregan; no se borran automáticamente. Revisar nombres y contenido de cada miembro y comparar SHA256 con la fuente, además del escaneo de secretos. Los ZIP no se cargaron a ningún servicio.
