import { LightningElement, api, track } from 'lwc';

export default class LinkedObjectFilter extends LightningElement {
    @api 
    canEditFilter = false;

    @api 
    sourceObject;

    @api 
    sourceObjectInfo;

    @api 
    linkedObject;

    @api 
    linkedObjectInfo;

    @api 
    filterIndex;

    @api 
    filter;

    get isEditing() {
        console.log('[linkedObjectFilter.isEditing] filter', this.filter);
        return this.filter == undefined ? false : this.filter.isEditing;
    }

    get filterFieldLabel() {
        return this.filter == undefined ? '' : this.filter.FieldName__c;
    }
    get filterFieldValue() {
        return this.filter == undefined ? '' : this.filter.FieldValue__c;
    }

    get tileLabel() {
        return this.filter == undefined ? '' : this.filter.Object__c +'.'+this.filter.FieldName__c;
    }
    get operator() {
        let val = '';
        if (this.filter != undefined) {
            switch(this.filter.Operator__c) {
                case 'equals':
                    val = 'matches';
                    break;
                case 'notequal':
                    val = 'does not match';
                    break;
                case '>':
                    val = 'greater than';
                    break;
                case '>=':
                    val = 'greater than or equal to';
                    break;
                case '<':
                    val = 'less than';
                    break;
                case '<=':
                    val = 'less than or equal to';
                    break;
                case 'include':
                    val = 'includes';
                    break;
                case 'notinclude':
                    val = 'does not include';
                    break;
                case 'startswith':
                    val = 'starts with';
                    break;
                case 'endswith':
                    val = 'ends with';
                    break;
                case 'contains':
                    val = 'contains';
                    break;
                default:
                    val = 'matches';
                    break;

            }
        }
        return val;
    }
    get fieldValue() {
        return this.filter == undefined ? '' : this.filter.FieldValue__c;
    }

    closeFilterDialog(event) {
        this.filter.isEditing = false;
    }

    editFilter(event) {
        console.log('[linkedObjectFilter] editFilter');
        this.filter = {...this.filter};
        this.filter.isEditing = true;
        console.log('[linkedObjectFilter.editFilter] filter', this.filter);
    }

    updateFilter(event) {
        try {
            console.log('[linkedObjectFilter.updateFilter] event.detail', JSON.stringify(event.detail));
            console.log('[linkedObjectFilter.updateFilter] this.filter', JSON.stringify(this.filter));
            this.filter = Object.assign({}, this.filter);
            this.filter.Object__c = event.detail.Object__c;
            this.filter.FieldName__c = event.detail.FieldName__c;
            this.filter.FieldValue__c = event.detail.FieldValue__c;
            this.filter.Operator__c = event.detail.Operator__c;
            this.filter.isEditing = false;
            this.filter.Index__c = this.filterIndex;
            console.log('[linkedObjectFilter.updateFilter] this.filter', JSON.stringify(this.filter));

            this.dispatchEvent(new CustomEvent('save', { 
                        detail: { 
                                filter: this.filter, 
                                index: this.filterIndex 
                            }
                        }));
        }catch(ex) {
            console.log('[linkedObjectFilter.updateFilter] exception', ex);
        }
    }

    removeFilter(event) {
        this.dispatchEvent(new CustomEvent('remove', {detail: this.filterIndex}));    
        
    }

}