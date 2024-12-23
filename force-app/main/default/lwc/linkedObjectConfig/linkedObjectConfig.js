import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { refreshApex } from "@salesforce/apex";

import getConfigForRecord from '@salesforce/apex/LinkedObjectConfig_Controller.getConfigForRecord';
import createConfigForRecord from '@salesforce/apex/LinkedObjectConfig_Controller.createConfigForRecord';
import getRecordData from '@salesforce/apex/LinkedObjectConfig_Controller.getRecordData';
import saveItemConfiguration from '@salesforce/apex/LinkedObjectConfig_Controller.saveItemConfiguration';
import getUserDetail from '@salesforce/apex/LinkedObjectConfig_Controller.getUserDetail';
import deleteItem from '@salesforce/apex/LinkedObjectConfig_Controller.deleteItem';
import getFieldsetDetails from '@salesforce/apex/LinkedObjectConfig_Controller.getFieldsetDetails';

import OBJECT_BF_CONFIG from '@salesforce/schema/BF_Configuration__c';

export default class LinkedObjectConfig extends LightningElement {
    labels = {
        actions: { label: 'Actions' },
        counters: { label: 'Counters' },
        filters: { label: 'Filters' }
    };

    @api 
    recordId;

    @api 
    marketId;

    @api 
    marketName;

    @api 
    sourceObject;

    @api 
    linkedObject;

    @track 
    sourceObjectInfo;

    @track 
    sourceObjectOptions;

    @track 
    linkedObjectInfo;

    @track
    linkedObjectConfigInfo;

    @track 
    linkedObjectOptions;

    canEditFilters = true;

    @track 
    bfConfigInfo;

    @track 
    isWorking = false;

    recordTypeId;

    queuedActions = 4;

    /*
    @wire(getObjectInfo, { objectApiName: OBJECT_BF_CONFIG })
    getBFConfigInfo({ data, error }) {
        console.log('data', data);
        console.log('recordId', this.recordId);
        if (data) {
            this.error = undefined;
            this.bfConfigInfo = data;
            
            if (data.recordTypeInfos) {
                Object.keys(data.recordTypeInfos).forEach(rt => {
                    if (data.recordTypeInfos[rt].name == 'Linked Objects') {
                        this.recordTypeId = data.recordTypeInfos[rt].recordTypeId;
                    }
                });
            }

            console.log('recordTypeId', this.recordTypeId);
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }

        this.queuedActions--;
        if (queuedActions <= 0) {
            this.isWorking = false;
        }

    };
    */
    sourceObjectInfo;
    sourceObjectFields;
    
    @wire(getObjectInfo, { objectApiName: '$sourceObject' })
    getSourceObjectInfo({error, data}) {
        console.log('[getSourceObjectInfo] data', data);
        if (data) {
            this.error = undefined;
            this.sourceObjectInfo = data;      
        } else if (error) {
            this.error = error;
            if (error.status == 400) {  // INVALID_TYPE - Object is not supported to give metadata describe info
                this.sourceObjectInfo = {
                    data : {
                        apiName: this.sourceObject,
                        label: this.sourceObject,
                        labelPlural: this.sourceObject,
                        fields: {
                            Id: { apiName: 'Id', label: 'Record Id' },
                            Name: { apiName: 'Name', label: 'Name' }
                        }
                    }
                };
            } else {
                this.sourceObjectInfo = undefined;
            }
        }

    };
    
    linkedObjectInfo;
    linkedObjectFields;
    
    @wire(getObjectInfo, { objectApiName: '$linkedObject' })
    getLinkedObjectInfo({error, data}) {
        console.log('[getLinkedObjectInfo] data', data);
        if (data) {
            this.error = undefined;
            this.linkedObjectInfo = data;
        } else if (error) {
            this.error = error;
            if (error.status == 400) {  // INVALID_TYPE - Object is not supported to give metadata describe info
                this.linkedObjectInfo = {
                    apiName: this.linkedObject,
                    label: this.linkedObject,
                    labelPlural: this.linkedObject,
                    fields: {
                        Id: { apiName: 'Id', label: 'Record Id', dataType: 'String' },
                        Name: { apiName: 'Name', label: 'Name', dataType: 'String' }
                    }
                };
            } else {
                this.linkedObjectInfo = undefined;
            }
        }
    };
    
