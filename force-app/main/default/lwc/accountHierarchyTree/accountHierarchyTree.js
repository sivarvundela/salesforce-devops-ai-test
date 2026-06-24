import { LightningElement, api, track, wire } from 'lwc';
import getAccountHierarchy from '@salesforce/apex/AccountHierarchyService.getAccountHierarchy';

export default class AccountHierarchyTree extends LightningElement {
    @api recordId;
    @track isLoading = false;
    @track error;
    @track accountTree = [];

    connectedCallback() {
        this.loadAccountHierarchy();
    }

    loadAccountHierarchy() {
        this.isLoading = true;
        getAccountHierarchy({ accountId: this.recordId })
            .then(result => {
                this.accountTree = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error.body?.message ?? 'An error occurred while loading account hierarchy';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    toggleNode(event) {
        const accountId = event.target.dataset.id;
        this.toggleAccountNode(accountId);
    }

    toggleAccountNode(accountId) {
        this.updateAccountNode(accountId, (node) => {
            node.isExpanded = !node.isExpanded;
            node.expandIcon = node.isExpanded ? 'utility:chevronup' : 'utility:chevrondown';
            return node;
        });
    }

    updateAccountNode(accountId, updateFunction) {
        const updatedTree = this.accountTree.map(node => {
            if (node.Id === accountId) {
                return updateFunction(node);
            }
            
            if (node.children) {
                const updatedChildren = node.children.map(child => {
                    if (child.Id === accountId) {
                        return updateFunction(child);
                    }
                    return child;
                });
                
                if (updatedChildren.length > 0) {
                    return { ...node, children: updatedChildren };
                }
            }
            
            return node;
        });
        
        this.accountTree = updatedTree;
    }
}