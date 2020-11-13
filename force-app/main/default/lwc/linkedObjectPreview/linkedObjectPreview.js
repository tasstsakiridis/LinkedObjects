import { LightningElement, api, wire } from 'lwc';

import getDataForPreview from '@salesforce/apex/LinkedObjectConfig_Controller.getDataForPreview';
import updateConfigFieldList from '@salesforce/apex/LinkedObjectConfig_Controller.updateConfigFieldList';

const rowActions = [
    { label: 'Create Quick Promotion', name:"quick_promotion" }
];

export default class LinkedObjectPreview extends LightningElement {
    @api 
    recordId;
    
    @api
    bfConfig;

    @api 
    linkedObjectConfigId;

    @api 
    sourceObjectInfo;

    _linkedObjectInfo;

    @api 
    get linkedObjectInfo() {
        return this._linkedObjectInfo;
    }
    set linkedObjectInfo(value) {
        this._linkedObjectInfo = value;
        if (value != undefined && value.data != undefined) {
            const flds = [];
            Object.keys(value.data.fields).forEach(key => {
                const fld = value.data.fields[key];
                flds.push({label:fld.label + ' ['+fld.apiName+']', value: fld.apiName, apiName: fld.apiName, type: fld.dataType});
            });
            flds.sort(function(a, b) {
                let x = a.label.toLowerCase();
                let y = b.label.toLowerCase();
                if (x < y) { return -1; }
                if (x > y) { return 1; }
                return 0; 
            });
            this.availableFields = [...flds];    
        }
    }

    isWorking = false;

    @api 
    refresh(configId) {
        console.log('[linkedObjectPreview.refresh preview]');
        this.linkedObjectConfigId = configId;
        this.getData();
    }
    
    get sourceObjectLabelPlural() {
        return this.sourceObjectInfo == undefined ? 'SOURCE' : this.sourceObjectInfo.data.labelPlural;
    }
    get linkedObjectLabelPlural() {
        return this.linkedObjectInfo == undefined ? 'ROWS' : this.linkedObjectInfo.data.labelPlural;
    }
    
    get counters() {
        if (this.bfConfig == undefined || this.bfConfig.BF_Configuration_Items__r == undefined) {
            return [];
        } else {
            console.log('[linkedObjectPreview.counters] this.bfConfig', JSON.parse(JSON.stringify(this.bfConfig)));
            //const c = this.bfConfig.BF_Configuration_Items__r.filter(bfci => bfci.Is_Counter__c == true);
            //console.log('[linkedObjectPreview.counters] counters', JSON.parse(JSON.stringify(c)));
            return this.bfConfig.BF_Configuration_Items__r.filter(bfci => bfci.Is_Counter__c == true);
        }
    }

    selectedFields = [];
    availableFields = [];
    originalSelectedFields = [];
    selectedRows = [];
    previewField1;
    previewField2;

    error;
    data;
    columns;
    numberOfSourceObjectRows;
    numberOfLinkedObjectRows
    getData() {
        this.isWorking = true;
        console.log('[linkedObjectPreview.getData] config id', this.linkedObjectConfigId);
        getDataForPreview({configId: this.linkedObjectConfigId})
        .then(result => {
            console.log('[linkedObjectPreview.getData] result', result);
            const fields = [];
            this.error = undefined;            
            const newColumns = result.columns;
            newColumns.forEach(c => {
                if (c.fieldName == 'Name') {
                    c.actions = [{label: 'Select fields', checked: true, name: 'selectFields', iconName: 'utility:list'}];
                }

                fields.push(c.fieldName);
            });  
            newColumns.push({ type: 'action', typeAttributes: { rowActions: rowActions }});
            this.columns = [...newColumns];
            this.selectedFields = [...fields];  
            this.previewField1 = result.previewField1;
            this.previewField2 = result.previewField2;    
            this.data = result.linkedObjectRows;
            this.numberOfSourceObjectRows = result.sourceObjectRowCount;
            this.numberOfLinkedObjectRows = result.linkedObjectRowCount;
            this.isWorking = false;
        })
        .catch(error => {
            console.log('[linkedObjectPreview.getData] error', error);
            this.data = undefined;
            this.error = error;
            this.isWorking = false;
        });
    }

    selectFieldsToDisplay(event) {
        try {
            console.log('[linkedObjectPreview.selectFields]');
            this.originalSelectedFields = [...this.selectedFields];
            this.template.querySelector('.field-selector').show();
        }catch(ex) {
            console.log('[linkedObjectPreview.selectFields] exception', ex);
        }
    }
    closeModal() {
        this.template.querySelector('.field-selector').hide();
        this.selectedFields = [...this.originalSelectedFields];
    }
    handleFieldsChange(event) {
        this.selectedFields = event.detail.value;
    }
    applyFieldSelections() {
        const newColumns = [];
        this.selectedFields.forEach(fld => {
            const fdsr = this.linkedObjectInfo.data.fields[fld];
            if (fdsr) {
                newColumns.push({
                    'label': fdsr.label,
                    'fieldName': fdsr.apiName,
                    'type': fdsr.type,
                    'sortable': true,
                    'hideDefaultActions': true
                });    
            }
        });
        newColumns.push({ type: 'action', typeAttributes: { rowActions: rowActions }});
        this.columns = [...newColumns];
        this.template.querySelector('.field-selector').hide();
        this.isWorking = true;
        console.log('[linkedObjectPreview.applyFieldSelections] columns', this.columns);
        if (this.previewField1 && this.previewField1 != '' && this.selectedFields.indexOf(this.previewField1) < 0) {
            this.previewField1 = '';
        }
        if (this.previewField2 && this.previewField2 != '' && this.selectedFields.indexOf(this.previewField2) < 0) {
            this.previewField2 = '';
        }
        updateConfigFieldList({configId: this.linkedObjectConfigId, 
                                objectName: this.linkedObjectInfo.data.apiName, 
                                fieldList: this.selectedFields,
                                previewField1: this.previewField1,
                                previewField2: this.previewField2})
        .then(result => {
            console.log('[linkedObjectPreview.updateConfigFieldList] result', result);
            this.getData();
        })
        .catch(error => {
            console.log('[linkedObjectPreview.updateConfigFieldList] error', error);
            this.error = error;
            this.isWorking = false;
        });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        console.log('[rowAction] actionName', actionName);
        console.log('[rowAction] row', row);
    }
    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
        console.log('selectedRows', this.selectedRows);
    }

    updatePreviewField(event) {
        console.log('[linkedObjectPreview.updatePreviewField] detail', JSON.parse(JSON.stringify(event.detail)));
        if (event.detail.index == '1') {
            this.previewField1 = event.detail.fieldName;
        } else {
            this.previewField2 = event.detail.fieldName;
        }
        updateConfigFieldList({configId: this.linkedObjectConfigId, 
                                objectName: this.linkedObjectInfo.data.apiName,
                                fieldList: this.selectedFields,
                                previewField1: this.previewField1, 
                                previewField2: this.previewField2})
        .then(result => {
            console.log('[updatePreviewFields] result', result);
        })
        .catch(error => {
            this.error = error;
            console.log('[linkedObjectPreview.updatePreviewField] error', error);
        })

    }
}