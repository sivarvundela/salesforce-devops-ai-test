/**
 * @description Structured wrapper for validation error responses across enrollment services.
 */
public with sharing class ValidationErrorWrapper {

    /** @description List of error messages collected during validation. */
    public List<String> errors { get; private set; }

    /** @description List of warning messages collected during validation. */
    public List<String> warnings { get; private set; }

    /** @description Whether validation passed with no errors. */
    public Boolean isValid { get; private set; }

    /** @description Optional field-level error map keyed by field API name. */
    public Map<String, String> fieldErrors { get; private set; }

    /**
     * @description Initializes a valid wrapper with empty error and warning collections.
     */
    public ValidationErrorWrapper() {
        this.errors = new List<String>();
        this.warnings = new List<String>();
        this.fieldErrors = new Map<String, String>();
        this.isValid = true;
    }

    /**
     * @description Adds an error message and marks the wrapper as invalid.
     * @param message The error message to record.
     */
    public void addError(String message) {
        if (String.isNotBlank(message)) {
            this.errors.add(message);
            this.isValid = false;
        }
    }

    /**
     * @description Adds a field-level error and marks the wrapper as invalid.
     * @param fieldName The API name of the field with the error.
     * @param message The error message for the field.
     */
    public void addFieldError(String fieldName, String message) {
        if (String.isNotBlank(fieldName) && String.isNotBlank(message)) {
            this.fieldErrors.put(fieldName, message);
            this.errors.add(fieldName + ': ' + message);
            this.isValid = false;
        }
    }

    /**
     * @description Adds a warning message without marking the wrapper as invalid.
     * @param message The warning message to record.
     */
    public void addWarning(String message) {
        if (String.isNotBlank(message)) {
            this.warnings.add(message);
        }
    }

    /**
     * @description Merges all errors and warnings from another wrapper into this one.
     * @param other The ValidationErrorWrapper whose errors and warnings to absorb.
     */
    public void combine(ValidationErrorWrapper other) {
        if (other == null) { return; }
        this.errors.addAll(other.errors);
        this.warnings.addAll(other.warnings);
        this.fieldErrors.putAll(other.fieldErrors);
        if (!other.isValid) {
            this.isValid = false;
        }
    }

    /**
     * @description Returns a single concatenated error string for simple display.
     * @return Newline-delimited string of all error messages, or empty string if none.
     */
    public String getErrorSummary() {
        if (this.errors.isEmpty()) { return ''; }
        return String.join(this.errors, '\n');
    }

    /**
     * @description Returns the count of recorded errors.
     * @return Integer count of errors.
     */
    public Integer errorCount() {
        return this.errors.size();
    }
}