/**
 * @description Wrapper class for structured validation error responses, providing
 *              a consistent error format across all enrollment validation services.
 */
public with sharing class ValidationErrorWrapper {
    /** @description Whether validation passed (true) or failed (false). */
    public Boolean isValid { get; private set; }

    /** @description List of error messages describing validation failures. */
    public List<String> errors { get; private set; }

    /** @description Type of validation (e.g., FIELD_FORMAT, DUPLICATE, ELIGIBILITY). */
    public String validationType { get; private set; }

    /** @description Field API name that failed validation, if applicable. */
    public String failedField { get; private set; }

    /**
     * @description Constructor for a successful validation result (no errors).
     */
    public ValidationErrorWrapper() {
        this.isValid = true;
        this.errors = new List<String>();
        this.validationType = null;
        this.failedField = null;
    }

    /**
     * @description Constructor for a failed validation with error message and type.
     * @param errorMessage The validation error message.
     * @param validationType The type of validation that failed.
     */
    public ValidationErrorWrapper(String errorMessage, String validationType) {
        this.isValid = false;
        this.errors = new List<String>{ errorMessage };
        this.validationType = validationType;
        this.failedField = null;
    }

    /**
     * @description Constructor for a failed validation with error message, type, and field.
     * @param errorMessage The validation error message.
     * @param validationType The type of validation that failed.
     * @param failedField The field API name that failed validation.
     */
    public ValidationErrorWrapper(String errorMessage, String validationType, String failedField) {
        this.isValid = false;
        this.errors = new List<String>{ errorMessage };
        this.validationType = validationType;
        this.failedField = failedField;
    }

    /**
     * @description Adds an error message to an existing validation result.
     * @param errorMessage The additional error message.
     */
    public void addError(String errorMessage) {
        this.isValid = false;
        this.errors.add(errorMessage);
    }

    /**
     * @description Adds an error message and marks validation type and failed field.
     * @param errorMessage The error message.
     * @param fieldName The field that failed.
     */
    public void addError(String errorMessage, String fieldName) {
        this.isValid = false;
        this.errors.add(errorMessage);
        this.failedField = fieldName;
    }

    /**
     * @description Returns the first error message, or null if validation passed.
     * @return First error string, or null if no errors.
     */
    public String getFirstError() {
        return this.errors.isEmpty() ? null : this.errors.get(0);
    }

    /**
     * @description Returns all error messages as a semicolon-separated string.
     * @return Concatenated error messages, or empty string if no errors.
     */
    public String getErrorSummary() {
        return this.errors.isEmpty() ? '' : String.join(this.errors, '; ');
    }

    /**
     * @description Returns the count of accumulated errors.
     * @return Number of error messages.
     */
    public Integer getErrorCount() {
        return this.errors.size();
    }
}
