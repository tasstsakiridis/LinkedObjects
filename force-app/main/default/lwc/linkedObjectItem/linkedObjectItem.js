import { LightningElement, api, track } from 'lwc';

import LABEL_ACTION_TYPE from '@salesforce/label/c.Action_Type';
import LABEL_CLASS_NAME from '@salesforce/label/c.Class_Name';
import LABEL_METHOD_NAME from '@salesforce/label/c.Method_Name';
import LABEL_FIELD from '@salesforce/label/c.Field';
import LABEL_FIELD_TYPE from '@salesforce/label/c.Field_Type';
import LABEL_FLOW_NAME from '@salesforce/label/c.Flow_Name';
import LABEL_LABEL from '@salesforce/label/c.Label';
import LABEL_NEW from '@salesforce/label/c.New';
import LABEL_NEWFILTER from '@salesforce/label/c.NewFilter';
import LABEL_OBJECT_TO_COUNT from '@salesforce/label/c.Object_to_Count';
import LABEL_OPERATOR from '@salesforce/label/c.Operator';
import LABEL_SELECT from '@salesforce/label/c.Select';
import LABEL_VALUE from '@salesforce/label/c.Value';

const operators = [
    { label: 'equals', value: "equals", type: 'text,numeric,boolean,date' },
    { label: 'does not equal', value: 'notequals', type: 'text,numeric,date' },
    { label: 'greater than', value: ">", type: 'numeric,date' },
    { label: 'greater than or equal to', value: ">=", type: 'numeric,date' },
    { label: 'less than', value: "<", type: 'numeric,date' },
    { label: 'less than or equal to', value: '<=', type: 'numeric,date' },
    { label: 'includes', value: 'includes', type: 'text,list' },
    { label: 'not include', value: 'notinclude', type: 'text,list' },
    { label: 'starts with', value: 'starts with', type: 'text' },
    { label: 'ends with', value: 'ends with', type: 'text' },
    { label: 'contains', value: 'contains', type: 'text' },
    { label: 'not contain', value: 'notcontain', type: 'text' }
];

const fieldTypeOptions = [
    { label: 'Text', value: 'Text' },
    { label: 'Date', value: 'Date' },
    { label: 'True/False', value: 'Boolean' },
    { label: 'Number/Currency', value: 'Numeric' }
];

const booleanOptions = [
    { label: 'TRUE', value: 'true' },
    { label: 'FALSE', value: 'false' }
];

const actionTypeOptions = [
    { label: 'APEX', value: 'Apex' },
    { label: 'FLOW', value: 'Flow'}
];

export default class LinkedObjectItem extends LightningElement {
    labels = {
        actionLabel: { label: LABEL_LABEL },
        actionType: { label: LABEL_ACTION_TYPE },
        className : { label: LABEL_CLASS_NAME },
        methodName: { label: LABEL_METHOD_NAME },
        field: { label: LABEL_FIELD },
        fieldType: { label: LABEL_FIELD_TYPE },
        flowName: { label: LABEL_FLOW_NAME },
        label: { label: 'Label' },
        new: { label: LABEL_NEW },
        newFilter: { label: LABEL_NEWFILTER },
        objectToCount: { label: LABEL_OBJECT_TO_COUNT },
        operator: { label: LABEL_OPERATOR },
        select: { label: LABEL_SELECT },
        value: { label: LABEL_VALUE }
    };

    actionTypeOptions = actionTypeOptions;
    booleanOptions = booleanOptions;
    operatorOptions = operators;
    fieldTypeOptions = fieldTypeOptions;
    
