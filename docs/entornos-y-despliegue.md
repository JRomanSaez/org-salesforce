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

## Todas las sandboxes se crean desde PROD (no de QA ni de UAT)

Confusión típica: **no se "saca una sandbox de QA"**. TODAS las sandboxes son
copias de **producción**. Cada IT/dev pide **su propia Developer Sandbox creada
desde PROD**.

```
                  PROD (única fuente)
                    │  Setup → Sandboxes → New Sandbox
        ┌───────────┼───────────┬──────────────┐
        ▼           ▼           ▼              ▼
       UAT         QA        DEV-juan       DEV-maria
  (Partial/Full)  (Pro)     (Developer)    (Developer)
```

"Actualizar" una sandbox con lo último de prod = **Refresh** (la vuelve a copiar).

## Límites de sandboxes (según licencia de PROD)

| Tipo | Cantidad típica (Enterprise) | Refresco mínimo |
|---|---|---|
| Developer | ~25-50+ | 1 día |
| Developer Pro | ~25 | 1 día |
| Partial Copy | ~5 | 5 días |
| Full | 1 | 29 días |

Developer son abundantes (una por dev); Full son escasas/caras (add-on de pago).

## ¿Cómo distingue el login si todas usan test.salesforce.com?

Por el **username con sufijo**, no por la URL. `test.salesforce.com` es la puerta
común; el sufijo indica a qué sandbox entras:

```
PROD:              juan@empresa.com
Sandbox "devjuan": juan@empresa.com.devjuan
Sandbox "qa":      juan@empresa.com.qa
```

## ¿Cómo trae un dev "todo lo de prod" a su sandbox nueva?

**No hace falta `retrieve` de todo.** Al crear la Developer Sandbox, Salesforce
**ya copia toda la metadata de prod** automáticamente. La sandbox nace completa.

Separar dos cosas:
- **Metadata** → ya está en la sandbox desde el minuto cero (la copió de prod).
- **Código en git** → sirve para el *flujo de trabajo*, no para "traer prod".

Flujo de un dev con su sandbox:
```bash
git checkout main && git pull              # main = espejo de PROD
git checkout -b feature/dev1-loquesea      # rama propia desde main
# ... desarrolla en su sandbox (que ya tiene todo prod) ...
sf project retrieve start --metadata ApexClass:MiClase   # SOLO lo que cambia
git add . && git commit && git push        # PR → merge a main → deploy
```

Claves:
- `main` ≈ espejo de PROD (convención: todo deploy a PROD sale de `main`).
- Creas rama desde `main` y trabajas (sí, tu intuición era correcta).
- `retrieve` **solo de lo que tú modificas**, no de todo (serían miles de archivos).

## Resumen mental

- ❌ No hay "fork" de orgs. ❌ UAT no nace de DEV. ❌ No se saca sandbox de QA.
- ✅ Todas las sandboxes (UAT/QA/DEV) son copias **creadas desde PROD**.
- ✅ La sandbox nace con **toda la metadata de prod** ya dentro (no hace falta retrieve masivo).
- ✅ El **repo git es la fuente única** del código; `main` = espejo de PROD.
- ✅ Cada dev: rama desde `main` → trabaja en su sandbox → retrieve de SUS cambios → PR.
- ✅ Promoción = deploy a la siguiente org, con tests obligatorios al llegar a PROD.
