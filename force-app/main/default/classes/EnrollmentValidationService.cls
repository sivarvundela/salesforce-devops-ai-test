/**
 * @description Validates enrollment request records for required fields, email format,
 *              phone format, ZIP code format, and date constraints. Returns structured
 *              error responses via ValidationErrorWrapper.
 */
public with sharing class EnrollmentValidationService {
    private static final String EMAIL_PATTERN = '^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2}$';
    private static final String PHONE_PATTERN = '^\\d{10}$';
    private static final String ZIP_PATTERN = '^\\d{5}(-\\d{4})?$';

    /**
     * @description Validates an enrollment request for required fields and format constraints.
     * @param enrollment The Enrollment_Request__c record to validate.
     * @return ValidationErrorWrapper with validation result and any error messages.
     */
    public static ValidationErrorWrapper validateEnrollment(Enrollment_Request__c enrollment) {
        ValidationErrorWrapper result = new ValidationErrorWrapper();

        if (enrollment == null) {
            return new ValidationErrorWrapper('Enrollment record is required', 'NULL_RECORD');
        }

        validateRequiredFields(enrollment, result);
        if (!result.isValid) {
            return result;
        }

        validateEmailFormat(enrollment.Email__c, result);
        validatePhoneFormat(enrollment.PhoneNumber__c, result);
        validateZipCodeFormat(enrollment.ZIPCode__c, result);
        validateDateConstraints(enrollment, result);

        return result;
    }

    /**
     * @description Validates that all required fields are populated.
     * @param enrollment The enrollment record.
     * @param result The validation result wrapper to accumulate errors.
     */
    private static void validateRequiredFields(
        Enrollment_Request__c enrollment,
        ValidationErrorWrapper result
    ) {
        if (String.isBlank(enrollment.FirstName__c)) {
            result.addError('First Name is required', 'FirstName__c');
        }
        if (String.isBlank(enrollment.LastName__c)) {
            result.addError('Last Name is required', 'LastName__c');
        }
        if (String.isBlank(enrollment.Email__c)) {
            result.addError('Email is required', 'Email__c');
        }
        if (String.isBlank(enrollment.PhoneNumber__c)) {
            result.addError('Phone Number is required', 'PhoneNumber__c');
        }
        if (enrollment.DateOfBirth__c == null) {
            result.addError('Date of Birth is required', 'DateOfBirth__c');
        }
        if (String.isBlank(enrollment.SSN__c)) {
            result.addError('SSN is required', 'SSN__c');
        }
        if (String.isBlank(enrollment.AddressLine1__c)) {
            result.addError('Address Line 1 is required', 'AddressLine1__c');
        }
        if (String.isBlank(enrollment.City__c)) {
            result.addError('City is required', 'City__c');
        }
        if (String.isBlank(enrollment.State__c)) {
            result.addError('State is required', 'State__c');
        }
        if (String.isBlank(enrollment.ZIPCode__c)) {
            result.addError('ZIP Code is required', 'ZIPCode__c');
        }
        if (enrollment.EffectiveDate__c == null) {
            result.addError('Effective Date is required', 'EffectiveDate__c');
        }
    }

    /**
     * @description Validates email format using regex pattern.
     * @param email The email address to validate.
     * @param result The validation result wrapper.
     */
    private static void validateEmailFormat(String email, ValidationErrorWrapper result) {
        if (String.isBlank(email)) {
            return;
        }
        if (!Pattern.matches(EMAIL_PATTERN, email)) {
            result.addError(
                'Email format is invalid. Please enter a valid email address.',
                'Email__c'
            );
        }
    }

    /**
     * @description Validates phone format (must be exactly 10 digits).
     * @param phone The phone number to validate.
     * @param result The validation result wrapper.
     */
    private static void validatePhoneFormat(String phone, ValidationErrorWrapper result) {
        if (String.isBlank(phone)) {
            return;
        }
        String digitsOnly = phone.replaceAll('[^0-9]', '');
        if (!Pattern.matches(PHONE_PATTERN, digitsOnly)) {
            result.addError(
                'Phone number must be exactly 10 digits.',
                'PhoneNumber__c'
            );
        }
    }

    /**
     * @description Validates ZIP code format (5 digits or 5+4 format).
     * @param zipCode The ZIP code to validate.
     * @param result The validation result wrapper.
     */
    private static void validateZipCodeFormat(String zipCode, ValidationErrorWrapper result) {
        if (String.isBlank(zipCode)) {
            return;
        }
        if (!Pattern.matches(ZIP_PATTERN, zipCode)) {
            result.addError(
                'ZIP code must be in format 12345 or 12345-6789.',
                'ZIPCode__c'
            );
        }
    }

    /**
     * @description Validates date constraints (DOB must be in past, effective date must be in future or today).
     * @param enrollment The enrollment record.
     * @param result The validation result wrapper.
     */
    private static void validateDateConstraints(
        Enrollment_Request__c enrollment,
        ValidationErrorWrapper result
    ) {
        if (enrollment.DateOfBirth__c != null && enrollment.DateOfBirth__c > Date.today()) {
            result.addError(
                'Date of Birth cannot be in the future.',
                'DateOfBirth__c'
            );
        }
        if (enrollment.EffectiveDate__c != null && enrollment.EffectiveDate__c < Date.today()) {
            result.addError(
                'Effective Date must be today or in the future.',
                'EffectiveDate__c'
            );
        }
    }
}
