//with sharing hace que la clase respete las reglas de seguridad y uso compartido de registros del usuario que ejecuta el código
    public with sharing class entelCurrencyBancoCentral{
        
        public class currencyBancoCentral {
            public Integer Codigo;
            public String Descripcion;
            public currencySeries Series;
        }
        
        public class currencySeries {
            public String descripEsp;
            public String descripIng;
            public String seriesId;
            public List<currencyObs> Obs;
        }
        
        public class currencyObs {
            public String indexDateString;
            public String value;
            public String statusCode;
        }

        public class AuthResponse {
            public String access_token;
            public String signature;
            public String instance_url;
            public String id;
            public String token_type;
            public String issued_at;
        }
        
        public static List<String> logs = new List<String>();       
        // Método para obtener todos los logs acumulados
        public static List<String> getLogs() {
            return logs;
        }
                
        @InvocableMethod(label='getCurrencyNowBancoCentral' description='Ejecuta una lógica personalizada desde Flow')
        public static List<List<String>> ejecutarMetodo(List<String> parametros) {                    
            //antes de la ejecucion obtiene el ultimo registro modificado desde la tabla CurrencyType
            CurrencyType latestCurrencyType = [SELECT Id, LastModifiedDate 
                                           FROM CurrencyType
                                           ORDER BY LastModifiedDate DESC
                                           LIMIT 1];
            
            //Llama ejecucion asincrona
            getCurrencyNow();                      
            List<List<String>> listSalida = new List<List<String>>();           
            listSalida.add(getLogs());
            return listSalida;
        }
        
        @future(callout=true)
        public static void getCurrencyNow() {       
            try {            
                Map<String, CurrencyType> monedasVigentes = new Map<String, CurrencyType>();
                for (CurrencyType mon : [SELECT IsoCode FROM CurrencyType WHERE IsActive = true AND IsCorporate = false]) {
                    monedasVigentes.put(mon.IsoCode, mon);
                }                        
        
                Set<String> isoCodesActivos = new Set<String>();
                for (String isoCode : monedasVigentes.keySet()) {
                    isoCodesActivos.add(isoCode);
                }
                    
                Map<String, DatedConversionRate> monedas = new Map<String, DatedConversionRate>();            
                for (DatedConversionRate moneda : [SELECT Id, IsoCode FROM DatedConversionRate WHERE IsoCode IN :isoCodesActivos]) {
                    monedas.put(moneda.IsoCode, moneda);
                }
        
                Map<String, entelGetCurrencyMetadataBancoCentral__mdt> mantenedorMap = new Map<String, entelGetCurrencyMetadataBancoCentral__mdt>();
                for (entelGetCurrencyMetadataBancoCentral__mdt record : [SELECT CurrencyIsoCode__c, endPoint__c, clientId__c, clientSecret__c, user__c, password__c, serie__c FROM entelGetCurrencyMetadataBancoCentral__mdt]) {
                    mantenedorMap.put(record.CurrencyIsoCode__c, record);
                }
        
                Map<String, Decimal> conversionRates = new Map<String, Decimal>();
                Map<String, Double> currencyTypes = new Map<String, Double>();
        
                for (String isoCode : monedas.keySet()) {
                    entelGetCurrencyMetadataBancoCentral__mdt encontrado = mantenedorMap.get(isoCode);
                    if (encontrado != null) {                                         
                        Date firstDate = Date.today();
                        Date lastDate = Date.today();
                        
                        String formattedFirstDate = firstDate.year() + '-' +
                                                    (firstDate.month() < 10 ? '0' + firstDate.month() : String.valueOf(firstDate.month())) + '-' +
                                                    (firstDate.day() < 10 ? '0' + firstDate.day() : String.valueOf(firstDate.day()));
                        
                        String formattedLastDate = lastDate.year() + '-' +
                                                   (lastDate.month() < 10 ? '0' + lastDate.month() : String.valueOf(lastDate.month())) + '-' +
                                                   (lastDate.day() < 10 ? '0' + lastDate.day() : String.valueOf(lastDate.day()));
                        string urlBuild = encontrado.endPoint__c +'user='+encontrado.user__c + '&pass='+encontrado.password__c + 
                                         '&firstdate=' + formattedFirstDate + '&lastdate='+ formattedLastDate +'&timeseries=' + encontrado.serie__c;
                        System.debug('getCurrencyNow - Endpoint encontrado: ' + urlBuild );
                        String valorMoneda = getMonedaApi(urlBuild);
                        System.debug('getCurrencyNow - Valor moneda recibido: ' + valorMoneda);
                        if (valorMoneda != null) {
                            Decimal conversionRate = (1 / Decimal.valueOf(valorMoneda.replace(',', '.'))).setScale(6);                        
                            conversionRates.put(isoCode, conversionRate);
                            currencyTypes.put(isoCode, Double.valueOf(valorMoneda.replace(',', '.')));
                        }
                    }
                }
        
                if (!conversionRates.isEmpty()) {
                    for (String isoCode : conversionRates.keySet()) {
                        entelGetCurrencyMetadataBancoCentral__mdt encontrado = mantenedorMap.get(isoCode);
                        DatedConversionRate moneda = monedas.get(isoCode);
                        System.debug('ConversionRate' + encontrado);
                        if (encontrado != null) {                      
                            actualizarConversionRate(moneda.Id, conversionRates.get(isoCode), encontrado.clientId__c, encontrado.clientSecret__c);
                        }
                    }
                }
                
                if (!currencyTypes.isEmpty()) {
                    for (String isoCode : currencyTypes.keySet()) {
                        entelGetCurrencyMetadataBancoCentral__mdt encontrado = mantenedorMap.get(isoCode);
                        CurrencyType moneda = monedasVigentes.get(isoCode);
                        System.debug('CurrencyType' + encontrado);
                        if (encontrado != null) {                      
                            actualizarCurrencyType(moneda.Id, currencyTypes.get(isoCode), encontrado.clientId__c, encontrado.clientSecret__c);
                        }
                    }
                }
                
            } catch (Exception e) {
                System.debug('Catch Error en getCurrencyNowBancoCentral: ' + e.getMessage());
            }
        }
        
    
        public static AuthResponse getTokenRest(String clientId, String clientSecret) {
            try {
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/oauth2/token');
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                request.setBody('grant_type=client_credentials' + '&client_id=' + clientId + '&client_secret=' + clientSecret);
                system.debug('getTokenRest + ClientID: ' + clientId);
                system.debug('getTokenRest + ClientSecret: ' + clientSecret);
                request.setTimeout(120000);
                HttpResponse response = http.send(request);
                if (response.getStatusCode() == 200 && !String.isEmpty(response.getBody())) {
                    return (AuthResponse) JSON.deserialize(response.getBody(), AuthResponse.class);
                } else {
                    System.debug('getTokenRest - Error al obtener token: ' + response.getStatus());
                    return null;
                }
            } catch (Exception e) {
                System.debug('Catch Excepción en getTokenRest: ' + e.getMessage());
                return null;
            }
        }
        
        public static void actualizarConversionRate(String idRegistro, Decimal valorConversionRate, String clientId, String clientSecret) {
            AuthResponse authResponse = getTokenRest(clientId, clientSecret);        
            if (authResponse == null || String.isEmpty(authResponse.access_token)) {
                System.debug('actualizarConversionRate - No se pudo obtener el token de autenticación.');                
                return;
            }
        
            try {
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v62.0/sobjects/DatedConversionRate/' + idRegistro);
                request.setMethod('PATCH');
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('Authorization', 'Bearer ' + authResponse.access_token);
                request.setBody('{"ConversionRate" : ' + valorConversionRate + '}');
                HttpResponse response = http.send(request);
                System.debug('actualizarConversionRate - Respuesta: ' + response.getBody());
            } catch (Exception e) {
                System.debug('Catch Error en actualizarConversionRate: ' + e.getMessage());
            }
        }
    
        
        
        public static void actualizarCurrencyType(String idRegistro, Decimal valorConversionRate, String clientId, String clientSecret) {
            AuthResponse authResponse = getTokenRest(clientId, clientSecret);        
            if (authResponse == null || String.isEmpty(authResponse.access_token)) {
                System.debug('actualizarCurrencyType - No se pudo obtener el token de autenticación.');
                return;
            }
        
            try {
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v62.0/sobjects/CurrencyType/' + idRegistro);
                request.setMethod('PATCH');
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('Authorization', 'Bearer ' + authResponse.access_token);
                request.setBody('{"ConversionRate" : ' + valorConversionRate + '}');      
                HttpResponse response = http.send(request);
                System.debug('actualizarCurrencyType - Respuesta: ' + response.getBody());
            } catch (Exception e) {
                System.debug('Catch Error en actualizarCurrencyType: ' + e.getMessage());
            }
        }
        
        public static String getMonedaApi(String url) {        
            String salidaResponse = null;
            
             
            // Realizar la llamada HTTP POST
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(url);
            request.setMethod('POST');
            request.setBody('');
            HttpResponse response = http.send(request); 
            
            if (response.getStatusCode() == 200) {            
                // Deserializar el JSON           
                //MonedaInfo apiResponse = (MonedaInfo)JSON.deserialize(removeDynamicKey(response.getBody()), MonedaInfo.class);
                currencyBancoCentral apiResponse = (currencyBancoCentral)JSON.deserialize(response.getBody(), currencyBancoCentral.class);
                //MonedaResponse apiResponse = (MonedaResponse)JSON.deserialize(removeDynamicKey(response.getBody()), MonedaResponse.class);            
                // Acceder a los datos deserializados
                if (apiResponse != null) {
                    currencyBancoCentral moneda = apiResponse;
                    salidaResponse = moneda.Series.Obs[0].value;
                }
            } else {
                System.debug('getMonedaApi - Error al obtener moneda' + response.getStatus()); 
            }
        return salidaResponse;
        }    
    
        
        
    }