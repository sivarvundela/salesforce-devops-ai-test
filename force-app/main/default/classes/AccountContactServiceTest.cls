@IsTest
private class AccountContactServiceTest {

    // ── Shared test data ─────────────────────────────────────────────────────
    @TestSetup
    static void makeData() {
        Account acct = new Account(
            Name    = 'Acme Test Corp',
            Phone   = '4155550100',
            Website = 'https://acme.example.com',
            Industry = 'Technology',
            Type     = 'Customer'
        );
        insert acct;

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 1; i <= 5; i++) {
            contacts.add(new Contact(
                AccountId  = acct.Id,
                FirstName  = 'First' + i,
                LastName   = 'Last'  + i,
                Email      = 'contact' + i + '@acme.example.com',
                Phone      = '415555010' + i,
                Title      = 'Engineer ' + i,
                Department = 'Engineering'
            ));
        }
        insert contacts;
    }

    // ── 1. getAccountWithContacts — positive / happy path ────────────────────
    @IsTest
    static void getAccountWithContacts_validId_returnsAccountAndContacts() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'Acme Test Corp' LIMIT 1];

        Test.startTest();
        AccountContactService.AccountContactWrapper result =
            AccountContactService.getAccountWithContacts(acct.Id);
        Test.stopTest();

        System.assertNotEquals(null, result,
            'Wrapper must not be null for a valid account Id');
        System.assertNotEquals(null, result.accountRecord,
            'accountRecord inside wrapper must not be null');
        System.assertEquals('Acme Test Corp', result.accountRecord.Name,
            'Account Name must match the inserted record');
        System.assertNotEquals(null, result.contacts,
            'contacts list must not be null');
        System.assertEquals(5, result.contacts.size(),
            'Exactly 5 contacts should be returned for this account');
    }

    // ── 2. getAccountWithContacts — null Id throws AuraHandledException ───────
    @IsTest
    static void getAccountWithContacts_nullId_throwsAuraHandledException() {
        Test.startTest();
        try {
            AccountContactService.getAccountWithContacts(null);
            System.assert(false,
                'Expected AuraHandledException for null accountId but none was thrown');
        } catch (AuraHandledException ex) {
            System.assert(
                ex.getMessage().contains('accountId parameter is required') ||
                ex.getMessage().contains('Script-thrown exception'),
                'Exception message should reference the required accountId: ' + ex.getMessage()
            );
        }
        Test.stopTest();
    }

    // ── 3. getAccountWithContacts — non-existent Id throws AuraHandledException
    @IsTest
    static void getAccountWithContacts_unknownId_throwsAuraHandledException() {
        // Construct a syntactically valid but non-existent Account Id
        Id fakeId = '001000000000001AAA';

        Test.startTest();
        try {
            AccountContactService.getAccountWithContacts(fakeId);
            System.assert(false,
                'Expected AuraHandledException for unknown accountId but none was thrown');
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage() != null,
                'AuraHandledException must carry a non-null message');
        }
        Test.stopTest();
    }

    // ── 4. getAccountWithContacts — account with no contacts ─────────────────
    @IsTest
    static void getAccountWithContacts_noContacts_returnsEmptyList() {
        Account emptyAcct = new Account(Name = 'No Contacts Corp');
        insert emptyAcct;

        Test.startTest();
        AccountContactService.AccountContactWrapper result =
            AccountContactService.getAccountWithContacts(emptyAcct.Id);
        Test.stopTest();

        System.assertNotEquals(null, result,
            'Wrapper must not be null even when there are no related contacts');
        System.assertEquals(0, result.contacts.size(),
            'contacts list must be empty when no contacts are related to the account');
    }

    // ── 5. getAccountDetails — positive / happy path ─────────────────────────
    @IsTest
    static void getAccountDetails_validId_returnsAccountRecord() {
        Account acct = [SELECT Id, Name, Industry FROM Account WHERE Name = 'Acme Test Corp' LIMIT 1];

        Test.startTest();
        Account result = AccountContactService.getAccountDetails(acct.Id);
        Test.stopTest();

        System.assertNotEquals(null, result,
            'Returned Account must not be null for a valid Id');
        System.assertEquals('Acme Test Corp', result.Name,
            'Account Name must match the inserted record');
        System.assertEquals('Technology', result.Industry,
            'Industry field must be returned and match the inserted value');
    }

    // ── 6. getAccountDetails — null Id throws AuraHandledException ────────────
    @IsTest
    static void getAccountDetails_nullId_throwsAuraHandledException() {
        Test.startTest();
        try {
            AccountContactService.getAccountDetails(null);
            System.assert(false,
                'Expected AuraHandledException for null accountId but none was thrown');
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage() != null,
                'AuraHandledException must carry a non-null message for null input');
        }
        Test.stopTest();
    }

    // ── 7. getRelatedContacts — positive / happy path ────────────────────────
    @IsTest
    static void getRelatedContacts_validId_returnsContacts() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'Acme Test Corp' LIMIT 1];

        Test.startTest();
        List<Contact> results = AccountContactService.getRelatedContacts(acct.Id);
        Test.stopTest();

        System.assertNotEquals(null, results,
            'Contact list must not be null for a valid account Id');
        System.assertEquals(5, results.size(),
            'All 5 inserted contacts must be returned');
        // Verify ORDER BY LastName ASC is respected
        System.assertEquals('Last1', results[0].LastName,
            'First contact in sorted list should be Last1');
    }

    // ── 8. getRelatedContacts — null Id throws AuraHandledException ───────────
    @IsTest
    static void getRelatedContacts_nullId_throwsAuraHandledException() {
        Test.startTest();
        try {
            AccountContactService.getRelatedContacts(null);
            System.assert(false,
                'Expected AuraHandledException for null accountId but none was thrown');
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage() != null,
                'AuraHandledException must carry a non-null message for null input');
        }
        Test.stopTest();
    }

    // ── 9. Bulk — 200 contacts returned without governor limit errors ─────────
    @IsTest
    static void getRelatedContacts_bulk200Contacts_allReturned() {
        Account bulkAcct = new Account(Name = 'Bulk Account Corp');
        insert bulkAcct;

        List<Contact> bulkContacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            bulkContacts.add(new Contact(
                AccountId = bulkAcct.Id,
                FirstName = 'BulkFirst' + i,
                LastName  = 'BulkLast'  + i,
                Email     = 'bulk' + i + '@bulk.example.com'
            ));
        }
        insert bulkContacts;

        Test.startTest();
        List<Contact> results = AccountContactService.getRelatedContacts(bulkAcct.Id);
        Test.stopTest();

        System.assertEquals(200, results.size(),
            'All 200 bulk-inserted contacts must be returned without hitting governor limits');
    }

    // ── 10. Bulk — getAccountWithContacts wrapper handles 200 contacts ────────
    @IsTest
    static void getAccountWithContacts_bulk200Contacts_wrapperCorrect() {
        Account bulkAcct = new Account(Name = 'Bulk Wrapper Corp');
        insert bulkAcct;

        List<Contact> bulkContacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            bulkContacts.add(new Contact(
                AccountId = bulkAcct.Id,
                FirstName = 'WFirst' + i,
                LastName  = 'WLast'  + i,
                Email     = 'w' + i + '@bulk.example.com'
            ));
        }
        insert bulkContacts;

        Test.startTest();
        AccountContactService.AccountContactWrapper result =
            AccountContactService.getAccountWithContacts(bulkAcct.Id);
        Test.stopTest();

        System.assertNotEquals(null, result,
            'Wrapper must not be null when account has 200 related contacts');
        System.assertEquals('Bulk Wrapper Corp', result.accountRecord.Name,
            'Account name must match the bulk test account');
        System.assertEquals(200, result.contacts.size(),
            'Wrapper contacts list must contain all 200 inserted contacts');
    }
}