// Crea el usuario de integración dedicado para el servicio Onboarding de Nuam (REQ-001).
// Licencia: Salesforce Integration (Client Credentials). Perfil: Minimum Access - API Only Integrations.
// Idempotente: si ya existe, solo asegura el Permission Set.

String uname = 'integracion.nuam@entel.cl.uat.nuamint';
String alias = 'nuamint';

Id profileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - API Only Integrations' LIMIT 1].Id;

List<User> existing = [SELECT Id FROM User WHERE Username = :uname LIMIT 1];
Id userId;
if (existing.isEmpty()) {
    User u = new User(
        Username = uname,
        LastName = 'Integracion Nuam Onboarding',
        Alias = alias,
        Email = 'salesforce_nuam@entel.cl',
        TimeZoneSidKey = 'America/Santiago',
        LocaleSidKey = 'es_CL',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'es',
        ProfileId = profileId
    );
    insert u;
    userId = u.Id;
    System.debug('USER_CREATED id=' + userId);
} else {
    userId = existing[0].Id;
    System.debug('USER_EXISTS id=' + userId);
}

// Asegura Permission Set con Apex + CRUD Lead + FLS ED_*
Id psId = [SELECT Id FROM PermissionSet WHERE Name = 'ED_Nuam_Onboarding_Integracion' LIMIT 1].Id;
List<PermissionSetAssignment> psa = [SELECT Id FROM PermissionSetAssignment
                                     WHERE AssigneeId = :userId AND PermissionSetId = :psId];
if (psa.isEmpty()) {
    insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = psId);
    System.debug('PS_ASSIGNED');
} else {
    System.debug('PS_ALREADY_ASSIGNED');
}
System.debug('INTEGRATION_USER_DONE username=' + uname);
