@isTest
private class TodoApiClientTest {
    /** Mock que simula la respuesta HTTP de la API externa. */
    private class TodoMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        TodoMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(this.statusCode);
            res.setBody(this.body);
            return res;
        }
    }

    @isTest
    static void getTodo_parsesSuccessResponse() {
        String json = '{"userId":1,"id":1,"title":"delectus aut autem","completed":false}';
        Test.setMock(HttpCalloutMock.class, new TodoMock(200, json));

        Test.startTest();
        TodoApiClient.Todo todo = TodoApiClient.getTodo(1);
        Test.stopTest();

        System.assertEquals(1, todo.id);
        System.assertEquals('delectus aut autem', todo.title);
        System.assertEquals(false, todo.completed);
    }

    @isTest
    static void getTodo_throwsOnError() {
        Test.setMock(HttpCalloutMock.class, new TodoMock(404, 'Not Found'));

        Test.startTest();
        try {
            TodoApiClient.getTodo(99999);
            System.assert(false, 'Debería haber lanzado excepción');
        } catch (TodoApiClient.TodoApiException e) {
            System.assert(e.getMessage().contains('404'), 'El mensaje debe incluir el código');
        }
        Test.stopTest();
    }
}
