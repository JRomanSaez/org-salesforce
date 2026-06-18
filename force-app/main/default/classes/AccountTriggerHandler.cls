/**
 * Handler del trigger de Account: contiene la lógica de negocio.
 * Mantener la lógica fuera del trigger permite testearla y reutilizarla.
 */
public with sharing class AccountTriggerHandler {
    /**
     * Rellena Nombre_Longitud__c con el nº de caracteres del Name.
     * Trabaja sobre la lista completa (bulkificado): NUNCA hagas SOQL/DML
     * por cada registro dentro de un bucle.
     *
     * En contexto "before", basta con asignar el valor al registro en memoria;
     * Salesforce lo persiste sin necesidad de un DML extra.
     *
     * @param accounts los registros del Trigger.new
     */
    public static void setNombreLongitud(List<Account> accounts) {
        for (Account acc : accounts) {
            acc.Nombre_Longitud__c = acc.Name == null ? 0 : acc.Name.length();
        }
    }
}
