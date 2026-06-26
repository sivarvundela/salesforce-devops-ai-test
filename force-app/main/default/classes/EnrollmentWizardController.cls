public with sharing class EnrollmentWizardController {

    @AuraEnabled
    public static Enrollment_Request__c getEnrollmentRequest(Id recordId) {
        if (recordId == null) { return new Enrollment_Request__c(); }
        List<Enrollment_Request__c> records = [
            SELECT Id, FirstName__c, LastName__c, MiddleName__c, DateOfBirth__c,
                   Gender__c, MaritalStatus__c, SSN__c, PreferredLanguage__c,
                   Email__c, PhoneNumber__c,
                   AddressLine1__c, AddressLine2__c, City__c, State__c,
                   ZIPCode__c, County__c,
                   PlanType__c, PlanName__c, CoverageLevel__c,
                   EffectiveDate__c, PrimaryCareProvider__c,
                   EmployerGroup__c, Status__c, Member__c
            FROM Enrollment_Request__c
            WHERE Id = :recordId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (records.isEmpty()) { throw new AuraHandledException('Enrollment Request not found.'); }
        return records[0];
    }

    @AuraEnabled
    public static Id saveEnrollmentRequest(Enrollment_Request__c record) {
        if (record == null) { throw new AuraHandledException('Record cannot be null.'); }
        try {
            if (record.Id == null) {
                if (!Schema.sObjectType.Enrollment_Request__c.isCreateable()) {
                    throw new AuraHandledException('Insufficient permissions to create Enrollment Request.');
                }
                insert record;
            } else {
                if (!Schema.sObjectType.Enrollment_Request__c.isUpdateable()) {
                    throw new AuraHandledException('Insufficient permissions to update Enrollment Request.');
                }
                update record;
            }
            return record.Id;
        } catch (DmlException ex) {
            throw new AuraHandledException(ex.getDmlMessage(0));
        }
    }

    @AuraEnabled
    public static void saveEnrollmentDocument(Id enrollmentRequestId, String fileName,
                                               String documentType, Long fileSize, Id contentVersionId) {
        if (enrollmentRequestId == null || String.isBlank(fileName)) {
            throw new AuraHandledException('Enrollment Request ID and file name are required.');
        }
        if (!Schema.sObjectType.Enrollment_Document__c.isCreateable()) {
            throw new AuraHandledException('Insufficient permissions to create Enrollment Document.');
        }
        Enrollment_Document__c doc = new Enrollment_Document__c(
            Enrollment_Request__c = enrollmentRequestId,
            File_Name__c          = fileName,
            Document_Type__c      = documentType,
            File_Size__c          = fileSize != null ? fileSize : 0,
            Upload_Date__c        = Date.today()
        );
        try {
            insert doc;
        } catch (DmlException ex) {
            throw new AuraHandledException(ex.getDmlMessage(0));
        }
    }

    @AuraEnabled
    public static List<Enrollment_Document__c> getEnrollmentDocuments(Id enrollmentRequestId) {
        if (enrollmentRequestId == null) { return new List<Enrollment_Document__c>(); }
        return [
            SELECT Id, File_Name__c, Document_Type__c, File_Size__c, Upload_Date__c
            FROM Enrollment_Document__c
            WHERE Enrollment_Request__c = :enrollmentRequestId
            WITH SECURITY_ENFORCED
            ORDER BY Upload_Date__c DESC
        ];
    }

    @AuraEnabled
    public static Decimal getMaxFileSizeMb() {
        List<EnrollmentSystemConfig__c> configs = [
            SELECT Max_File_Size_MB__c
            FROM EnrollmentSystemConfig__c
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (!configs.isEmpty() && configs[0].Max_File_Size_MB__c != null) {
            return configs[0].Max_File_Size_MB__c;
        }
        return 10;
    }
}