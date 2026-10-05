# Reto 4 - Triage asistido por IA

**Estado: no implementado; diferido por priorización del tiempo disponible.**

Se priorizó el cierre de los retos de diagnóstico, mantenimiento seguro y observabilidad en Azure porque podían entregarse con evidencia real, pruebas reproducibles y resultados verificables. Esta decisión sigue la indicación del enunciado de entregar menos componentes bien terminados y explicar lo pendiente, en lugar de presentar todos los retos parcialmente desarrollados.

Se decidió no presentar una integración de IA superficial o insuficientemente evaluada. Un componente de triage requiere validar el esquema de salida, restringir las acciones sugeridas a un catálogo autorizado, controlar la información enviada al modelo y demostrar cómo responde ante indisponibilidad, demoras, respuestas inválidas o recomendaciones inventadas.

No existe código, integración ni evidencia de ejecución correspondiente al Reto 4, y no se presenta como implementado.

## Orden de implementación pendiente

1. Definir un contrato JSON cerrado para entrada y salida.
2. Crear un catálogo versionado y autorizado de runbooks.
3. Minimizar y depurar los logs y eventos enviados al modelo.
4. Implementar clasificación, resumen y recomendación estructurada.
5. Validar la respuesta contra el esquema y rechazar runbooks inexistentes.
6. Manejar timeout, indisponibilidad del proveedor y JSON inválido.
7. Preparar casos de prueba de memoria, pool detenido o respuestas 503 y capacidad de disco.
8. Incluir un caso donde el modelo se equivoque o invente evidencia y demostrar que el diseño lo detecta.
9. Evaluar precisión, consistencia, utilidad y nivel de confianza.
10. Mantener revisión humana obligatoria y no permitir ejecución automática de cambios en la primera versión.

## Límites previstos

- Ningún secreto o dato sensible se enviaría al modelo.
- El modelo solo podría elegir acciones de un catálogo cerrado.
- Una respuesta inválida, incompleta o de baja confianza produciría escalamiento humano.
- La primera versión sería únicamente de recomendación y no tendría permisos para modificar producción.