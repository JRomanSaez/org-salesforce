# org-salesforce — Práctica de Salesforce DX

Repositorio para practicar desarrollo en Salesforce: **Apex** e **integraciones**
(callouts REST a APIs externas), con la estructura estándar de **Salesforce DX (SFDX)**.

## Contenido

```
force-app/main/default/
├── classes/
│   ├── AccountService.cls         # Práctica Apex: SOQL + DML
│   ├── AccountServiceTest.cls
│   ├── TodoApiClient.cls          # Integración: callout HTTP REST
│   └── TodoApiClientTest.cls      # Test con HttpCalloutMock
└── remoteSiteSettings/
    └── JsonPlaceholder.remoteSite-meta.xml   # Permite el callout externo
config/project-scratch-def.json    # Definición de Scratch Org
```

## Requisitos previos (desde cero)

### 1. Instalar la Salesforce CLI

Vía npm (recomendada, requiere Node.js):

```powershell
npm install --global @salesforce/cli
```

> Nota: en winget no existe un paquete oficial fiable (`Salesforce.sfdx-cli` es la
> CLI antigua deprecada). Usa npm o el instalador oficial:
> https://developer.salesforce.com/tools/salesforcecli

Verifica:

```powershell
sf --version
```

### 2. Conseguir una org gratuita

Crea una **Developer Edition Org** gratis (no caduca):
https://developer.salesforce.com/signup

> Alternativa: si activas Dev Hub en tu org, puedes usar **Scratch Orgs**
> efímeras con `config/project-scratch-def.json` (ideal para CI/práctica limpia).

### 3. Autenticar la org

```powershell
sf org login web --alias miOrg --set-default --instance-url 'url de la instancia'
```

> 📖 Manual completo de comandos `sf` (en español, material de formación):
> [docs/comandos-sf.md](docs/comandos-sf.md)

## Flujo de trabajo

Desplegar el código fuente a la org:

```powershell
sf project deploy start --source-dir force-app
```

Ejecutar los tests de Apex:

```powershell
sf apex run test --code-coverage --result-format human --wait 10
```

Probar el callout de integración desde la consola anónima:

```powershell
sf apex run --file scripts/probar-callout.apex
```

Traer cambios hechos en la org de vuelta al repo:

```powershell
sf project retrieve start --source-dir force-app
```

## Notas

- El callout de `TodoApiClient` necesita el **Remote Site Setting** incluido
  (`JsonPlaceholder.remoteSite-meta.xml`) para funcionar en la org.
- Nunca commitees credenciales: `.gitignore` ya excluye `.env`, `*.key` y archivos de auth.
- `sourceApiVersion` está fijado en **61.0**; ajústalo si tu org usa otra versión.
