# Buenas prácticas de Apex (triggers y handlers)

Conocimiento base para el equipo. Aplica a cualquier trigger en Salesforce.

## Las 4 reglas clave

### 1. Un solo trigger por objeto, sin lógica dentro
- Un único `.trigger` por objeto (patrón *One Trigger Per Object*).
- El trigger **solo decide cuándo y delega** en una clase handler.
- Varios triggers en el mismo objeto = orden de ejecución impredecible.
- Toda la lógica de negocio va en el **handler**, nunca en el `.trigger`.

### 2. Bulkificación (la más importante)
- Salesforce puede disparar el trigger con **hasta 200 registros a la vez**.
- El handler recibe **una lista** (`Trigger.new`) y la recorre con un `for`.
- ❌ **NUNCA** pongas SOQL ni DML **dentro** de un bucle → revienta los
  *governor limits* (límites de la plataforma).
- ✅ Consulta/inserta en bloque, fuera del bucle.

### 3. Contexto `before` = sin DML extra
- En `before insert` / `before update` puedes asignar valores al registro
  en memoria (`acc.Campo__c = ...`) y Salesforce los guarda solo.
- No necesitas un `update` adicional (que sí harías en `after`, más costoso
  y con riesgo de recursión).
- Regla: si solo modificas el propio registro → usa `before`.

### 4. Null-checks
- Comprueba nulos antes de usar métodos: `acc.Name == null ? 0 : acc.Name.length()`.
- Evita `NullPointerException` cuando un campo viene vacío.

## Patrón de archivos por cada trigger

| Archivo | Rol |
|---|---|
| `MiObjetoTrigger.trigger` | Delega según el evento (insert/update/...) |
| `MiObjetoTriggerHandler.cls` | Lógica de negocio (testeable, reutilizable) |
| `MiObjetoTriggerHandlerTest.cls` | Tests (obligatorios para producción, 75%) |

> Convención del ecosistema: por cada clase de lógica, una clase `...Test`.

## Crear triggers/clases: usa el generador, no escribas el XML a mano

Cada componente necesita 2 archivos: el código (`.cls`/`.trigger`) y su
metadata (`-meta.xml`). Sin el `-meta.xml`, el deploy falla. **No lo escribas a
mano** — usa el generador, que crea ambos correctos:

```bash
sf apex generate trigger --name AccountTrigger --sobject Account \
  --output-dir force-app/main/default/triggers
sf apex generate class --name AccountTriggerHandler \
  --output-dir force-app/main/default/classes
```

Luego solo editas el `.cls`/`.trigger` con tu lógica. El `-meta.xml` típico solo
contiene `apiVersion` y `status` (Active).