    _item;
    @api 
    get item() {
        return this._item;
    }
    set item(value) {
        console.log('[linkedObjectItem.set item] value', value);
        console.log('[linkedObjectItem.set item] sourceObject', this.sourceObject);
        console.log('[linkedObjectItem.set item] sourceObjectInfo', this.sourceObjectInfo);
        console.log('[linkedObjectItem.set item] linkedObject', this.sourceObject);
        console.log('[linkedObjectItem.set item] linkedObjectInfo', this.sourceObjectInfo);
        this._item = value;
        this.isEditing = value.isEditing;
        if (value != undefined) {
            this.itemIndex = value.index;
            this.itemType = value.itemType;
            this.objectName = value.objectName;
            this.fieldName = value.fieldName;
            this.fieldValue = value.fieldValue;
            this.fieldType = value.fieldType;
            this.operator = value.operator;
            this.actionLabel = value.actionLabel;
            this.actionType = value.actionType;
            this.actionClassName = value.actionClassName;
            this.actionMethodName = value.actionMethodName;
            this.actionFlowName = value.actionFlowName;
            this.objectToCount = value.objectToCount;    
            this.filterType = value.filterType;
            this.referencedObject = value.referencedObject;
            this.referencedField = value.referencedField;
        }
    }

    @api 
    itemIndex;

    @api 
    bfConfig;

    @api 
    sourceObject;

    @api 
    sourceObjectInfo;


    @api 
    linkedObject;

    @api
    linkedObjectInfo;

    sourceObjectFields;
    linkedObjectFields;

    @api 
    canEdit;

    @track 
    isEditing = false;

    selectedFieldApiName;
    selectedFieldValue;
    selectedFieldType;

    fieldOptions;
    fieldPicklistValues;
    availableFields;
    showFieldNameSearch = false;
    actionLabel = '';
    actionClassName = '';
    actionMethodName = '';
    actionFlowName = '';

    fieldName = '';
    fieldType = 'text';
    fieldTypeDateTime = false;
    fieldTypeBoolean = false;
    fieldTypeText = true;
    fieldTypeNumeric = false;
    filterType = 'Value';
    referencedObject = '';
    referencedField = '';
    counterLabel = '';

    get isAction() {
        return this.item != undefined && this.item.itemType == 'Action';
    }
    get isFilter() {
        return this.item == undefined || this.item.itemType == 'Filter';
    }
    get isCounter() {
        return this.item != undefined && this.item.itemType == 'Counter';
    }

    get title() {
        var _title = '';
        switch (this.item.itemType) {
            case 'Action':
                _title = `${this.actionType}:${this.actionLabel}`;
                break;

            case 'Filter':
                _title = `${this.objectName}.${this.fieldName}`;
                break;

            case 'Counter':
                _title = `${this.objectToCount}.${this.fieldName}`;
                break;
        }                

        return _title;
    }
    get subTitle() {
        console.log('[linkObjectItem.subTitle] item', JSON.parse(JSON.stringify(this.item)));
        console.log('[linkedObjectItem.subTitle] actionFlowName', this.actionFlowName);
        console.log('[linkedObjectItem.subTitle] actionClassName', this.actionClassName);
        console.log('[linkedObjectItem.subTitle] actionMethodName', this.actionMethodName);
        console.log('[linkedObjectItem.subTitle] filterType', this.filterType);
        console.log('[linkedObjectItem.subTitle] operator', this.operator);
        console.log('[linkedObjectItem.subTitle] referencedObject', this.referencedObject);
        console.log('[linkedObjectItem.subTitle] referencedField', this.referencedField);
        console.log('[linkedObjectItem.subTitle] fieldValue', this.fieldValue);
        var _subtitle = '';
        switch (this.item.itemType) {
            case 'Action':
                if (this.isFlow) {
                    _subtitle = this.actionFlowName;
                } else {
                    _subtitle = `${this.actionClassName}.${this.actionMethodName}`;
                }
                break;

            case 'Filter':
                if (this.filterType == 'Value') {
                    _subtitle = `${this.operator}  ${this.fieldValue}`;
                } else {
                    _subtitle = `${this.operator}  ${this.referencedObject}.${this.referencedField}`;
                }
                break;

        }

        return _subtitle;
    }

