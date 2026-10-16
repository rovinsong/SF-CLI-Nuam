# Correo — Onboarding Nuam → Salesforce · Datos de conexión servicio REST (UAT)

> **BORRADOR — PROPUESTA PENDIENTE DE IMPLEMENTAR. NO ENVIAR COMO SERVICIO DISPONIBLE.**
> El endpoint `/v1/account` no está implementado ni desplegado. URLs, comportamiento
> y respuestas de este documento son propuestas, pendientes de aprobación e implementación.

**Para:** [Equipo Nuam]
**CC:** [Entel — Negocios Digitales B2B]
**Asunto:** [PROPUESTA / NO DISPONIBLE] Onboarding Nuam → Salesforce · Account + Contact

---

Estimados,

Les compartimos para revisión la propuesta del futuro servicio REST de Onboarding que crearía/actualizaría **Cuentas y Contactos** en Salesforce a partir del payload de Nuam. El servicio está pendiente de implementar y no está disponible para consumo.

## 1. Autenticación (OAuth 2.0 – Client Credentials)

- **Token endpoint:** `https://platform-drive-1165--uat.sandbox.my.salesforce.com/services/oauth2/token`
- **grant_type:** `client_credentials`
- **client_id (Consumer Key):** _[pendiente — se entrega al crear la Connected App, por canal seguro]_
- **client_secret (Consumer Secret):** _[pendiente — se entrega al crear la Connected App, por canal seguro]_

## 2. Endpoint del servicio

- **URL:** `https://platform-drive-1165--uat.sandbox.my.salesforce.com/services/apexrest/nuam/onboarding/v1/account`
- **Método:** POST · **Content-Type:** application/json · **Authorization:** Bearer `<access_token>`

## 3. Comportamiento propuesto (pendiente de implementar)

- Operación idempotente por `onboardingId`: la primera llamada crea la Cuenta y sus Contactos (HTTP 201), las siguientes con el mismo `onboardingId` los actualizan (HTTP 200). No genera duplicados.
- Cada persona del payload (representante legal, contacto de facturación) se crea como Contacto asociado a la Cuenta, con su rol. Representante legal y facturación admiten múltiples registros.
- Validar siempre el campo `status` del cuerpo de respuesta, no solo el código HTTP.

## 4. Documentación adjunta

- Contrato propuesto (request/response y obligatoriedad): `REQ-001-contrato-account-contact-v1.md`.
- Especificación OpenAPI Account/Contact: pendiente de construir; no se adjunta.

## 5. Pendientes para cerrar v1

- Confirmar nombres definitivos de campos del JSON y el mapeo por país (CL/CO/PE difieren: RUT/NIT/RUC, geografía y campos notariales).
- Cerrar los pasos **Accionistas** y **Beneficiarios finales** del formulario (definen si van como Contactos o como objeto dedicado).
- Enviar el catálogo de valores de `actividad` / `rubroComercial` (se mapea a un picklist en Salesforce).
- Indicar la(s) IP(s) de origen de Nuam para el allowlist de la conexión.
- Quedamos atentos a coordinar una prueba conjunta en UAT.

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
  'https://platform-drive-1165--uat.sandbox.my.salesforce.com/services/apexrest/nuam/onboarding/v1/account' \
  -H 'Authorization: Bearer <access_token>' \
  -H 'Content-Type: application/json' \
  -d '{
    "onboardingId": "ONB-2026-000123",
    "pais": "CL",
    "empresa": {
      "razonSocial": "Comercial Andes SpA",
      "identificador": { "tipo": "RUT", "valor": "76123456-7" },
      "pais": "Chile",
      "region": "Metropolitana",
      "comuna": "Las Condes",
      "direccion": "Av. Apoquindo 1234",
      "actividad": "Comercio textil",
      "poseeDirectorio": true
    },
    "representantesLegales": [
      {
        "nombres": "Juan Pablo", "apellidos": "Soto Rojas",
        "tipoIdentificacion": "RUT", "numeroIdentificacion": "12345678-9",
        "nacionalidad": "Chilena", "paisResidencia": "Chile",
        "fechaNacimiento": "1985-04-12", "cargo": "Representante Legal",
        "areaCargo": "Legal", "correo": "jp.soto@andes.cl",
        "escrituraPublica": {
          "fecha": "2020-06-30", "numeroRepertorio": "12345-2020",
          "nombreNotaria": "Notaría Eduardo Pinto"
        }
      }
    ],
    "contactosFacturacion": [
      {
        "nombres": "María José", "apellidos": "Lagos",
        "telefono": "+56922222222", "cargo": "Jefa Finanzas",
        "areaCargo": "Finanzas", "pais": "Chile",
        "region": "Metropolitana", "comuna": "Providencia",
        "direccion": "Av. Providencia 1234",
        "correoFacturacion": "facturacion@andes.cl"
      }
    ],
    "accionistas": [],
    "beneficiariosFinales": []
  }'
```

### Respuesta esperada (creación)

```json
{
  "status": "created",
  "accountId": "001di00000QQnXZEA1",
  "dedupKey": "ONB-2026-000123",
  "contactos": [
    { "rol": "RepresentanteLegal", "contactId": "003di000GHIJKL1AAA", "status": "created" },
    { "rol": "Facturacion",        "contactId": "003di000MNOPQR2AAA", "status": "created" }
  ],
  "accionistas": [],
  "beneficiariosFinales": [],
  "message": "Cuenta y 2 contacto(s) procesados.",
  "timestamp": "2026-08-27T13:40:00Z"
}
```

---

Saludos,
[Nombre]
Negocios Digitales B2B · Entel
