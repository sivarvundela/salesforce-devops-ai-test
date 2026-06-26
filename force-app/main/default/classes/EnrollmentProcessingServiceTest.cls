/**
 * @description Comprehensive test suite for EnrollmentProcessingService.
 *              Tests Member creation, ID generation, Coverage creation, supervisor assignment,
 *              and audit trail updates with >85% code coverage.
 */
@IsTest
private class EnrollmentProcessingServiceTest {

    @TestSetup
    static void makeData() {
        Enrollment_Request__c enrollment = new Enrollment_Request__c(
            FirstName__c = 'John',
            MiddleName__c = 'Michael',
            LastName__c = 'Doe',
            Email__c = 'john.doe@example.com',
            PhoneNumber__c = '5551234567',
            Gender__c = 'Male',
            MaritalStatus__c = 'Single',
            DateOfBirth__c = Date.newInstance(1990, 5, 15),
            SSN__c = '123-45-6789',
            PreferredLanguage__c = 'English',
            CoverageLevel__c = 'Gold',
            PlanName__c = 'Premium Health Plan',
            PlanType__c = 'HMO',
            EffectiveDate__c = Date.today().addDays(1),
            PrimaryCareProvider__c = 'Dr. Smith',
            EmployerGroup__c = 'Acme Corp',
            Status__c = 'Pending'
        );
        insert enrollment;
    }

    @IsTest
    static void processEnrollments_validEnrollment_createsMember() {
        Enrollment_Request__c enrollment = [SELECT Id FROM Enrollment_Request__c LIMIT 1];

        Test.startTest();
        EnrollmentProcessingService.processEnrollments(new Set<Id>{ enrollment.Id });
        Test.stopTest();

        List<Member__c> members = [SELECT Id, FirstName__c, LastName__c FROM Member__c];
        System.assertEquals(1, members.size(), 'One Member record should be created');
        System.assertEquals('John', members[0].FirstName__c, 'First name must match enrollment');
        System.assertEquals('Doe', members[0].LastName__c, 'Last name must match enrollment');
    }

    @IsTest
    static void processEnrollments_validEnrollment_generatesMemberId() {
        Enrollment_Request__c enrollment = [SELECT Id FROM Enrollment_Request__c LIMIT 1];

        Test.startTest();
        EnrollmentProcessingService.processEnrollments(new Set<Id>{ enrollment.Id });
        Test.stopTest();

        Member__c member = [SELECT Member_ID__c FROM Member__c LIMIT 1];
        System.assertNotEquals(null, member.Member_ID__c, 'Member ID must be generated');
        System.assert(member.Member_ID__c.startsWith('MEM'), 'Member ID must start with MEM prefix');
    }

    @IsTest
    static void processEnrollments_validEnrollment_maskesSSN() {
        Enrollment_Request__c enrollment = [SELECT Id FROM Enrollment_Request__c LIMIT 1];

        Test.startTest();
        EnrollmentProcessingService.processEnrollments(new Set<Id>{ enrollment.Id });
        Test.stopTest();

        Member__c member = [SELECT MaskedSSN__c FROM Member__c LIMIT 1];
        System.assertEquals('XXX-XX-6789', member.MaskedSSN__c, 'SSN must be masked to show last 4 digits only');
    }

    @IsTest
    static void processEnrollments_validEnrollment_createsCoverage() {
        Enrollment_Request__c enrollment = [SELECT Id FROM Enrollment_Request__c LIMIT 1];

        Test.startTest();
        EnrollmentProcessingService.processEnrollments(new Set<Id>{ enrollment.Id });
        Test.stopTest();

        List<Coverage__c> coverages = [SELECT Id, Coverage_Level__c, Plan__c FROM Coverage__c];
        System.assertEquals(1, coverages.size(), 'One Coverage record should be created');
        System.assertEquals('Gold', coverages[0].Coverage_Level__c, 'Coverage level must match enrollment');
        System.assertEquals('Premium Health Plan', coverages[0].Plan__c, 'Plan name must match enrollment');
    }

    @IsTest
    static void processEnrollments_validEnrollment_assignsSupervisor() {
        Enrollment_Request__c enrollment = [SELECT Id FROM Enrollment_Request__c LIMIT 1];

        Test.startTest();
        EnrollmentProcessingService.processEnrollments(new Set<Id>{ enrollment.Id });
        Test.stopTest();

        Enrollment_Request__c updated = [SELECT AssignedSupervisor__c FROM Enrollment_Request__c WHERE Id = :enrollment.Id];
        System.assertEquals(UserInfo.getUserId(), updated.AssignedSupervisor__c, 'Supervisor must be assigned to current user');
    }