    _objectName;
    linkedObjectSelected = false;
    @api
    get objectName() {
        return this._objectName;
    }
    set objectName(value) {
        console.log('[linkedObjectItem.setObject] value', value);
        //console.log('[linkedObjectFilterDetail.setObject] sourceObjectInfo',this.sourceObjectInfo == undefined ? this.sourceObjectInfo : JSON.parse(JSON.stringify(this.sourceObjectInfo)));
        //console.log('[linkedObjectFilterDetail.setObject] linkedObjectInfo',this.linkedObjectInfo == undefined ? this.linkedObjectInfo : JSON.parse(JSON.stringify(this.linkedObjectInfo)));
        //this.isWorking = true;
        this._objectName = value;
        if (value == this.linkedObject) {
            this.linkedObjectSelected = true;
        } else {
            this.linkedObjectSelected = false;
        }
        try {
            console.log('[linkedObjectItem.objectName] sourceObjectFields', this.sourceObjectFields);
            console.log('[linkedObjectItem.objectName] linkedObjectFields', this.linkedObjectFields);
            if (this.isFilter) {
                if (this.sourceObject == value) {
                    this.availableFields = [...this.sourceObjectFields];
                } else {
                    this.availableFields = [...this.linkedObjectFields];
                }    
            }
            //if (this.sourceObjectInfo != undefined && this.linkedObjectInfo != undefined) {
                /*
                this.fieldOptions = this.sourceObjectInfo.fields;
                if (value == this.linkedObject) {
                    this.fieldOptions = this.linkedObjectInfo.fields;
                }
                console.log('[linkedObjectFilterDetail.setObject] fieldOptions', this.fieldOptions);
                
                const flds = [];
                Object.keys(this.fieldOptions).forEach(key => {
                    const fld = this.fieldOptions[key];
                    console.log('[linkedObjectFilterDetail.setObject] fld for ' + key, fld);
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
                this.availableFields = [...flds];   
                console.log('[linkedObjectFilterDetail.setObject] availableFields ', this.availableFields);
                */
               //console.log('[linkedObjectItem.setObject] linkedObjectFields', this.linkedObjectFields == undefined ? this.linkedObjectFields : JSON.parse(JSON.stringify(this.linkedObjectFields)));
               //console.log('[linkedObjectItem.setObject] sourceObjectFields', this.sourceObjectFields == undefined ? this.sourceObjectFields : JSON.parse(JSON.stringify(this.sourceObjectFields)));
               //if (value == this.linkedObject) {
                   //this.availableFields = [...this.linkedObjectFields];
               //} else {
                   //this.availableFields = [...this.sourceObjectFields];
               //}
            //}  
        }catch(ex) {
            console.log('[linkedObjectItem.setObject] exception', ex);
        }finally {
            this.isWorking = false;    
        }
    }

    
    _fieldName;
    @api 
    get fieldName() {
        return this._fieldName;
    }
    set fieldName(value) {
        try {
            this._fieldName = value;
            console.log('[linkedObjectItem.set fieldName] value', value);
            if (value != undefined && this.availableFields != undefined) {
                const fld = this.objectName == this.sourceObject ? this.sourceObjectInfo.fields[value] : this.linkedObjectInfo.fields[value];
                console.log('fld', JSON.parse(JSON.stringify(fld)));
                console.log('datatype', fld.dataType);

                switch(fld.dataType) {
                    case "Boolean":
                        this.setFieldType("Boolean");
                        if (this.fieldValue == undefined || this.fieldValue == '') { this.fieldValue = 'true'; }
                        break;

                    case "Date":
                    case "DateTime":
                        this.setFieldType("Date");
                        break;
                        
                    case "Currency":
                    case "Double":
                    case "Int":
                    case "Percent":
                        this.setFieldType("Number");
                        break;

                    default:    
                        this.setFieldType("Text");
                        break;            
                }
            }
        }catch(ex) {
            console.log('[linkedObjectItem.handleFieldNameChange] exception', ex);
        }
    }
    

    _actionType = 'apex';
    @api 
    get actionType() {
        return this._actionType;
    }
    set actionType(value) {
        this._actionType = value;
    }

