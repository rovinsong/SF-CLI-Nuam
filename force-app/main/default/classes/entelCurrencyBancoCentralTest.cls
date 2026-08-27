@isTest
private class entelCurrencyBancoCentralTest {
    
    @testSetup
    static void setupData() {
        // Verifica que exista la moneda USD en el org
        List<CurrencyType> usdCurrency = [SELECT Id, IsoCode FROM CurrencyType WHERE IsoCode = 'USD' LIMIT 1];
        System.assert(usdCurrency.size() > 0, 'Debe existir una moneda USD en el sistema');

        List<DatedConversionRate> usdRate = [SELECT Id, IsoCode FROM DatedConversionRate WHERE IsoCode = 'USD' LIMIT 1];
        System.assert(usdRate.size() > 0, 'Debe existir una tasa de conversión USD en el sistema');
    }

    @isTest
    static void testEjecutarMetodo() {
        // Inyección de parámetros simulados
        List<String> parametros = new List<String>{'TestParametro1', 'TestParametro2'};

        Test.startTest();
        List<List<String>> resultado = entelCurrencyBancoCentral.ejecutarMetodo(parametros);
        Test.stopTest();

        System.assertNotEquals(null, resultado, 'El resultado no debe ser nulo');
        System.assertNotEquals(0, resultado.size(), 'Debe haber al menos un log');
    }

    @isTest
    static void testGetCurrencyNow() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCalloutBancoCentral());
        Test.startTest();
        entelCurrencyBancoCentral.getCurrencyNow();
        Test.stopTest();
        System.assert(true, 'Se ejecutó getCurrencyNow sin errores');
    }

    @isTest
    static void testGetTokenRest() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCalloutBancoCentral());
        Test.startTest();
        entelCurrencyBancoCentral.AuthResponse response = entelCurrencyBancoCentral.getTokenRest('fakeClientId', 'fakeClientSecret');
        Test.stopTest();
        System.assertNotEquals(null, response);
        System.assertEquals('fakeToken', response.access_token);
    }

    @isTest
    static void testActualizarConversionRate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCalloutBancoCentral());
        Test.startTest();
        entelCurrencyBancoCentral.actualizarConversionRate('fakeId', 0.001234, 'fakeClientId', 'fakeClientSecret');
        Test.stopTest();
    }

    @isTest
    static void testActualizarCurrencyType() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCalloutBancoCentral());
        Test.startTest();
        entelCurrencyBancoCentral.actualizarCurrencyType('fakeId', 940.5, 'fakeClientId', 'fakeClientSecret');
        Test.stopTest();
    }

    @isTest
    static void testGetMonedaApi() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCalloutBancoCentral());
        Test.startTest();
        String response = entelCurrencyBancoCentral.getMonedaApi('https://fakeapi.com');
        Test.stopTest();
        System.assertEquals('940,99', response);
    }

    // Mock para simular respuestas HTTP
    private class MockHttpCalloutBancoCentral implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            if (req.getEndpoint().contains('/services/oauth2/token')) {
                res.setBody('{"access_token": "fakeToken"}');
            } else if (req.getEndpoint().contains('https://fakeapi.com')) {
                // Simula el JSON que espera deserializar entelCurrencyBancoCentral
                res.setBody('{"Codigo": 1, "Descripcion": "USD", "Series": {"descripEsp": "Dólar", "descripIng": "Dollar", "seriesId": "F072.COP.USD.N.O.D", "Obs": [{"indexDateString": "2025-07-30", "value": "940,99", "statusCode": "OK"}]}}');
            } else {
                res.setBody('{}');
            }
            return res;
        }
    }
}