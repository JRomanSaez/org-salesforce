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

### 5. Evitar la recursión infinita

Un trigger (o un Flow) que actualiza un registro puede **re-dispararse a sí
mismo** (o a otro automatismo del mismo objeto), creando un bucle:

```
update Account → trigger se dispara → update Account → trigger otra vez → ... ♾️
```

Salesforce lo corta con un error (`Maximum trigger depth exceeded`, ~16 saltos, o
límites SOQL/DML), pero **tu operación falla**. Dos defensas:

**a) Guard con variable estática** — vive durante toda la transacción y actúa de freno:
```apex
public class AccountTriggerHandler {
    private static Boolean yaEjecutado = false;

    public static void run(List<Account> accs) {
        if (yaEjecutado) return;   // si ya corrió en esta transacción, salgo
        yaEjecutado = true;
        // ... lógica
    }
}
```

**b) Actuar solo si el campo relevante cambió** (lo más efectivo) — compara
valor viejo (`Trigger.oldMap`) vs. nuevo:
```apex
if (acc.Name != Trigger.oldMap.get(acc.Id).Name) {
    // solo recalculo si Name realmente cambió
}
```

> **Regla de oro:** el ciclo se rompe cuando **dejas de escribir si no hay cambio
> real**. Un automatismo que siempre actualiza, siempre se re-dispara; uno que
> solo actúa ante un cambio, se detiene solo.
>
> Por esto es arriesgado mezclar triggers y Flows sobre el mismo objeto sin
> coordinarlos: es donde nacen la mayoría de recursiones.

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
