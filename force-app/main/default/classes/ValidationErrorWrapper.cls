public with sharing class ValidationErrorWrapper {
    @AuraEnabled public String fieldName { get; set; }
    @AuraEnabled public String message { get; set; }
    @AuraEnabled public String severity { get; set; } // ERROR, WARNING, INFO
    @AuraEnabled public String validationType { get; set; } // DATA, DUPLICATE, ELIGIBILITY

    public ValidationErrorWrapper(String fieldName, String message, String severity, String validationType) {
        this.fieldName = fieldName;
        this.message = message;
        this.severity = severity;
        this.validationType = validationType;
    }

    public static List<ValidationErrorWrapper> filterBySeverity(List<ValidationErrorWrapper> errors, String severity) {
        List<ValidationErrorWrapper> filtered = new List<ValidationErrorWrapper>();
        for (ValidationErrorWrapper error : errors) {
            if (error.severity == severity) {
                filtered.add(error);
            }
        }
        return filtered;
    }

    public static List<ValidationErrorWrapper> filterByType(List<ValidationErrorWrapper> errors, String validationType) {
        List<ValidationErrorWrapper> filtered = new List<ValidationErrorWrapper>();
        for (ValidationErrorWrapper error : errors) {
            if (error.validationType == validationType) {
                filtered.add(error);
            }
        }
        return filtered;
    }

    public static Boolean hasErrors(List<ValidationErrorWrapper> errors) {
        return !errors.isEmpty();
    }

    public static Boolean hasErrorsWithSeverity(List<ValidationErrorWrapper> errors, String severity) {
        for (ValidationErrorWrapper error : errors) {
            if (error.severity == severity) {
                return true;
            }
        }
        return false;
    }
}