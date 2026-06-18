/**
 * Clase de práctica Apex: lógica de negocio sencilla sobre Account.
 * Sirve para practicar SOQL, DML y bulkificación.
 */
public with sharing class AccountService {
    /**
     * Crea cuentas a partir de una lista de nombres.
     * @param names nombres de las cuentas a crear
     * @return las cuentas insertadas (con Id)
     */
    public static List<Account> createAccounts(List<String> names) {
        List<Account> toInsert = new List<Account>();
        for (String name : names) {
            if (String.isNotBlank(name)) {
                toInsert.add(new Account(Name = name));
            }
        }
        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
        return toInsert;
    }

    /**
     * Devuelve las cuentas cuyo nombre empieza por el prefijo dado.
     */
    public static List<Account> findByPrefix(String prefix) {
        String pattern = prefix + '%';
        return [
            SELECT Id, Name
            FROM Account
            WHERE Name LIKE :pattern
            ORDER BY Name
            LIMIT 200
        ];
    }
}