    get isApexClass() {
        return this.actionType == undefined || this.actionType == 'Apex';        
    }    
    get isFlow() {
        return this.actionType != undefined && this.actionType == 'Flow';
    }

    objectOptions = [];    
    showBooleanValues = false;
    relatedObjects = new Map();

    connectedCallback() {
        console.log('[linkedObjectItem.connectedCallback] sourceObject, linkedObject', this.sourceObject, this.linkedObject);
        console.log('[linkedObjectItem.connectedCallback] sourceObjectInfo', this.sourceObjectInfo == undefined ? 'undefined' : JSON.parse(JSON.stringify(this.sourceObjectInfo)));
        console.log('[linkedObjectItem.connectedCallback] linkedObjectInfo', this.linkedObjectInfo == undefined ? 'undefined' : JSON.parse(JSON.stringify(this.linkedObjectInfo)));
        let options = [];
        let relatedObjectAPINames = [];
        this.relatedObjects.clear();


        if (this.sourceObjectInfo != undefined) {
            options.push({label: this.sourceObjectInfo.label, value: this.sourceObject});
            
            const sourceflds = [];
            Object.keys(this.sourceObjectInfo.fields).forEach(key => {
                const fld = this.sourceObjectInfo.fields[key];
                //console.log('[linkedObjectItem.connectedCallback] fld for ' + key, fld);
                if (fld) {
                    sourceflds.push({label:fld.label + ' ['+fld.apiName+']', value: fld.apiName, apiName: fld.apiName, type: fld.dataType});
                }
            });
            if (this.sourceObjectInfo.childRelationships) {
                this.sourceObjectInfo.childRelationships.forEach(cr => {
                    console.log('[linkedObjectItem.connectedCallback] sourceObjectInfo.childrelations', cr);
                    if (!this.relatedObjects.has(cr.relationshipName)) {
                        this.relatedObjects.set(cr.relationshipName, cr);
                        relatedObjectAPINames.push({ label: cr.childObjectApiName, value: cr.relationshipName });
                    }
                });                
            }

            sourceflds.sort(function(a, b) {
                let x = a.label.toLowerCase();
                let y = b.label.toLowerCase();
                if (x < y) { return -1; }
                if (x > y) { return 1; }
                return 0; 
            });
            this.sourceObjectFields = sourceflds;
            
        }
        if (this.linkedObjectInfo != undefined) {
            options.push({label: this.linkedObjectInfo.label, value: this.linkedObject});
            
            const linkedflds = [];
            console.log('linkedObjectInfo.fields keys', Object.keys(this.linkedObjectInfo.fields));
            Object.keys(this.linkedObjectInfo.fields).forEach(key => {
                const fld = this.linkedObjectInfo.fields[key];
                //console.log('[linkedObjectFilterDetail.setObject] fld for ' + key, fld);
                if (fld) {
                    linkedflds.push({label:fld.label + ' ['+fld.apiName+']', value: fld.apiName, apiName: fld.apiName, type: fld.dataType});
                }
            });
            console.log('linkedObjectInfo.childRelationships', this.linkedObjectInfo.childRelationships);
            if (this.linkedObjectInfo.childRelationships) {
                this.linkedObjectInfo.childRelationships.forEach(cr => {
                    if (!this.relatedObjects.has(cr.childObjectApiName)) {
                        this.relatedObjects.set(cr.childObjectApiName, cr);
                        relatedObjectAPINames.push({ label: cr.childObjectApiName, value: cr.childObjectApiName });
                    }
                });
            }
            linkedflds.sort(function(a, b) {
                let x = a.label.toLowerCase();
                let y = b.label.toLowerCase();
                if (x < y) { return -1; }
                if (x > y) { return 1; }
                return 0; 
            });
            this.linkedObjectFields = linkedflds;
            
        } 
        
        this.objectOptions = [...options];
        this.availableFields = this.sourceObjectFields;
        this.relatedObjectList = [...relatedObjectAPINames];
        //this.object = this.sourceObject;
        //this.fieldTypeText = true;
        console.log('[linkedObjectItem.connectedCallback] objectOptions', this.objectOptions);
    }

