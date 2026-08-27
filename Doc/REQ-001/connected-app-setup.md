# Connected App — Setup manual (REQ-001)

La org NUAM **bloquea la creación de Connected Apps vía Metadata API**
(error `No puede crear una aplicación conectada. Para activar la creación... contacte a Salesforce`).
Por eso la Connected App se crea **manualmente en la UI**. El XML de referencia está en
`connected-app/NUAM_Onboarding_Integracion.connectedApp-meta.xml`.

## Pasos (Setup UI)

1. **Setup → App Manager → New Connected App** (formulario Connected App tradicional).
2. Basic Information:
   - Connected App Name: `NUAM Onboarding Integracion`
   - API Name: `NUAM_Onboarding_Integracion`
   - Contact Email: correo del responsable Entel.
3. **Enable OAuth Settings**:
   - Callback URL: `https://login.salesforce.com/services/oauth2/callback` (requerido por el form aunque Client Credentials no lo use).
   - OAuth Scopes: `Manage user data via APIs (api)` y `Perform requests at any time (refresh_token, offline_access)`.
   - **Enable Client Credentials Flow**: marcado.
4. Save. Esperar ~10 min a la propagación.
5. **Manage → Edit Policies**:
   - Permitted Users: `Admin approved users are pre-authorized`.
   - **Client Credentials Flow → Run As**: seleccionar el **usuario de integración dedicado** (ver más abajo).
   - IP Relaxation: según política Entel (idealmente allowlist de IPs de Nuam).
6. El usuario de integración ya tiene asignado el Permission Set **`ED_Nuam_Onboarding_Apex`** (solo acceso a las clases Apex). NO usar `ED_Nuam_Onboarding_Integracion` para este usuario: esa licencia no admite CRUD sobre Lead.
7. Obtener **Consumer Key** y **Consumer Secret** (Manage Consumer Details). Entregarlos a Nuam por canal seguro. **Nunca** versionar en git.

## Usuario de integración (Run As) — YA CREADO en UAT

- Username: `integracion.nuam@entel.cl.uat.nuamint`
- Licencia: **Salesforce Integration** · Perfil: `Minimum Access - API Only Integrations`
- Permission Set: **`ED_Nuam_Onboarding_Apex`** (solo `classAccesses` a las 3 clases del servicio).

### Por qué dos Permission Sets (decisión de arquitectura)

La licencia **Salesforce Integration NO admite permisos CRUD sobre objetos estándar** (Lead).
Al intentar asignar `ED_Nuam_Onboarding_Integracion` (que incluye Create/Edit Lead + FLS) falla con
`La licencia de usuario no admite el permiso: Crear Lead`.

Solución: el Apex se ejecuta en **system mode** (el CRUD/FLS del objeto lo resuelve la clase, no el
usuario). Por eso el usuario de integración solo necesita **acceso a la clase Apex**, no CRUD directo.

- `ED_Nuam_Onboarding_Apex` → usuario de integración (licencia Integration). Solo Apex.
- `ED_Nuam_Onboarding_Integracion` → usuarios internos reales que necesiten ver/editar los campos
  ED_* del Lead en la UI (CRUD Lead + FLS). NO para el usuario de integración.

## Flujo OAuth para Nuam (Client Credentials)

```
POST https://<mi-dominio>.my.salesforce.com/services/oauth2/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
&client_id=<Consumer Key>
&client_secret=<Consumer Secret>
```

Respuesta → `access_token`. Luego:

```
POST https://<mi-dominio>.my.salesforce.com/services/apexrest/nuam/onboarding/v1/lead
Authorization: Bearer <access_token>
Content-Type: application/json

{ ...payload de onboarding... }
```

## Seguridad

- Consumer Secret y access_token son credenciales: canal seguro, rotación, sin loguear.
- Preferir IP allowlist de Nuam en las policies de la Connected App.
- El usuario Run As opera con FLS/CRUD mínimos del Permission Set, no admin.

Tags: #nuam #REQ-001 #connectedapp #oauth #setup
