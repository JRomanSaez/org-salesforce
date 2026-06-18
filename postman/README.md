# Postman — Simular una app externa llamando a Salesforce

Colección que simula tu web/app llamando al endpoint `LeadFormApi` para crear
un Lead. Flujo: **autenticar (obtener token) → crear Lead**.

## Archivos

- `salesforce-lead-api.postman_collection.json` — las 2 requests (Auth + Crear Lead)
- `salesforce-local.postman_environment.json` — variables (URLs, client_id/secret)

## 1. Importar en Postman

Postman → **Import** → arrastra los dos archivos.
Arriba a la derecha, selecciona el entorno **"Salesforce Local (org-salesforce)"**.

## 2. Configurar la Connected App (en Salesforce)

1. Setup → **App Manager** → **New Connected App**
2. Enable OAuth Settings; Callback URL: `https://login.salesforce.com/services/oauth2/callback`
3. OAuth Scopes: `api`, `refresh_token`
4. ☑ **Enable Client Credentials Flow**
5. Save (espera unos minutos a que active)
6. En la app → **Manage** → **Edit Policies** → en *Client Credentials Flow*
   asigna un **Run As** user (tu usuario admin)
7. **Manage Consumer Details** → copia **Consumer Key** y **Consumer Secret**

## 3. Rellenar variables de entorno

En Postman, edita el entorno y pon:
- `client_id` = Consumer Key
- `client_secret` = Consumer Secret
- (las URLs ya apuntan a tu My Domain)

## 4. Ejecutar

1. Lanza **"Auth - Client Credentials"** → guarda el `access_token` automáticamente.
2. Lanza **"Crear Lead"** → debería devolver `201` y `{ "ok": true, "leadId": "00Q..." }`.

## ⚠️ Seguridad

NO commitees el entorno con el `client_secret` real. El `.gitignore` del repo
debe excluirlo (ver nota en el README raíz).
