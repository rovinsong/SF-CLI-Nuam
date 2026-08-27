# ADR-001 — Mecanismo de exposición del servicio Onboarding (REQ-001)

- **Estado:** Aceptada
- **Fecha:** 2026-08-27
- **Proyecto:** SF-CLI-NUAM · Org `NUAM` (sandbox UAT)
- **Decisores:** VP Negocios Digitales B2B / Arquitectura Entel

## Contexto

Nuam debe enviar el payload de Onboarding (4 bloques: Empresa, Usuario administrador, Representante legal, Facturación) y recibir en la **misma llamada** el `leadId` y el estado de la operación. El sistema externo inicia; Salesforce recibe.

Marco de referencia: **Salesforce Well-Architected — Integration Patterns**
(https://architect.salesforce.com/docs/architect/fundamentals/guide/integration-patterns.html).
Se usa por ser la guía canónica del vendor, que clasifica cada opción por *fit* con justificación.

Patrón identificado: **Remote Call-In**, síncrono (request/reply). Confirmado con negocio que la respuesta con `leadId` debe ser síncrona.

## Opciones evaluadas

| Opción | Fit oficial | Veredicto para REQ-001 |
|---|---|---|
| REST API estándar (`/sobjects`, upsert) | Best | Descartada: no transforma payload anidado ni entrega contrato de respuesta propio; obligaría a Nuam a conocer campos internos y validation rules |
| Composite / Composite Graph API | Best | Descartada: pensada para múltiples operaciones/objetos por transacción, innecesario para 1 Lead |
| Bulk API 2.0 | Best (bulk) | Descartada: asíncrona y para >2.000 registros |
| Platform Events + Pub/Sub API | Best (fire-and-forget) | Descartada: rompe el requisito de respuesta síncrona con `leadId` |
| **Apex REST** | Suboptimal (regla general) | **Elegida**, por la excepción documentada del framework: *"custom logic must be applied on the Salesforce side before committing"* |

## Decisión

Exponer el servicio como **Apex REST** (`@RestResource`), endpoint versionado
`/services/apexrest/nuam/onboarding/v1/lead`, con **upsert por External Id** (`ED_Onboarding_Id__c`).

Justificación de la desviación respecto al fit "Best": REQ-001 requiere lógica custom pre-commit
(transformación de 4 bloques anidados, validación de obligatoriedad por bloque, contrato de
respuesta propio, encapsular las validation rules de la org). El propio framework habilita
Apex REST/web services para este escenario.

## Autenticación

**Connected App + OAuth 2.0 Client Credentials Flow**, server-to-server, con **usuario de
integración dedicado** y el Permission Set `ED_Nuam_Onboarding_Integracion`. No se usa login
web interactivo. Alineado con la recomendación de seguridad del framework para Remote Call-In.

## Consecuencias

**Positivas**
- Contrato de API estable y versionado, desacoplado del modelo interno.
- La complejidad (validation rules, mapeo, LeadSource='Onboarding') queda encapsulada en Salesforce.
- Respuesta síncrona con `leadId` y `errors[]` estructurados.

**Negativas / deuda**
- Apex REST implica código a mantener y cubrir con tests (vs configuración declarativa).
- Sin resiliencia nativa de reintentos (a diferencia de Platform Events). Si a futuro Nuam
  tolera asincronía, reevaluar hacia event-driven.
- 1 Lead por request: si Nuam requiere lotes, migrar a Composite/Bulk.

**Riesgos a gestionar antes de producción**
- Error handling por contenido, no solo HTTP status (el framework advierte respuestas 200 con
  fallo en el body). Nuestro contrato ya separa `status`/`errors[]`.
- Límites de gobernador bajo volumen.
- Modelo Lead concentrando 4 personas + empresa: revisar conversión posterior a Account/Contact.

## Referencias

- [[REQ-001 - Diseño Técnico Onboarding Lead]]
- Salesforce Well-Architected — Integration Patterns (Remote Call-In, tabla de fit).

Tags: #nuam #REQ-001 #ADR #arquitectura #integracion
