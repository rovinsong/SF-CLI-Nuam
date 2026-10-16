# REQ-001 — Resumen de implementación Onboarding Nuam

**Fecha de revisión local:** 2026-10-16

**Proyecto:** SF-CLI-NUAM

**Org objetivo documentada:** NUAM UAT (`salesforce_nuam@entel.cl.uat`)

**Estado general:** solución Onboarding → Lead implementada; evolución Account + Contact todavía en diseño.

## 1. Objetivo

El proyecto implementa una integración REST inbound para recibir desde Nuam los datos de onboarding de una empresa y crear o actualizar un registro en Salesforce. El contrato vigente implementado trabaja con `Lead` y devuelve en forma síncrona el identificador Salesforce y el resultado de la operación.

## 2. Arquitectura implementada

- Patrón: Remote Call-In síncrono.
- Tecnología: Apex REST.
- Endpoint v1: `POST /services/apexrest/nuam/onboarding/v1/lead`.
- Autenticación prevista: OAuth 2.0 Client Credentials con usuario de integración dedicado.
- Idempotencia: upsert mediante `Lead.ED_Onboarding_Id__c` como External Id único.
- Respuesta: `created`, `updated` o `error`, junto con `leadId`, `dedupKey`, mensaje, errores y timestamp.

## 3. Componentes construidos

### Apex

| Componente | Responsabilidad |
|---|---|
| `ED_NuamOnboardingLeadRest` | Expone el endpoint, deserializa el JSON y traduce el resultado a códigos HTTP. |
| `ED_NuamOnboardingLeadService` | Valida obligatorios, mapea el payload y ejecuta el upsert de Lead. |
| `ED_NuamOnboardingLeadDTO` | Define los DTO de request, response y errores. |
| `ED_NuamOnboardingLeadRestTest` | Prueba creación, actualización, validación y JSON malformado. |

### Modelo de datos

Se agregaron 15 campos `ED_*` en Lead:

- Identificador único de onboarding.
- RUT y comuna de la empresa.
- Área de cargo del usuario administrador.
- Nombres, apellidos, cargo y correo del representante legal.
- Nombres, apellidos, teléfono, cargo, área, país y correo de facturación.

También se incorporó `Onboarding` como valor de `LeadSource`.

### Seguridad e integración

- `ED_Nuam_Onboarding_Apex`: acceso a las clases Apex para el usuario con licencia Salesforce Integration.
- `ED_Nuam_Onboarding_Integracion`: CRUD/FLS de Lead para usuarios internos compatibles.
- Metadata y guía para configurar Connected App / External Client App con Client Credentials.
- Plantilla para entregar Consumer Key y Consumer Secret por un canal seguro.

### Despliegue y operación

- Manifest de feature: `manifest/features/REQ-001-onboarding-lead.xml`.
- Smoke test: `scripts/apex/smoke-req001.apex`.
- Contrato Markdown y especificación OpenAPI 3.0.
- ADR con la decisión de utilizar Apex REST.
- Instrucciones de configuración de la aplicación OAuth.

## 4. Payload implementado

El contrato Lead recibe cuatro bloques:

1. Empresa: razón social, RUT, país, comuna, dirección y rubro comercial.
2. Usuario administrador: nombre, apellido, teléfono, correo, cargo y área.
3. Representante legal: nombres, apellidos, cargo y correo.
4. Facturación: nombres, apellidos, teléfono, cargo, área, país y correo.

Los campos opcionales pueden omitirse; los obligatorios generan una respuesta HTTP 400 cuando están vacíos.

## 5. Evidencia histórica registrada en Git

El historial local indica:

- Validación inicial del servicio y sus componentes.
- Despliegue de REQ-001 en NUAM UAT.
- Ejecución satisfactoria de un smoke test de creación, actualización y validación.
- Creación del usuario de integración y del Permission Set Apex-only.

Estas entradas son evidencia histórica del repositorio. Deben reconfirmarse contra la org antes de una nueva entrega o promoción.

## 6. Evolución Account + Contact

Existe una propuesta local para reemplazar el modelo Lead por:

- Empresa → Account.
- Representantes legales → uno o varios Contact.
- Contactos de facturación → uno o varios Contact.
- Variantes de campos para Chile, Colombia y Perú.
- Futuro modelado de accionistas y beneficiarios finales.

Esta evolución no está implementada. Actualmente no existen:

- Endpoint `/services/apexrest/nuam/onboarding/v1/account`.
- Clases Apex Account/Contact.
- Campos de Account/Contact propios de este contrato.
- Lógica de deduplicación de contactos.
- Modelo de accionistas o beneficiarios finales.
- Pruebas o manifest de despliegue para esta versión.

Los documentos Account/Contact deben tratarse como borradores y no como un servicio disponible.

## 7. Pendientes antes de producción

1. Confirmar con Nuam si el modelo definitivo será Lead o Account + Contact.
2. Alinear el manifest con `ED_Nuam_Onboarding_Apex` y la configuración OAuth realmente utilizada.
3. Aplicar mínimo privilegio a scopes, políticas OAuth y usuario Run As.
4. Reemplazar la detección `created`/`updated` previa al upsert por `UpsertResult.isCreated()`.
5. Validar longitudes, formatos de correo/RUT, países y catálogo de `Industry` antes del DML.
6. Evitar retornar mensajes internos de excepciones Salesforce al consumidor.
7. Incorporar pruebas de permisos, límites, errores DML, concurrencia e idempotencia.
8. Ejecutar validación y pruebas Apex en NUAM UAT.
9. Verificar en la org cualquier Flow relacionado; el XML local no demuestra el estado de la versión activa.

## 8. Estado verificable al 2026-10-16

- Código, metadata, manifest y documentación Lead: presentes localmente.
- XML y OpenAPI: sintácticamente válidos en la última revisión local.
- Tests Apex en esta revisión: no ejecutados; la conexión CLI a NUAM UAT no respondió por resolución DNS.
- Estado funcional OAuth/HTTP end-to-end: pendiente de reconfirmación.
- Repositorio Git: rama local `main`, sin remote ni upstream configurado al momento de esta revisión.
