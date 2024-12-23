import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import USER_ID from '@salesforce/user/Id';

import getDataForPreview from '@salesforce/apex/LinkedObjectConfig_Controller.getDataForPreview';
import updateConfigFieldList from '@salesforce/apex/LinkedObjectConfig_Controller.updateConfigFieldList';
import callAction from '@salesforce/apex/BF_CALL_CUSTOM_ACTION.callAction';

import LABEL_ALL_DATA from '@salesforce/label/c.All_Data';
import LABEL_ERROR from '@salesforce/label/c.Error';
import LABEL_MY_DATA from '@salesforce/label/c.My_Data';
import LABEL_NOTHING_TO_SHOW from '@salesforce/label/c.Nothing_To_Show';
import LABEL_SUCCESS from '@salesforce/label/c.Success';

const ROW_ACTIONS = [
    { label: 'Create Quick Promotion', name:"quick_promotion" }
];

export default class LinkedObjectPreview extends LightningElement {
    labels = {
        nothingToShow: { label: LABEL_NOTHING_TO_SHOW }
    }

    @api 
    recordId;
    
    @api
    bfConfig;

    @api 
    recordType;

    @api 
    isAdmin = false;

    _counters;
    @api 
    get counters() {
        return this._counters;
    }
    set counters(value) {
        this._counters = value;
    }

    _actions;
    @api 
    get actions() {
        return this._actions;
    }
    set actions(value) {
        this._actions = value;
        console.log('[linkedObjectPreview.actions] value', value);
        if (value != undefined && value.length > 0) {
            let selectionActions = [];
            let nsActions = [];
            value.forEach(a => {
                if (a.requiresSelection == undefined || a.requiresSelection == true) {
                    selectionActions.push({ label: a.actionLabel, name: a.id, value: a.id });
                } else {
                    nsActions.push({ label: a.actionLabel, name: a.id, value: a.id });
                }
            });
            this.availableActions = [...selectionActions];
            this.noSelectionActions = [...nsActions];
            console.log('[linkedObjectPreview.actions] availableActions', this.availableActions);
            console.log('[linkedObjectPreview.actions] noSelectionActions', this.noSelectionActions);
            if (this.linkedObjectColumns != undefined && this.linkedObjectColumns.length > 0) {
                const actionsColumn = this.linkedObjectColumns.find(lc => lc.type == 'action');
                if (actionsColumn == undefined) {
                    const updatedColumns = this.linkedObjectColumns;
                    updatedColumns.push({type: 'action', typeAttributes: { rowAction: this.availableActions }});
                } else {
                    actionsColumn.typeAttributes.rowAction = this.availableActions;
                }
            }
        }
    }

    @api 
    linkedObjectConfigId;

    @api 
    sourceObject;

    _sourceObjectInfo;
    @api 
    get sourceObjectInfo() {
        return this._sourceObjectInfo;
    }
    set sourceObjectInfo(value) {
        this._sourceObjectInfo = value;
        
        const sourceflds = [];
        if (value != undefined && value.fields != undefined) {
            Object.keys(value.fields).forEach(key => {
                const fld = value.fields[key];
                if (fld) {
                    sourceflds.push({label:fld.label + ' ['+fld.apiName+']', value: fld.apiName, apiName: fld.apiName, type: fld.dataType});
                }
            });
    
            sourceflds.sort(function(a, b) {
                let x = a.label.toLowerCase();
                let y = b.label.toLowerCase();
                if (x < y) { return -1; }
                if (x > y) { return 1; }
                return 0; 
            });    
        }
        this.sourceObjectFields = sourceflds;

    }

    @api 
    linkedObject;

    _linkedObjectInfo;
    @api 
    get linkedObjectInfo() {
        return this._linkedObjectInfo;
    }
    set linkedObjectInfo(value) {
        this._linkedObjectInfo = value;
        const flds = [];

        if (value != undefined && value.fields != undefined) {
            this.hasOwnerData = value.fields['OwnerId'] != undefined;

            Object.keys(value.fields).forEach(key => {
                const fld = value.fields[key];
                if (fld) {
                    flds.push({label:fld.label + ' ['+fld.apiName+']', value: fld.apiName, apiName: fld.apiName, type: fld.dataType});
                }
            });
    
            flds.sort(function(a, b) {
                let x = a.label.toLowerCase();
                let y = b.label.toLowerCase();
                if (x < y) { return -1; }
                if (x > y) { return 1; }
                return 0; 
            });    

            for(var i = 0; i < this.ownerFilterButtons.length; i++) {
                this.ownerFilterButtons[i].label = this.ownerFilterButtons[i].label.replace('%0%', value.labelPlural);
            }
        }
        this.linkedObjectFields = flds;
    }


