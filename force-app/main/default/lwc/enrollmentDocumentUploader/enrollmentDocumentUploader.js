import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import DOCUMENTS_LABEL from '@salesforce/label/c.UI_Documents_Section';
import saveEnrollmentDocument from '@salesforce/apex/EnrollmentWizardController.saveEnrollmentDocument';
import getMaxFileSizeMb from '@salesforce/apex/EnrollmentWizardController.getMaxFileSizeMb';

const ACCEPTED_TYPES   = ['application/pdf', 'image/png', 'image/jpeg', 'application/msword',
                          'application/vnd.openxmlformats-officedocument.wordprocessingml.document'];
const ACCEPTED_EXTENSIONS = ['.pdf', '.png', '.jpg', '.jpeg', '.doc', '.docx'];

export default class EnrollmentDocumentUploader extends LightningElement {
    @api get enrollmentRequestId() { return this._enrollmentRequestId; }
    set enrollmentRequestId(val) { this._enrollmentRequestId = val; }

    _enrollmentRequestId;
    isDragging        = false;
    isUploading       = false;
    selectedDocumentType = '';
    uploadedFiles     = [];
    validationErrors  = [];
    maxFileSizeMb     = 10;
    _nextFileId       = 1;

    documentsLabel = DOCUMENTS_LABEL;

    connectedCallback() {
        getMaxFileSizeMb()
            .then(result => { this.maxFileSizeMb = result || 10; })
            .catch(() => { this.maxFileSizeMb = 10; });
    }

    get documentTypeOptions() {
        return [
            { label: '-- Select Document Type --', value: '' },
            { label: 'Application',                value: 'Application' },
            { label: 'Government Issued ID',       value: 'Government Issued ID' },
            { label: 'Proof of Residence',         value: 'Proof of Residence' },
            { label: 'Insurance Card',             value: 'Insurance Card' },
            { label: 'Medical Records',            value: 'Medical Records' },
            { label: 'Other',                      value: 'Other' }
        ];
    }

    get dropZoneClass() {
        return this.isDragging
            ? 'enrollment-uploader__drop-zone enrollment-uploader__drop-zone_active'
            : 'enrollment-uploader__drop-zone';
    }

    get hasUploadedFiles() { return this.uploadedFiles.length > 0; }
    get hasValidationErrors() { return this.validationErrors.length > 0; }

    handleDocumentTypeChange(event) {
        this.selectedDocumentType = event.detail.value;
    }

    handleChooseFiles() {
        this.template.querySelector('[data-id="fileInput"]').click();
    }

    handleFileInputChange(event) {
        this.processFiles([...event.target.files]);
        event.target.value = '';
    }

    handleDragOver(event) {
        event.preventDefault();
        this.isDragging = true;
    }

    handleDragLeave() {
        this.isDragging = false;
    }

    handleDrop(event) {
        event.preventDefault();
        this.isDragging = false;
        this.processFiles([...event.dataTransfer.files]);
    }

    processFiles(files) {
        this.validationErrors = [];
        if (!this.selectedDocumentType) {
            this.validationErrors = ['Please select a Document Type before uploading files.'];
            return;
        }
        const errors = [];
        const validFiles = [];
        const maxBytes = this.maxFileSizeMb * 1024 * 1024;

        files.forEach(file => {
            const ext = '.' + file.name.split('.').pop().toLowerCase();
            if (!ACCEPTED_EXTENSIONS.includes(ext) && !ACCEPTED_TYPES.includes(file.type)) {
                errors.push(`"${file.name}" is not an accepted file type. Accepted: PDF, PNG, JPG, DOC, DOCX.`);
            } else if (file.size > maxBytes) {
                errors.push(`"${file.name}" exceeds the maximum file size of ${this.maxFileSizeMb} MB.`);
            } else {
                validFiles.push(file);
            }
        });

        this.validationErrors = errors;
        if (validFiles.length > 0) {
            this.uploadFiles(validFiles);
        }
    }

    uploadFiles(files) {
        if (!this._enrollmentRequestId) {
            this.validationErrors = ['Enrollment Request must be saved before uploading documents.'];
            return;
        }
        this.isUploading = true;
        const uploads = files.map(file => {
            const localId = this._nextFileId++;
            return saveEnrollmentDocument({
                enrollmentRequestId: this._enrollmentRequestId,
                fileName:            file.name,
                documentType:        this.selectedDocumentType,
                fileSize:            file.size,
                contentVersionId:    null
            }).then(() => {
                this.uploadedFiles = [...this.uploadedFiles, {
                    id:           localId,
                    name:         file.name,
                    documentType: this.selectedDocumentType,
                    sizeLabel:    this.formatFileSize(file.size),
                    removeLabel:  'Remove ' + file.name
                }];
                this.dispatchEvent(new CustomEvent('documentuploaded', {
                    detail: { fileName: file.name, documentType: this.selectedDocumentType },
                    bubbles: false
                }));
            }).catch(err => {
                this.validationErrors = [...this.validationErrors,
                    `Failed to upload "${file.name}": ${err.body ? err.body.message : err.message}`
                ];
            });
        });

        Promise.all(uploads).finally(() => { this.isUploading = false; });
    }

    handleRemoveFile(event) {
        const fileId = parseInt(event.currentTarget.dataset.id, 10);
        this.uploadedFiles = this.uploadedFiles.filter(f => f.id !== fileId);
    }

    formatFileSize(bytes) {
        if (bytes < 1024)       { return bytes + ' B'; }
        if (bytes < 1048576)    { return (bytes / 1024).toFixed(1) + ' KB'; }
        return (bytes / 1048576).toFixed(1) + ' MB';
    }

    @api
    validate() {
        if (!this.hasUploadedFiles) {
            this.validationErrors = ['Please upload at least one document before proceeding.'];
            return false;
        }
        this.validationErrors = [];
        return true;
    }
}