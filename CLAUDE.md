# Proyecto SF-CLI-NUAM

Proyecto Salesforce operado con `sf` CLI y la skill `salesforce-cli`.

## Org

| Campo | Valor |
|-------|-------|
| Alias | `NUAM` (default local) |
| Username | `salesforce_nuam@entel.cl.uat` |
| Tipo | Sandbox (UAT) — login vía `test.salesforce.com` |
| OrgId | `00Ddi000004xlyHEAQ` |
| API | 67.0 |

## Convenciones

- Metadata en `force-app/main/default/`. Manifests por feature en `manifest/features/`.
- Antes de modificar: discovery/retrieve de metadata vigente. No inventar campos ni datos de negocio.
- Deploy: `deploy validate` primero; `deploy start` solo con alcance confirmado y evidencia post-deploy.
- Labels en español; `description` e `inlineHelpText` por cada campo custom.
- Diagramas de arquitectura derivados en `arquitectura/` (no son fuente de verdad ni metadata desplegable).

## Estado

Scaffolding SFDX inicial. Sin metadata funcional aún.
