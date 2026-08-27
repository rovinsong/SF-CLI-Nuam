/**
 * Lógica de mapeo Onboarding Nuam -> Lead y upsert por External Id.
 * Sin anotaciones REST para permitir pruebas unitarias sin RestContext.
 */
public with sharing class ED_NuamOnboardingLeadService {

    public class ValidationException extends Exception {}

    // Origen del Candidato (LeadSource) para Leads creados por la integración.
    // La org exige LeadSource no vacío en estado 'No contactado' (validation rule
    // Campos_Obligatorios_Estado_No_Contactado). Valor dedicado 'Onboarding'
    // agregado al StandardValueSet para identificar el origen digital de Nuam.
    @TestVisible
    private static final String DEFAULT_LEAD_SOURCE = 'Onboarding';

    /**
     * Procesa el request: valida obligatorios, mapea y hace upsert del Lead.
     * @return OnboardingResponse con status created/updated y el Id del Lead.
     */
    public static ED_NuamOnboardingLeadDTO.OnboardingResponse process(
        ED_NuamOnboardingLeadDTO.OnboardingRequest req
    ) {
        ED_NuamOnboardingLeadDTO.OnboardingResponse resp = new ED_NuamOnboardingLeadDTO.OnboardingResponse();

        List<ED_NuamOnboardingLeadDTO.FieldError> errs = validate(req);
        if (!errs.isEmpty()) {
            resp.status = 'error';
            resp.errors = errs;
            resp.message = 'Payload inválido: ' + errs.size() + ' error(es) de validación.';
            return resp;
        }

        Lead ld = mapToLead(req);

        // Detecta si ya existe para reportar created vs updated.
        Boolean exists = [
            SELECT COUNT() FROM Lead WHERE ED_Onboarding_Id__c = :req.onboardingId
        ] > 0;

        Database.UpsertResult ur = Database.upsert(ld, Lead.ED_Onboarding_Id__c, true);

        resp.status = exists ? 'updated' : 'created';
        resp.leadId = ur.getId();
        resp.dedupKey = req.onboardingId;
        resp.message = exists ? 'Lead actualizado.' : 'Lead creado.';
        return resp;
    }

    /** Valida los campos obligatorios del set v1. */
    @TestVisible
    private static List<ED_NuamOnboardingLeadDTO.FieldError> validate(
        ED_NuamOnboardingLeadDTO.OnboardingRequest req
    ) {
        List<ED_NuamOnboardingLeadDTO.FieldError> errs = new List<ED_NuamOnboardingLeadDTO.FieldError>();
        if (req == null) {
            errs.add(new ED_NuamOnboardingLeadDTO.FieldError('root', 'REQUIRED', 'Body vacío.'));
            return errs;
        }
        req('onboardingId', req.onboardingId, errs, 'onboardingId');

        if (req.empresa == null) {
            errs.add(new ED_NuamOnboardingLeadDTO.FieldError('empresa', 'REQUIRED', 'Bloque Empresa obligatorio.'));
        } else {
            req('empresa.razonSocial', req.empresa.razonSocial, errs, 'empresa.razonSocial');
            req('empresa.rut', req.empresa.rut, errs, 'empresa.rut');
            req('empresa.pais', req.empresa.pais, errs, 'empresa.pais');
            req('empresa.comuna', req.empresa.comuna, errs, 'empresa.comuna');
            req('empresa.direccion', req.empresa.direccion, errs, 'empresa.direccion');
            req('empresa.rubroComercial', req.empresa.rubroComercial, errs, 'empresa.rubroComercial');
        }

        if (req.usuarioAdministrador == null) {
            errs.add(new ED_NuamOnboardingLeadDTO.FieldError('usuarioAdministrador', 'REQUIRED', 'Bloque Usuario administrador obligatorio.'));
        } else {
            req('usuarioAdministrador.nombre', req.usuarioAdministrador.nombre, errs, 'usuarioAdministrador.nombre');
            req('usuarioAdministrador.apellido', req.usuarioAdministrador.apellido, errs, 'usuarioAdministrador.apellido');
            req('usuarioAdministrador.correo', req.usuarioAdministrador.correo, errs, 'usuarioAdministrador.correo');
        }

        if (req.representanteLegal == null) {
            errs.add(new ED_NuamOnboardingLeadDTO.FieldError('representanteLegal', 'REQUIRED', 'Bloque Representante legal obligatorio.'));
        } else {
            req('representanteLegal.nombres', req.representanteLegal.nombres, errs, 'representanteLegal.nombres');
            req('representanteLegal.apellidos', req.representanteLegal.apellidos, errs, 'representanteLegal.apellidos');
            req('representanteLegal.cargo', req.representanteLegal.cargo, errs, 'representanteLegal.cargo');
            req('representanteLegal.correo', req.representanteLegal.correo, errs, 'representanteLegal.correo');
        }

        if (req.facturacion == null) {
            errs.add(new ED_NuamOnboardingLeadDTO.FieldError('facturacion', 'REQUIRED', 'Bloque Facturación obligatorio.'));
        } else {
            req('facturacion.nombres', req.facturacion.nombres, errs, 'facturacion.nombres');
            req('facturacion.apellidos', req.facturacion.apellidos, errs, 'facturacion.apellidos');
            req('facturacion.cargo', req.facturacion.cargo, errs, 'facturacion.cargo');
            req('facturacion.pais', req.facturacion.pais, errs, 'facturacion.pais');
            req('facturacion.correoFacturacion', req.facturacion.correoFacturacion, errs, 'facturacion.correoFacturacion');
        }
        return errs;
    }

    /** Helper: agrega error si el valor está en blanco. */
    private static void req(
        String field, String value,
        List<ED_NuamOnboardingLeadDTO.FieldError> errs, String label
    ) {
        if (String.isBlank(value)) {
            errs.add(new ED_NuamOnboardingLeadDTO.FieldError(field, 'REQUIRED', 'Campo obligatorio: ' + label));
        }
    }

    /** Mapea el request a un registro Lead según el mapeo v1. */
    @TestVisible
    private static Lead mapToLead(ED_NuamOnboardingLeadDTO.OnboardingRequest req) {
        Lead ld = new Lead();
        ld.ED_Onboarding_Id__c = req.onboardingId;
        ld.LeadSource = DEFAULT_LEAD_SOURCE; // requerido por validation rule de la org

        // Empresa
        ld.Company = req.empresa.razonSocial;
        ld.ED_RUT_Empresa__c = req.empresa.rut;
        ld.Country = req.empresa.pais;
        ld.ED_Comuna__c = req.empresa.comuna;
        ld.Street = req.empresa.direccion;
        ld.Industry = req.empresa.rubroComercial; // texto->picklist: validar mapeo con Nuam

        // Usuario administrador -> persona natural del Lead
        ld.FirstName = req.usuarioAdministrador.nombre;
        ld.LastName = req.usuarioAdministrador.apellido;
        ld.Phone = req.usuarioAdministrador.telefono;
        ld.Email = req.usuarioAdministrador.correo;
        ld.Title = req.usuarioAdministrador.cargo;
        ld.ED_Admin_Area_Cargo__c = req.usuarioAdministrador.areaCargo;

        // Representante legal -> custom
        ld.ED_RepLegal_Nombres__c = req.representanteLegal.nombres;
        ld.ED_RepLegal_Apellidos__c = req.representanteLegal.apellidos;
        ld.ED_RepLegal_Cargo__c = req.representanteLegal.cargo;
        ld.ED_RepLegal_Correo__c = req.representanteLegal.correo;

        // Facturación -> custom
        ld.ED_Fact_Nombres__c = req.facturacion.nombres;
        ld.ED_Fact_Apellidos__c = req.facturacion.apellidos;
        ld.ED_Fact_Telefono__c = req.facturacion.telefono;
        ld.ED_Fact_Cargo__c = req.facturacion.cargo;
        ld.ED_Fact_Area_Cargo__c = req.facturacion.areaCargo;
        ld.ED_Fact_Pais__c = req.facturacion.pais;
        ld.ED_Fact_Correo__c = req.facturacion.correoFacturacion;

        return ld;
    }
}
