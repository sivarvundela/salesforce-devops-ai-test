/**
 * @description Test class for ValidationErrorWrapper — uses in-memory object creation (Strategy A).
 */
@IsTest
private class ValidationErrorWrapperTest {

    @IsTest
    static void constructor_noArgs_createsValidResult() {
        Test.startTest();
        ValidationErrorWrapper wrapper = new ValidationErrorWrapper();
        Test.stopTest();

        System.assertEquals(true, wrapper.isValid, 'Default constructor must create a valid result');
        System.assertEquals(0, wrapper.getErrorCount(), 'Default constructor must have zero errors');
        System.assertEquals(null, wrapper.validationType, 'Validation type must be null');
        System.assertEquals(null, wrapper.failedField, 'Failed field must be null');
    }

    @IsTest
    static void constructor_withMessageAndType_createsInvalidResult() {
        Test.startTest();
        ValidationErrorWrapper wrapper = new ValidationErrorWrapper('Email format invalid', 'FIELD_FORMAT');
        Test.stopTest();

        System.assertEquals(false, wrapper.isValid, 'Constructor with message must create invalid result');
        System.assertEquals(1, wrapper.getErrorCount(), 'Must have exactly one error');
        System.assertEquals('Email format invalid', wrapper.getFirstError(), 'Error message must match');
        System.assertEquals('FIELD_FORMAT', wrapper.validationType, 'Validation type must be set');
    }

    @IsTest
    static void constructor_withMessageTypeAndField_setsAllProperties() {
        Test.startTest();
        ValidationErrorWrapper wrapper = new ValidationErrorWrapper(
            'Phone is invalid',
            'FIELD_FORMAT',
            'PhoneNumber__c'
        );
        Test.stopTest();

        System.assertEquals(false, wrapper.isValid, 'Must be invalid');
        System.assertEquals('Phone is invalid', wrapper.getFirstError(), 'Error message must match');
        System.assertEquals('FIELD_FORMAT', wrapper.validationType, 'Type must be FIELD_FORMAT');
        System.assertEquals('PhoneNumber__c', wrapper.failedField, 'Failed field must be set');
    }

    @IsTest
    static void addError_singleMessage_addsToErrors() {
        ValidationErrorWrapper wrapper = new ValidationErrorWrapper();
        Test.startTest();
        wrapper.addError('ZIP code is invalid');
        Test.stopTest();

        System.assertEquals(false, wrapper.isValid, 'Valid result must become invalid after adding error');
        System.assertEquals(1, wrapper.getErrorCount(), 'Must have one error');
        System.assertEquals('ZIP code is invalid', wrapper.getFirstError(), 'Error must match');
    }

    @IsTest
    static void addError_multipleMessages_accumulates() {
        ValidationErrorWrapper wrapper = new ValidationErrorWrapper();
        Test.startTest();
        wrapper.addError('Error 1');
        wrapper.addError('Error 2');
        wrapper.addError('Error 3');
        Test.stopTest();

        System.assertEquals(3, wrapper.getErrorCount(), 'All three errors must be accumulated');
        System.assertEquals('Error 1', wrapper.getFirstError(), 'First error must be first');
    }

    @IsTest
    static void addError_withField_setsFailedField() {
        ValidationErrorWrapper wrapper = new ValidationErrorWrapper();
        Test.startTest();
        wrapper.addError('DOB cannot be in future', 'DateOfBirth__c');
        Test.stopTest();

        System.assertEquals(false, wrapper.isValid, 'Must be invalid');
        System.assertEquals('DateOfBirth__c', wrapper.failedField, 'Failed field must be set');
        System.assertEquals('DOB cannot be in future', wrapper.getFirstError(), 'Error message must match');
    }

    @IsTest
    static void getErrorSummary_noErrors_returnsEmpty() {
        ValidationErrorWrapper wrapper = new ValidationErrorWrapper();
        Test.startTest();
        String summary = wrapper.getErrorSummary();
        Test.stopTest();

        System.assertEquals('', summary, 'Summary must be empty when no errors');
    }

    @IsTest
    static void getErrorSummary_multipleErrors_joins() {
        ValidationErrorWrapper wrapper = new ValidationErrorWrapper('First error', 'TEST');
        wrapper.addError('Second error');
        wrapper.addError('Third error');
        Test.startTest();
        String summary = wrapper.getErrorSummary();
        Test.stopTest();

        System.assert(
            summary.contains('First error'),
            'Summary must contain first error: ' + summary
        );
        System.assert(
            summary.contains('Second error'),
            'Summary must contain second error: ' + summary
        );
        System.assert(
            summary.contains('Third error'),
            'Summary must contain third error: ' + summary
        );
        System.assert(
            summary.contains(';'),
            'Summary must join with semicolon: ' + summary
        );
    }

    @IsTest
    static void getFirstError_noErrors_returnsNull() {
        ValidationErrorWrapper wrapper = new ValidationErrorWrapper();
        Test.startTest();
        String firstError = wrapper.getFirstError();
        Test.stopTest();

        System.assertEquals(null, firstError, 'First error must be null when no errors');
    }

    @IsTest
    static void getErrorCount_empty_returnsZero() {
        ValidationErrorWrapper wrapper = new ValidationErrorWrapper();
        Test.startTest();
        Integer count = wrapper.getErrorCount();
        Test.stopTest();

        System.assertEquals(0, count, 'Count must be zero when no errors');
    }

    @IsTest
    static void getErrorCount_afterAdding_returnsCorrect() {
        ValidationErrorWrapper wrapper = new ValidationErrorWrapper('Error 1', 'TYPE');
        wrapper.addError('Error 2');
        wrapper.addError('Error 3');
        Test.startTest();
        Integer count = wrapper.getErrorCount();
        Test.stopTest();

        System.assertEquals(3, count, 'Count must be three');
    }

    @IsTest
    static void properties_areAccessible() {
        ValidationErrorWrapper wrapper = new ValidationErrorWrapper('Test error', 'TEST_TYPE', 'TestField');
        Test.startTest();
        Boolean isValidValue = wrapper.isValid;
        List<String> errorsList = wrapper.errors;
        String typeValue = wrapper.validationType;
        String fieldValue = wrapper.failedField;
        Test.stopTest();

        System.assertEquals(false, isValidValue, 'isValid property must be accessible');
        System.assertEquals(1, errorsList.size(), 'errors list must be accessible');
        System.assertEquals('TEST_TYPE', typeValue, 'validationType must be accessible');
        System.assertEquals('TestField', fieldValue, 'failedField must be accessible');
    }
}
