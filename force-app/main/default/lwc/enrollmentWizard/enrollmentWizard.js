import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TITLE_LABEL        from '@salesforce/label/c.UI_New_Member_Enrollment_Title';
import BACK_LABEL         from '@salesforce/label/c.UI_Back_Button';
import NEXT_LABEL         from '@salesforce/label/c.UI_Next_Button';
import VALIDATE_LABEL     from '@salesforce/label/c.UI_Validate_Button';
import SAVE_DRAFT_LABEL   from '@salesforce/label/c.UI_Save_Draft_Button';
import getEnrollmentRequest  from '@salesforce/apex/EnrollmentWizardController.getEnrollmentRequest';
import saveEnrollmentRequest from '@salesforce/apex/EnrollmentWizardController.saveEnrollmentRequest';

const STEPS = [
    { label: 'Member Information', value: 'step1' },
    { label: 'Documents',          value: 'step2' },
    { label: 'Review & Submit',    value: 'step3' }
];

export default class EnrollmentWizard extends LightningElement {
    @api get enrollmentRequestId() { return this._enrollmentRequestId; }
    set enrollmentRequestId(val) {
        this._enrollmentRequestId = val;
        if (val) { this.loadEnrollmentRequest(); }
    }

    _enrollmentRequestId;
    currentStepIndex  = 0;
    enrollmentRecord  = {};
    isLoading         = false;
    errorMessage      = '';
    stepHasError      = false;
    documentCount     = 0;

    newMemberEnrollmentTitle = TITLE_LABEL;
    backLabel                = BACK_LABEL;
    nextLabel                = NEXT_LABEL;
    validateLabel            = VALIDATE_LABEL;
    saveDraftLabel           = SAVE_DRAFT_LABEL;

    get steps() { return STEPS; }
    get currentStepValue() { return STEPS[this.currentStepIndex].value; }
    get isStep1() { return this.currentStepIndex === 0; }
    get isStep2() { return this.currentStepIndex === 1; }
    get isStep3() { return this.currentStepIndex === 2; }
    get isLastStep() { return this.currentStepIndex === STEPS.length - 1; }
    get showBack() { return this.currentStepIndex > 0; }
    get fullName() {
        const f = this.enrollmentRecord.FirstName__c || '';
        const m = this.enrollmentRecord.MiddleName__c ? ' ' + this.enrollmentRecord.MiddleName__c : '';
        const l = this.enrollmentRecord.LastName__c || '';
        return (f + m + ' ' + l).trim();
    }

    loadEnrollmentRequest() {
        this.isLoading = true;
        this.errorMessage = '';
        getEnrollmentRequest({ recordId: this._enrollmentRequestId })
            .then(result => { this.enrollmentRecord = result ? { ...result } : {}; })
            .catch(err => { this.errorMessage = err.body ? err.body.message : err.message; })
            .finally(() => { this.isLoading = false; });
    }

    handleFormChange(event) {
        this.enrollmentRecord = { ...this.enrollmentRecord, ...event.detail.formData };
    }

    handleDocumentUploaded() {
        this.documentCount += 1;
    }

    handleBack() {
        if (this.currentStepIndex > 0) {
            this.currentStepIndex -= 1;
            this.stepHasError = false;
            this.errorMessage = '';
        }
    }

    handleNext() {
        if (!this.validateCurrentStep()) { return; }
        this.isLoading = true;
        this.errorMessage = '';
        const recordToSave = { ...this.enrollmentRecord };
        saveEnrollmentRequest({ record: recordToSave })
            .then(savedId => {
                if (!this._enrollmentRequestId) {
                    this._enrollmentRequestId = savedId;
                    this.enrollmentRecord = { ...this.enrollmentRecord, Id: savedId };
                }
                this.currentStepIndex += 1;
                this.stepHasError = false;
            })
            .catch(err => {
                this.errorMessage = err.body ? err.body.message : err.message;
                this.stepHasError = true;
            })
            .finally(() => { this.isLoading = false; });
    }

    handleSaveDraft() {
        this.isLoading = true;
        this.errorMessage = '';
        const recordToSave = { ...this.enrollmentRecord, Status__c: 'Draft' };
        saveEnrollmentRequest({ record: recordToSave })
            .then(savedId => {
                if (!this._enrollmentRequestId) {
                    this._enrollmentRequestId = savedId;
                    this.enrollmentRecord = { ...this.enrollmentRecord, Id: savedId };
                }
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Draft Saved',
                    message: 'Enrollment request saved as draft.',
                    variant: 'success'
                }));
            })
            .catch(err => { this.errorMessage = err.body ? err.body.message : err.message; })
            .finally(() => { this.isLoading = false; });
    }

    handleSubmit() {
        if (!this.validateCurrentStep()) { return; }
        this.isLoading = true;
        this.errorMessage = '';
        const recordToSave = { ...this.enrollmentRecord, Status__c: 'Submitted' };
        saveEnrollmentRequest({ record: recordToSave })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Enrollment Submitted',
                    message: 'Enrollment request has been submitted successfully.',
                    variant: 'success'
                }));
                this.dispatchEvent(new CustomEvent('enrollmentsubmitted', {
                    detail: { enrollmentRequestId: this._enrollmentRequestId },
                    bubbles: true
                }));
            })
            .catch(err => {
                this.errorMessage = err.body ? err.body.message : err.message;
                this.stepHasError = true;
            })
            .finally(() => { this.isLoading = false; });
    }

    validateCurrentStep() {
        if (this.currentStepIndex === 0) {
            const memberInfoCmp = this.template.querySelector('c-enrollment-member-information');
            if (memberInfoCmp) {
                const isValid = memberInfoCmp.validate();
                if (!isValid) {
                    this.stepHasError = true;
                    this.errorMessage = 'Please fill in all required fields.';
                    return false;
                }
            }
        }
        if (this.currentStepIndex === 1) {
            const uploaderCmp = this.template.querySelector('c-enrollment-document-uploader');
            if (uploaderCmp) {
                const isValid = uploaderCmp.validate();
                if (!isValid) {
                    this.stepHasError = true;
                    this.errorMessage = 'Please upload at least one document.';
                    return false;
                }
            }
        }
        this.stepHasError = false;
        this.errorMessage = '';
        return true;
    }
}