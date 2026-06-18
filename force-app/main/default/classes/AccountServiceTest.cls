@isTest
private class AccountServiceTest {
    @isTest
    static void createAccounts_insertsValidNames() {
        Test.startTest();
        List<Account> created = AccountService.createAccounts(
            new List<String>{ 'Acme', '', 'Globex', null }
        );
        Test.stopTest();

        System.assertEquals(2, created.size(), 'Debe ignorar nombres vacíos/null');
        System.assertEquals(
            2,
            [SELECT COUNT() FROM Account WHERE Name IN ('Acme', 'Globex')],
            'Las cuentas válidas deben persistir'
        );
    }

    @isTest
    static void findByPrefix_returnsMatches() {
        insert new List<Account>{
            new Account(Name = 'Praxis Alpha'),
            new Account(Name = 'Praxis Beta'),
            new Account(Name = 'Otra')
        };

        Test.startTest();
        List<Account> result = AccountService.findByPrefix('Praxis');
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Solo las que empiezan por el prefijo');
    }
}
