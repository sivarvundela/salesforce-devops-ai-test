/**
 * @description Verifies enrollment eligibility by checking employer status, plan availability,
 *              Medicare/Medicaid eligibility, coverage effective dates, and PCP availability
 *              using existing org data from Account, Coverage__c, and Enrollment_Request__c.
 */
public with sharing class EligibilityVerificationService {

    private static final Set<String> MEDICARE_PLAN_TYPES = new Set<String>{'Medicare Advantage', 'Medicare Supplement', 'Part D'};
    private static final Set<String> MEDICAID_PLAN_TYPES = new Set<String>{'Medicaid', 'CHIP', 'Managed Medicaid'};
    private static final Integer MAX_FUTURE_DAYS = 365;

    /** @description Typed exception for unrecoverable eligibility check errors. */
    public class EligibilityException extends Exception {}

    /**
     * @description Runs all eligibility checks for a single enrollment request.
     * @param req The Enrollment_Request__c to verify.
     * @return ValidationErrorWrapper with any eligibility errors or warnings.
     */
    public static ValidationErrorWrapper verifyEligibility(Enrollment_Request__c req) {
        ValidationErrorWrapper result = new ValidationErrorWrapper();
        if (req == null) {
            result.addError('Enrollment request must not be null.');
            return result;
        }
        checkEmployerEligibility(req, result);
        checkPlanAvailability(req, result);
        checkGovernmentProgramEligibility(req, result);
        checkCoverageEffectiveDates(req, result);
        checkPcpAvailability(req, result);
        return result;
    }

    /**
     * @description Verifies that the employer group account is active and eligible.
     * @param req The enrollment request.
     * @param result The wrapper to accumulate errors into.
     */
    private static void checkEmployerEligibility(Enrollment_Request__c req, ValidationErrorWrapper result) {
        if (String.isBlank(req.EmployerGroup__c)) {
            result.addWarning('No employer group specified; individual enrollment assumed.');
            return;
        }
        List<Account> employers = [
            SELECT Id, Name, Active__c, Type
            FROM Account
            WHERE Name = :req.EmployerGroup__c
            AND Type = 'Customer'
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (employers.isEmpty()) {
            result.addFieldError('EmployerGroup__c',
                'Employer group not found: ' + req.EmployerGroup__c);
            return;
        }
        Account employer = employers[0];
        if (employer.Active__c != 'Yes') {
            result.addFieldError('EmployerGroup__c',
                'Employer group is not active: ' + req.EmployerGroup__c);
        }
    }

    /**
     * @description Checks whether the requested plan has active coverage records in the org.
     * @param req The enrollment request.
     * @param result The wrapper to accumulate errors into.
     */
    private static void checkPlanAvailability(Enrollment_Request__c req, ValidationErrorWrapper result) {
        if (String.isBlank(req.PlanName__c)) { return; }
        List<Coverage__c> availablePlans = [
            SELECT Id, Plan__c, Status__c, Coverage_Level__c
            FROM Coverage__c
            WHERE Plan__c = :req.PlanName__c
            AND Status__c = 'Active'
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (availablePlans.isEmpty()) {
            result.addFieldError('PlanName__c',
                'The requested plan is not available or not active: ' + req.PlanName__c);
        }
    }

    /**
     * @description Checks Medicare and Medicaid eligibility constraints based on plan type.
     * @param req The enrollment request.
     * @param result The wrapper to accumulate errors into.
     */
    private static void checkGovernmentProgramEligibility(Enrollment_Request__c req, ValidationErrorWrapper result) {
        if (String.isBlank(req.PlanType__c)) { return; }
        if (MEDICARE_PLAN_TYPES.contains(req.PlanType__c)) {
            checkMedicareAge(req, result);
        }
        if (MEDICAID_PLAN_TYPES.contains(req.PlanType__c)) {
            checkMedicaidIncome(req, result);
        }
    }

    /**
     * @description Validates that Medicare plan enrollees are at least 65 years old.
     * @param req The enrollment request.
     * @param result The wrapper to accumulate errors into.
     */
    private static void checkMedicareAge(Enrollment_Request__c req, ValidationErrorWrapper result) {
        if (req.DateOfBirth__c == null) {
            result.addFieldError('DateOfBirth__c',
                'Date of birth is required to verify Medicare eligibility.');
            return;
        }
        Integer age = calculateAge(req.DateOfBirth__c);
        if (age < 65) {
            result.addFieldError('PlanType__c',
                'Medicare plans require the enrollee to be at least 65 years old. Current age: ' + age);
        }
    }

    /**
     * @description Adds a Medicaid income verification advisory warning.
     * @param req The enrollment request.
     * @param result The wrapper to accumulate errors into.
     */
    private static void checkMedicaidIncome(Enrollment_Request__c req, ValidationErrorWrapper result) {
        result.addWarning(
            'Medicaid/CHIP plans require income and residency verification. ' +
            'Ensure supporting documents are submitted with this enrollment.'
        );
    }

    /**
     * @description Verifies that the effective date is within acceptable future bounds.
     * @param req The enrollment request.
     * @param result The wrapper to accumulate errors into.
     */
    private static void checkCoverageEffectiveDates(Enrollment_Request__c req, ValidationErrorWrapper result) {
        if (req.EffectiveDate__c == null) { return; }
        if (req.EffectiveDate__c < Date.today()) {
            result.addFieldError('EffectiveDate__c',
                'Coverage effective date must not be in the past.');
            return;
        }
        Long daysDiff = Date.today().daysBetween(req.EffectiveDate__c);
        if (daysDiff > MAX_FUTURE_DAYS) {
            result.addFieldError('EffectiveDate__c',
                'Coverage effective date cannot be more than ' + MAX_FUTURE_DAYS +
                ' days in the future.');
        }
    }

    /**
     * @description Verifies that a specified PCP exists as an active coverage record.
     * @param req The enrollment request.
     * @param result The wrapper to accumulate errors into.
     */
    private static void checkPcpAvailability(Enrollment_Request__c req, ValidationErrorWrapper result) {
        if (String.isBlank(req.PrimaryCareProvider__c)) {
            result.addWarning('No Primary Care Provider specified. A PCP may be required for HMO plans.');
            return;
        }
        List<Coverage__c> pcpRecords = [
            SELECT Id, Primary_Care_Provider__c, Status__c
            FROM Coverage__c
            WHERE Primary_Care_Provider__c = :req.PrimaryCareProvider__c
            AND Status__c = 'Active'
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (pcpRecords.isEmpty()) {
            result.addFieldError('PrimaryCareProvider__c',
                'The specified Primary Care Provider is not available in the network: ' +
                req.PrimaryCareProvider__c);
        }
    }

    /**
     * @description Calculates age in full years from a given date of birth.
     * @param dob The date of birth.
     * @return Integer age in years.
     */
    private static Integer calculateAge(Date dob) {
        Date today = Date.today();
        Integer age = today.year() - dob.year();
        if (today.month() < dob.month() ||
            (today.month() == dob.month() && today.day() < dob.day())) {
            age -= 1;
        }
        return age;
    }

    /**
     * @description Verifies eligibility for a list of enrollment requests.
     * @param requests List of enrollment requests to verify.
     * @return List of ValidationErrorWrapper instances, one per input record.
     */
    public static List<ValidationErrorWrapper> verifyAll(List<Enrollment_Request__c> requests) {
        List<ValidationErrorWrapper> results = new List<ValidationErrorWrapper>();
        if (requests == null || requests.isEmpty()) { return results; }
        for (Enrollment_Request__c req : requests) {
            results.add(verifyEligibility(req));
        }
        return results;
    }
}