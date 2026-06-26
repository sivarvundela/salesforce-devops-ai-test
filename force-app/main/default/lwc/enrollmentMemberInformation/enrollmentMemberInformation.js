import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import MEMBER_INFO_LABEL      from '@salesforce/label/c.UI_Member_Information_Section';
import CONTACT_INFO_LABEL     from '@salesforce/label/c.UI_Contact_Information_Section';
import ADDRESS_INFO_LABEL     from '@salesforce/label/c.UI_Address_Information_Section';
import COVERAGE_INFO_LABEL    from '@salesforce/label/c.UI_Coverage_Information_Section';

const REQUIRED_FIELDS = [
    'FirstName__c', 'LastName__c', 'DateOfBirth__c', 'Gender__c',
    'Email__c', 'PhoneNumber__c',
    'AddressLine1__c', 'City__c', 'State__c', 'ZIPCode__c',
    'PlanType__c', 'CoverageLevel__c', 'EffectiveDate__c'
];

export default class EnrollmentMemberInformation extends LightningElement {
    @api get formData() { return this._formData; }
    set formData(val) { this._formData = val ? { ...val } : {}; }

    _formData = {};
    hasErrors = false;

    label = {
        memberInfo:   MEMBER_INFO_LABEL,
        contactInfo:  CONTACT_INFO_LABEL,
        addressInfo:  ADDRESS_INFO_LABEL,
        coverageInfo: COVERAGE_INFO_LABEL
    };

    get memberInfoLabel()   { return this.label.memberInfo; }
    get contactInfoLabel()  { return this.label.contactInfo; }
    get addressInfoLabel()  { return this.label.addressInfo; }
    get coverageInfoLabel() { return this.label.coverageInfo; }

    get genderOptions() {
        return [
            { label: 'Male',   value: 'Male' },
            { label: 'Female', value: 'Female' },
            { label: 'Other',  value: 'Other' }
        ];
    }

    get maritalStatusOptions() {
        return [
            { label: 'Single',   value: 'Single' },
            { label: 'Married',  value: 'Married' },
            { label: 'Divorced', value: 'Divorced' },
            { label: 'Widowed',  value: 'Widowed' }
        ];
    }

    get languageOptions() {
        return [
            { label: 'English', value: 'English' },
            { label: 'Spanish', value: 'Spanish' },
            { label: 'French',  value: 'French' }
        ];
    }

    get stateOptions() {
        return [
            { label: 'Alabama', value: 'AL' },
            { label: 'Alaska', value: 'AK' },
            { label: 'Arizona', value: 'AZ' },
            { label: 'Arkansas', value: 'AR' },
            { label: 'California', value: 'CA' },
            { label: 'Colorado', value: 'CO' },
            { label: 'Connecticut', value: 'CT' },
            { label: 'Delaware', value: 'DE' },
            { label: 'Florida', value: 'FL' },
            { label: 'Georgia', value: 'GA' },
            { label: 'Hawaii', value: 'HI' },
            { label: 'Idaho', value: 'ID' },
            { label: 'Illinois', value: 'IL' },
            { label: 'Indiana', value: 'IN' },
            { label: 'Iowa', value: 'IA' },
            { label: 'Kansas', value: 'KS' },
            { label: 'Kentucky', value: 'KY' },
            { label: 'Louisiana', value: 'LA' },
            { label: 'Maine', value: 'ME' },
            { label: 'Maryland', value: 'MD' },
            { label: 'Massachusetts', value: 'MA' },
            { label: 'Michigan', value: 'MI' },
            { label: 'Minnesota', value: 'MN' },
            { label: 'Mississippi', value: 'MS' },
            { label: 'Missouri', value: 'MO' },
            { label: 'Montana', value: 'MT' },
            { label: 'Nebraska', value: 'NE' },
            { label: 'Nevada', value: 'NV' },
            { label: 'New Hampshire', value: 'NH' },
            { label: 'New Jersey', value: 'NJ' },
            { label: 'New Mexico', value: 'NM' },
            { label: 'New York', value: 'NY' },
            { label: 'North Carolina', value: 'NC' },
            { label: 'North Dakota', value: 'ND' },
            { label: 'Ohio', value: 'OH' },
            { label: 'Oklahoma', value: 'OK' },
            { label: 'Oregon', value: 'OR' },
            { label: 'Pennsylvania', value: 'PA' },
            { label: 'Rhode Island', value: 'RI' },
            { label: 'South Carolina', value: 'SC' },
            { label: 'South Dakota', value: 'SD' },
            { label: 'Tennessee', value: 'TN' },
            { label: 'Texas', value: 'TX' },
            { label: 'Utah', value: 'UT' },
            { label: 'Vermont', value: 'VT' },
            { label: 'Virginia', value: 'VA' },
            { label: 'Washington', value: 'WA' },
            { label: 'West Virginia', value: 'WV' },
            { label: 'Wisconsin', value: 'WI' },
            { label: 'Wyoming', value: 'WY' }
        ];
    }

    get countyOptions() {
        return [
            { label: '-- None --', value: '' }
        ];
    }

    get planTypeOptions() {
        return [
            { label: 'HMO',  value: 'HMO' },
            { label: 'PPO',  value: 'PPO' },
            { label: 'EPO',  value: 'EPO' },
            { label: 'POS',  value: 'POS' }
        ];
    }

    get coverageLevelOptions() {
        return [
            { label: 'Individual',           value: 'Individual' },
            { label: 'Individual + Spouse',  value: 'Individual + Spouse' },
            { label: 'Individual + Children', value: 'Individual + Children' },
            { label: 'Family',               value: 'Family' }
        ];
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        this._formData = { ...this._formData, [field]: value };
        this.dispatchEvent(new CustomEvent('formchange', {
            detail: { field, value, formData: { ...this._formData } },
            bubbles: false
        }));
    }

    @api
    validate() {
        const inputsValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((acc, el) => { return el.reportValidity() && acc; }, true);

        const missingRequired = REQUIRED_FIELDS.some(
            f => !this._formData[f] || String(this._formData[f]).trim() === ''
        );

        this.hasErrors = !inputsValid || missingRequired;
        return !this.hasErrors;
    }
}