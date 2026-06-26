/**
 * @description Tests for EnrollmentValidationService — Strategy A (in-memory records, no SOQL/DML).
 */
@IsTest
private class EnrollmentValidationServiceTest {

    @TestSetup
    static void makeData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        insert new User(
            Alias = 'evst', Email = 'evst@example.com', EmailEncodingKey = 'UTF-8',
            LastName = 'EVSTest', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
            ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'evst_' + System.currentTimeMillis() + '@example.com'
        );
    }

    private static Enrollment_Request__c buildValidRequest() {
        return new Enrollment_Request__c(
            FirstName__c = 'John',
            LastName__c = 'Doe',
            DateOfBirth__c = Date.today().addYears(-30),
            Email__c = 'john.doe@example.com',
            PhoneNumber__c = '5551234567',
            AddressLine1__c = '123 Main St',
            City__c = 'Springfield',
            State__c = 'IL',
            ZIPCode__c = '62701',
            PlanName__c = 'Gold Plan',
            PlanType__c = 'HMO',
            EffectiveDate__c = Date.today().addDays(30),
            SSN__c = '123-45-6789'
        );
    }

    @IsTest
    static void validateValidRequestReturnsValid() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(true, result.isValid, 'Fully valid request must pass validation');
            System.assertEquals(0, result.errorCount(), 'No errors expected for valid request');
        }
    }

    @IsTest
    static void validateNullRequestReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(null);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Null request must fail validation');
            System.assert(result.errors[0].contains('null'), 'Error must mention null record');
        }
    }

    @IsTest
    static void validateMissingFirstNameReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            req.FirstName__c = null;
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Missing first name must fail');
            System.assert(result.fieldErrors.containsKey('FirstName__c'), 'Field error for FirstName__c expected');
        }
    }

    @IsTest
    static void validateMissingLastNameReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            req.LastName__c = '';
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Missing last name must fail');
            System.assert(result.fieldErrors.containsKey('LastName__c'), 'Field error for LastName__c expected');
        }
    }

    @IsTest
    static void validateMissingDobReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            req.DateOfBirth__c = null;
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Missing DOB must fail');
            System.assert(result.fieldErrors.containsKey('DateOfBirth__c'), 'Field error for DateOfBirth__c expected');
        }
    }

    @IsTest
    static void validateFutureDobReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            req.DateOfBirth__c = Date.today().addDays(1);
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Future DOB must fail');
            System.assert(result.fieldErrors.containsKey('DateOfBirth__c'), 'Field error for future DOB expected');
        }
    }

    @IsTest
    static void validateImplausibleDobReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            req.DateOfBirth__c = Date.today().addYears(-135);
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Implausible DOB (>130 years) must fail');
        }
    }

    @IsTest
    static void validateInvalidEmailReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            req.Email__c = 'not-an-email';
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Invalid email format must fail');
            System.assert(result.fieldErrors.containsKey('Email__c'), 'Field error for Email__c expected');
        }
    }

    @IsTest
    static void validateMissingEmailReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            req.Email__c = null;
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Missing email must fail');
        }
    }

    @IsTest
    static void validateInvalidPhoneReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            req.PhoneNumber__c = '123';
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Short phone must fail');
            System.assert(result.fieldErrors.containsKey('PhoneNumber__c'), 'Field error for PhoneNumber__c expected');
        }
    }

    @IsTest
    static void validateMissingPhoneReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            req.PhoneNumber__c = null;
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Missing phone must fail');
        }
    }

    @IsTest
    static void validateInvalidZipReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            req.ZIPCode__c = 'ABCDE';
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Non-numeric ZIP must fail');
            System.assert(result.fieldErrors.containsKey('ZIPCode__c'), 'Field error for ZIPCode__c expected');
        }
    }

    @IsTest
    static void validateZipPlusFourPassesValidation() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            req.ZIPCode__c = '62701-1234';
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(true, result.isValid, 'ZIP+4 format must pass validation');
        }
    }

    @IsTest
    static void validateMissingAddressReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            req.AddressLine1__c = null;
            req.City__c = null;
            req.State__c = null;
            req.ZIPCode__c = null;
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Missing address fields must fail');
            System.assert(result.fieldErrors.containsKey('AddressLine1__c'), 'AddressLine1__c error expected');
            System.assert(result.fieldErrors.containsKey('City__c'), 'City__c error expected');
        }
    }

    @IsTest
    static void validateMissingPlanFieldsReturnErrors() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            req.PlanName__c = null;
            req.PlanType__c = null;
            req.SSN__c = null;
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Missing plan fields must fail');
            System.assert(result.fieldErrors.containsKey('PlanName__c'), 'PlanName__c error expected');
            System.assert(result.fieldErrors.containsKey('SSN__c'), 'SSN__c error expected');
        }
    }

    @IsTest
    static void validatePastEffectiveDateReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            req.EffectiveDate__c = Date.today().addDays(-10);
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Past effective date must fail');
            System.assert(result.fieldErrors.containsKey('EffectiveDate__c'), 'EffectiveDate__c error expected');
        }
    }

    @IsTest
    static void validateNullEffectiveDateReturnsError() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Enrollment_Request__c req = buildValidRequest();
            req.EffectiveDate__c = null;
            Test.startTest();
            ValidationErrorWrapper result = EnrollmentValidationService.validate(req);
            Test.stopTest();
            System.assertEquals(false, result.isValid, 'Null effective date must fail');
        }
    }

    @IsTest
    static void validateAllReturnsOneResultPerRecord() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            List<Enrollment_Request__c> reqs = new List<Enrollment_Request__c>{
                buildValidRequest(),
                new Enrollment_Request__c(FirstName__c = null, LastName__c = null)
            };
            Test.startTest();
            List<ValidationErrorWrapper> results = EnrollmentValidationService.validateAll(reqs);
            Test.stopTest();
            System.assertEquals(2, results.size(), 'One result per input record expected');
            System.assertEquals(true, results[0].isValid, 'First record is valid');
            System.assertEquals(false, results[1].isValid, 'Second record is invalid');
        }
    }

    @IsTest
    static void validateAllEmptyListReturnsEmpty() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            List<ValidationErrorWrapper> results = EnrollmentValidationService.validateAll(new List<Enrollment_Request__c>());
            Test.stopTest();
            System.assertEquals(0, results.size(), 'Empty input must return empty result list');
        }
    }

    @IsTest
    static void validateAllNullListReturnsEmpty() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            List<ValidationErrorWrapper> results = EnrollmentValidationService.validateAll(null);
            Test.stopTest();
            System.assertEquals(0, results.size(), 'Null list must return empty result list');
        }
    }

    @IsTest
    static void validateBulkOf200RecordsHandlesAll() {
        User u = [SELECT Id FROM User WHERE LastName = 'EVSTest' LIMIT 1];
        System.runAs(u) {
            List<Enrollment_Request__c> reqs = new List<Enrollment_Request__c>();
            for (Integer i = 0; i < 200; i++) {
                Enrollment_Request__c req = buildValidRequest();
                req.Email__c = 'user' + i + '@example.com';
                reqs.add(req);
            }
            Test.startTest();
            List<ValidationErrorWrapper> results = EnrollmentValidationService.validateAll(reqs);
            Test.stopTest();
            System.assertEquals(200, results.size(), '200 results expected for 200 input records');
            for (ValidationErrorWrapper r : results) {
                System.assertEquals(true, r.isValid, 'All bulk records must be valid');
            }
        }
    }
}