    handleObjectChange(event) {
        this.objectName = event.detail.value;
    }
    handleFieldNameChange(event) {
        this.fieldName = event.detail.value;
        console.log('[linkedObjectItem.handleFieldNameChange] fieldname', this.fieldName);
    }
    handleFieldTypeChange(event) {
        this.fieldType = event.detail.value;
        this.setFieldType();
    }
    handleOperatorChange(event) {
        this.operator = event.detail.value;
    }
    handleFieldValueChange(event) {
        this.fieldValue = event.detail.value;
    }
    handleBooleanOptionChange(event) {
        this.fieldValue = event.detail.value;
    }    
    setFieldType(fieldType) {
        console.log('[linkedObjectItem.setFieldType] fieldType', fieldType);
        this.fieldTypeDateTime = false;
        this.fieldTypeBoolean = false;
        this.fieldTypeText = false;
        this.fieldTypeNumeric = false;
        this.fieldType = fieldType;

        switch(fieldType) {
            case "Date":
                this.fieldTypeDateTime = true;
                this.operatorOptions = [...operators.filter(o => o.type.indexOf('date') > -1)];
                break;

            case "Boolean":
                this.fieldTypeBoolean = true;
                this.operatorOptions = [...operators.filter(o => o.type.indexOf('boolean') > -1)];
                break;

            case "Number":
                this.fieldTypeNumeric = true;
                this.operatorOptions = [...operators.filter(o => o.type.indexOf('numeric') > -1)];
                break;

            default:
                this.fieldTypeText = true;
                this.operatorOptions = [...operators.filter(o => o.type.indexOf('text') > -1)];
                break;
        }
    }

    handleActionLabelChange(event) {
        this.actionLabel = event.detail.value;
    }
    handleActionTypeChange(event) {
        console.log('[linkedObjectItem.handleActionTypeChange] value', event.detail.value);
        this.actionType = event.detail.value;
    }
    handleActionClassNameChange(event) {
        this.actionClassName = event.detail.value;
    }
    handleActionMethodNameChange(event) {
        this.actionMethodName = event.detail.value;
    }
    handleActionFlowNameChange(event) {
        this.actionFlowName = event.detail.value;
    }
    handleObjectToCountChange(event) {
        this.objectToCount = event.detail.value;
        const objectToCountDetails = this.relatedObjects.get(this.objectToCount);
        this.fieldName = objectToCountDetails.fieldName;        
    }
    handleCounterLabelChange(event) {
        this.counterLabel = event.detail.value;
    }

    closeItem() {
        this.isEditing = false;
        if (this.item.id == '') {
            this.deleteItem();
        }
    }
    applyChanges() {
        console.log('[linkedObjectItem.applyChanges]');
        try {
            const item = {
                id: this.item.id,
                itemType: this.item.itemType,
                index: this.itemIndex,
                objectName: this.objectName,
                fieldName: this.fieldName,
                fieldType: this.fieldType,
                fieldValue: this.fieldValue,
                filterType: 'Value',
                operator: this.operator,
                actionType: this.actionType,
                actionLabel: this.actionLabel,
                actionClassName: this.actionClassName,
                actionMethodName: this.actionMethodName,
                actionFlowName: this.actionFlowName,
                objectToCount: this.objectToCount,
                counterLabel: this.counterLabel,
                isEditing: false
            };
            console.log('[linkedObjectItem.applyChanges] item', item);

            const ev = new CustomEvent('update',
            {
                bubbles: true,
                composed: true,
                detail: {
                    item: item,
                    index: this.itemIndex
                }
            });
            this.dispatchEvent(ev);
        }catch(ex) {
            console.log('[linkedObjectItem.applyChanges] exception', ex);
        }
    }

    editItem() {
        this.isEditing = true;
    }
    deleteItem() {
        this.dispatchEvent(new CustomEvent('delete', { 
            bubbles: true, 
            composed: true,
            detail: {
                index: this.item.itemIndex,
                item: this.item
            }
        }));
    }

}