    getAvailableFields() {
        getFieldsetDetails({
            sourceObject: this.sourceObject,
            sourceObjectFieldsetName: this.bfConfig.SourceObject_Fieldset__c,
            linkedObject: this.linkedObject,
            linkedObjectFieldsetName: this.bfConfig.LinkedObject_Fieldset__c 
        }).then(result => {
            this.error = undefined;
            try {
                console.log('[getFieldsetDetails] result', result);
            if (result.sourceObjectFields == undefined || result.sourceObjectFields.length == 0) {
                let sourceflds = this.sourceObjectInfo == undefined ? [] : Object.values(this.sourceObjectInfo.fields).map(f => {
                    return {
                        type: f.dataType,
                        apiName: f.apiName,
                        label: f.label,
                        value: f.apiName
                    }
                });
                this.sourceObjectFields = sourceflds.slice(0, 10);
            } else {
                this.sourceObjectFields = result.sourceObjectFields;
            }
            if (result.linkedObjectFields == undefined || result.linkedObjectFields.length == 0) {
                this.linkedObjectFields = this.linkedObjectInfo == undefined ? [] : Object.values(this.linkedObjectInfo.fields).map(f => {
                    return {
                        type: f.dataType,
                        apiName: f.apiName,
                        label: `${f.label} [${f.apiName}]`,
                        value: f.apiName
                    }
                });
            } else {
                this.linkedObjectFields = result.linkedObjectFields;            
            }
            } catch(ex) {
                console.log('[getAvailableFields] exception', ex);
                this.sourceObjectFields = [];
                this.linkedObjectFields = [];
            }
        }).catch(error => {
            console.log('[linkedObjectConfig.getAvailableFields] error', error);
            this.error = error;        
            this.sourceObjectFields = undefined;
            this.linkedObjectFields = undefined;
        });
    }
    /*
    picklistValuesMap;
    @wire(getPicklistValuesByRecordType, { objectApiName: OBJECT_BF_CONFIG , recordTypeId: '$recordTypeId' })
    wiredPicklistValues({ error, data }) {
        console.log('[getPicklistValues] recordtypeid', this.recordTypeId);
        console.log('[getPicklistValues] data', data);
        console.log('[getPicklistValues] error', error);
        if (data) {
            this.error = undefined;
            this.picklistValuesMap = data.picklistFieldValues;
            this.setFieldOptions(data.picklistFieldValues);            
        } else if (error) {
            this.error = error;
            this.picklistValuesMap = undefined;
        }
    }
    */

    @track 
    filters;

    @track 
    actions;

    @track 
    counters;

    @track
    marketFilters;

    @track
    marketActions;

    @track
    marketCounters;

    bfConfig;
    bfConfigId;
    theRecord;
    theRecordType;
    hasConfig = false;
    
    userDetails;
    canCreateFilters = false;
    isAdmin = false;
    @wire(getUserDetail)
    getWiredUsedDetail({data, error}) {
        if (data) {
            this.userDetails = data.user;
            this.isAdmin = data.isAdmin;
            this.canCreateFilters = data.canCreateFilters || data.isAdmin;
        } else if (error) {
            this.error = error;
            this.userDetails = undefined;
            this.canCreateFilters = false;
            this.isAdmin = false;
        }
    }
    
    @wire(getConfigForRecord, { recordId: '$recordId', type: 'Linked Objects'})
    getWiredConfigForRecord({data, error}) {
        console.log('[getConfigForRecord] data', data);
        if (data) {
            this.hasConfig = true;
            this.bfConfig = data.config;   
            if (data.config != undefined) {
                this.bfConfigId = data.config.Id;   
                this.sourceObject = data.config.Source_Object__c;
                this.linkedObject = data.config.Linked_Object__c;  
                if (data.theRecord_SObjectType != 'BF_Configuration__c') {
                    this.refreshPreview({detail: data.config.Id});
                }

                this.getAvailableFields();
            }

            this.theRecord_SObjectType = data.theRecord_SObjectType;
            this.filters = data.filters;
            this.marketFilters = data.marketFilters;
            this.counters = data.counters;
            this.marketCounters = data.marketCounters;
            this.actions = data.actions;
            this.marketActions = data.marketActions;
            if (data.theRecord_SObjectType != 'BF_Configuration__c') {
                this.getRecord(data.config == undefined);
            }
        } else if (error) {
            this.error = error;
            this.bfConfig = undefined;
            this.bfConfigId = undefined;
        }

    }
    

