public with sharing class ValidationService {
    private static final String ERROR = 'ERROR';
    private static final String WARNING = 'WARNING';
    private static final String INFO = 'INFO';
    private static final String DATA = 'DATA';
    private static final String DUPLICATE = 'DUPLICATE';
    private static final String ELIGIBILITY = 'ELIGIBILITY';

    private static final Integer MAX_FILE_SIZE_MB = 25;
    private static final Set<String> ALLOWED_FILE_TYPES = new Set<String>{ 'pdf', 'jpg', 'jpeg', 'png' };
    private static final String EMAIL_PATTERN = '^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2}$';
    private static final String PHONE_PATTERN = '^\\d{10}$';
    private static final String ZIP_PATTERN = '^\\d{5}(-\\d{4})?$';
    private static final String SSN_PATTERN = '^\\d{3}-\\d{2}-\\d{4}$';

    // ========== DATA VALIDATION ==========

    public static List<ValidationErrorWrapper> validateRequiredFields(Map<String, Object> fieldMap, List<String> requiredFields) {
        List<ValidationErrorWrapper> errors = new List<ValidationErrorWrapper>();
        if (fieldMap == null || requiredFields == null) {
            return errors;
        }

        for (String fieldName : requiredFields) {
            Object value = fieldMap.get(fieldName);
            if (value == null || (value instanceof String && String.isBlank((String) value))) {
                errors.add(new ValidationErrorWrapper(
                    fieldName,
                    fieldName + ' is required',
                    ERROR,
                    DATA
                ));
            }
        }
        return errors;
    }

    public static List<ValidationErrorWrapper> validateEmailFormat(String email, String fieldName) {
        List<ValidationErrorWrapper> errors = new List<ValidationErrorWrapper>();
        if (String.isBlank(email)) {
            return errors;
        }

        Pattern emailPattern = Pattern.compile(EMAIL_PATTERN);
        if (!emailPattern.matcher(email).matches()) {
            errors.add(new ValidationErrorWrapper(
                fieldName != null ? fieldName : 'Email',
                'Invalid email format',
                ERROR,
                DATA
            ));
        }
        return errors;
    }

    public static List<ValidationErrorWrapper> validatePhoneFormat(String phone, String fieldName) {
        List<ValidationErrorWrapper> errors = new List<ValidationErrorWrapper>();
        if (String.isBlank(phone)) {
            return errors;
        }

        String cleanPhone = phone.replaceAll('[^0-9]', '');
        Pattern phonePattern = Pattern.compile(PHONE_PATTERN);
        if (!phonePattern.matcher(cleanPhone).matches()) {
            errors.add(new ValidationErrorWrapper(
                fieldName != null ? fieldName : 'Phone',
                'Phone must be 10 digits',
                ERROR,
                DATA
            ));
        }
        return errors;
    }

    public static List<ValidationErrorWrapper> validateZipCode(String zip, String fieldName) {
        List<ValidationErrorWrapper> errors = new List<ValidationErrorWrapper>();
        if (String.isBlank(zip)) {
            return errors;
        }

        Pattern zipPattern = Pattern.compile(ZIP_PATTERN);
        if (!zipPattern.matcher(zip).matches()) {
            errors.add(new ValidationErrorWrapper(
                fieldName != null ? fieldName : 'ZIP Code',
                'ZIP code must be 5 digits or 5+4 format',
                ERROR,
                DATA
            ));
        }
        return errors;
    }

    public static List<ValidationErrorWrapper> validateSSNFormat(String ssn, String fieldName) {
        List<ValidationErrorWrapper> errors = new List<ValidationErrorWrapper>();
        if (String.isBlank(ssn)) {
            return errors;
        }

        Pattern ssnPattern = Pattern.compile(SSN_PATTERN);
        if (!ssnPattern.matcher(ssn).matches()) {
            errors.add(new ValidationErrorWrapper(
                fieldName != null ? fieldName : 'SSN',
                'SSN must be in XXX-XX-XXXX format',
                ERROR,
                DATA
            ));
        }
        return errors;
    }

    public static List<ValidationErrorWrapper> validateDateOfBirth(Date dob, String fieldName) {
        List<ValidationErrorWrapper> errors = new List<ValidationErrorWrapper>();
        if (dob == null) {
            return errors;
        }

        if (dob > Date.today()) {
            errors.add(new ValidationErrorWrapper(
                fieldName != null ? fieldName : 'DateOfBirth',
                'Date of birth cannot be in the future',
                ERROR,
                DATA
            ));
        }
        return errors;
    }

    public static List<ValidationErrorWrapper> validateEffectiveDate(Date effectiveDate, String fieldName) {
        List<ValidationErrorWrapper> errors = new List<ValidationErrorWrapper>();
        if (effectiveDate == null) {
            return errors;
        }

        if (effectiveDate < Date.today()) {
            errors.add(new ValidationErrorWrapper(
                fieldName != null ? fieldName : 'EffectiveDate',
                'Effective date cannot be in the past',
                ERROR,
                DATA
            ));
        }
        return errors;
    }

    public static List<ValidationErrorWrapper> validateFileUpload(String fileName, Double fileSizeMB, String fieldName) {
        List<ValidationErrorWrapper> errors = new List<ValidationErrorWrapper>();
        if (String.isBlank(fileName)) {
            return errors;
        }

        String extension = fileName.substringAfterLast('.').toLowerCase();
        if (!ALLOWED_FILE_TYPES.contains(extension)) {
            errors.add(new ValidationErrorWrapper(
                fieldName != null ? fieldName : 'File',
                'File type must be PDF, JPG, or PNG',
                ERROR,
                DATA
            ));
        }

        if (fileSizeMB > MAX_FILE_SIZE_MB) {
            errors.add(new ValidationErrorWrapper(
                fieldName != null ? fieldName : 'File',
                'File size must not exceed ' + MAX_FILE_SIZE_MB + ' MB',
                ERROR,
                DATA
            ));
        }
        return errors;
    }

    public static List<ValidationErrorWrapper> validateStringLength(String value, Integer maxLength, String fieldName) {
        List<ValidationErrorWrapper> errors = new List<ValidationErrorWrapper>();
        if (String.isBlank(value)) {
            return errors;
        }

        if (value.length() > maxLength) {
            errors.add(new ValidationErrorWrapper(
                fieldName != null ? fieldName : 'Field',
                'Value must not exceed ' + maxLength + ' characters',
                ERROR,
                DATA
            ));
        }
        return errors;
    }

    public static List<ValidationErrorWrapper> validateNumericRange(Decimal value, Decimal minValue, Decimal maxValue, String fieldName) {
        List<ValidationErrorWrapper> errors = new List<ValidationErrorWrapper>();
        if (value == null) {
            return errors;
        }

        if (value < minValue || value > maxValue) {
            errors.add(new ValidationErrorWrapper(
                fieldName != null ? fieldName : 'Field',
                'Value must be between ' + minValue + ' and ' + maxValue,
                ERROR,
                DATA
            ));
        }
        return errors;
    }

    // ========== HELPER METHODS ==========

    public static Boolean allErrorsHaveSeverity(List<ValidationErrorWrapper> errors, String severity) {
        if (errors.isEmpty()) {
            return true;
        }
        for (ValidationErrorWrapper error : errors) {
            if (error.severity != severity) {
                return false;
            }
        }
        return true;
    }

    public static Integer countErrorsBySeverity(List<ValidationErrorWrapper> errors, String severity) {
        Integer count = 0;
        for (ValidationErrorWrapper error : errors) {
            if (error.severity == severity) {
                count++;
            }
        }
        return count;
    }

    public static Integer countErrorsByType(List<ValidationErrorWrapper> errors, String validationType) {
        Integer count = 0;
        for (ValidationErrorWrapper error : errors) {
            if (error.validationType == validationType) {
                count++;
            }
        }
        return count;
    }

    public static List<ValidationErrorWrapper> mergeErrorLists(List<List<ValidationErrorWrapper>> errorLists) {
        List<ValidationErrorWrapper> merged = new List<ValidationErrorWrapper>();
        for (List<ValidationErrorWrapper> errorList : errorLists) {
            if (errorList != null) {
                merged.addAll(errorList);
            }
        }
        return merged;
    }

    public static Map<String, List<ValidationErrorWrapper>> groupErrorsByField(List<ValidationErrorWrapper> errors) {
        Map<String, List<ValidationErrorWrapper>> grouped = new Map<String, List<ValidationErrorWrapper>>();
        for (ValidationErrorWrapper error : errors) {
            if (!grouped.containsKey(error.fieldName)) {
                grouped.put(error.fieldName, new List<ValidationErrorWrapper>());
            }
            grouped.get(error.fieldName).add(error);
        }
        return grouped;
    }

    public static Map<String, List<ValidationErrorWrapper>> groupErrorsBySeverity(List<ValidationErrorWrapper> errors) {
        Map<String, List<ValidationErrorWrapper>> grouped = new Map<String, List<ValidationErrorWrapper>>();
        for (ValidationErrorWrapper error : errors) {
            if (!grouped.containsKey(error.severity)) {
                grouped.put(error.severity, new List<ValidationErrorWrapper>());
            }
            grouped.get(error.severity).add(error);
        }
        return grouped;
    }
}
