# Manual de comandos Salesforce CLI (`sf`)

Guía de referencia en español de los comandos más útiles de la **Salesforce CLI
moderna** (`sf`, paquete `@salesforce/cli`). Pensada como material de formación.

> La CLI antigua usaba el ejecutable `sfdx`. Hoy el comando es `sf` y la sintaxis
> es `sf <tema> <acción> [--flags]` (p. ej. `sf org login web`). Casi todos los
> comandos `sf` tienen forma larga (`--alias`) y corta (`-a`).

---

## 1. Comprobar instalación y entorno

```powershell
sf --version                 # versión de la CLI
sf --help                    # lista de temas (org, project, apex, data, ...)
sf org --help                # acciones del tema "org"
sf update                    # actualiza la CLI a la última versión
sf doctor                    # diagnóstico del entorno (útil para soporte)
```

---

## 2. Autenticación de orgs (`sf org login`)

### Login interactivo por navegador (lo más habitual)

```powershell
sf org login web --alias miOrg --set-default
```

- `--alias miOrg` (`-a`): nombre corto para referirte a la org después.
- `--set-default` (`-d`): la marca como org por defecto del proyecto.
- `--instance-url https://login.salesforce.com`: login normal (producción/dev).
  Para una **sandbox** usa `https://test.salesforce.com`.

Se abre el navegador, inicias sesión y autorizas. Al volver, la org queda guardada.

> ⚠️ **El "Nombre de usuario" NO es tu email.** En Salesforce el *username* de
> login es independiente del email de la cuenta. Las orgs nuevas asignan un
> username automático con sufijo, p. ej. `j.roman.0587.50a72bb417e4@agentforce.com`,
> aunque tu email sea `j.roman.0587@gmail.com`. Si el login da "Compruebe su usuario
> y contraseña", casi siempre es porque pusiste el email en vez del username real.
> Para verlo: dentro de la org → avatar → **Configuración** →
> **Información personal avanzada** → campo **Nombre de usuario**.

> **My Domain:** las Developer Editions modernas tienen un dominio propio
> (p. ej. `https://orgfarm-XXXX-dev-ed.develop.my.salesforce.com`). Si el login en
> `login.salesforce.com` da "Compruebe su usuario y contraseña" aunque sí puedas
> entrar por la web, usa tu My Domain en `--instance-url`. Si ya tienes sesión
> abierta en el navegador, solo tendrás que pulsar "Permitir acceso" (Allow).
>
> ```powershell
> sf org login web --alias miOrg --set-default \
>   --instance-url https://orgfarm-XXXX-dev-ed.develop.my.salesforce.com
> ```

### Otros métodos de login

```powershell
# Sandbox
sf org login web --alias miSandbox --instance-url https://test.salesforce.com

# Login para CI/CD sin navegador (JWT, requiere certificado y Connected App)
sf org login jwt --username usuario@org.com --jwt-key-file server.key \
  --client-id <CONSUMER_KEY> --alias ciOrg

# Pegar manualmente un "sfdxAuthUrl" (útil para compartir auth de forma segura)
sf org login sfdx-url --sfdx-url-file authFile.json --alias miOrg
```

### Cerrar sesión

```powershell
sf org logout --target-org miOrg
sf org logout --all
```

---

## 3. Gestionar orgs conectadas

```powershell
sf org list                          # todas las orgs autenticadas
sf org list --all                    # incluye scratch orgs expiradas
sf org display --target-org miOrg    # detalles: usuario, instancia, access token
sf org open --target-org miOrg       # abre la org en el navegador
sf config set target-org=miOrg       # fija la org por defecto del proyecto
sf config list                       # ver configuración actual
```

---

## 4. Scratch Orgs (orgs efímeras, requieren Dev Hub)

```powershell
# Habilitar Dev Hub: en la org -> Setup -> Dev Hub -> Enable. Luego:
sf org login web --alias devhub --set-default-dev-hub

# Crear una scratch org de 7 días a partir del fichero de definición
sf org create scratch --definition-file config/project-scratch-def.json \
  --alias scratch1 --set-default --duration-days 7

sf org list                          # ver scratch orgs y cuándo expiran
sf org delete scratch --target-org scratch1   # borrarla cuando ya no se use
```

---

## 5. Desplegar y recuperar código (`sf project`)

```powershell
# Desplegar TODO el código fuente del proyecto a la org
sf project deploy start --source-dir force-app

# Desplegar solo una carpeta o un fichero concreto
sf project deploy start --source-dir force-app/main/default/classes

# Validar sin desplegar (dry-run) y ejecutando tests
sf project deploy validate --source-dir force-app --test-level RunLocalTests

# Ver estado del último despliegue
sf project deploy report

# Traer cambios hechos EN la org de vuelta al repo local
sf project retrieve start --source-dir force-app

# Traer un tipo concreto de metadata
sf project retrieve start --metadata ApexClass:AccountService
```

---

## 6. Tests de Apex (`sf apex`)

