# REQ-001 — Contrato API Onboarding → Account + Contact (v1 propuesto)

> **Estado: PROPUESTA PENDIENTE DE IMPLEMENTAR — NO DESPLEGADA.**
> El endpoint `/v1/account`, los campos y la lógica descritos son un diseño propuesto;
> no están disponibles para consumo. La implementación local existente es `/v1/lead`.
> Esta propuesta plantea reemplazar la integración a `Lead`. Pendiente cerrar pasos
> `03 Datos accionistas` y `04 Datos beneficiarios finales`, y confirmar API names /
> tipos contra la org real de Nuam antes de congelar.

## Modelo de datos

- **Empresa** → `Account` (1).
- **Representante legal** → `Contact` hijo, rol `RepresentanteLegal`. Multiplicidad **1..N**.
- **Contacto de facturación** → `Contact` hijo, rol `Facturacion`. Multiplicidad **1..N** (confirmado en Perú).
- **Accionistas** / **Beneficiarios finales** → pendiente (Contact-con-rol vs objeto custom con % de participación). Reservados como arreglos vacíos en el contrato.
- **Deduplicación:** `onboardingId` como External Id del Account; Contactos por rol + identificación.

## Endpoint

```
POST {instanceUrl}/services/apexrest/nuam/onboarding/v1/account
Authorization: Bearer <token>
Content-Type: application/json
```

UAT: `https://platform-drive-1165--uat.sandbox.my.salesforce.com/services/apexrest/nuam/onboarding/v1/account`

## Discriminador de país

`pais`: `CL` | `CO` | `PE`. Superset de campos; los no aplicables van `null`. Obligatoriedad condicional por país.

### Empresa por país

| Campo | CL | CO | PE |
|---|---|---|---|
| identificador.tipo | RUT | NIT | RUC |
| geo | comuna | departamento + ciudad | (solo país + dirección) |
| actividad | rubroComercial | actividadEconomica | rubroComercial |
| poseeDirectorio | sí | — | sí (directores) |

### Representante legal por país (1..N)

| Campo | CL | CO | PE |
|---|---|---|---|
| tipoIdentificacion | (RUT implícito) | ✔ | ✔ |
| paisResidencia | ✔ | ✔ | — |
| fechaNacimiento | ✔ | — | — |
| cargo / areaCargo | ✔ | — | cargo ✔ |
| escrituraPublica (fecha, repertorio, notaría) | ✔ | — | — |

### Facturación por país

| Campo | CL | CO | PE |
|---|---|---|---|
| multiplicidad | 1 | 1 | 1..N |
| geo | region + comuna + dirección | departamento + ciudad + dirección | — |
| telefono/cargo/area obligatorios | no | sí | teléfono sí |
| hesOc | ✔ | — | — |

## Request de ejemplo (CL)

```json
{
  "onboardingId": "ONB-CL-0001",
  "pais": "CL",
  "empresa": {
    "razonSocial": "Comercializadora Andes SpA",
    "identificador": { "tipo": "RUT", "valor": "76.123.456-7" },
    "pais": "Chile",
    "departamento": null,
    "region": "Metropolitana",
    "ciudad": null,
    "comuna": "Las Condes",
    "direccion": "Av. Apoquindo 4500, of. 1201",
    "actividad": "Comercio textil",
    "poseeDirectorio": true
  },
  "representantesLegales": [
    {
      "nombres": "María José",
      "apellidos": "Velásquez Fuentes",
      "tipoIdentificacion": "RUT",
      "numeroIdentificacion": "12.345.678-9",
      "nacionalidad": "Chilena",
      "paisResidencia": "Chile",
      "fechaNacimiento": "1985-04-12",
      "cargo": "Gerente General",
      "areaCargo": "Administración",
      "correo": "mj.velasquez@andes.cl",
      "escrituraPublica": {
        "fecha": "2020-06-30",
        "numeroRepertorio": "12345-2020",
        "nombreNotaria": "Notaría Eduardo Pinto"
      }
    }
  ],
  "contactosFacturacion": [
    {
      "nombres": "Rodrigo",
      "apellidos": "Salas Pérez",
      "telefono": "+56 9 5555 1234",
      "cargo": "Jefe de Finanzas",
      "areaCargo": "Finanzas",
      "pais": "Chile",
      "region": "Metropolitana",
      "comuna": "Providencia",
      "direccion": "Av. Providencia 1234",
      "correoFacturacion": "facturacion@andes.cl",
      "hesOc": "Tengo documento"
    }
  ],
  "accionistas": [],
  "beneficiariosFinales": []
}
```

## Response de ejemplo

```json
{
  "status": "created",
  "accountId": "001di000ABCDEF1AAO",
  "dedupKey": "ONB-CL-0001",
  "contactos": [
    { "rol": "RepresentanteLegal", "contactId": "003di000GHIJKL1AAA", "status": "created" },
    { "rol": "Facturacion",        "contactId": "003di000MNOPQR2AAA", "status": "created" }
  ],
  "accionistas": [],
  "beneficiariosFinales": [],
  "message": "Cuenta y 2 contacto(s) procesados.",
  "timestamp": "2026-09-11T18:40:00Z",
  "errors": []
}
```

## Response de error

```json
{
  "status": "error",
  "message": "Payload inválido: 2 error(es) de validación.",
  "errors": [
    { "field": "empresa.identificador.valor", "code": "REQUIRED", "detail": "Campo obligatorio: RUT/NIT/RUC" },
    { "field": "representantesLegales[0].correo", "code": "REQUIRED", "detail": "Campo obligatorio: correo" }
  ]
}
```

## Pendientes antes de congelar

- [ ] Pasos `03 Datos accionistas` y `04 Datos beneficiarios finales` (CL/CO/PE) → definen Contact-con-rol vs objeto custom con % participación.
- [ ] Confirmar API names / tipos / obligatoriedad de campos custom en Account y Contact contra la org.
- [ ] Confirmar si "Usuario administrador" (v1 Lead) queda fuera de alcance (en PE el stepper lo liga al paso Empresa).
- [ ] Estrategia de dedup de Contactos (por rol + identificación vs correo).
- [ ] Autenticación del servicio inbound (Connected App + OAuth / JWT).
