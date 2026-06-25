@IsTest
private class ValidationServiceTest {

    // ========== SETUP ==========
    @TestSetup
    static void makeData() {
        // Setup test data if needed
    }

    // ========== DATA VALIDATION TESTS ==========

    @IsTest
    static void validateRequiredFields_missingField_returnsError() {
        Map<String, Object> fieldMap = new Map<String, Object>{
            'FirstName' => 'John',
            'LastName' => '',
            'Email' => 'john@example.com'
        };
        List<String> requiredFields = new List<String>{ 'FirstName', 'LastName', 'Email', 'Phone' };

        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateRequiredFields(fieldMap, requiredFields);
        Test.stopTest();

        System.assertEquals(2, errors.size(), 'Should have 2 errors for missing LastName and Phone');
        Boolean hasLastNameError = false;
        Boolean hasPhoneError = false;
        for (ValidationErrorWrapper error : errors) {
            if (error.fieldName == 'LastName') hasLastNameError = true;
            if (error.fieldName == 'Phone') hasPhoneError = true;
        }
        System.assert(hasLastNameError && hasPhoneError, 'Errors must include LastName and Phone');
    }

    @IsTest
    static void validateRequiredFields_allFieldsPopulated_noErrors() {
        Map<String, Object> fieldMap = new Map<String, Object>{
            'FirstName' => 'John',
            'LastName' => 'Doe',
            'Email' => 'john@example.com',
            'Phone' => '5551234567'
        };
        List<String> requiredFields = new List<String>{ 'FirstName', 'LastName', 'Email', 'Phone' };

        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateRequiredFields(fieldMap, requiredFields);
        Test.stopTest();

        System.assertEquals(0, errors.size(), 'No errors should be returned when all required fields are populated');
    }

    @IsTest
    static void validateEmailFormat_validEmail_noErrors() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateEmailFormat('test@example.com', 'Email');
        Test.stopTest();

        System.assertEquals(0, errors.size(), 'Valid email should return no errors');
    }

    @IsTest
    static void validateEmailFormat_invalidEmail_returnsError() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateEmailFormat('invalid.email', 'Email');
        Test.stopTest();

        System.assertEquals(1, errors.size(), 'Invalid email should return an error');
        System.assertEquals('Email', errors[0].fieldName, 'Error should be for Email field');
    }

    @IsTest
    static void validatePhoneFormat_validPhone_noErrors() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validatePhoneFormat('5551234567', 'Phone');
        Test.stopTest();

        System.assertEquals(0, errors.size(), 'Valid phone should return no errors');
    }

    @IsTest
    static void validatePhoneFormat_invalidPhone_returnsError() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validatePhoneFormat('123', 'Phone');
        Test.stopTest();

        System.assertEquals(1, errors.size(), 'Invalid phone should return an error');
    }

    @IsTest
    static void validateZipCode_validZip_noErrors() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateZipCode('12345', 'ZIP');
        Test.stopTest();

        System.assertEquals(0, errors.size(), 'Valid ZIP code should return no errors');
    }

    @IsTest
    static void validateZipCode_validZipPlus4_noErrors() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateZipCode('12345-6789', 'ZIP');
        Test.stopTest();

        System.assertEquals(0, errors.size(), 'Valid ZIP+4 code should return no errors');
    }

    @IsTest
    static void validateSSNFormat_validSSN_noErrors() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateSSNFormat('123-45-6789', 'SSN');
        Test.stopTest();

        System.assertEquals(0, errors.size(), 'Valid SSN should return no errors');
    }

    @IsTest
    static void validateSSNFormat_invalidSSN_returnsError() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateSSNFormat('12345678', 'SSN');
        Test.stopTest();

        System.assertEquals(1, errors.size(), 'Invalid SSN should return an error');
    }

    @IsTest
    static void validateDateOfBirth_validDOB_noErrors() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateDateOfBirth(Date.today().addYears(-30), 'DOB');
        Test.stopTest();

        System.assertEquals(0, errors.size(), 'Valid past DOB should return no errors');
    }

    @IsTest
    static void validateDateOfBirth_futureDOB_returnsError() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateDateOfBirth(Date.today().addDays(1), 'DOB');
        Test.stopTest();

        System.assertEquals(1, errors.size(), 'Future DOB should return an error');
    }

    @IsTest
    static void validateEffectiveDate_validEffectiveDate_noErrors() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateEffectiveDate(Date.today().addDays(1), 'EffectiveDate');
        Test.stopTest();

        System.assertEquals(0, errors.size(), 'Valid future effective date should return no errors');
    }

    @IsTest
    static void validateEffectiveDate_pastEffectiveDate_returnsError() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateEffectiveDate(Date.today().addDays(-1), 'EffectiveDate');
        Test.stopTest();

        System.assertEquals(1, errors.size(), 'Past effective date should return an error');
    }

    @IsTest
    static void validateStringLength_withinLimit_noErrors() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateStringLength('Test', 10, 'TestField');
        Test.stopTest();

        System.assertEquals(0, errors.size(), 'String within limit should return no errors');
    }

    @IsTest
    static void validateStringLength_exceedsLimit_returnsError() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateStringLength('This is a very long string', 10, 'TestField');
        Test.stopTest();

        System.assertEquals(1, errors.size(), 'String exceeding limit should return an error');
    }

    @IsTest
    static void validateNumericRange_withinRange_noErrors() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateNumericRange(50, 0, 100, 'TestField');
        Test.stopTest();

        System.assertEquals(0, errors.size(), 'Value within range should return no errors');
    }

    @IsTest
    static void validateNumericRange_outsideRange_returnsError() {
        Test.startTest();
        List<ValidationErrorWrapper> errors = ValidationService.validateNumericRange(150, 0, 100, 'TestField');
        Test.stopTest();

        System.assertEquals(1, errors.size(), 'Value outside range should return an error');
    }
}
