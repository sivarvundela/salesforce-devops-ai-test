@IsTest
private class EnrollmentWizardControllerTest {

    @TestSetup
    static void makeData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'ewtest', Email = 'ewtest@example.com',
            EmailEncodingKey = 'UTF-8', LastName = 'EWTestUser',
            LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
            ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'ewtest_' + System.currentTimeMillis() + '@example.com'
        );
        insert u;

        Enrollment_Request__c er = new Enrollment_Request__c(
            FirstName__c  = 'Jane',
            LastName__c   = 'Doe',
            Email__c      = 'jane.doe@example.com',
            PhoneNumber__c = '5551234567',
            Status__c     = 'Draft'
        );
        insert er;

        EnrollmentSystemConfig__c cfg = new EnrollmentSystemConfig__c(
            Name = 'Default',
            Max_File_Size_MB__c = 5
        );
        insert cfg;
    }

    @IsTest
    static void getEnrollmentRequestReturnsRecord() {
        Enrollment_Request__c er = [SELECT Id FROM Enrollment_Request__c LIMIT 1];
        User u = [SELECT Id FROM User WHERE LastName = 'EWTestUser' LIMIT 1];
        Enrollment_Request__c result;
        Test.startTest();
        System.runAs(u) {
            result = EnrollmentWizardController.getEnrollmentRequest(er.Id);
        }
        Test.stopTest();
        System.assertNotEquals(null, result, 'Should return the Enrollment Request record');
        System.assertEquals('Jane', result.FirstName__c, 'First name should match inserted record');
    }

    @IsTest
    static void getEnrollmentRequestNullIdReturnsEmpty() {
        User u = [SELECT Id FROM User WHERE LastName = 'EWTestUser' LIMIT 1];
        Enrollment_Request__c result;
        Test.startTest();
        System.runAs(u) {
            result = EnrollmentWizardController.getEnrollmentRequest(null);
        }
        Test.stopTest();
        System.assertNotEquals(null, result, 'Should return an empty sObject, not null');
        System.assertEquals(null, result.Id, 'Returned record should have no Id for null input');
    }

    @IsTest
    static void getEnrollmentRequestInvalidIdThrows() {
        User u = [SELECT Id FROM User WHERE LastName = 'EWTestUser' LIMIT 1];
        Boolean exThrown = false;
        Test.startTest();
        System.runAs(u) {
            try {
                EnrollmentWizardController.getEnrollmentRequest('001000000000000AAA');
            } catch (AuraHandledException ex) {
                exThrown = true;
                System.assert(ex.getMessage() != null, 'Exception message should not be null');
            }
        }
        Test.stopTest();
        System.assert(exThrown, 'AuraHandledException should be thrown for non-existent record');
    }

    @IsTest
    static void saveEnrollmentRequestInsertCreatesRecord() {
        User u = [SELECT Id FROM User WHERE LastName = 'EWTestUser' LIMIT 1];
        Id newId;
        Test.startTest();
        System.runAs(u) {
            Enrollment_Request__c newEr = new Enrollment_Request__c(
                FirstName__c = 'John',
                LastName__c  = 'Smith',
                Status__c    = 'Draft'
            );
            newId = EnrollmentWizardController.saveEnrollmentRequest(newEr);
        }
        Test.stopTest();
        System.assertNotEquals(null, newId, 'Saved record should return a non-null Id');
        Enrollment_Request__c saved = [SELECT FirstName__c FROM Enrollment_Request__c WHERE Id = :newId];
        System.assertEquals('John', saved.FirstName__c, 'Inserted record should have correct first name');
    }

    @IsTest
    static void saveEnrollmentRequestUpdateModifiesRecord() {
        Enrollment_Request__c er = [SELECT Id FROM Enrollment_Request__c LIMIT 1];
        User u = [SELECT Id FROM User WHERE LastName = 'EWTestUser' LIMIT 1];
        Test.startTest();
        System.runAs(u) {
            er.FirstName__c = 'Updated';
            EnrollmentWizardController.saveEnrollmentRequest(er);
        }
        Test.stopTest();
        Enrollment_Request__c updated = [SELECT FirstName__c FROM Enrollment_Request__c WHERE Id = :er.Id];
        System.assertEquals('Updated', updated.FirstName__c, 'First name should be updated after save');
    }

    @IsTest
    static void saveEnrollmentRequestNullThrows() {
        User u = [SELECT Id FROM User WHERE LastName = 'EWTestUser' LIMIT 1];
        Boolean exThrown = false;
        Test.startTest();
        System.runAs(u) {
            try {
                EnrollmentWizardController.saveEnrollmentRequest(null);
            } catch (AuraHandledException ex) {
                exThrown = true;
                System.assert(ex.getMessage().contains('null') || ex.getMessage() != null,
                    'Exception thrown for null record');
            }
        }
        Test.stopTest();
        System.assert(exThrown, 'AuraHandledException should be thrown when record is null');
    }

    @IsTest
    static void saveEnrollmentDocumentCreatesRecord() {
        Enrollment_Request__c er = [SELECT Id FROM Enrollment_Request__c LIMIT 1];
        User u = [SELECT Id FROM User WHERE LastName = 'EWTestUser' LIMIT 1];
        Test.startTest();
        System.runAs(u) {
            EnrollmentWizardController.saveEnrollmentDocument(
                er.Id, 'test.pdf', 'Application', 102400L, null
            );
        }
        Test.stopTest();
        List<Enrollment_Document__c> docs = [
            SELECT File_Name__c, Document_Type__c
            FROM Enrollment_Document__c
            WHERE Enrollment_Request__c = :er.Id
        ];
        System.assertEquals(1, docs.size(), 'One document record should be created');
        System.assertEquals('test.pdf', docs[0].File_Name__c, 'File name should match');
        System.assertEquals('Application', docs[0].Document_Type__c, 'Document type should match');
    }

    @IsTest
    static void saveEnrollmentDocumentNullIdThrows() {
        User u = [SELECT Id FROM User WHERE LastName = 'EWTestUser' LIMIT 1];
        Boolean exThrown = false;
        Test.startTest();
        System.runAs(u) {
            try {
                EnrollmentWizardController.saveEnrollmentDocument(null, 'file.pdf', 'Application', 100L, null);
            } catch (AuraHandledException ex) {
                exThrown = true;
            }
        }
        Test.stopTest();
        System.assert(exThrown, 'AuraHandledException expected when enrollmentRequestId is null');
    }

    @IsTest
    static void getEnrollmentDocumentsReturnsDocuments() {
        Enrollment_Request__c er = [SELECT Id FROM Enrollment_Request__c LIMIT 1];
        Enrollment_Document__c doc = new Enrollment_Document__c(
            Enrollment_Request__c = er.Id,
            File_Name__c = 'sample.pdf',
            Document_Type__c = 'ID',
            File_Size__c = 50000,
            Upload_Date__c = Date.today()
        );
        insert doc;
        User u = [SELECT Id FROM User WHERE LastName = 'EWTestUser' LIMIT 1];
        List<Enrollment_Document__c> results;
        Test.startTest();
        System.runAs(u) {
            results = EnrollmentWizardController.getEnrollmentDocuments(er.Id);
        }
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return one document for the enrollment request');
        System.assertEquals('sample.pdf', results[0].File_Name__c, 'File name should match');
    }

    @IsTest
    static void getEnrollmentDocumentsNullIdReturnsEmpty() {
        User u = [SELECT Id FROM User WHERE LastName = 'EWTestUser' LIMIT 1];
        List<Enrollment_Document__c> results;
        Test.startTest();
        System.runAs(u) {
            results = EnrollmentWizardController.getEnrollmentDocuments(null);
        }
        Test.stopTest();
        System.assertEquals(0, results.size(), 'Null ID should return an empty list');
    }

    @IsTest
    static void getMaxFileSizeMbReturnsConfigValue() {
        User u = [SELECT Id FROM User WHERE LastName = 'EWTestUser' LIMIT 1];
        Decimal maxSize;
        Test.startTest();
        System.runAs(u) {
            maxSize = EnrollmentWizardController.getMaxFileSizeMb();
        }
        Test.stopTest();
        System.assertEquals(5, maxSize, 'Max file size should match config value of 5 MB');
    }

    @IsTest
    static void getMaxFileSizeMbDefaultsWhenNoConfig() {
        delete [SELECT Id FROM EnrollmentSystemConfig__c];
        User u = [SELECT Id FROM User WHERE LastName = 'EWTestUser' LIMIT 1];
        Decimal maxSize;
        Test.startTest();
        System.runAs(u) {
            maxSize = EnrollmentWizardController.getMaxFileSizeMb();
        }
        Test.stopTest();
        System.assertEquals(10, maxSize, 'Default max file size should be 10 MB when no config exists');
    }
}