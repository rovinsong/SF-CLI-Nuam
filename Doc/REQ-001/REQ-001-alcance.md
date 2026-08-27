# REQ-001 — Servicio REST inbound Onboarding → Lead

## Resumen ejecutivo

- Entel construye un servicio REST **inbound** (POST, JSON) que **crea o actualiza (upsert)** un `Lead` en Salesforce a partir del payload de Onboarding de Nuam.
- Incluye: contrato de API (request/response con Id de Lead y estado de operación), **versionado en la URL**, y **upsert** por clave de deduplicación.
- Mapeo de campos en 4 bloques: **Empresa, Usuario administrador, Representante legal, Facturación** (set v1).
- Consideración técnica clave: **Representante legal** y **Facturación** traen nombre/apellido propios → **no** se mapean a los campos estándar de contacto del Lead; requieren **campos personalizados**.
- **Todo el mapeo (API name, tipo de dato, obligatoriedad) debe confirmarse contra la org real de Nuam antes de congelar el contrato.**

---

## 3.1 Servicio REST inbound

| Aspecto | Definición |
|---|---|
| Método | POST (recibe JSON) |
| Acción | Crear o actualizar `Lead` |
| Contrato | Request + Response (con Id del Lead y estado de la operación) |
| Versionado | En la URL, para evolucionar el contrato sin romper al consumidor |
| Deduplicación | Upsert según clave a definir |

## 3.2 Mapeo de campos Onboarding → Lead (set v1)

> El mapeo final y la obligatoriedad se cierran con Nuam antes de congelar el contrato.

### 3.3 Bloque Empresa

| Campo Onboarding | Obligatorio |
|---|---|
| Razón social | Sí |
| RUT | Sí |
| País | Sí |
| Comuna | Sí |
| Dirección | Sí |
| Rubro comercial | Sí |

### 3.4 Bloque Usuario administrador

| Campo Onboarding | Obligatorio |
|---|---|
| Nombre | Sí |
| Apellido | Sí |
| Teléfono | No |
| Correo electrónico | Sí |
| Cargo | No |
| Área de cargo | No |

### 3.5 Bloque Representante legal

| Campo Onboarding | Obligatorio |
|---|---|
| Nombres | Sí |
| Apellidos | Sí |
| Cargo | Sí |
| Correo electrónico | Sí |

### 3.6 Bloque Facturación

| Campo Onboarding | Obligatorio |
|---|---|
| Nombres | Sí |
| Apellidos | Sí |
| Teléfono | No |
| Cargo | Sí |
| Área de cargo | No |
| País | Sí |
| Correo de facturación | Sí |

## Consideración técnica

Los bloques **Representante legal** y **Facturación** traen sus propios nombres y apellidos, por lo que **no** se mapean a los campos estándar de contacto del `Lead` y **requieren campos personalizados**. Debe confirmarse contra la org real de Nuam, incluyendo el **API name** y el **tipo de dato** de cada campo.

---

## Pendientes / puntos abiertos (a cerrar con Nuam antes de congelar contrato)

- [ ] **Clave de deduplicación** del upsert: ¿RUT empresa? ¿Correo admin? ¿External Id dedicado? — sin esto no se puede implementar el upsert.
- [ ] **Mapeo a campos estándar vs. custom** del Lead (Empresa → `Company`, Admin → `FirstName`/`LastName`/`Email`, etc.) y catálogo de campos custom para Rep. legal y Facturación.
- [ ] **Tipos de dato y API names** confirmados contra la org real de Nuam.
- [ ] **Contrato response**: estructura del estado de operación (created / updated / error) y códigos.
- [ ] **Esquema de versionado** de la URL (ej. `/services/apexrest/nuam/onboarding/v1`).
- [ ] **Autenticación** del servicio inbound (Connected App + OAuth, JWT, etc.) — no está en el alcance descrito, confirmar.
- [ ] **Manejo de RUT**: formato esperado, validación, normalización.
