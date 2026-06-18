/**
 * Endpoint REST INBOUND: tu web (formulario) llama AQUÍ para crear un Lead.
 *
 * URL del endpoint (una vez desplegado y autenticado):
 *   POST https://<tu-dominio>/services/apexrest/lead-formulario/
 *
 * Body JSON esperado:
 *   { "nombre": "Ana López", "email": "ana@x.com", "empresa": "Acme", "telefono": "600..." }
 *
 * A diferencia de TodoApiClient (Salesforce llama hacia FUERA), aquí Salesforce
 * EXPONE el endpoint y es el cliente externo quien llama hacia DENTRO.
 */
@RestResource(urlMapping='/lead-formulario/*')
global with sharing class LeadFormApi {

    /** Estructura del body de entrada (se deserializa solo desde el JSON). */
    global class LeadRequest {
        global String nombre;
        global String email;
        global String empresa;
        global String telefono;
    }

    /** Estructura de la respuesta que devolvemos a la web. */
    global class LeadResponse {
        global Boolean ok;
        global String leadId;
        global String mensaje;
    }

    @HttpPost
    global static LeadResponse crearLead() {
        LeadResponse resp = new LeadResponse();

        // 1. Leer y deserializar el body de la petición
        RestRequest req = RestContext.request;
        LeadRequest input = (LeadRequest) JSON.deserialize(
            req.requestBody.toString(),
            LeadRequest.class
        );

        // 2. Validación mínima
        if (String.isBlank(input.nombre) || String.isBlank(input.email)) {
            RestContext.response.statusCode = 400;
            resp.ok = false;
            resp.mensaje = 'nombre y email son obligatorios';
            return resp;
        }

        // 3. Crear el Lead
        try {
            Lead l = new Lead(
                LastName = input.nombre,
                Email = input.email,
                Company = String.isBlank(input.empresa) ? 'Sin empresa' : input.empresa,
                Phone = input.telefono,
                LeadSource = 'Web'
            );
            insert l;

            RestContext.response.statusCode = 201;
            resp.ok = true;
            resp.leadId = l.Id;
            resp.mensaje = 'Lead creado';
        } catch (Exception e) {
            RestContext.response.statusCode = 500;
            resp.ok = false;
            resp.mensaje = 'Error: ' + e.getMessage();
        }
        return resp;
    }
}
