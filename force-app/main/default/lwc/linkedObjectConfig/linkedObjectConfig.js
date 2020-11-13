import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';

import getConfigForRecord from '@salesforce/apex/LinkedObjectConfig_Controller.getConfigForRecord';

import OBJECT_BF_CONFIG from '@salesforce/schema/BF_Configuration__c';

export default class LinkedObjectConfig extends LightningElement {
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

    recordTypeId;

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
    };

    @wire(getObjectInfo, { objectApiName: '$sourceObject' })
    sourceObjectInfo;

    @wire(getObjectInfo, { objectApiName: '$linkedObject' })
    linkedObjectInfo;

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
    
    bfConfig;
    bfConfigId;
    
    @wire(getConfigForRecord, { recordId: '$recordId'})
    getWiredConfigForRecord({data, error}) {
        console.log('[linkedObjectConfig.getConfigForRecord] data', data);
        console.log('[linkedObjectConfig.getConfigForRecord] error', error);
        if (data) {
            this.bfConfig = data;   
            this.bfConfigId = data.Id;   
            console.log('[linkedObjectConfig.getConfigForRecord] id', data.Id);
            this.refreshPreview({detail: data.Id});      
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
        return this.bfConfigInfo == undefined ? 'Source Object' : this.bfConfigInfo.fields['Linked_Object__c'].label;
    }

    connectedCallback() {
        console.log('[linkedObjectConfig.connectedCallback] recordId', this.recordId);
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

    refreshPreview(event) {
        if (this.bfConfigId == undefined) { this.bfConfigId = event.detail; }
        console.log('[linkedObjectConfig.refreshPreview] configId', this.bfConfigId);
        console.log('[linkedobjectconfig.refreshPreview] sourceObjectInfo', JSON.parse(JSON.stringify(this.sourceObjectInfo)));
        console.log('[linkedobjectconfig.refreshPreview] linkedObjectInfo', JSON.parse(JSON.stringify(this.linkedObjectInfo)));
        const previewElement = this.template.querySelector("c-linked-object-preview");
        previewElement.refresh(this.bfConfigId);
    }
}