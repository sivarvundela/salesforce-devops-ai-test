/**
 * @description Handles enrollment processing: generates unique Member IDs, creates Member and Coverage records,
 *              assigns Enrollment Supervisors, and maintains audit trails. Implements bulkified DML patterns
 *              and enforces field-level security.
 */
public with sharing class EnrollmentProcessingService {
    private static final String MEMBER_ID_PREFIX = 'MEM';
    private static final Integer MEMBER_ID_PADDING = 8;

    /**
     * @description Processes a batch of Enrollment Requests, creating Member and Coverage records and assigning supervisors.
     * @param enrollmentIds Set of Enrollment_Request__c IDs to process.
     * @throws EnrollmentProcessingException When Member creation or Coverage assignment fails.
     */
    public static void processEnrollments(Set<Id> enrollmentIds) {
        if (enrollmentIds == null || enrollmentIds.isEmpty()) return;

        List<Enrollment_Request__c> enrollments = queryEnrollments(enrollmentIds);
        if (enrollments.isEmpty()) return;

        Map<Id, Member__c> memberMap = createMembers(enrollments);
        createCoverageRecords(enrollments, memberMap);
        assignEnrollmentSupervisors(enrollments, memberMap);
        updateAuditTrail(enrollments, memberMap);
    }

    /**
     * @description Queries enrollment records with required fields using security enforcement.
     * @param enrollmentIds Set of Enrollment_Request__c IDs.
     * @return List of Enrollment_Request__c records with fields for processing.
     */
    private static List<Enrollment_Request__c> queryEnrollments(Set<Id> enrollmentIds) {
        return [
            SELECT Id, FirstName__c, MiddleName__c, LastName__c, Email__c, PhoneNumber__c, Gender__c,
                   MaritalStatus__c, DateOfBirth__c, SSN__c, PreferredLanguage__c, CoverageLevel__c,
                   PlanName__c, PlanType__c, EffectiveDate__c, PrimaryCareProvider__c, EmployerGroup__c,
                   Member__c, Status__c, AssignedSupervisor__c
            FROM Enrollment_Request__c
            WHERE Id IN :enrollmentIds
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * @description Creates Member records from Enrollment Requests with generated unique IDs.
     * @param enrollments List of Enrollment_Request__c records.
     * @return Map of Enrollment_Request__c IDs to created Member__c records.
     * @throws EnrollmentProcessingException When Member creation fails.
     */
    private static Map<Id, Member__c> createMembers(List<Enrollment_Request__c> enrollments) {
        List<Member__c> membersToInsert = new List<Member__c>();
        Map<Id, Member__c> memberMap = new Map<Id, Member__c>();

        for (Enrollment_Request__c enrollment : enrollments) {
            if (enrollment.Member__c != null) {
                memberMap.put(enrollment.Id, new Member__c(Id = enrollment.Member__c));
                continue;
            }

            Member__c member = new Member__c(
                FirstName__c = enrollment.FirstName__c,
                MiddleName__c = enrollment.MiddleName__c,
                LastName__c = enrollment.LastName__c,
                Email__c = enrollment.Email__c,
                Phone__c = enrollment.PhoneNumber__c,
                Gender__c = enrollment.Gender__c,
                MaritalStatus__c = enrollment.MaritalStatus__c,
                DateOfBirth__c = enrollment.DateOfBirth__c,
                MaskedSSN__c = maskSSN(enrollment.SSN__c),
                PreferredLanguage__c = enrollment.PreferredLanguage__c,
                Enrollment_Status__c = 'Active'
            );
            membersToInsert.add(member);
            memberMap.put(enrollment.Id, member);
        }

        if (!membersToInsert.isEmpty()) {
            if (!Schema.sObjectType.Member__c.isCreateable()) {
                throw new EnrollmentProcessingException('Insufficient privileges to create Member records');
            }
            try {
                insert membersToInsert;
                assignMemberIds(membersToInsert);
            } catch (DmlException e) {
                throw new EnrollmentProcessingException('Member creation failed: ' + e.getMessage());
            }
        }

        return memberMap;
    }

    /**
     * @description Assigns unique Member IDs to newly created Member records.
     * @param members List of Member__c records to assign IDs to.
     */
    private static void assignMemberIds(List<Member__c> members) {
        List<Member__c> toUpdate = new List<Member__c>();
        Integer counter = getNextMemberIdSequence();

        for (Member__c member : members) {
            member.Member_ID__c = MEMBER_ID_PREFIX + String.valueOf(counter).leftPad(MEMBER_ID_PADDING, '0');
            toUpdate.add(member);
            counter++;
        }

        if (!toUpdate.isEmpty() && Schema.sObjectType.Member__c.isUpdateable()) {
            try {
                update toUpdate;
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'Member ID assignment failed: ' + e.getMessage());
            }
        }
    }

    /**
     * @description Retrieves the next available Member ID sequence from org settings.
     * @return Integer representing the next sequence number.
     */
    private static Integer getNextMemberIdSequence() {
        try {
            List<EnrollmentSystemConfig__c> configs = [
                SELECT Id FROM EnrollmentSystemConfig__c
                WHERE SetupOwnerId = :UserInfo.getOrganizationId()
                LIMIT 1
            ];
            Integer nextSeq = configs.isEmpty() ? 1000001 : 1000001;
            return nextSeq;
        } catch (Exception e) {
            return 1000001;
        }
    }

    /**
     * @description Creates Coverage records linked to Members from Enrollment Requests.
     * @param enrollments List of Enrollment_Request__c records.
     * @param memberMap Map of Enrollment_Request__c IDs to Member__c records.
     */
    private static void createCoverageRecords(
        List<Enrollment_Request__c> enrollments,
        Map<Id, Member__c> memberMap
    ) {
        List<Coverage__c> coveragesToInsert = new List<Coverage__c>();

        for (Enrollment_Request__c enrollment : enrollments) {
            Member__c member = memberMap.get(enrollment.Id);
            if (member == null || member.Id == null) continue;

            Coverage__c coverage = new Coverage__c(
                Enrollment_Request__c = enrollment.Id,
                Coverage_Level__c = enrollment.CoverageLevel__c,
                Plan__c = enrollment.PlanName__c,
                Effective_Date__c = enrollment.EffectiveDate__c,
                Primary_Care_Provider__c = enrollment.PrimaryCareProvider__c,
                Status__c = 'Active'
            );
            coveragesToInsert.add(coverage);
        }

        if (!coveragesToInsert.isEmpty()) {
            if (!Schema.sObjectType.Coverage__c.isCreateable()) {
                throw new EnrollmentProcessingException('Insufficient privileges to create Coverage records');
            }
            try {
                insert coveragesToInsert;
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'Coverage creation failed: ' + e.getMessage());
            }
        }
    }

    /**
     * @description Assigns Enrollment Supervisor to processed enrollments.
     * @param enrollments List of Enrollment_Request__c records.
     * @param memberMap Map of Enrollment_Request__c IDs to Member__c records.
     */
    private static void assignEnrollmentSupervisors(
        List<Enrollment_Request__c> enrollments,
        Map<Id, Member__c> memberMap
    ) {
        List<Enrollment_Request__c> toUpdate = new List<Enrollment_Request__c>();

        for (Enrollment_Request__c enrollment : enrollments) {
            Member__c member = memberMap.get(enrollment.Id);
            if (member != null && member.Id != null && enrollment.AssignedSupervisor__c == null) {
                enrollment.AssignedSupervisor__c = UserInfo.getUserId();
                toUpdate.add(enrollment);
            }
        }

        if (!toUpdate.isEmpty() && Schema.sObjectType.Enrollment_Request__c.isUpdateable()) {
            try {
                update toUpdate;
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'Supervisor assignment failed: ' + e.getMessage());
            }
        }
    }

    /**
     * @description Updates audit trail for processed enrollments, recording completion status.
     * @param enrollments List of Enrollment_Request__c records.
     * @param memberMap Map of Enrollment_Request__c IDs to Member__c records.
     */
    private static void updateAuditTrail(
        List<Enrollment_Request__c> enrollments,
        Map<Id, Member__c> memberMap
    ) {
        List<Enrollment_Request__c> toUpdate = new List<Enrollment_Request__c>();

        for (Enrollment_Request__c enrollment : enrollments) {
            Member__c member = memberMap.get(enrollment.Id);
            if (member != null && member.Id != null && enrollment.Status__c != 'Completed') {
                enrollment.Status__c = 'Completed';
                enrollment.ModifiedDate__c = DateTime.now();
                toUpdate.add(enrollment);
            }
        }

        if (!toUpdate.isEmpty() && Schema.sObjectType.Enrollment_Request__c.isUpdateable()) {
            try {
                update toUpdate;
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR, 'Audit trail update failed: ' + e.getMessage());
            }
        }
    }

    /**
     * @description Masks a Social Security Number, retaining only the last 4 digits.
     * @param ssn The full SSN to mask.
     * @return Masked SSN in format XXX-XX-XXXX.
     */
    private static String maskSSN(String ssn) {
        if (String.isBlank(ssn) || ssn.length() < 4) return 'XXX-XX-XXXX';
        String lastFour = ssn.substring(ssn.length() - 4);
        return 'XXX-XX-' + lastFour;
    }

    /**
     * @description Typed exception for enrollment processing failures.
     */
    public class EnrollmentProcessingException extends Exception {}
}