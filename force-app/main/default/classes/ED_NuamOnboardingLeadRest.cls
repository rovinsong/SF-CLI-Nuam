/**
 * Servicio REST inbound de Onboarding de Nuam.
 * Endpoint versionado: /services/apexrest/nuam/onboarding/v1/lead
 * Solo binding HTTP; la lógica vive en ED_NuamOnboardingLeadService.
 */
@RestResource(urlMapping='/nuam/onboarding/v1/lead')
global with sharing class ED_NuamOnboardingLeadRest {

    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        ED_NuamOnboardingLeadDTO.OnboardingResponse resp;
        try {
            String body = req.requestBody != null ? req.requestBody.toString() : '';
            ED_NuamOnboardingLeadDTO.OnboardingRequest input =
                (ED_NuamOnboardingLeadDTO.OnboardingRequest) JSON.deserialize(
                    body, ED_NuamOnboardingLeadDTO.OnboardingRequest.class);

            resp = ED_NuamOnboardingLeadService.process(input);
            res.statusCode = resolveStatus(resp.status);

        } catch (JSONException je) {
            resp = new ED_NuamOnboardingLeadDTO.OnboardingResponse();
            resp.status = 'error';
            resp.message = 'JSON inválido: ' + je.getMessage();
            res.statusCode = 400;
        } catch (Exception e) {
            resp = new ED_NuamOnboardingLeadDTO.OnboardingResponse();
            resp.status = 'error';
            resp.message = 'Error no controlado: ' + e.getMessage();
            res.statusCode = 500;
        }

        res.responseBody = Blob.valueOf(JSON.serialize(resp, true));
    }

    private static Integer resolveStatus(String status) {
        if (status == 'created') return 201;
        if (status == 'updated') return 200;
        return 400; // error de validación
    }
}
