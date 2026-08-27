// Smoke test del servicio desplegado contra la org real (sin capa HTTP/OAuth).
// Ejercita: mapeo 4 bloques -> Lead, upsert por External Id, validation rules de la org.
ED_NuamOnboardingLeadDTO.OnboardingRequest req = new ED_NuamOnboardingLeadDTO.OnboardingRequest();
req.onboardingId = 'SMOKE-APEX-001';

req.empresa = new ED_NuamOnboardingLeadDTO.Empresa();
req.empresa.razonSocial = 'Smoke Apex SpA';
req.empresa.rut = '77555444-3';
req.empresa.pais = 'Chile';
req.empresa.comuna = 'Providencia';
req.empresa.direccion = 'Av Prueba 100';
req.empresa.rubroComercial = 'Technology';

req.usuarioAdministrador = new ED_NuamOnboardingLeadDTO.UsuarioAdministrador();
req.usuarioAdministrador.nombre = 'Carlos';
req.usuarioAdministrador.apellido = 'Ruiz';
req.usuarioAdministrador.correo = 'carlos.ruiz@smoke.cl';

req.representanteLegal = new ED_NuamOnboardingLeadDTO.RepresentanteLegal();
req.representanteLegal.nombres = 'Pedro';
req.representanteLegal.apellidos = 'Gomez';
req.representanteLegal.cargo = 'Rep Legal';
req.representanteLegal.correo = 'pedro@smoke.cl';

req.facturacion = new ED_NuamOnboardingLeadDTO.Facturacion();
req.facturacion.nombres = 'Laura';
req.facturacion.apellidos = 'Diaz';
req.facturacion.cargo = 'Finanzas';
req.facturacion.pais = 'Chile';
req.facturacion.correoFacturacion = 'fact@smoke.cl';

// 1) CREATE
ED_NuamOnboardingLeadDTO.OnboardingResponse r1 = ED_NuamOnboardingLeadService.process(req);
System.debug('SMOKE_CREATE status=' + r1.status + ' leadId=' + r1.leadId);

// 2) UPDATE (mismo onboardingId, cambia razon social)
req.empresa.razonSocial = 'Smoke Apex ACTUALIZADO SpA';
ED_NuamOnboardingLeadDTO.OnboardingResponse r2 = ED_NuamOnboardingLeadService.process(req);
System.debug('SMOKE_UPDATE status=' + r2.status + ' leadId=' + r2.leadId);

// 3) VALIDATION ERROR (payload incompleto)
ED_NuamOnboardingLeadDTO.OnboardingRequest bad = new ED_NuamOnboardingLeadDTO.OnboardingRequest();
bad.onboardingId = 'SMOKE-APEX-002';
bad.empresa = new ED_NuamOnboardingLeadDTO.Empresa();
bad.empresa.razonSocial = 'Incompleta';
ED_NuamOnboardingLeadDTO.OnboardingResponse r3 = ED_NuamOnboardingLeadService.process(bad);
System.debug('SMOKE_ERROR status=' + r3.status + ' nErrors=' + r3.errors.size());

// Verificacion en BD
List<Lead> found = [SELECT Id, Company, LeadSource, ED_Onboarding_Id__c, ED_RepLegal_Nombres__c, ED_Fact_Correo__c
                    FROM Lead WHERE ED_Onboarding_Id__c = 'SMOKE-APEX-001'];
System.debug('SMOKE_DB count=' + found.size());
if (!found.isEmpty()) {
    System.debug('SMOKE_DB company=' + found[0].Company + ' source=' + found[0].LeadSource
        + ' repLegal=' + found[0].ED_RepLegal_Nombres__c + ' factMail=' + found[0].ED_Fact_Correo__c);
}
// limpieza
delete found;
System.debug('SMOKE_DONE');
