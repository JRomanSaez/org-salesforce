@isTest
private class LeadFormApiTest {

    /** Construye una petición REST simulada con el body indicado. */
    private static void prepararPeticion(String bodyJson) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/lead-formulario/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(bodyJson);
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @isTest
    static void crearLead_ok() {
        prepararPeticion('{"nombre":"Ana López","email":"ana@x.com","empresa":"Acme"}');

        Test.startTest();
        LeadFormApi.LeadResponse resp = LeadFormApi.crearLead();
        Test.stopTest();

        System.assertEquals(true, resp.ok, 'Debe crear el lead');
        System.assertNotEquals(null, resp.leadId, 'Debe devolver el Id');
        System.assertEquals(201, RestContext.response.statusCode);
        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE Email = 'ana@x.com']);
    }

    @isTest
    static void crearLead_faltanCampos() {
        prepararPeticion('{"nombre":"","email":""}');

        Test.startTest();
        LeadFormApi.LeadResponse resp = LeadFormApi.crearLead();
        Test.stopTest();

        System.assertEquals(false, resp.ok, 'Debe rechazar sin nombre/email');
        System.assertEquals(400, RestContext.response.statusCode);
    }
}
