/**
 * @description Tests for ValidationErrorWrapper — uses in-memory strategy (no SOQL/DML).
 */
@IsTest
private class ValidationErrorWrapperTest {

    @TestSetup
    static void makeData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        insert new User(
            Alias = 'vewt', Email = 'vewt@example.com', EmailEncodingKey = 'UTF-8',
            LastName = 'VEWTest', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
            ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'vewt_' + System.currentTimeMillis() + '@example.com'
        );
    }

    @IsTest
    static void constructorInitializesValidState() {
        User u = [SELECT Id FROM User WHERE LastName = 'VEWTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ValidationErrorWrapper w = new ValidationErrorWrapper();
            Test.stopTest();
            System.assertEquals(true, w.isValid, 'New wrapper must be valid');
            System.assertEquals(0, w.errors.size(), 'Errors must be empty on init');
            System.assertEquals(0, w.warnings.size(), 'Warnings must be empty on init');
            System.assertEquals(0, w.fieldErrors.size(), 'FieldErrors must be empty on init');
        }
    }

    @IsTest
    static void addErrorMarksInvalid() {
        User u = [SELECT Id FROM User WHERE LastName = 'VEWTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ValidationErrorWrapper w = new ValidationErrorWrapper();
            w.addError('Something went wrong');
            Test.stopTest();
            System.assertEquals(false, w.isValid, 'Wrapper must be invalid after addError');
            System.assertEquals(1, w.errors.size(), 'One error expected');
            System.assertEquals('Something went wrong', w.errors[0], 'Error message must match');
        }
    }

    @IsTest
    static void addErrorIgnoresBlankMessage() {
        User u = [SELECT Id FROM User WHERE LastName = 'VEWTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ValidationErrorWrapper w = new ValidationErrorWrapper();
            w.addError('');
            w.addError(null);
            Test.stopTest();
            System.assertEquals(true, w.isValid, 'Blank/null errors must not invalidate wrapper');
            System.assertEquals(0, w.errors.size(), 'No errors added for blank/null messages');
        }
    }

    @IsTest
    static void addFieldErrorRecordsFieldAndGlobalError() {
        User u = [SELECT Id FROM User WHERE LastName = 'VEWTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ValidationErrorWrapper w = new ValidationErrorWrapper();
            w.addFieldError('Email__c', 'Invalid email format');
            Test.stopTest();
            System.assertEquals(false, w.isValid, 'Must be invalid after field error');
            System.assertEquals(1, w.fieldErrors.size(), 'One field error expected');
            System.assertEquals('Invalid email format', w.fieldErrors.get('Email__c'), 'Field error message must match');
            System.assertEquals(1, w.errors.size(), 'Global errors list must also contain entry');
        }
    }

    @IsTest
    static void addFieldErrorIgnoresBlanks() {
        User u = [SELECT Id FROM User WHERE LastName = 'VEWTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ValidationErrorWrapper w = new ValidationErrorWrapper();
            w.addFieldError('', 'Message');
            w.addFieldError('Field', '');
            w.addFieldError(null, null);
            Test.stopTest();
            System.assertEquals(true, w.isValid, 'Blank field errors must not invalidate wrapper');
            System.assertEquals(0, w.fieldErrors.size(), 'No field errors expected for blank inputs');
        }
    }

    @IsTest
    static void addWarningDoesNotInvalidate() {
        User u = [SELECT Id FROM User WHERE LastName = 'VEWTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ValidationErrorWrapper w = new ValidationErrorWrapper();
            w.addWarning('Minor issue noted');
            Test.stopTest();
            System.assertEquals(true, w.isValid, 'Warnings must not invalidate wrapper');
            System.assertEquals(1, w.warnings.size(), 'One warning expected');
        }
    }

    @IsTest
    static void addWarningIgnoresBlank() {
        User u = [SELECT Id FROM User WHERE LastName = 'VEWTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ValidationErrorWrapper w = new ValidationErrorWrapper();
            w.addWarning(null);
            w.addWarning('  ');
            Test.stopTest();
            System.assertEquals(0, w.warnings.size(), 'Blank warnings must not be added');
        }
    }

    @IsTest
    static void combineAbsorbsErrorsAndInvalidates() {
        User u = [SELECT Id FROM User WHERE LastName = 'VEWTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ValidationErrorWrapper w1 = new ValidationErrorWrapper();
            w1.addError('Error one');
            ValidationErrorWrapper w2 = new ValidationErrorWrapper();
            w2.addError('Error two');
            w2.addWarning('Warning one');
            w2.addFieldError('Phone__c', 'Invalid phone');
            w1.combine(w2);
            Test.stopTest();
            System.assertEquals(false, w1.isValid, 'Combined wrapper must be invalid');
            System.assertEquals(3, w1.errors.size(), 'Both error lists must be merged (2 errors + 1 field error)');
            System.assertEquals(1, w1.warnings.size(), 'Warning from second wrapper must appear');
            System.assert(w1.fieldErrors.containsKey('Phone__c'), 'Field errors must be merged');
        }
    }

    @IsTest
    static void combineWithNullDoesNotThrow() {
        User u = [SELECT Id FROM User WHERE LastName = 'VEWTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ValidationErrorWrapper w = new ValidationErrorWrapper();
            w.addError('Existing error');
            w.combine(null);
            Test.stopTest();
            System.assertEquals(1, w.errors.size(), 'Errors must be unchanged after combining null');
        }
    }

    @IsTest
    static void getErrorSummaryJoinsMessages() {
        User u = [SELECT Id FROM User WHERE LastName = 'VEWTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ValidationErrorWrapper w = new ValidationErrorWrapper();
            w.addError('First');
            w.addError('Second');
            String summary = w.getErrorSummary();
            Test.stopTest();
            System.assert(summary.contains('First'), 'Summary must include first error');
            System.assert(summary.contains('Second'), 'Summary must include second error');
        }
    }

    @IsTest
    static void getErrorSummaryReturnsEmptyWhenNoErrors() {
        User u = [SELECT Id FROM User WHERE LastName = 'VEWTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ValidationErrorWrapper w = new ValidationErrorWrapper();
            String summary = w.getErrorSummary();
            Test.stopTest();
            System.assertEquals('', summary, 'Summary must be empty string when no errors');
        }
    }

    @IsTest
    static void errorCountReturnsCorrectSize() {
        User u = [SELECT Id FROM User WHERE LastName = 'VEWTest' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            ValidationErrorWrapper w = new ValidationErrorWrapper();
            w.addError('A');
            w.addError('B');
            w.addError('C');
            Test.stopTest();
            System.assertEquals(3, w.errorCount(), 'Error count must equal number of added errors');
        }
    }
}