    get objectsSelected() {
        return this.sourceObject != undefined && this.linkedObject != undefined;
    }
    get sourceObjectLabel() {
        return this.bfConfigInfo == undefined ? 'Source Object' : this.bfConfigInfo.fields['Source_Object__c'].label;
    }
    get linkedObjectLabel() {
        return this.bfConfigInfo == undefined ? 'Linked Object' : this.bfConfigInfo.fields['Linked_Object__c'].label;
    }

    hasRefreshed = false;
    /*
    connectedCallback() {
        console.log('[linkedObjectConfig.connectedCallback] recordId', this.recordId);
        
    }
    renderedCallback() {
        console.log('[linkedObjectConfig.renderedCallback]');
    }
    */
    /*
    getConfig() {
        getConfigForRecord({
            recordId: this.recordId,
            sourceObject: this.sourceObject,
            linkedObject: this.linkedObject
        })
        .then(result => {
            console.log('[linkedObjectConfig.getConfigForRecord] result',JSON.parse(JSON.stringify(result)));
            this.bfConfig = result.config;   
            if (result.config == undefined) {
                this.getRecord(true);
            } else {
                this.bfConfigId = result.Id;   
                console.log('[linkedObjectConfig.getConfigForRecord] id', result.Id);
                this.refreshPreview({detail: result.Id});          
            }
        })
        .catch(error => {
            console.log('[linkedObjectConfig.getConfigForRecord] error', error);
            this.error = error;
            this.bfConfig = undefined;
            this.bfConfigId = undefined;
        });
    }
    */

    createConfig() {
        createConfigForRecord({
            recordId: this.recordId,
            sourceObject: this.sourceObject,
            linkedObject: this.linkedObject,
            recordName: this.theRecord.Name,
            marketName: this.theRecord.Market__c == undefined ? '' : this.theRecord.Market__c
        })
        .then(result => {
            this.bfConfig = result.config;   
            this.bfConfigId = result.config.Id;   
            this.marketFilters = [...result.marketFilters];
            this.marketCounters = [...result.marketCounters];
            this.marketActions = [...result.marketActions];
            this.actions = [...result.actions];
            this.filters = [...result.filters];
            this.counters = [...result.counters];
            this.getAvailableFields();
            this.refreshPreview({detail: result.config.Id});          
        })
        .catch(error => {
            console.log('[linkedObjectConfig.createConfig] error', error);
            this.error = error;
            this.bfConfig = undefined;
            this.bfConfigId = undefined;
        });
    }
    getRecord(createConfig) {
        getRecordData({recordId: this.recordId})
        .then(result => {
            this.theRecord = result.theRecord;
            this.theRecordType = result.theRecordType;
            if (createConfig) {
                this.createConfig();
            }
        })
        .catch(error => {
            console.log('[linkedObjectConfig.getRecord] error', error);
            this.error = error;
        });
    }

    handleSourceObjectChange(event) {
        this.sourceObject = event.detail.value;
    }
    handleLinkedObjectChange(event) {
        this.linkedObject = event.detail.value;
    }

    setFieldOptions(picklistValues) {
        Object.keys(picklistValues).forEach(picklist => {            
            if (picklist === 'Source_Object__c') {
                this.sourceObjectOptions = this.setFieldOptionsForField(picklistValues, picklist);                
            }
            if (picklist === 'Linked_Object__c') {
                this.linkedObjectOptions = this.setFieldOptionsForField(picklistValues, picklist);
            }
        });

    }
    
    setFieldOptionsForField(picklistValues, picklist) {        
        return picklistValues[picklist].values.map(item => ({
            label: item.label, value: item.value
        }));
    }

