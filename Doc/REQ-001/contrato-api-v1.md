# Contrato de API — Onboarding Nuam → Lead (REQ-001 v1)

> Servicio REST inbound de Entel/Salesforce. Consumidor: Nuam.
> Org UAT: `https://platform-drive-1165--uat.sandbox.my.salesforce.com`
> Versión de contrato: **v1**

## 1. Autenticación (OAuth 2.0 Client Credentials)

Paso 1 — obtener token:

```
POST https://platform-drive-1165--uat.sandbox.my.salesforce.com/services/oauth2/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
&client_id=<Consumer Key>
&client_secret=<Consumer Secret>
```

Respuesta:

```json
{
  "access_token": "00D...!AQ...",
  "instance_url": "https://platform-drive-1165--uat.sandbox.my.salesforce.com",
  "token_type": "Bearer"
}
```

El `client_id` / `client_secret` los entrega Entel por canal seguro tras crear la Connected App.

## 2. Endpoint

```
POST {instance_url}/services/apexrest/nuam/onboarding/v1/lead
Authorization: Bearer <access_token>
Content-Type: application/json
```

Idempotente por `onboardingId`: la primera llamada **crea** el Lead, las siguientes con el mismo `onboardingId` lo **actualizan** (upsert). No genera duplicados.

## 3. Request

```json
{
  "onboardingId": "ONB-2026-000123",
  "empresa": {
    "razonSocial": "Comercial Andes SpA",
    "rut": "76123456-7",
    "pais": "Chile",
    "comuna": "Las Condes",
    "direccion": "Av. Apoquindo 1234",
    "rubroComercial": "Technology"
  },
  "usuarioAdministrador": {
    "nombre": "Ana",
    "apellido": "Pérez",
    "telefono": "+56911111111",
    "correo": "ana.perez@andes.cl",
    "cargo": "Gerente",
    "areaCargo": "TI"
  },
  "representanteLegal": {
    "nombres": "Juan Pablo",
    "apellidos": "Soto Rojas",
    "cargo": "Representante Legal",
    "correo": "jp.soto@andes.cl"
  },
  "facturacion": {
    "nombres": "María José",
    "apellidos": "Lagos",
    "telefono": "+56922222222",
    "cargo": "Jefa Finanzas",
    "areaCargo": "Finanzas",
    "pais": "Chile",
    "correoFacturacion": "facturacion@andes.cl"
  }
}
```

### Obligatoriedad de campos (set v1)

| Bloque | Campo | Obligatorio |
|---|---|---|
| (raíz) | `onboardingId` | Sí |
| empresa | `razonSocial`, `rut`, `pais`, `comuna`, `direccion`, `rubroComercial` | Sí (todos) |
| usuarioAdministrador | `nombre`, `apellido`, `correo` | Sí |
| usuarioAdministrador | `telefono`, `cargo`, `areaCargo` | No |
| representanteLegal | `nombres`, `apellidos`, `cargo`, `correo` | Sí (todos) |
| facturacion | `nombres`, `apellidos`, `cargo`, `pais`, `correoFacturacion` | Sí |
| facturacion | `telefono`, `areaCargo` | No |

## 4. Response

### Éxito — creado (HTTP 201)

```json
{
  "status": "created",
  "leadId": "00Qdi00000QQnXZEA1",
  "dedupKey": "ONB-2026-000123",
  "message": "Lead creado.",
  "errors": [],
  "timestamp": "2026-08-27T13:40:00Z"
}
```

### Éxito — actualizado (HTTP 200)

```json
{
  "status": "updated",
  "leadId": "00Qdi00000QQnXZEA1",
  "dedupKey": "ONB-2026-000123",
  "message": "Lead actualizado.",
  "errors": [],
  "timestamp": "2026-08-27T13:41:00Z"
}
```

### Error de validación (HTTP 400)

```json
{
  "status": "error",
  "leadId": null,
  "dedupKey": null,
  "message": "Payload inválido: 3 error(es) de validación.",
  "errors": [
    { "field": "empresa.rut", "code": "REQUIRED", "detail": "Campo obligatorio: empresa.rut" },
    { "field": "empresa.pais", "code": "REQUIRED", "detail": "Campo obligatorio: empresa.pais" },
    { "field": "representanteLegal", "code": "REQUIRED", "detail": "Bloque Representante legal obligatorio." }
  ],
  "timestamp": "2026-08-27T13:42:00Z"
}
```

### JSON malformado (HTTP 400)

```json
{ "status": "error", "message": "JSON inválido: ...", "errors": [], "timestamp": "..." }
```

## 5. Códigos HTTP

| HTTP | status | Significado |
|---|---|---|
| 201 | created | Lead creado |
| 200 | updated | Lead actualizado (mismo onboardingId) |
| 400 | error | Payload inválido, campo obligatorio faltante o JSON malformado |
| 401 | — | Token ausente/expirado/ inválido |
| 500 | error | Error no controlado en Salesforce |

## 6. Reglas de contrato para el consumidor (Nuam)

1. **No confiar solo en el HTTP status**: siempre leer el campo `status` del body. Un 200/201 con `status:"error"` no debe ocurrir por diseño, pero la validación se hace por `status` + `errors[]`.
2. **Reintentos**: usar el mismo `onboardingId` para reintentar sin duplicar (upsert idempotente).
3. **`onboardingId`** debe ser único y estable por solicitud de onboarding; es la clave de deduplicación.
4. **Versionado**: este contrato es `v1`. Cambios incompatibles saldrán como `v2` en la URL sin romper `v1`.

## 7. Pendientes a confirmar con Nuam (antes de congelar v1)

- Nombres definitivos de propiedades del JSON (hoy provisionales).
- `rubroComercial`: se mapea al picklist `Industry` de Salesforce. Enviar catálogo de valores válidos o acordar tabla de mapeo. Valor no reconocido queda vacío.
- Formato/validación de `rut`.
- IP de origen de Nuam para allowlist en la Connected App.

Tags: #nuam #REQ-001 #contrato-api #openapi
