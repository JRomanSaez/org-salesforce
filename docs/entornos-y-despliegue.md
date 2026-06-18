# Entornos (DEV / UAT / PROD) y promoción de cambios

Cómo se organizan los entornos en Salesforce y cómo se promociona el código
entre ellos. Material de formación para el equipo.

## Concepto clave: cada entorno es una ORG distinta

En Salesforce **no se "forkea" una org**. UAT y PROD **no salen** de tu org de
desarrollo. Son **orgs independientes**:

- **Producción (PROD)** es la org "real" que paga la empresa.
- **UAT / QA / Integración** son **Sandboxes**: copias de producción que se crean
  **desde** la org de producción (no desde dev), pensadas para probar.
- **DEV** suele ser una sandbox de desarrollador o una scratch org.

```
        PROD (org de pago)
          │  (crea sandboxes desde Setup → Sandboxes)
          ├──────────────► Full / Partial Sandbox  → UAT
          ├──────────────► Developer Sandbox        → DEV
          └──────────────► Developer Pro Sandbox     → QA
```

> Tu Developer Edition de práctica es una org **suelta**, no ligada a un PROD.
> En una empresa real, las sandboxes "cuelgan" de la org de producción.

## Tipos de Sandbox

| Tipo | Qué copia | Uso típico |
|---|---|---|
| **Developer** | Solo metadata (sin datos) | Desarrollo individual |
| **Developer Pro** | Metadata + más espacio | Desarrollo / QA |
| **Partial Copy** | Metadata + muestra de datos | UAT / pruebas con datos |
| **Full** | Metadata + TODOS los datos | UAT final / pre-producción (réplica exacta) |

Se crean desde: **PROD → Setup → Sandboxes → New Sandbox**.

## El código NO se "copia" entre orgs: se DESPLIEGA

Lo que conecta los entornos **no es un fork, es git + deploy**. El mismo repo se
despliega a cada org:

```
        git repo (force-app/)
          │  sf project deploy start --target-org <orgX>
          ├──────► DEV     (mientras desarrollas)
          ├──────► UAT     (cuando pasa code review)
          └──────► PROD    (cuando UAT da el OK)  ← exige tests + 75%
```

Flujo típico de promoción:
1. Desarrollas en **DEV**, haces `retrieve` y commit al repo.
2. PR / code review → merge.
3. CI despliega a **UAT** con `--test-level RunLocalTests`.
4. El negocio valida en UAT.
5. CI despliega a **PROD** (tests obligatorios + 75% cobertura).

## Conectar varias orgs en la CLI

Cada org se autentica con su propio alias:

```powershell
sf org login web --alias dev   --instance-url https://test.salesforce.com
sf org login web --alias uat   --instance-url https://test.salesforce.com   # sandboxes = test.salesforce.com
sf org login web --alias prod  --instance-url https://login.salesforce.com

sf project deploy start --source-dir force-app --target-org uat --test-level RunLocalTests
sf project deploy start --source-dir force-app --target-org prod --test-level RunLocalTests
```

> **Sandboxes** se autentican contra `https://test.salesforce.com`.
> **Producción / Developer Edition** contra `https://login.salesforce.com`
> (o el My Domain correspondiente).

## Resumen mental

- ❌ No hay "fork" de orgs. ❌ UAT no nace de DEV.
- ✅ UAT/QA/DEV son **Sandboxes creadas desde PROD**.
- ✅ El **repo git es la fuente única**; el mismo código se **despliega** a cada org.
- ✅ Promoción = deploy a la siguiente org, con tests obligatorios al llegar a PROD.