    /*
    _linkedObjectInfo;
    @api 
    get linkedObjectInfo() {
        return this._linkedObjectInfo;
    }
    set linkedObjectInfo(value) {
        this._linkedObjectInfo = value;
        console.log('[linkedObjectPreview.set linkedObjectInfo] value', value);
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
    */

    isWorking = false;

    @api 
    refresh(configId) {
        this.linkedObjectConfigId = configId;
        this.getData();
    }
    
    connectedCallback() {
        this.dispatchEvent(new CustomEvent('refreshready', { detail: { bfConfigId: this.configId }}));
    }

    get sourceObjectLabelPlural() {
        return this.sourceObjectInfo == undefined ? 'SOURCE' : this.sourceObjectInfo.labelPlural;
    }
    get linkedObjectLabelPlural() {
        return this.linkedObjectInfo == undefined ? 'ROWS' : this.linkedObjectInfo.labelPlural;
    }
    get isBFConfig() {
        return this.recordType == 'BF_Configuration__c';
    }
    get hasData() {
        return (this.sourceObjectData != undefined && this.sourceObjectData.length > 0) || (this.linkedObjectData != undefined && this.linkedObjectData.length > 0);
    }
    

    ownerFilterButtons = [
        { label: LABEL_MY_DATA, value: 'my' },
        { label: LABEL_ALL_DATA, value: 'all' }
    ];

    selectedFields = [];
    availableFields = [];
    originalSelectedFields = [];
    sourceSelectedFields = [];
    linkedSelectedFields = [];
    linkedObjectFields = [];
    sourceObjectFields = [];
    selectedRows = [];
    previewField1;
    previewField2;
    selectingSourceFields = false;
    selectingLinkedFields = false;
    selectedOwnerFilter = 'all';
    hasOwnerData = false;

    availableActions = [];
    noSelectionActions = [];
    selectedAction;

    error;
    sourceObjectData;
    linkedObjectData;
    sourceObjectColumns;
    linkedObjectColumns;
    numberOfSourceObjectRows;
    numberOfLinkedObjectRows
    getData() {
        this.isWorking = true;
        getDataForPreview({
            configId: this.linkedObjectConfigId,
            allLinkedData: this.selectedOwnerFilter == 'all',
            userId: USER_ID
        })
        .then(result => {
            const sourceFields = [];
            const linkedFields = [];
            this.error = undefined;            
            if (this.isBFConfig) {
                if (result.sourceObjectColumns != undefined) {
                    const newSourceObjectColumns = result.sourceObjectColumns;
                    newSourceObjectColumns.forEach(c => {
                        if (c.fieldName == 'Name') {
                            c.actions = [{label: 'Select fields', checked: true, name: 'selectFields', iconName: 'utility:list'}];
                        }
                    });      
                    this.sourceObjectColumns = [...newSourceObjectColumns];
                    sourceFields.push(c.fieldName);    
                }
            }

            if (result.linkedObjectColumns != undefined) {
                const newLinkedObjectColumns = result.linkedObjectColumns;
                newLinkedObjectColumns.forEach(c => {
                    if (c.fieldName == 'Name') {
                        c.actions = [{label: 'Select fields', checked: true, name: 'selectFields', iconName: 'utility:list'}];
                    }
    
                    linkedFields.push(c.fieldName);
                });  
                if (this.availableActions != undefined && this.availableActions.length > 0) {
                    newLinkedObjectColumns.push({ type: 'action', typeAttributes: { rowActions: this.availableActions }});
                }
    
                this.linkedObjectColumns = [...newLinkedObjectColumns];    
            }

            this.linkedSelectedFields = [...linkedFields];  
            this.sourceSelectedFields = [...sourceFields];
            this.previewField1 = result.previewField1;
            this.previewField2 = result.previewField2; 
            this.sourceObjectData = result.sourceObjectRows;   
            this.linkedObjectData = result.linkedObjectRows;
            this.numberOfSourceObjectRows = result.sourceObjectRowCount;
            this.numberOfLinkedObjectRows = result.linkedObjectRowCount;
            this.isWorking = false;
        })
        .catch(error => {
            console.log('[linkedObjectPreview.getData] error', error);
            this.linkedObjectData = undefined;
            this.sourceObjectData = undefined;
            this.error = error;
            this.isWorking = false;
        });
    }

