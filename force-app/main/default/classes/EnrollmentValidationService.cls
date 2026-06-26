/**
 * @description Validates Enrollment_Request__c records for required fields, format constraints,
 *              and date rules. Returns a ValidationErrorWrapper with all collected errors.
 */
public with sharing class EnrollmentValidationService {

    private static final String EMAIL_REGEX = '^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$';
    private static final String PHONE_REGEX = '^[0-9\\-\\(\\)\\+\\s]{10,15}$';
    private static final String ZIP_REGEX = '^\\d{5}(-\\d{4})?$';
    private static final Integer MIN_AGE_YEARS = 0;
    private static final Integer MAX_AGE_YEARS = 130;

    /** @description Typed exception for unrecoverable validation configuration errors. */
    public class EnrollmentValidationException extends Exception {}

    /**
     * @description Validates all rules for a single enrollment request.
     * @param req The Enrollment_Request__c record to validate.
     * @return ValidationErrorWrapper containing all errors found, or valid if none.
     */
    public static ValidationErrorWrapper validate(Enrollment_Request__c req) {
        ValidationErrorWrapper result = new ValidationErrorWrapper();
        if (req == null) {
            result.addError('Enrollment request record must not be null.');
            return result;
        }
        validatePersonFields(req, result);
        validateContactFields(req, result);
        validateAddressFields(req, result);
        validateEnrollmentFields(req, result);
        return result;
    }

    /**
     * @description Validates all enrollment requests in a list, keyed by record index.
     * @param requests List of Enrollment_Request__c records to validate.
     * @return List of ValidationErrorWrapper instances, one per input record.
     */
    public static List<ValidationErrorWrapper> validateAll(List<Enrollment_Request__c> requests) {
        List<ValidationErrorWrapper> results = new List<ValidationErrorWrapper>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }
        for (Enrollment_Request__c req : requests) {
            results.add(validate(req));
        }
        return results;
    }

    /**
     * @description Validates name and date-of-birth fields.
     * @param req The enrollment request.
     * @param result The wrapper to accumulate errors into.
     */
    private static void validatePersonFields(Enrollment_Request__c req, ValidationErrorWrapper result) {
        if (String.isBlank(req.FirstName__c)) {
            result.addFieldError('FirstName__c', 'First name is required.');
        }
        if (String.isBlank(req.LastName__c)) {
            result.addFieldError('LastName__c', 'Last name is required.');
        }
        if (req.DateOfBirth__c == null) {
            result.addFieldError('DateOfBirth__c', 'Date of birth is required.');
        } else {
            validateDateOfBirth(req.DateOfBirth__c, result);
        }
    }

    /**
     * @description Validates email and phone contact fields.
     * @param req The enrollment request.
     * @param result The wrapper to accumulate errors into.
     */
    private static void validateContactFields(Enrollment_Request__c req, ValidationErrorWrapper result) {
        if (String.isBlank(req.Email__c)) {
            result.addFieldError('Email__c', 'Email address is required.');
        } else if (!isValidEmail(req.Email__c)) {
            result.addFieldError('Email__c', 'Email address format is invalid.');
        }
        if (String.isBlank(req.PhoneNumber__c)) {
            result.addFieldError('PhoneNumber__c', 'Phone number is required.');
        } else if (!isValidPhone(req.PhoneNumber__c)) {
            result.addFieldError('PhoneNumber__c', 'Phone number format is invalid. Use 10-15 digits.');
        }
    }

    /**
     * @description Validates address fields including ZIP code format.
     * @param req The enrollment request.
     * @param result The wrapper to accumulate errors into.
     */
    private static void validateAddressFields(Enrollment_Request__c req, ValidationErrorWrapper result) {
        if (String.isBlank(req.AddressLine1__c)) {
            result.addFieldError('AddressLine1__c', 'Address line 1 is required.');
        }
        if (String.isBlank(req.City__c)) {
            result.addFieldError('City__c', 'City is required.');
        }
        if (String.isBlank(req.State__c)) {
            result.addFieldError('State__c', 'State is required.');
        }
        if (String.isBlank(req.ZIPCode__c)) {
            result.addFieldError('ZIPCode__c', 'ZIP code is required.');
        } else if (!isValidZip(req.ZIPCode__c)) {
            result.addFieldError('ZIPCode__c', 'ZIP code must be 5 digits or ZIP+4 format (e.g. 12345 or 12345-6789).');
        }
    }

    /**
     * @description Validates coverage-specific enrollment fields and effective date.
     * @param req The enrollment request.
     * @param result The wrapper to accumulate errors into.
     */
    private static void validateEnrollmentFields(Enrollment_Request__c req, ValidationErrorWrapper result) {
        if (String.isBlank(req.PlanName__c)) {
            result.addFieldError('PlanName__c', 'Plan name is required.');
        }
        if (String.isBlank(req.PlanType__c)) {
            result.addFieldError('PlanType__c', 'Plan type is required.');
        }
        if (req.EffectiveDate__c == null) {
            result.addFieldError('EffectiveDate__c', 'Coverage effective date is required.');
        } else {
            validateEffectiveDate(req.EffectiveDate__c, result);
        }
        if (String.isBlank(req.SSN__c)) {
            result.addFieldError('SSN__c', 'Social Security Number is required.');
        }
    }

    /**
     * @description Validates that date of birth represents a plausible age.
     * @param dob The date of birth to validate.
     * @param result The wrapper to accumulate errors into.
     */
    private static void validateDateOfBirth(Date dob, ValidationErrorWrapper result) {
        if (dob >= Date.today()) {
            result.addFieldError('DateOfBirth__c', 'Date of birth must be in the past.');
            return;
        }
        Integer age = calculateAge(dob);
        if (age > MAX_AGE_YEARS) {
            result.addFieldError('DateOfBirth__c', 'Date of birth indicates an implausible age (over ' + MAX_AGE_YEARS + ' years).');
        }
    }

    /**
     * @description Validates that the effective date is not in the past.
     * @param effectiveDate The coverage effective date to validate.
     * @param result The wrapper to accumulate errors into.
     */
    private static void validateEffectiveDate(Date effectiveDate, ValidationErrorWrapper result) {
        if (effectiveDate < Date.today()) {
            result.addFieldError('EffectiveDate__c', 'Coverage effective date cannot be in the past.');
        }
    }

    /**
     * @description Calculates age in full years from date of birth to today.
     * @param dob The date of birth.
     * @return Integer age in years.
     */
    private static Integer calculateAge(Date dob) {
        Date today = Date.today();
        Integer age = today.year() - dob.year();
        if (today.month() < dob.month() || (today.month() == dob.month() && today.day() < dob.day())) {
            age -= 1;
        }
        return age;
    }

    /**
     * @description Checks whether an email string matches the expected email pattern.
     * @param email The email string to test.
     * @return True if the format is valid.
     */
    private static Boolean isValidEmail(String email) {
        return Pattern.matches(EMAIL_REGEX, email.trim());
    }

    /**
     * @description Checks whether a phone string matches the accepted phone pattern.
     * @param phone The phone string to test.
     * @return True if the format is valid.
     */
    private static Boolean isValidPhone(String phone) {
        return Pattern.matches(PHONE_REGEX, phone.trim());
    }

    /**
     * @description Checks whether a ZIP code string matches 5-digit or ZIP+4 format.
     * @param zip The ZIP code string to test.
     * @return True if the format is valid.
     */
    private static Boolean isValidZip(String zip) {
        return Pattern.matches(ZIP_REGEX, zip.trim());
    }
}