# Integración Onboarding Nuam → Salesforce

Fecha: 2026-10-16. Diagrama derivado del código y de los borradores locales.

![Diagrama de integración](diagrama-integracion-onboarding.svg)

## Lectura y alcance

- El panel azul representa componentes implementados en el checkout. No certifica despliegue ni prueba end-to-end en UAT.
- OAuth Client Credentials representa el mecanismo documentado; usuario Run As, permisos y políticas requieren alineación y verificación en la org.
- El panel ámbar representa exclusivamente la propuesta Account + Contact. Su endpoint no existe en la implementación actual.
- No se incluye middleware: no hay uno implementado o documentado en este alcance.
- Los contratos y diagramas no contienen credenciales. La ruta completa implementada es `/services/apexrest/nuam/onboarding/v1/lead`.

## Fuente editable Mermaid

El archivo [diagrama-integracion-onboarding.mmd](diagrama-integracion-onboarding.mmd) contiene la fuente. El SVG es una vista de presentación de la misma arquitectura, con distribución manual tipo herramienta de diagramación.

```mermaid
flowchart LR
  N["Nuam · Backend onboarding"]
  subgraph SF["Salesforce · solución Lead implementada localmente"]
    O["OAuth 2.0 Client Credentials<br/>Configuración y conectividad por reconfirmar"]
    R["Apex REST · POST /v1/lead<br/>ED_NuamOnboardingLeadRest"]
    S["Validación y mapeo de 4 bloques<br/>ED_NuamOnboardingLeadService + DTO"]
    L[("Lead<br/>ED_Onboarding_Id__c · único / External Id<br/>15 campos ED_* · LeadSource Onboarding")]
  end
  N -->|"1. POST /services/oauth2/token"| O
  O -->|"2. access_token"| N
  N -->|"3. JSON + Bearer token"| R
  R --> S
  S -->|"4. Upsert por onboardingId"| L
  S -->|"5. Resultado"| R
  R -->|"6. 201 / 200 / 400 / 500 + JSON"| N
  subgraph P["PROPUESTA · PENDIENTE DE IMPLEMENTAR / NO DESPLEGADA"]
    A["POST /v1/account<br/>Servicio Apex por construir"]
    AC[("Account · Empresa<br/>External Id propuesto: onboardingId")]
    C[("Contact · Representante legal / Facturación<br/>1..N por rol · deduplicación por definir")]
    X["Accionistas y beneficiarios finales<br/>Modelo y alcance pendientes"]
    A -.-> AC
    AC -.->|"1:N propuesto"| C
    A -.-> X
  end
  N -.->|"Evolución propuesta · CL / CO / PE"| A
  style N fill:#e0e7ff,stroke:#4338ca,color:#1f2937
  style SF fill:#f0f9ff,stroke:#0e7490
  style P fill:#fffbeb,stroke:#b45309,stroke-dasharray:6 4
  style O fill:#ede9fe,stroke:#6d28d9,color:#1f2937
  style R fill:#e0f2fe,stroke:#0369a1,color:#1f2937
  style S fill:#e0f2fe,stroke:#0369a1,color:#1f2937
  style L fill:#dcfce7,stroke:#15803d,color:#1f2937
  style A fill:#fef3c7,stroke:#b45309,stroke-dasharray:6 4,color:#1f2937
  style AC fill:#fef3c7,stroke:#b45309,stroke-dasharray:6 4,color:#1f2937
  style C fill:#fef3c7,stroke:#b45309,stroke-dasharray:6 4,color:#1f2937
  style X fill:#fef3c7,stroke:#b45309,stroke-dasharray:6 4,color:#1f2937
```

## Secuencia síncrona implementada

```mermaid
sequenceDiagram
    autonumber
    participant N as Nuam Backend
    participant O as Salesforce OAuth
    participant R as Apex REST
    participant S as Onboarding Service + DTO
    participant L as Lead
    Note over N,L: Implementación local; OAuth y estado UAT por reconfirmar
    N->>O: POST /services/oauth2/token (Client Credentials)
    O-->>N: access_token + instance_url
    N->>R: POST /v1/lead (JSON + Bearer)
    R->>S: Deserializar y validar request
    alt Payload obligatorio incompleto
        S-->>R: status=error + errors[]
        R-->>N: HTTP 400 + JSON
    else Payload válido
        S->>L: Upsert por ED_Onboarding_Id__c
        L-->>S: Resultado DML
        S-->>R: status + leadId
        R-->>N: HTTP 201 created / 200 updated
    end
    Note over R,S: JSON inválido: 400; excepción no controlada: 500
```

## Alternativa de texto

```text
NUAM backend
  |-- OAuth Client Credentials --> Salesforce OAuth
  |<--------- access_token -------|
  |-- POST /v1/lead + Bearer ----> Apex REST
  |                                  |
  |                             Service + DTO
  |                                  |
  |                           upsert por External Id
  |                                  v
  |                                Lead
  |<----- HTTP + JSON (leadId) -------|

PROPUESTA PENDIENTE DE IMPLEMENTAR
NUAM -- /v1/account --> Servicio futuro --> Account --> Contact (1:N)
                           |
                           +--> Accionistas / beneficiarios: por definir
```