    selectSourceObjectFieldsToDisplay(event) {
        try {
            this.selectingSourceFields = true;       
            this.selectingLinkedFields = false;       
            this.availableFields = [...this.sourceObjectFields];
            this.selectedFields = [...this.sourceSelectedFields];
            this.template.querySelector('.field-selector').show();
        }catch(ex) {
            console.log('[linkedObjectPreview.selectFields] exception', ex);
        }
    }
    selectLinkedObjectFieldsToDisplay(event) {
        try {
            this.selectingLinkedFields = true;       
            this.selectingSourceFields = false;       
            this.availableFields = [...this.linkedObjectFields];
            this.selectedFields = [...this.linkedSelectedFields];            
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
        try {
            if (this.selectingSourceFields) {
                this.selectedSourceFields = [...this.selectedFields];
            } else {
                this.selectedLinkedFields = [...this.selectedFields];
            }

            const newColumns = [];
            this.selectedFields.forEach(fld => {
                const fdsr = this.linkedObjectInfo.fields[fld];
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
            newColumns.push({ type: 'action', typeAttributes: { rowActions: ROW_ACTIONS }});
            this.columns = [...newColumns];
            this.template.querySelector('.field-selector').hide();
            this.isWorking = true;
            if (this.previewField1 && this.previewField1 != '' && this.selectedFields.indexOf(this.previewField1) < 0) {
                this.previewField1 = '';
            }
            if (this.previewField2 && this.previewField2 != '' && this.selectedFields.indexOf(this.previewField2) < 0) {
                this.previewField2 = '';
            }
            updateConfigFieldList({configId: this.linkedObjectConfigId, 
                                    objectName: this.selectingLinkedFields ? this.linkedObjectInfo.apiName : this.sourceObjectInfo.apiName, 
                                    fieldList: this.selectedFields,
                                    previewField1: this.previewField1,
                                    previewField2: this.previewField2})
            .then(result => {
                this.getData();
            })
            .catch(error => {
                console.log('[linkedObjectPreview.updateConfigFieldList] error', error);
                this.error = error;
                this.isWorking = false;
            });
        }catch(ex) {
            console.log('[linkedObjectPreview.updateConfigFieldList] exception', ex);            
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
    }
    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    updatePreviewField(event) {
        try {
            if (event.detail.index == '1') {
                this.previewField1 = event.detail.fieldName;
            } else {
                this.previewField2 = event.detail.fieldName;
            }
            updateConfigFieldList({configId: this.linkedObjectConfigId, 
                                    objectName: this.linkedObjectInfo.apiName,
                                    fieldList: this.selectedFields,
                                    previewField1: this.previewField1, 
                                    previewField2: this.previewField2})
            .then(result => {
                console.log('[updatePreviewFields] result', result);
            })
            .catch(error => {
                this.error = error;
                console.log('[linkedObjectPreview.updatePreviewField] error', error);
            });
        }catch(ex) {
            console.log('[linkedObjectPreview.updatePreviewField] exception', ex);
        }

    }

    handleActionClick(event) {
        this.isWorking = true;

        this.selectedAction = this.actions.find(a => a.actionLabel == event.target.label);

        const linkedRecordIds = this.selectedRows.map(r => r.Id);
        const inputs = {
            'sourceObjectRecordId': this.recordId,
            'linkedRecordIds' : linkedRecordIds
        };
        callAction({
            className: this.selectedAction.actionClassName,
            actionName: this.selectedAction.actionMethodName,
            actionType: this.selectedAction.actionType,
            bfConfigId: this.bfConfigId,
            inputs: JSON.stringify(inputs)
        }).then(result => {
            this.setSelectedRows = [];
            this.isWorking = false;

            const evt = new ShowToastEvent({
                title: LABEL_SUCCESS,
                message: result.message,
                variant: 'success'
            });
            this.dispatchEvent(evt);
        }).catch(error => {
            this.isWorking = false;
            console.log('[linkedObjectPreview.callAction] error', error);
            const evt = new ShowToastEvent({
                title: LABEL_ERROR,
                message: result.message,
                variant: 'error'
            });
            this.dispatchEvent(evt);

        });
    }

    handleOwnerFilterButtonChange(event) {
        this.selectedOwnerFilter = event.detail.value;        

        this.getData();
        this.dispatchEvent(new CustomEvent('refreshready', {
            configId: this.configId,
            includeAllData: this.includeAllData == 'all'
        }));
    }
}