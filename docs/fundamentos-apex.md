# Fundamentos de Apex

Guía base del lenguaje **Apex** para el equipo. Apex es muy parecido a **Java**:
sintaxis de llaves, clases, tipado estático, `try/catch`. Si vienes de Java o
Spring Boot, te resultará familiar — aquí destacamos lo **distinto** y lo básico.

> Apex se ejecuta **en los servidores de Salesforce**, no en tu máquina. Está
> pensado para manipular datos de la plataforma y siempre corre bajo límites
> estrictos (*governor limits*).

---

## 1. Tipos de datos

### Primitivos
```apex
Integer  i = 10;
Long     l = 100000L;
Decimal  d = 19.99;      // para dinero / precisión (NO uses Double para €)
Double   db = 3.14;
Boolean  b = true;
String   s = 'Hola';     // comillas SIMPLES siempre (no dobles)
Date     hoy = Date.today();
Datetime ahora = Datetime.now();
Id       recordId = '001xx...';   // tipo especial: el Id de un registro
```

Peculiaridades:
- **Strings con comilla simple** `'texto'`. Las dobles `"` NO existen para String.
- **`Decimal`** es el tipo para importes (no `Double`), por precisión.
- **`Id`** es un tipo propio: representa el identificador único de 15/18 chars
  de un registro de Salesforce.

### Colecciones (las 3 que usarás siempre)
```apex
List<String> nombres = new List<String>{ 'a', 'b' };   // lista ordenada
Set<Id>      ids      = new Set<Id>();                  // sin duplicados
Map<Id, Account> porId = new Map<Id, Account>();        // clave-valor
```
- `List` = como `ArrayList` en Java.
- `Set` = como `HashSet`.
- `Map` = como `HashMap`. Muy usado para agrupar por Id.

### sObjects (lo MÁS propio de Apex)
Un **sObject** es un registro de la base de datos como objeto en memoria.
Cada objeto de Salesforce (Account, Contact, tu `Poliza__c`) es un tipo:
```apex
Account acc = new Account(Name = 'Acme', Phone = '600...');
acc.Nombre_Longitud__c = acc.Name.length();   // campos custom acaban en __c
```
No hay getters/setters: accedes a los campos directamente (`acc.Name`).

---

## 2. Consultas: SOQL y SOSL (integrado en el lenguaje)

A diferencia de Java/JPA, **las consultas van embebidas en el código** entre
corchetes `[ ]`, no como strings sueltos:

```apex
// SOQL: consultar registros (como SELECT de SQL, pero de Salesforce)
List<Account> cuentas = [SELECT Id, Name FROM Account WHERE Name LIKE 'A%'];

// Variables de Apex dentro de SOQL con ":"  (bind variable)
String prefijo = 'Acme%';
List<Account> r = [SELECT Id FROM Account WHERE Name LIKE :prefijo];

// Contar
Integer total = [SELECT COUNT() FROM Account];
```
- Solo pides los campos que necesitas (`SELECT Id, Name`), no `SELECT *`.
- El `:variable` inyecta valores de Apex de forma segura (evita inyección).

---

## 3. DML: insertar / actualizar / borrar

```apex
Account a = new Account(Name = 'Nueva');
insert a;            // guarda y rellena a.Id

a.Name = 'Cambiada';
update a;

delete a;
undelete a;          // sí, se puede deshacer (papelera)
upsert a;            // insert o update según tenga Id
```
- Tras `insert`, el registro recibe su `Id` automáticamente.
- ⚠️ **Bulkificación:** nunca hagas DML/SOQL dentro de un bucle. Trabaja con
  listas: `insert listaDeCuentas;` en vez de insertar de una en una.

---

## 4. Clases y modificadores

```apex
public with sharing class MiServicio {
    public static String saludar(String nombre) {
        return 'Hola ' + nombre;
    }
}
```
Peculiaridades frente a Java:
- **`with sharing` / `without sharing`**: controla si el código respeta los
  permisos de registro del usuario. `with sharing` = respeta seguridad (lo
  habitual). Es un concepto exclusivo de Salesforce.
- **`global`**: un nivel de acceso por encima de `public`, visible incluso
  desde fuera del paquete/namespace. Se usa poco.
- No hay `package` ni `import`: todas las clases comparten un espacio común
  (por eso los namespaces y los nombres únicos importan).

---

## 5. Tests — aquí lo que te recordaba a Spring (`@isTest`)

Apex usa **anotaciones** parecidas a JUnit/Spring:

```apex
@isTest
private class MiServicioTest {

    @TestSetup
    static void setup() {
        // Datos comunes a todos los tests (como @BeforeEach)
        insert new Account(Name = 'Base');
    }

    @isTest
    static void saluda_ok() {
        Test.startTest();              // marca el bloque a medir (límites frescos)
        String r = MiServicio.saludar('Ana');
        Test.stopTest();

        System.assertEquals('Hola Ana', r, 'mensaje si falla');
    }
}
```

Peculiaridades MUY importantes de los tests en Apex:
- **`@isTest`** sobre la clase y sobre cada método de test.
- Los tests **NO ven los datos reales** de la org: arrancan con BD vacía. Tienes
  que **crear tú los datos** dentro del test (`insert ...`).
- **`Test.startTest()` / `Test.stopTest()`**: aíslan el código a probar y le dan
  un conjunto **fresco** de governor limits. El código asíncrono se ejecuta al
  llegar a `stopTest()`.
- **`System.assertEquals(esperado, real, mensaje)`**: las aserciones.
- **`@TestSetup`**: prepara datos una vez para todos los métodos (como
  `@BeforeEach` / `@BeforeAll` de JUnit).
- **Callouts HTTP prohibidos en tests** → se simulan con `HttpCalloutMock`
  (ver `TodoApiClientTest`).
- **Cobertura mínima 75%** para desplegar a producción.

Anotaciones afines:
- **`@AuraEnabled`** → expone un método a componentes Lightning (frontend).
- **`@future`** → ejecuta el método de forma asíncrona.
- **`@InvocableMethod`** → permite llamar el método desde Flows.

---

## 6. Governor Limits (lo más exclusivo de Apex)

Salesforce es multi-tenant: muchos clientes comparten servidores. Para que nadie
los acapare, impone **límites por transacción**. Los que más te afectan:

| Límite | Valor aprox. por transacción |
|---|---|
| Consultas SOQL | 100 |
| Registros DML | 150 operaciones |
| Registros recuperados por SOQL | 50.000 |
| Tiempo de CPU | 10 segundos |

Por eso la **bulkificación** no es opcional: si haces SOQL en un bucle de 200
registros, superas el límite y la transacción **falla entera**.

---

## 7. Resumen "vengo de Java"

| Java / Spring | Apex |
|---|---|
| `String s = "x"` | `String s = 'x'` (comilla simple) |
| `import` / `package` | no existen (espacio común) |
| JPA / `@Repository` | SOQL embebido `[SELECT ...]` |
| `@Test` (JUnit) | `@isTest` |
| `@BeforeEach` | `@TestSetup` |
| `assertEquals` | `System.assertEquals` |
| `BigDecimal` | `Decimal` |
| Sin límites de runtime | Governor limits estrictos |
| Seguridad en capa de servicio | `with sharing` en la clase |