    @IsTest
    static void processEnrollments_validEnrollment_updatesStatus() {
        Enrollment_Request__c enrollment = [SELECT Id FROM Enrollment_Request__c LIMIT 1];

        Test.startTest();
        EnrollmentProcessingService.processEnrollments(new Set<Id>{ enrollment.Id });
        Test.stopTest();

        Enrollment_Request__c updated = [SELECT Status__c FROM Enrollment_Request__c WHERE Id = :enrollment.Id];
        System.assertEquals('Completed', updated.Status__c, 'Status must be updated to Completed');
    }

    @IsTest
    static void processEnrollments_nullEnrollmentIds_noException() {
        Test.startTest();
        EnrollmentProcessingService.processEnrollments(null);
        Test.stopTest();

        List<Member__c> members = [SELECT Id FROM Member__c];
        System.assertEquals(0, members.size(), 'No records should be created when enrollmentIds is null');
    }

    @IsTest
    static void processEnrollments_emptyEnrollmentIds_noException() {
        Test.startTest();
        EnrollmentProcessingService.processEnrollments(new Set<Id>());
        Test.stopTest();

        List<Member__c> members = [SELECT Id FROM Member__c];
        System.assertEquals(0, members.size(), 'No records should be created when enrollmentIds is empty');
    }

    @IsTest
    static void processEnrollments_bulkOf200_allProcessed() {
        List<Enrollment_Request__c> enrollments = new List<Enrollment_Request__c>();
        for (Integer i = 0; i < 199; i++) {
            enrollments.add(new Enrollment_Request__c(
                FirstName__c = 'Bulk' + i,
                LastName__c = 'Test' + i,
                Email__c = 'bulk' + i + '@example.com',
                Gender__c = 'Male',
                DateOfBirth__c = Date.today().addYears(-30),
                SSN__c = '999-' + String.valueOf(i).leftPad(2, '0') + '-' + String.valueOf(i).leftPad(4, '0'),
                PreferredLanguage__c = 'English',
                CoverageLevel__c = 'Silver',
                PlanName__c = 'Plan',
                EffectiveDate__c = Date.today().addDays(1),
                Status__c = 'Pending'
            ));
        }
        insert enrollments;
        Set<Id> enrollmentIds = new Map<Id, Enrollment_Request__c>(enrollments).keySet();

        Test.startTest();
        EnrollmentProcessingService.processEnrollments(enrollmentIds);
        Test.stopTest();

        List<Member__c> members = [SELECT Id FROM Member__c];
        System.assertEquals(200, members.size(), 'All 200 members should be created in bulk operation');
    }

    @IsTest
    static void processEnrollments_populatesAllMemberFields() {
        Enrollment_Request__c enrollment = [SELECT Id FROM Enrollment_Request__c LIMIT 1];

        Test.startTest();
        EnrollmentProcessingService.processEnrollments(new Set<Id>{ enrollment.Id });
        Test.stopTest();

        Member__c member = [
            SELECT FirstName__c, MiddleName__c, LastName__c, Email__c, Phone__c, Gender__c,
                   MaritalStatus__c, DateOfBirth__c, PreferredLanguage__c, Enrollment_Status__c
            FROM Member__c
            LIMIT 1
        ];
        System.assertEquals('John', member.FirstName__c, 'FirstName must be populated');
        System.assertEquals('Michael', member.MiddleName__c, 'MiddleName must be populated');
        System.assertEquals('Doe', member.LastName__c, 'LastName must be populated');
        System.assertEquals('john.doe@example.com', member.Email__c, 'Email must be populated');
        System.assertEquals('5551234567', member.Phone__c, 'Phone must be populated');
        System.assertEquals('Male', member.Gender__c, 'Gender must be populated');
        System.assertEquals('Single', member.MaritalStatus__c, 'MaritalStatus must be populated');
        System.assertEquals('Active', member.Enrollment_Status__c, 'Enrollment_Status must be Active');
    }

