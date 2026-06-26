/**
 * @description Tests for EnrollmentDuplicateCheckService — Strategy B (@TestSetup) because service runs SOQL.
 */
@IsTest
private class EnrollmentDuplicateCheckServiceTest {

    @TestSetup
    static void makeData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        insert new User(
            Alias = 'edcs', Email = 'edcs@example.com', EmailEncodingKey = 'UTF-8',
            LastName = 'EDCSTest', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
            ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'edcs_' + System.currentTimeMillis() + '@example.com'
        );
        Member__c m = new Member__c(
            FirstName__c = 'Jane',
            LastName__c = 'Smith',
            MaskedSSN__c = '6789',
            Email__c = 'jane@example.com',
            Phone__c = '5559876543'
        );
        insert m;
        Enrollment_Request__c existing = new Enrollment_Request__c(
            FirstName__c = 'Jane',
            LastName__c = 'Smith',
            SSN__c = '987-65-6789',
            PlanName__c = 'Gold Plan',
            PlanType__c = 'HMO',
            Status__c = 'Active',
            Member__c = m.Id,
            Email__c = 'jane@example.com',
            PhoneNumber__c = '5559876543',
            DateOfBirth__c = Date.today().addYears(-40),
            EffectiveDate__c = Date.today().addDays(10),
            AddressLine1__c = '456 Elm St',
            City__c = 'Chicago',
            State__c = 'IL',
            ZIPCode__c = '60601'
        );
        insert existing;
    }

    @IsTest
    static void checkNullRequestReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EDCSTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentDuplicateCheckService.checkForDuplicates(null);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Null request must return invalid');
            System.assert(result.errors[0].contains('null'), 'Error must mention null');
        }
    }

    @IsTest
    static void checkDuplicateSSNReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EDCSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c newReq = new Enrollment_Request__c(
                FirstName__c = 'John',
                LastName__c = 'Doe',
                SSN__c = '987-65-6789'
            );
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentDuplicateCheckService.checkForDuplicates(newReq);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Duplicate SSN must fail');
            System.assert(result.fieldErrors.containsKey('SSN__c'), 'SSN__c field error expected');
        }
    }

    @IsTest
    static void checkUniqueSSNPasses() {
        User u = [SELECT Id FROM User WHERE LastName = 'EDCSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c newReq = new Enrollment_Request__c(
                FirstName__c = 'New',
                LastName__c = 'Person',
                SSN__c = '111-22-3333'
            );
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentDuplicateCheckService.checkForDuplicates(newReq);
            Test.stopTest();
            System.assertEquals(true, result.isValid, 'Unique SSN must pass duplicate check');
        }
    }

    @IsTest
    static void checkExistingMemberLastFourMatchTriggersWarning() {
        User u = [SELECT Id FROM User WHERE LastName = 'EDCSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c newReq = new Enrollment_Request__c(
                FirstName__c = 'Other',
                LastName__c = 'Person',
                SSN__c = '000-00-6789'
            );
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentDuplicateCheckService.checkForDuplicates(newReq);
            Test.stopTest();
            System.assertEquals(1, result.warnings.size(), 'Warning expected when member last-4 matches');
        }
    }

    @IsTest
    static void checkBlankSSNSkipsDuplicateChecks() {
        User u = [SELECT Id FROM User WHERE LastName = 'EDCSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c newReq = new Enrollment_Request__c(
                FirstName__c = 'No',
                LastName__c = 'SSN',
                SSN__c = null
            );
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentDuplicateCheckService.checkForDuplicates(newReq);
            Test.stopTest();
            System.assertEquals(0, result.fieldErrors.size(), 'No field errors when SSN is blank');
        }
    }

    @IsTest
    static void checkDuplicateCoverageForSameMemberReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EDCSTest' LIMIT 1];
        System.runAs(u) {
            Member__c m = [SELECT Id FROM Member__c LIMIT 1];
            Enrollment_Request__c newReq = new Enrollment_Request__c(
                FirstName__c = 'Jane',
                LastName__c = 'Smith',
                SSN__c = '111-11-1111',
                Member__c = m.Id,
                PlanName__c = 'Gold Plan'
            );
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentDuplicateCheckService.checkForDuplicates(newReq);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Duplicate coverage for same member must fail');
            System.assert(result.fieldErrors.containsKey('PlanName__c'), 'PlanName__c field error expected');
        }
    }

    @IsTest
    static void checkDuplicateCoverageNoMemberSkipsCheck() {
        User u = [SELECT Id FROM User WHERE LastName = 'EDCSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c newReq = new Enrollment_Request__c(
                FirstName__c = 'No',
                LastName__c = 'Member',
                SSN__c = '000-00-0001',
                Member__c = null,
                PlanName__c = 'Gold Plan'
            );
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentDuplicateCheckService.checkForDuplicates(newReq);
            Test.stopTest();
            System.assert(!result.fieldErrors.containsKey('PlanName__c'), 'No coverage check without Member__c');
        }
    }

    @IsTest
    static void checkAllEmptyListReturnsEmpty() {
        User u = [SELECT Id FROM User WHERE LastName = 'EDCSTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            List<ValidationErrorWrapper> results =
                EnrollmentDuplicateCheckService.checkAllForDuplicates(new List<Enrollment_Request__c>());
            Test.stopTest();
            System.assertEquals(0, results.size(), 'Empty list must return empty results');
        }
    }

    @IsTest
    static void checkAllNullListReturnsEmpty() {
        User u = [SELECT Id FROM User WHERE LastName = 'EDCSTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            List<ValidationErrorWrapper> results =
                EnrollmentDuplicateCheckService.checkAllForDuplicates(null);
            Test.stopTest();
            System.assertEquals(0, results.size(), 'Null list must return empty results');
        }
    }

    @IsTest
    static void checkAllBulkOf50RecordsCompletes() {
        User u = [SELECT Id FROM User WHERE LastName = 'EDCSTest' LIMIT 1];
        System.runAs(u) {
            List<Enrollment_Request__c> reqs = new List<Enrollment_Request__c>();
            for (Integer i = 0; i < 50; i++) {
                reqs.add(new Enrollment_Request__c(
                    FirstName__c = 'Bulk',
                    LastName__c = 'User' + i,
                    SSN__c = '200-00-' + String.valueOf(1000 + i)
                ));
            }
            Test.startTest();
            List<ValidationErrorWrapper> results =
                EnrollmentDuplicateCheckService.checkAllForDuplicates(reqs);
            Test.stopTest();
            System.assertEquals(50, results.size(), '50 results expected for 50 inputs');
        }
    }
}