```powershell
# Ejecutar todos los tests con cobertura, salida legible
sf apex run test --code-coverage --result-format human --wait 10

# Ejecutar una clase de test concreta
sf apex run test --class-names AccountServiceTest --result-format human --wait 10

# Ejecutar un bloque de código anónimo desde un fichero
sf apex run --file scripts/probar-callout.apex

# Ver logs de depuración
sf apex tail log               # logs en tiempo real
sf apex list log               # lista de logs guardados
sf apex get log --log-id <ID>  # descargar un log concreto
```

### ⚠️ ¿Cuándo corre tests un deploy?

**Por defecto, `sf project deploy start` NO ejecuta tests en sandbox/dev**, da
igual que el Apex sea nuevo o modificado (verás `Running Tests: Skipped`).

| Comando en dev/sandbox | ¿Corre tests? |
|---|---|
| `deploy start` (por defecto) | **No**, aunque el Apex sea nuevo |
| `deploy start --test-level RunLocalTests` | **Sí, siempre** |
| Deploy a **producción** | **Sí, obligatorio** (+75% cobertura) |

```powershell
# Forzar que corran (lo que usarías en CI/QA):
sf project deploy start --source-dir force-app --test-level RunLocalTests
```

Niveles de `--test-level`:
- `NoTestRun` — no corre (defecto en sandbox)
- `RunLocalTests` — tus tests, sin los de paquetes gestionados ← **el de CI/QA**
- `RunAllTestsInOrg` — absolutamente todos
- `RunSpecifiedTests` — solo los que indiques

> Regla: para garantizar tests, **pídelos siempre con `--test-level`**. No te
> fíes del comportamiento por defecto.

---

## 7. Datos y consultas (`sf data`)

```powershell
# Ejecutar una consulta SOQL
sf data query --query "SELECT Id, Name FROM Account LIMIT 5"

# SOQL con salida en CSV/JSON
sf data query --query "SELECT Id, Name FROM Account" --result-format csv

# Crear un registro
sf data create record --sobject Account --values "Name='Prueba CLI'"

# Actualizar / borrar por Id
sf data update record --sobject Account --record-id 001xxx --values "Name='Nuevo'"
sf data delete record --sobject Account --record-id 001xxx

# Importar/exportar datos en bloque (plan de árboles de registros)
sf data export tree --query "SELECT Id, Name FROM Account" --output-dir ./data
sf data import tree --files ./data/Account.json
```

---

## 7-bis. Backups: estructura vs. datos

Hay **dos tipos de backup** y son distintos:

| | Metadata (estructura) | Datos (registros) |
|---|---|---|
| Qué es | Objetos, campos, clases, flujos | Las filas reales (cuentas, contactos…) |
| Backup | `sf project retrieve` → git | `sf data export` → CSV/JSON |
| Restaurar | `sf project deploy` desde git | `sf data import` |

> **Regla:** todo objeto/campo que modifiques en la org → tráelo con `retrieve` y
> haz commit en git. **git es tu backup de estructura.**

### Backup de DATOS (registros)

```powershell
# Exportar registros de Account a archivo
sf data export tree --query "SELECT Id, Name, Phone FROM Account" \
  --output-dir ./backup-datos --target-org miOrg

# Restaurar esos datos más tarde
sf data import tree --files ./backup-datos/Account.json --target-org miOrg
```

> Los archivos de datos NO se versionan en git (pueden tener datos sensibles).

### Backup de METADATA

```powershell
# Traer la definición de un objeto (estándar o custom) al repo
sf project retrieve start --metadata "CustomObject:Account" --target-org miOrg
```

> En `sf`, el tipo `CustomObject` vale también para objetos estándar como Account.

---

## 8. Generar metadata y proyectos (`sf project generate`)

```powershell
# Crear un proyecto SFDX nuevo desde cero
sf project generate --name miProyecto

# Generar una clase Apex con su -meta.xml
sf apex generate class --name MiClase --output-dir force-app/main/default/classes

# Generar un trigger
sf apex generate trigger --name MiTrigger --sobject Account \
  --output-dir force-app/main/default/triggers

# Generar un Lightning Web Component
sf lightning generate component --name miComponente --type lwc \
  --output-dir force-app/main/default/lwc
```

---

## 9. Flujo de trabajo típico (resumen para formación)

1. `sf org login web --alias miOrg --set-default` — conectar la org una vez.
2. Editar código en `force-app/`.
3. `sf project deploy start --source-dir force-app` — subir cambios.
4. `sf apex run test --code-coverage --result-format human --wait 10` — probar.
5. `sf org open` — verificar en la org.
6. `git add` + `git commit` — versionar.

---

## Glosario rápido

| Término        | Qué es                                                            |
|----------------|-------------------------------------------------------------------|
| **Org**        | Una instancia de Salesforce (producción, sandbox, dev, scratch).  |
| **Dev Hub**    | Org especial que permite crear scratch orgs.                      |
| **Scratch Org**| Org temporal y desechable para desarrollo/CI.                     |
| **Metadata**   | Definición de la org como ficheros (clases, objetos, perfiles…).  |
| **Alias**      | Nombre corto para referirte a una org sin escribir el usuario.    |
| **`-meta.xml`**| Fichero que acompaña a cada componente con su configuración.      |
