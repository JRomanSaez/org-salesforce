/**
 * Clase de práctica de INTEGRACIÓN: hace un callout HTTP a una API REST externa.
 *
 * Antes de poder llamar a un host externo, hay que registrarlo como
 * "Remote Site Setting" o "Named Credential" en la org. Por ejemplo:
 *   https://jsonplaceholder.typicode.com
 *
 * Esta clase consume https://jsonplaceholder.typicode.com/todos/{id}
 * y devuelve el JSON deserializado en un wrapper tipado.
 */
public with sharing class TodoApiClient {
    private static final String BASE_URL = 'https://jsonplaceholder.typicode.com';

    /** Estructura tipada de la respuesta. */
    public class Todo {
        public Integer userId;
        public Integer id;
        public String title;
        public Boolean completed;
    }

    public class TodoApiException extends Exception {}

    /**
     * Recupera un TODO por su id mediante GET.
     * @param todoId id del recurso remoto
     * @return el Todo deserializado
     */
    public static Todo getTodo(Integer todoId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + '/todos/' + todoId);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(10000);

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) {
            throw new TodoApiException(
                'Callout falló: HTTP ' + res.getStatusCode() + ' - ' + res.getStatus()
            );
        }

        return (Todo) JSON.deserialize(res.getBody(), Todo.class);
    }
}