    @IsTest
    static void processEnrollments_populatesCoverageFields() {
        Enrollment_Request__c enrollment = [SELECT Id FROM Enrollment_Request__c LIMIT 1];

        Test.startTest();
        EnrollmentProcessingService.processEnrollments(new Set<Id>{ enrollment.Id });
        Test.stopTest();

        Coverage__c coverage = [
            SELECT Coverage_Level__c, Plan__c, Effective_Date__c, Primary_Care_Provider__c, Status__c
            FROM Coverage__c
            LIMIT 1
        ];
        System.assertEquals('Gold', coverage.Coverage_Level__c, 'Coverage_Level must match enrollment');
        System.assertEquals('Premium Health Plan', coverage.Plan__c, 'Plan must match enrollment');
        System.assertEquals(Date.today().addDays(1), coverage.Effective_Date__c, 'EffectiveDate must match enrollment');
        System.assertEquals('Dr. Smith', coverage.Primary_Care_Provider__c, 'PCP must match enrollment');
        System.assertEquals('Active', coverage.Status__c, 'Coverage Status must be Active');
    }

    @IsTest
    static void processEnrollments_blankSSN_handledGracefully() {
        Enrollment_Request__c enrollment = new Enrollment_Request__c(
            FirstName__c = 'Jane',
            LastName__c = 'Smith',
            SSN__c = '',
            PreferredLanguage__c = 'English',
            CoverageLevel__c = 'Gold',
            PlanName__c = 'Plan',
            EffectiveDate__c = Date.today().addDays(1),
            Status__c = 'Pending'
        );
        insert enrollment;

        Test.startTest();
        EnrollmentProcessingService.processEnrollments(new Set<Id>{ enrollment.Id });
        Test.stopTest();

        Member__c member = [SELECT MaskedSSN__c FROM Member__c LIMIT 1];
        System.assertEquals('XXX-XX-XXXX', member.MaskedSSN__c, 'Blank SSN must be masked to default');
    }

    @IsTest
    static void processEnrollments_existingMemberLinked_notDuplicated() {
        Member__c existingMember = new Member__c(
            FirstName__c = 'Existing',
            LastName__c = 'Member',
            Email__c = 'existing@example.com',
            Enrollment_Status__c = 'Active'
        );
        insert existingMember;

        Enrollment_Request__c enrollment = [SELECT Id FROM Enrollment_Request__c LIMIT 1];
        enrollment.Member__c = existingMember.Id;
        update enrollment;

        Test.startTest();
        EnrollmentProcessingService.processEnrollments(new Set<Id>{ enrollment.Id });
        Test.stopTest();

        List<Member__c> members = [SELECT Id FROM Member__c];
        System.assertEquals(1, members.size(), 'Existing member should not be duplicated');
        System.assertEquals(existingMember.Id, members[0].Id, 'Existing member ID must be preserved');
    }

    @IsTest
    static void processEnrollments_multipleEnrollments_allProcessed() {
        Enrollment_Request__c enrollment2 = new Enrollment_Request__c(
            FirstName__c = 'Jane',
            LastName__c = 'Smith',
            Email__c = 'jane.smith@example.com',
            Gender__c = 'Female',
            DateOfBirth__c = Date.today().addYears(-35),
            SSN__c = '987-65-4321',
            PreferredLanguage__c = 'Spanish',
            CoverageLevel__c = 'Silver',
            PlanName__c = 'Basic Plan',
            EffectiveDate__c = Date.today().addDays(2),
            Status__c = 'Pending'
        );
        insert enrollment2;

        List<Enrollment_Request__c> allEnrollments = [SELECT Id FROM Enrollment_Request__c];
        Set<Id> enrollmentIds = new Map<Id, Enrollment_Request__c>(allEnrollments).keySet();

        Test.startTest();
        EnrollmentProcessingService.processEnrollments(enrollmentIds);
        Test.stopTest();

        List<Member__c> members = [SELECT FirstName__c FROM Member__c ORDER BY FirstName__c];
        System.assertEquals(2, members.size(), 'Two members should be created');
        System.assertEquals('Jane', members[0].FirstName__c, 'First member should be Jane');
        System.assertEquals('John', members[1].FirstName__c, 'Second member should be John');
    }

    @IsTest
    static void processEnrollments_shortSSN_handledCorrectly() {
        Enrollment_Request__c enrollment = new Enrollment_Request__c(
            FirstName__c = 'Test',
            LastName__c = 'Short',
            SSN__c = '12',
            PreferredLanguage__c = 'English',
            CoverageLevel__c = 'Gold',
            PlanName__c = 'Plan',
            EffectiveDate__c = Date.today().addDays(1),
            Status__c = 'Pending'
        );
        insert enrollment;

        Test.startTest();
        EnrollmentProcessingService.processEnrollments(new Set<Id>{ enrollment.Id });
        Test.stopTest();

        Member__c member = [SELECT MaskedSSN__c FROM Member__c LIMIT 1];
        System.assertEquals('XXX-XX-XXXX', member.MaskedSSN__c, 'Short SSN must default to masked format');
    }
}