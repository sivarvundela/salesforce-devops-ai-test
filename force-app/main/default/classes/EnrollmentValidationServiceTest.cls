/**
 * @description Test class for EnrollmentValidationService — uses in-memory record creation (Strategy A).
 */
@IsTest
private class EnrollmentValidationServiceTest {

    /**
     * @description Helper method to create a valid enrollment record for testing.
     * @return A valid Enrollment_Request__c record with all required fields populated.
     */
    private static Enrollment_Request__c createValidEnrollment() {
        return new Enrollment_Request__c(
            FirstName__c = 'John',
            LastName__c = 'Doe',
            Email__c = 'john.doe@example.co',
            PhoneNumber__c = '5551234567',
            DateOfBirth__c = Date.newInstance(1980, 1, 15),
            SSN__c = '123456789',
            AddressLine1__c = '123 Main Street',
            City__c = 'Springfield',
            State__c = 'IL',
            ZIPCode__c = '62701',
            EffectiveDate__c = Date.today().addDays(30)
        );
    }

    @IsTest
    static void validateEnrollment_allFieldsValid_returnsValid() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(true, result.isValid, 'Valid enrollment must pass validation');
        System.assertEquals(0, result.getErrorCount(), 'No errors should be present');
    }

    @IsTest
    static void validateEnrollment_nullRecord_returnsError() {
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(null);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Null record must fail');
        System.assert(
            result.getFirstError().contains('required'),
            'Error must mention null record: ' + result.getFirstError()
        );
    }

    @IsTest
    static void validateEnrollment_missingFirstName_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.FirstName__c = null;
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Missing first name must fail');
        System.assert(
            result.getErrorSummary().contains('First Name'),
            'Error must mention first name: ' + result.getErrorSummary()
        );
    }

    @IsTest
    static void validateEnrollment_missingLastName_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.LastName__c = '';
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Missing last name must fail');
        System.assert(
            result.getErrorSummary().contains('Last Name'),
            'Error must mention last name: ' + result.getErrorSummary()
        );
    }

    @IsTest
    static void validateEnrollment_missingEmail_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.Email__c = null;
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Missing email must fail');
        System.assert(
            result.getErrorSummary().contains('Email'),
            'Error must mention email: ' + result.getErrorSummary()
        );
    }

    @IsTest
    static void validateEnrollment_missingPhoneNumber_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.PhoneNumber__c = null;
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Missing phone must fail');
        System.assert(
            result.getErrorSummary().contains('Phone'),
            'Error must mention phone: ' + result.getErrorSummary()
        );
    }

    @IsTest
    static void validateEnrollment_missingDateOfBirth_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.DateOfBirth__c = null;
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Missing DOB must fail');
        System.assert(
            result.getErrorSummary().contains('Date of Birth'),
            'Error must mention DOB: ' + result.getErrorSummary()
        );
    }

    @IsTest
    static void validateEnrollment_missingSSN_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.SSN__c = null;
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Missing SSN must fail');
        System.assert(
            result.getErrorSummary().contains('SSN'),
            'Error must mention SSN: ' + result.getErrorSummary()
        );
    }

    @IsTest
    static void validateEnrollment_missingAddress_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.AddressLine1__c = null;
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Missing address must fail');
        System.assert(
            result.getErrorSummary().contains('Address'),
            'Error must mention address: ' + result.getErrorSummary()
        );
    }

    @IsTest
    static void validateEnrollment_missingCity_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.City__c = null;
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Missing city must fail');
        System.assert(
            result.getErrorSummary().contains('City'),
            'Error must mention city: ' + result.getErrorSummary()
        );
    }

    @IsTest
    static void validateEnrollment_missingState_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.State__c = null;
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Missing state must fail');
        System.assert(
            result.getErrorSummary().contains('State'),
            'Error must mention state: ' + result.getErrorSummary()
        );
    }

    @IsTest
    static void validateEnrollment_missingZIP_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.ZIPCode__c = null;
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Missing ZIP must fail');
        System.assert(
            result.getErrorSummary().contains('ZIP'),
            'Error must mention ZIP: ' + result.getErrorSummary()
        );
    }

    @IsTest
    static void validateEnrollment_missingEffectiveDate_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.EffectiveDate__c = null;
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Missing effective date must fail');
        System.assert(
            result.getErrorSummary().contains('Effective Date'),
            'Error must mention effective date: ' + result.getErrorSummary()
        );
    }

    @IsTest
    static void validateEnrollment_invalidEmailFormat_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.Email__c = 'invalid-email';
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Invalid email format must fail');
        System.assert(
            result.getErrorSummary().contains('Email format'),
            'Error must mention email format: ' + result.getErrorSummary()
        );
    }

    @IsTest
    static void validateEnrollment_invalidPhoneFormat_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.PhoneNumber__c = '123';
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Invalid phone format must fail');
        System.assert(
            result.getErrorSummary().contains('Phone number'),
            'Error must mention phone number: ' + result.getErrorSummary()
        );
    }

    @IsTest
    static void validateEnrollment_invalidZIPFormat_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.ZIPCode__c = 'ABC';
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Invalid ZIP format must fail');
        System.assert(
            result.getErrorSummary().contains('ZIP code'),
            'Error must mention ZIP code: ' + result.getErrorSummary()
        );
    }

    @IsTest
    static void validateEnrollment_DOBInFuture_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.DateOfBirth__c = Date.today().addDays(1);
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Future DOB must fail');
        System.assert(
            result.getErrorSummary().contains('Date of Birth'),
            'Error must mention DOB: ' + result.getErrorSummary()
        );
    }

    @IsTest
    static void validateEnrollment_effectiveDateInPast_returnsError() {
        Enrollment_Request__c enrollment = createValidEnrollment();
        enrollment.EffectiveDate__c = Date.today().addDays(-1);
        Test.startTest();
        ValidationErrorWrapper result = EnrollmentValidationService.validateEnrollment(enrollment);
        Test.stopTest();

        System.assertEquals(false, result.isValid, 'Past effective date must fail');
        System.assert(
            result.getErrorSummary().contains('Effective Date'),
            'Error must mention effective date: ' + result.getErrorSummary()
        );
    }
}
