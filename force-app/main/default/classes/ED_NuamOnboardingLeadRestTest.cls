/**
 * Pruebas del servicio REST de Onboarding Nuam -> Lead.
 * Cubre: created (201), updated (200), validación (400) y JSON inválido (400).
 */
@IsTest
private class ED_NuamOnboardingLeadRestTest {

    private static String buildBody(String onboardingId) {
        Map<String, Object> empresa = new Map<String, Object>{
            'razonSocial' => 'Comercial Andes SpA', 'rut' => '76123456-7',
            'pais' => 'Chile', 'comuna' => 'Las Condes',
            'direccion' => 'Av. Apoquindo 1234', 'rubroComercial' => 'Technology'
        };
        Map<String, Object> admin = new Map<String, Object>{
            'nombre' => 'Ana', 'apellido' => 'Pérez', 'telefono' => '+56911111111',
            'correo' => 'ana.perez@andes.cl', 'cargo' => 'Gerente', 'areaCargo' => 'TI'
        };
        Map<String, Object> repLegal = new Map<String, Object>{
            'nombres' => 'Juan Pablo', 'apellidos' => 'Soto Rojas',
            'cargo' => 'Representante Legal', 'correo' => 'jp.soto@andes.cl'
        };
        Map<String, Object> fact = new Map<String, Object>{
            'nombres' => 'María José', 'apellidos' => 'Lagos', 'telefono' => '+56922222222',
            'cargo' => 'Jefa Finanzas', 'areaCargo' => 'Finanzas',
            'pais' => 'Chile', 'correoFacturacion' => 'facturacion@andes.cl'
        };
        Map<String, Object> root = new Map<String, Object>{
            'onboardingId' => onboardingId, 'empresa' => empresa,
            'usuarioAdministrador' => admin, 'representanteLegal' => repLegal,
            'facturacion' => fact
        };
        return JSON.serialize(root);
    }

    private static void setContext(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/nuam/onboarding/v1/lead';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @IsTest
    static void testCreate() {
        setContext(buildBody('ONB-0001'));
        Test.startTest();
        ED_NuamOnboardingLeadRest.doPost();
        Test.stopTest();

        System.assertEquals(201, RestContext.response.statusCode, 'Debe crear con 201');
        List<Lead> leads = [SELECT Id, Company, ED_Onboarding_Id__c, ED_RepLegal_Nombres__c,
                            ED_Fact_Correo__c FROM Lead WHERE ED_Onboarding_Id__c = 'ONB-0001'];
        System.assertEquals(1, leads.size(), 'Debe existir 1 Lead');
        System.assertEquals('Comercial Andes SpA', leads[0].Company);
        System.assertEquals('Juan Pablo', leads[0].ED_RepLegal_Nombres__c);
        System.assertEquals('facturacion@andes.cl', leads[0].ED_Fact_Correo__c);
    }

    @IsTest
    static void testUpdate() {
        insert new Lead(LastName = 'Pérez', Company = 'Old Name', ED_Onboarding_Id__c = 'ONB-0002', LeadSource = 'Web');
        setContext(buildBody('ONB-0002'));
        Test.startTest();
        ED_NuamOnboardingLeadRest.doPost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Debe actualizar con 200');
        List<Lead> leads = [SELECT Id, Company FROM Lead WHERE ED_Onboarding_Id__c = 'ONB-0002'];
        System.assertEquals(1, leads.size(), 'No debe duplicar');
        System.assertEquals('Comercial Andes SpA', leads[0].Company, 'Debe actualizar Company');
    }

    @IsTest
    static void testValidationError() {
        // onboardingId presente pero empresa incompleta -> 400
        Map<String, Object> root = new Map<String, Object>{
            'onboardingId' => 'ONB-0003',
            'empresa' => new Map<String, Object>{ 'razonSocial' => 'X' }
        };
        setContext(JSON.serialize(root));
        Test.startTest();
        ED_NuamOnboardingLeadRest.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode, 'Payload inválido -> 400');
        String resp = RestContext.response.responseBody.toString();
        System.assert(resp.contains('"status":"error"'), 'Response debe indicar error');
        System.assertEquals(0, [SELECT COUNT() FROM Lead WHERE ED_Onboarding_Id__c = 'ONB-0003']);
    }

    @IsTest
    static void testInvalidJson() {
        setContext('{ esto no es json valido ');
        Test.startTest();
        ED_NuamOnboardingLeadRest.doPost();
        Test.stopTest();
        System.assertEquals(400, RestContext.response.statusCode, 'JSON inválido -> 400');
    }
}
