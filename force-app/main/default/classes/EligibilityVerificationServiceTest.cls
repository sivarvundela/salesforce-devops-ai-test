/**
 * @description Tests for EligibilityVerificationService — Strategy B (@TestSetup) because service runs SOQL.
 */
@IsTest
private class EligibilityVerificationServiceTest {

    @TestSetup
    static void makeData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        insert new User(
            Alias = 'evst2', Email = 'evst2@example.com', EmailEncodingKey = 'UTF-8',
            LastName = 'EVSTest2', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
            ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'evst2_' + System.currentTimeMillis() + '@example.com'
        );
        Account activeEmployer = new Account(
            Name = 'Active Corp',
            Type = 'Customer',
            Active__c = 'Yes'
        );
        Account inactiveEmployer = new Account(
            Name = 'Inactive Corp',
            Type = 'Customer',
            Active__c = 'No'
        );
        insert new List<Account>{ activeEmployer, inactiveEmployer };
        Coverage__c activeCoverage = new Coverage__c(
            Plan__c = 'Gold Plan',
            Status__c = 'Active',
            Coverage_Level__c = 'Family',
            Primary_Care_Provider__c = 'Dr. Smith',
            Effective_Date__c = Date.today()
        );
        insert activeCoverage;
    }

    @IsTest
    static void verifyNullRequestReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(null);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Null request must return invalid');
        }
    }

    @IsTest
    static void verifyNoEmployerGroupAddsWarning() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                EmployerGroup__c = null,
                PlanName__c = 'Gold Plan',
                PlanType__c = 'HMO',
                EffectiveDate__c = Date.today().addDays(30),
                PrimaryCareProvider__c = 'Dr. Smith'
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assert(result.warnings.size() >= 1, 'Warning expected when no employer group');
        }
    }

    @IsTest
    static void verifyActiveEmployerPasses() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                EmployerGroup__c = 'Active Corp',
                PlanName__c = 'Gold Plan',
                PlanType__c = 'HMO',
                EffectiveDate__c = Date.today().addDays(30),
                PrimaryCareProvider__c = 'Dr. Smith'
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assert(!result.fieldErrors.containsKey('EmployerGroup__c'),
                'Active employer must not produce field error');
        }
    }

    @IsTest
    static void verifyInactiveEmployerReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                EmployerGroup__c = 'Inactive Corp',
                PlanName__c = 'Gold Plan',
                PlanType__c = 'HMO',
                EffectiveDate__c = Date.today().addDays(30),
                PrimaryCareProvider__c = 'Dr. Smith'
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Inactive employer must fail');
            System.assert(result.fieldErrors.containsKey('EmployerGroup__c'), 'EmployerGroup__c error expected');
        }
    }

    @IsTest
    static void verifyUnknownEmployerReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                EmployerGroup__c = 'Unknown Corp',
                PlanName__c = 'Gold Plan',
                PlanType__c = 'HMO',
                EffectiveDate__c = Date.today().addDays(30),
                PrimaryCareProvider__c = 'Dr. Smith'
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Unknown employer must fail');
            System.assert(result.fieldErrors.containsKey('EmployerGroup__c'), 'EmployerGroup__c error expected for unknown employer');
        }
    }

    @IsTest
    static void verifyActivePlanPasses() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                PlanName__c = 'Gold Plan',
                PlanType__c = 'HMO',
                EffectiveDate__c = Date.today().addDays(15),
                PrimaryCareProvider__c = 'Dr. Smith'
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assert(!result.fieldErrors.containsKey('PlanName__c'),
                'Active plan must not produce field error');
        }
    }

    @IsTest
    static void verifyInactivePlanReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                PlanName__c = 'Nonexistent Plan',
                PlanType__c = 'HMO',
                EffectiveDate__c = Date.today().addDays(30),
                PrimaryCareProvider__c = 'Dr. Smith'
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Unavailable plan must fail');
            System.assert(result.fieldErrors.containsKey('PlanName__c'), 'PlanName__c error expected');
        }
    }

    @IsTest
    static void verifyMedicarePlanUnder65ReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                PlanType__c = 'Medicare Advantage',
                DateOfBirth__c = Date.today().addYears(-40),
                EffectiveDate__c = Date.today().addDays(30)
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Under-65 Medicare enrollee must fail');
            System.assert(result.fieldErrors.containsKey('PlanType__c'), 'PlanType__c error expected for under-65 Medicare');
        }
    }

    @IsTest
    static void verifyMedicarePlanAt65OrOlderPasses() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                PlanType__c = 'Medicare Advantage',
                DateOfBirth__c = Date.today().addYears(-66),
                EffectiveDate__c = Date.today().addDays(30)
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assert(!result.fieldErrors.containsKey('PlanType__c'),
                'Enrollee aged 66 must not fail Medicare age check');
        }
    }

    @IsTest
    static void verifyMedicareNullDobReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                PlanType__c = 'Medicare Supplement',
                DateOfBirth__c = null,
                EffectiveDate__c = Date.today().addDays(30)
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Null DOB for Medicare plan must fail');
            System.assert(result.fieldErrors.containsKey('DateOfBirth__c'), 'DateOfBirth__c error expected');
        }
    }

    @IsTest
    static void verifyMedicaidPlanAddsWarning() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                PlanType__c = 'Medicaid',
                EffectiveDate__c = Date.today().addDays(30)
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assert(result.warnings.size() >= 1, 'Medicaid plan must produce income verification warning');
        }
    }

    @IsTest
    static void verifyPastEffectiveDateReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                PlanType__c = 'HMO',
                EffectiveDate__c = Date.today().addDays(-5)
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Past effective date must fail');
            System.assert(result.fieldErrors.containsKey('EffectiveDate__c'), 'EffectiveDate__c error expected');
        }
    }

    @IsTest
    static void verifyFarFutureEffectiveDateReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                PlanType__c = 'HMO',
                EffectiveDate__c = Date.today().addDays(400)
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Effective date >365 days in future must fail');
            System.assert(result.fieldErrors.containsKey('EffectiveDate__c'), 'EffectiveDate__c error expected for far-future date');
        }
    }

    @IsTest
    static void verifyActivePcpPasses() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                PlanType__c = 'HMO',
                PlanName__c = 'Gold Plan',
                EffectiveDate__c = Date.today().addDays(30),
                PrimaryCareProvider__c = 'Dr. Smith'
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assert(!result.fieldErrors.containsKey('PrimaryCareProvider__c'),
                'Active PCP must not produce field error');
        }
    }

    @IsTest
    static void verifyUnknownPcpReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                PlanType__c = 'HMO',
                EffectiveDate__c = Date.today().addDays(30),
                PrimaryCareProvider__c = 'Dr. Unknown'
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Unknown PCP must fail');
            System.assert(result.fieldErrors.containsKey('PrimaryCareProvider__c'), 'PrimaryCareProvider__c error expected');
        }
    }

    @IsTest
    static void verifyNoPcpAddsWarning() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                PlanType__c = 'HMO',
                EffectiveDate__c = Date.today().addDays(30),
                PrimaryCareProvider__c = null
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assert(result.warnings.size() >= 1, 'Missing PCP must produce advisory warning');
        }
    }

    @IsTest
    static void verifyAllEmptyListReturnsEmpty() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            List<ValidationErrorWrapper> results =
                EligibilityVerificationService.verifyAll(new List<Enrollment_Request__c>());
            Test.stopTest();
            System.assertEquals(0, results.size(), 'Empty list must return empty results');
        }
    }

    @IsTest
    static void verifyAllNullListReturnsEmpty() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            List<ValidationErrorWrapper> results =
                EligibilityVerificationService.verifyAll(null);
            Test.stopTest();
            System.assertEquals(0, results.size(), 'Null list must return empty results');
        }
    }

    @IsTest
    static void verifyAllBulkOf50RecordsCompletes() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            List<Enrollment_Request__c> reqs = new List<Enrollment_Request__c>();
            for (Integer i = 0; i < 50; i++) {
                reqs.add(new Enrollment_Request__c(
                    PlanType__c = 'HMO',
                    PlanName__c = 'Gold Plan',
                    EffectiveDate__c = Date.today().addDays(30),
                    PrimaryCareProvider__c = 'Dr. Smith'
                ));
            }
            Test.startTest();
            List<ValidationErrorWrapper> results = EligibilityVerificationService.verifyAll(reqs);
            Test.stopTest();
            System.assertEquals(50, results.size(), '50 results expected for 50 inputs');
        }
    }

    @IsTest
    static void verifyChipPlanAddsWarning() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest2' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = new Enrollment_Request__c(
                PlanType__c = 'CHIP',
                EffectiveDate__c = Date.today().addDays(30)
            );
            Test.startTest();
            ValidationErrorWrapper result = EligibilityVerificationService.verifyEligibility(req);
            Test.stopTest();
            System.assert(result.warnings.size() >= 1, 'CHIP plan must produce income verification warning');
        }
    }
}