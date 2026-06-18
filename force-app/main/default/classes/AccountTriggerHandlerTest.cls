@isTest
private class AccountTriggerHandlerTest {
    @isTest
    static void setsLengthOnInsert() {
        Account acc = new Account(Name = 'Acme');
        insert acc;

        acc = [SELECT Nombre_Longitud__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(4, acc.Nombre_Longitud__c, 'Debe contar los caracteres al crear');
    }

    @isTest
    static void updatesLengthOnUpdate() {
        Account acc = new Account(Name = 'Acme');
        insert acc;

        acc.Name = 'Globex Corp';
        update acc;

        acc = [SELECT Nombre_Longitud__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(11, acc.Nombre_Longitud__c, 'Debe recalcular al actualizar');
    }

    @isTest
    static void handlesBulk() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Cuenta ' + i));
        }
        Test.startTest();
        insert accounts;
        Test.stopTest();

        Integer ok = [
            SELECT COUNT()
            FROM Account
            WHERE Name LIKE 'Cuenta %' AND Nombre_Longitud__c > 0
        ];
        System.assertEquals(200, ok, 'Debe procesar los 200 registros en bloque');
    }
}
