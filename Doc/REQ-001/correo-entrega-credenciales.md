# Correo de entrega de credenciales — REQ-001

> Plantilla para enviar a Nuam. Completar remitente/destinatario antes de enviar.
> SEGURIDAD: el `client_secret` NO va en el cuerpo del correo. Enviarlo por canal seguro aparte.

---

**Para:** `[contacto técnico Nuam]`
**CC:** `[equipo Entel]`
**Asunto:** Credenciales y contrato de integración — Servicio Onboarding → Lead (Salesforce)

Estimados,

Les compartimos los datos para consumir el servicio REST de Onboarding que crea/actualiza Leads en Salesforce a partir del payload de Nuam.

## 1. Autenticación (OAuth 2.0 – Client Credentials)

- **Token endpoint:** `https://platform-drive-1165--uat.sandbox.my.salesforce.com/services/oauth2/token`
- **grant_type:** `client_credentials`
- **client_id (Consumer Key):** *pegar aquí el Consumer Key*
- **client_secret (Consumer Secret):** **se entrega por canal seguro aparte** (no se incluye en este correo por política de seguridad).

## 2. Endpoint del servicio

- **URL:** `https://platform-drive-1165--uat.sandbox.my.salesforce.com/services/apexrest/nuam/onboarding/v1/lead`
- **Método:** `POST` · **Content-Type:** `application/json` · **Authorization:** `Bearer <access_token>`

## 3. Comportamiento

- Operación **idempotente** por `onboardingId`: la primera llamada crea el Lead (HTTP 201), las siguientes con el mismo `onboardingId` lo actualizan (HTTP 200). No genera duplicados.
- Validar siempre el campo `status` del cuerpo de respuesta, no solo el código HTTP.

## 4. Documentación adjunta

- Contrato completo (request/response, obligatoriedad, códigos): `contrato-api-v1.md`
- Especificación OpenAPI 3.0 (importable en Postman/Swagger): `openapi-onboarding-v1.yaml`

## 5. Pendientes para cerrar v1

- Confirmar nombres definitivos de campos del JSON.
- Enviar el catálogo de valores de `rubroComercial` (se mapea a un picklist en Salesforce).
- Indicar la(s) IP(s) de origen de Nuam para el allowlist de la conexión.

Quedamos atentos a coordinar una prueba conjunta en UAT.

Saludos cordiales,
`[Nombre]` — VP Negocios Digitales B2B, Entel

---

## Ejemplo de consulta

### Paso 1 — obtener token

```bash
curl -X POST \
  'https://platform-drive-1165--uat.sandbox.my.salesforce.com/services/oauth2/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=client_credentials' \
  -d 'client_id=<CONSUMER_KEY>' \
  -d 'client_secret=<CONSUMER_SECRET>'
```

### Paso 2 — enviar el onboarding

```bash
curl -X POST \
  'https://platform-drive-1165--uat.sandbox.my.salesforce.com/services/apexrest/nuam/onboarding/v1/lead' \
  -H 'Authorization: Bearer <access_token>' \
  -H 'Content-Type: application/json' \
  -d '{
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
      "nombre": "Ana", "apellido": "Pérez",
      "telefono": "+56911111111", "correo": "ana.perez@andes.cl",
      "cargo": "Gerente", "areaCargo": "TI"
    },
    "representanteLegal": {
      "nombres": "Juan Pablo", "apellidos": "Soto Rojas",
      "cargo": "Representante Legal", "correo": "jp.soto@andes.cl"
    },
    "facturacion": {
      "nombres": "María José", "apellidos": "Lagos",
      "telefono": "+56922222222", "cargo": "Jefa Finanzas",
      "areaCargo": "Finanzas", "pais": "Chile",
      "correoFacturacion": "facturacion@andes.cl"
    }
  }'
```

### Respuesta esperada (creación)

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

Tags: #nuam #REQ-001 #correo #credenciales