    addExistingItem(event) {
        const item = {...event.detail.item};
        item.index = event.detail.index;
        item.isEditing = false;

        switch (event.detail.itemType) {
            case 'Action':
                const actions = [...this.actions];
                actions.push(item);
                this.actions = [...actions];
                break;

            case 'Filter':
                const filters = [...this.filters];
                filters.push(item);
                this.filters = [...filters];
                break;

            case 'Counter':
                const counters = [...this.counters];
                counters.push(item);
                this.counters = [...counters];
                break;
        }

    }
    addNewItem(event) {
        try {
            const item = {
                id: '',
                itemType: event.detail.itemType,
                index: event.detail.index,
                objectName: this.sourceObject,
                fieldName: '',
                fieldValue: '',
                operator: 'equals',
                actionLabel: '',
                actionType: 'apex',
                actionClassName: '',
                actionMethodName: '',
                actionFlowName: '',
                objectToCount: '',
                isEditing: true
            };
            
            switch (event.detail.itemType) {
                case 'Action':
                    const actions = [...this.actions];
                    actions.push(item);
                    this.actions = [...actions];
                    break;

                case 'Filter':
                    const filters = [...this.filters];
                    filters.push(item);
                    this.filters = [...filters];
                    break;

                case 'Counter':
                    const counters = [...this.counters];
                    counters.push(item);
                    this.counters = [...counters];
                    break;
            }
            
        }catch(ex) {
            console.log('[linkedObjectConfig.addNewItem] exception', ex);
        }
    }
    updateConfigItem(event) {
        this.isWorking = true;

        saveItemConfiguration({
            configId: this.bfConfig.Id,
            item: event.detail.item
        })
        .then(result => {
            if (result.status == 'SUCCESS') {
                switch (result.item.itemType) {
                    case 'Action':                    
                        const actions = [...this.actions];
                        actions[result.item.index] = result.item;
                        this.actions = [...actions];
                        break;
    
                    case 'Filter':
                        const filters = [...this.filters];
                        filters[result.item.index] = result.item;
                        this.filters = [...filters];
                        this.refreshPreview();
                        break;
    
                    case 'Counter':
                        const counters = [...this.counters];
                        counters[result.item.index] = result.item;
                        this.counters = [...counters];
                        this.refreshPreview();
                        break;
                }    
            } else if (result.status == 'ERROR') {
                this.error = result.message;
            }

            this.isWorking = false;
        })
        .catch(error => {
            console.log('linkedObjectConfig.updateConfigItem] error', error);
            this.isWorking = false;
        });
    }
    deleteConfigItem(event) {
        const item = event.detail.item;
        if (item.id != '') {
            deleteItem({itemId: item.id, itemType: item.itemType, index: item.index})
            .then(result => {
                this.removeItemFromList(result.itemId, result.itemType, result.index);
            })
            .catch(error => {
                console.log('[linkedObjectConfig.deleteConfigItem] error', error);
            });
        } else {
            this.removeItemFromList(item.id, item.itemType, item.index);
        }
    }
    removeItemFromList(itemId, itemType, itemIndex) {
        switch (itemType) {
            case 'Action':                    
                const actions = [...this.actions];
                actions.splice(itemIndex, 1);
                this.actions = [...actions];
                break;

            case 'Filter':
                const filters = [...this.filters];
                filters.splice(itemIndex, 1);
                this.filters = [...filters];
                if (itemId != '') {
                    this.refreshPreview();
                }
                break;

            case 'Counter':
                const counters = [...this.counters];
                counters.splice(itemIndex, 1);
                this.counters = [...counters];
                if (itemId != '') {
                    this.refreshPreview();
                }
                break;
        }   
         
    }
    handleRefreshReady() {
        if (this.theRecord_SObjectType == 'BF_Configuration__c') {
            this.refreshPreview();
        }
    }
    refreshPreview(event) {
        let includeAllData = false;
        if (this.bfConfigId == undefined && event != undefined) { this.bfConfigId = event.detail.configId; }
        try {
            const previewElement = this.template.querySelector("c-linked-object-preview");
            if (previewElement != undefined) {
                previewElement.refresh(this.bfConfigId);
                this.hasRefreshed = true;    
            }
        }catch(ex) {
            console.log('[linkedObjectConfig.refreshPreview] exception', ex);
        }
    }
}