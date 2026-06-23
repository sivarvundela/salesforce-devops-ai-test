import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getHierarchy from '@salesforce/apex/AccountHierarchyController.getHierarchy';

const COLUMNS = [
    {
        type: 'text',
        fieldName: 'name',
        label: 'Hierarchy Member Name',
        initialWidth: 320,
    },
    {
        type: 'text',
        fieldName: 'type',
        label: 'Type',
        initialWidth: 120,
        cellAttributes: {
            class: { fieldName: 'typeClass' }
        }
    },
    {
        type: 'text',
        fieldName: 'details',
        label: 'Details / Information',
    },
    {
        type: 'button',
        label: 'Actions',
        initialWidth: 110,
        typeAttributes: {
            label: 'View',
            name: 'view_record',
            title: 'Navigate to Record detail page',
            variant: 'border-filled',
            iconName: 'utility:forward'
        }
    }
];

export default class AccountHierarchyViewer extends NavigationMixin(LightningElement) {
    @api recordId;
    @track gridData = [];
    @track isLoading = true;
    @track error;

    columns = COLUMNS;
    wiredHierarchyResult;

    @wire(getHierarchy, { recordId: '$recordId' })
    wiredHierarchy(result) {
        this.wiredHierarchyResult = result;
        const { data, error } = result;
        this.isLoading = true;
        if (data) {
            this.gridData = this.transformData(data);
            this.error = undefined;
            this.isLoading = false;
        } else if (error) {
            this.error = error.body?.message ?? 'An unexpected error occurred while loading the Account Hierarchy.';
            this.gridData = [];
            this.isLoading = false;
        }
    }

    transformData(nodes) {
        return nodes.map(node => {
            let typeClass = 'slds-text-title_bold ';
            if (node.type === 'Account') {
                typeClass += 'slds-text-color_success';
            } else if (node.type === 'Contact') {
                typeClass += 'slds-text-color_weak';
            } else if (node.type === 'Address') {
                typeClass += 'slds-text-color_error';
            }

            let transformedNode = {
                id: node.id,
                name: node.name,
                type: node.type,
                details: node.details,
                typeClass: typeClass
            };

            if (node.children && node.children.length > 0) {
                transformedNode._children = this.transformData(node.children);
            }

            return transformedNode;
        });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
        // Standard navigations only valid for real SF IDs (exclude synthetic billing/shipping Ids)
        if (actionName === 'view_record') {
            const cleanId = row.id.split('_')[0];
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: cleanId,
                    actionName: 'view'
                }
            });
        }
    }

    handleExpandAll() {
        const grid = this.template.querySelector('lightning-tree-grid');
        if (grid) {
            grid.expandAll();
        }
    }

    handleCollapseAll() {
        const grid = this.template.querySelector('lightning-tree-grid');
        if (grid) {
            grid.collapseAll();
        }
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredHierarchyResult)
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error refreshing Hierarchy',
                        message: error.body?.message ?? 'Unknown refresh error.',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}