# Fase 2: Widgets y App Intents

## Cambios de cierre

1. `CafeineXIntentEnvironment` utiliza el contenedor persistente V5 y su plan de migración. El controlador de la app y los intents comparten el mismo contexto principal, también después de recuperación explícita. No se utiliza almacenamiento temporal en producción.
2. `CaffeineLoggingService` es la entrada de registro para Home, Quick Add, registrar de nuevo, widgets y Siri. Valida antes de escribir y devuelve el UUID local. Registro y outbox se guardan juntos. El UUID de la operación se conserva al reintentar; dos registros deliberados usan UUID distintos.
3. Undo usa ese mismo servicio. Espera una escritura HealthKit en curso, conserva el registro si la eliminación falla y no elimina exposiciones importadas. Los errores de Undo del sistema se conservan para mostrarlos y reintentarlos desde la app.
4. Solo las cuatro acciones solicitadas son descubribles. `LogFavoriteDrinkIntent` es interno, declara `name` y `caffeineMG` como parámetros y utiliza `supportedModes`, no `openAppWhenRun`.
5. Se corrigió el aislamiento Swift 6 de los valores de notificación y se añadió `SystemSurfaceLoggingTests`. La suite también detectó una expectativa incorrecta en `SleepSnapshotTests`: la noche anterior no pertenece a la sesión más reciente.

## Entrega del widget

El botón encola un comando en el App Group y abre la app. No escribe SwiftData desde la extensión. El inbox usa bloqueo entre procesos, JSON atómico y protección de archivo hasta el primer desbloqueo. La app consume al activarse y al recibir un comando mientras está abierta.

Un comando se reconoce solamente después del guardado local. Si la app termina entre guardar y reconocer, el reenvío conserva el UUID y no genera otro registro ni otro outbox. El doble toque del mismo favorito dentro de tres segundos se filtra, incluso si el primer comando ya se reconoció. No se descartan silenciosamente comandos antiguos ni los que superan veinte pendientes.

La cola anterior de UserDefaults se migra. Un archivo ilegible provoca un error visible, no un reinicio silencioso. Borrar todos los datos también limpia los comandos pendientes, el snapshot y los reintentos de Undo.

## HealthKit

La sincronización consulta primero muestras relacionadas mediante `appEntryID`. Las nuevas muestras llevan `HKMetadataKeySyncIdentifier` y `HKMetadataKeySyncVersion`. Después de guardar se consulta el UUID realmente persistido: un reintento de la misma versión puede ser ignorado por HealthKit y no debe enlazarse el UUID de un objeto descartado.

Los permisos denegados no impiden guardar localmente: el outbox permanece para sincronización posterior. Un registro desde Siri también queda en el outbox y se sincroniza cuando la app ejecuta su sincronización de Salud.

`CafeineXWidgetPublisher` actualiza los snapshots desde el contexto persistente sin depender de que Home esté abierto. Todos los rangos y estados continúan calculándose con `CaffeineEngine`.

## Comprobación reproducible

Desde la raíz:

```sh
./Scripts/cx build
./Scripts/cx test
./Scripts/cx analyze
```

`SystemSurfaceLoggingTests` cubre:

- Reabrir el almacenamiento después de guardar y antes de reconocer un comando.
- Identidad única en Home/widget, registros deliberados independientes y valores inválidos.
- Parámetros del favorito y visibilidad del intent interno.
- Doble toque, comandos concurrentes, migración y corrupción del inbox.
- Fallo de guardado sin registros pendientes accidentales.
- Outbox con permisos de Salud denegados.
- Recuperación de una muestra guardada pero aún no enlazada.
- Sincronización concurrente con Undo.
- Error de Undo, reabrir y reintentar; exclusión de muestras importadas.

Estas pruebas utilizan una implementación simulada de HealthKit. No sustituyen el recorrido desde SpringBoard/Siri ni la verificación en Salud real.

## Prueba de aceptación en dispositivo

- Instalar la nueva app y añadir Quick Log. Si el widget procede de una compilación anterior sin parámetros, quitarlo y añadirlo de nuevo.
- Configurar un favorito distinto de Espresso, por ejemplo Cold Brew de 200 mg.
- Con la app cerrada, tocarlo una vez: la app debe mostrar confirmación y History un solo registro, con nombre y cantidad correctos.
- Repetir con la app en segundo plano y abierta. Un doble toque accidental no debe duplicar el registro.
- Esperar más de tres segundos y registrar deliberadamente de nuevo: debe crear otra exposición.
- Activar Salud: comprobar una sola muestra por registro tras varias sincronizaciones y tras reabrir.
- Deshacer antes y después de la sincronización: debe desaparecer el registro correspondiente y su muestra propia, sin tocar muestras importadas.
- En Shortcuts/Siri, cancelar la confirmación de Log Caffeine: no debe escribirse nada. Aceptar: debe devolver un UUID local y persistir al reabrir.
- Probar Undo del sistema donde esté disponible. Si falla, la app debe ofrecer reintento; History sigue siendo el acceso al registro si el sistema no ofrece Undo.
- Comprobar Open Quick Add, Open History y Show Today’s Summary con la app cerrada y abierta.

No declarar el criterio de salida de dispositivo completado hasta registrar ese recorrido. Tampoco se considera validado aquí el rendimiento físico de menos de cinco segundos.

## Referencias de Apple

- [AppIntent e interacciones con el sistema](https://developer.apple.com/documentation/appintents/appintent)
- [Visibilidad de acciones internas](https://developer.apple.com/documentation/appintents/appintent/isdiscoverable-95nxm)
- [Modos de ejecución](https://developer.apple.com/documentation/appintents/appintent/supportedmodes-5zhmb)
- [Identidad de sincronización en HealthKit](https://developer.apple.com/documentation/healthkit/hkmetadatakeysyncidentifier)
- [Sincronización y prevención de duplicados](https://developer.apple.com/videos/play/wwdc2020/10184/)
