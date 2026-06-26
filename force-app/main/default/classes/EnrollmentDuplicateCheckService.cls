/**
 * @description Checks for duplicate SSN, existing Member records, and duplicate Coverage
 *              enrollments before persisting a new Enrollment_Request__c.
 */
public with sharing class EnrollmentDuplicateCheckService {

    /** @description Typed exception for duplicate-check failures. */
    public class DuplicateCheckException extends Exception {}

    /**
     * @description Runs all duplicate checks for a single enrollment request.
     * @param req The Enrollment_Request__c to check (not yet inserted).
     * @return ValidationErrorWrapper with duplicate errors, or valid if no duplicates found.
     */
    public static ValidationErrorWrapper checkForDuplicates(Enrollment_Request__c req) {
        ValidationErrorWrapper result = new ValidationErrorWrapper();
        if (req == null) {
            result.addError('Enrollment request must not be null.');
            return result;
        }
        checkDuplicateSSN(req, result);
        checkExistingMember(req, result);
        checkDuplicateCoverage(req, result);
        return result;
    }

    /**
     * @description Checks whether another enrollment request shares the same SSN.
     * @param req The current enrollment request.
     * @param result The wrapper to accumulate errors into.
     */
    private static void checkDuplicateSSN(Enrollment_Request__c req, ValidationErrorWrapper result) {
        if (String.isBlank(req.SSN__c)) { return; }
        String excludeId = req.Id != null ? req.Id : 'NONE_PLACEHOLDER';
        List<Enrollment_Request__c> dupes = [
            SELECT Id, FirstName__c, LastName__c
            FROM Enrollment_Request__c
            WHERE SSN__c = :req.SSN__c
            AND Id != :excludeId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (!dupes.isEmpty()) {
            result.addFieldError('SSN__c',
                'An enrollment request already exists with this Social Security Number.');
        }
    }

    /**
     * @description Checks whether a Member__c record with the same SSN already exists.
     * @param req The current enrollment request.
     * @param result The wrapper to accumulate errors into.
     */
    private static void checkExistingMember(Enrollment_Request__c req, ValidationErrorWrapper result) {
        if (String.isBlank(req.SSN__c)) { return; }
        String maskedSuffix = req.SSN__c.length() >= 4
            ? req.SSN__c.substring(req.SSN__c.length() - 4)
            : req.SSN__c;
        List<Member__c> existingMembers = [
            SELECT Id, FirstName__c, LastName__c
            FROM Member__c
            WHERE MaskedSSN__c = :maskedSuffix
            WITH SECURITY_ENFORCED
            LIMIT 5
        ];
        if (!existingMembers.isEmpty()) {
            result.addWarning(
                'A Member record matching the last 4 digits of this SSN already exists. ' +
                'Please verify this is not a duplicate member.'
            );
        }
    }

    /**
     * @description Checks whether an active enrollment with the same plan and coverage level exists for the member.
     * @param req The current enrollment request.
     * @param result The wrapper to accumulate errors into.
     */
    private static void checkDuplicateCoverage(Enrollment_Request__c req, ValidationErrorWrapper result) {
        if (req.Member__c == null || String.isBlank(req.PlanName__c)) { return; }
        List<Enrollment_Request__c> activeCoverage = [
            SELECT Id, PlanName__c, CoverageLevel__c, Status__c
            FROM Enrollment_Request__c
            WHERE Member__c = :req.Member__c
            AND PlanName__c = :req.PlanName__c
            AND Status__c IN ('Active', 'Submitted', 'Pending')
            AND Id != :req.Id
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (!activeCoverage.isEmpty()) {
            result.addFieldError('PlanName__c',
                'This member already has an active or pending enrollment for plan: ' + req.PlanName__c);
        }
    }

    /**
     * @description Runs duplicate checks for a list of enrollment requests.
     * @param requests List of enrollment requests to check.
     * @return List of ValidationErrorWrapper instances, one per input record.
     */
    public static List<ValidationErrorWrapper> checkAllForDuplicates(List<Enrollment_Request__c> requests) {
        List<ValidationErrorWrapper> results = new List<ValidationErrorWrapper>();
        if (requests == null || requests.isEmpty()) { return results; }
        for (Enrollment_Request__c req : requests) {
            results.add(checkForDuplicates(req));
        }
        return results;
    }
}