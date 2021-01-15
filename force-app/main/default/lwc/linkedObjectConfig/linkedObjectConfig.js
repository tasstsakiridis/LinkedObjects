import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';

import getConfigForRecord from '@salesforce/apex/LinkedObjectConfig_Controller.getConfigForRecord';
import createConfigForRecord from '@salesforce/apex/LinkedObjectConfig_Controller.createConfigForRecord';
import getRecordData from '@salesforce/apex/LinkedObjectConfig_Controller.getRecordData';
import saveItemConfiguration from '@salesforce/apex/LinkedObjectConfig_Controller.saveItemConfiguration';

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
        console.log('[linkedObjectConfig.getSourceObjectInfo] data',data);
        console.log('[linkedObjectConfig.getSourceObjectInfo] error',error);
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

        if (this.sourceObjectInfo != undefined) {
            const flds = [];
            Object.keys(this.sourceObjectInfo.fields).forEach(key => {
                const fld = this.sourceObjectInfo.fields[key];
                //console.log('[linkedObjectConfig.sourceObjectInfo] fld for ' + key, fld);
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
            this.sourceObjectFields = [...flds];

        }
        console.log('[linkedObjectConfig.getSourceObjectInfo] sourceObjectInfo', this.sourceObjectInfo);
        //console.log('[linkedObjectConfig.getSourceObjectInfo] sourceObjectFields', this.sourceObjectFields);
    };

    linkedObjectInfo;
    linkedObjectFields;
    @wire(getObjectInfo, { objectApiName: '$linkedObject' })
    getLinkedObjectInfo({error, data}) {
        console.log('[linkedObjectConfig.getLinkedObjectInfo] data',data);
        console.log('[linkedObjectConfig.getLinkedObjectInfo] error',error);
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
        if (this.linkedObjectInfo != undefined) {
            const flds = [];
            Object.keys(this.linkedObjectInfo.fields).forEach(key => {
                const fld = this.linkedObjectInfo.fields[key];
                //console.log('[linkedObjectConfig.sourceObjectInfo] fld for ' + key, fld);
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
            this.linkedObjectFields = [...flds];

        }

        console.log('[linkedObjectConfig.getLinkedObjectInfo] linkedObjectInfo', this.linkedObjectInfo);
    };

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

    bfConfig;
    bfConfigId;
    theRecord;
    theRecordType;
    hasConfig = false;
    
    @wire(getConfigForRecord, { recordId: '$recordId', type: 'Linked Objects'})
    getWiredConfigForRecord({data, error}) {
        console.log('[linkedObjectConfig.getConfigForRecord] data', data);
        console.log('[linkedObjectConfig.getConfigForRecord] error', error);
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
            }
            this.theRecord_SObjectType = data.theRecord_SObjectType;
            this.filters = data.filters;
            this.counters = data.counters;
            this.actions = data.actions;
            if (data.theRecord_SObjectType != 'BF_Configuration__c') {
                this.getRecord(data.config == undefined);
            }
            //this.refreshPreview({detail: data.config.Id});      
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
    connectedCallback() {
        console.log('[linkedObjectConfig.connectedCallback] recordId', this.recordId);
        
    }
    renderedCallback() {
        console.log('[linkedObjectConfig.renderedCallback]');
    }

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
        console.log('[linkedObjectConfig.createConfig] theRecord', this.theRecord);
        createConfigForRecord({
            recordId: this.recordId,
            sourceObject: this.sourceObject,
            linkedObject: this.linkedObject,
            recordName: this.theRecord.Name,
            marketName: this.theRecord.Market__c == undefined ? '' : this.theRecord.Market__c
        })
        .then(result => {
            console.log('[linkedObjectConfig.createConfig] result',JSON.parse(JSON.stringify(result)));
            this.bfConfig = result.config;   
            this.bfConfigId = result.config.Id;   
            if (result.filters != undefined) {
                this.filters = result.filters;
            }
            console.log('[linkedObjectConfig.createConfig] id', result.config.Id);
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
            console.log('[linkedObjectConfig.getRecord] result', result);
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
        console.log('[setFieldOptions] picklistValues', picklistValues);
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
        console.log('[setFieldOptionsForField] picklist field', picklist);
        return picklistValues[picklist].values.map(item => ({
            label: item.label, value: item.value
        }));
    }

    addNewItem(event) {
        console.log('[linkedObjectConfig.addNewItem] event.detail',event.detail);        
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
            
            console.log('[linkedObjectConfig.addNewItem] actions', this.actions);
            console.log('[linkedObjectConfig.addNewItem] filters', this.filters);
            console.log('[linkedObjectConfig.addNewItem] counters', this.counters);
            console.log('[linkedObjectConfig.addNewItem] sourceObject', this.sourceObject);
            console.log('[linkedObjectConfig.addNewItem] linkedObject', this.linkedObject);
            
            switch (event.detail.itemType) {
                case 'Action':
                    const actions = [...this.actions];
                    actions.push(item);
                    this.actions = [...actions];
                    console.log('[linkedObjectConfig.addNewItem] updated actions', JSON.parse(JSON.stringify(this.actions)));
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
        console.log('[linkedObjectConfig.updateConfigItem] event.detail',JSON.parse(JSON.stringify(event.detail)));
        this.isWorking = true;

        saveItemConfiguration({
            configId: this.bfConfig.Id,
            item: event.detail.item
        })
        .then(result => {
            console.log('[linkedObjectConfig.updateConfigItem] result', result);
            if (result.status == 'SUCCESS') {
                switch (result.item.itemType) {
                    case 'Action':                    
                        const actions = [...this.actions];
                        actions[result.item.index] = result.item;
                        this.actions = [...actions];
                        console.log('[linkedObjectConfig.updateConfigItem] actions', JSON.parse(JSON.stringify(this.actions)));
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
        console.log('[linkedObjectConfig.deleteConfigItem] event.detail',JSON.parse(JSON.stringify(event.detail)));
    }
    handleRefreshReady() {
        if (this.theRecord_SObjectType == 'BF_Configuration__c') {
            this.refreshPreview();
        }
    }
    refreshPreview(event) {
        console.log('[linkedObjectConfig.refreshPreview] event.detail', event == undefined ? 'undefined' : event.detail);
        console.log('[linkedObjectConfig.refreshPreview] configId', this.bfConfigId);
        console.log('[linkedobjectconfig.refreshPreview] sourceObjectInfo', this.sourceObjectInfo == undefined ? this.sourceObjectInfo : JSON.parse(JSON.stringify(this.sourceObjectInfo)));
        console.log('[linkedobjectconfig.refreshPreview] linkedObjectInfo', this.linkedObjectInfo == undefined ? this.linkedObjectInfo : JSON.parse(JSON.stringify(this.linkedObjectInfo)));
        if (this.bfConfigId == undefined && event != undefined) { this.bfConfigId = event.detail; }
        try {
            const previewElement = this.template.querySelector("c-linked-object-preview");
            console.log('[linkedObjectConfig.refreshPreview] previewElement', previewElement);
            if (previewElement != undefined) {
                previewElement.refresh(this.bfConfigId);
                this.hasRefreshed = true;    
            }
        }catch(ex) {
            console.log('[linkedObjectConfig.refreshPreview] exception', ex);
        }
    }
}