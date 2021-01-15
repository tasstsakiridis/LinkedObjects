import { LightningElement, api, track } from 'lwc';

import LABEL_ACTION_TYPE from '@salesforce/label/c.Action_Type';
import LABEL_CLASS_NAME from '@salesforce/label/c.Class_Name';
import LABEL_METHOD_NAME from '@salesforce/label/c.Method_Name';
import LABEL_FIELD from '@salesforce/label/c.Field';
import LABEL_FLOW_NAME from '@salesforce/label/c.Flow_Name';
import LABEL_NEW from '@salesforce/label/c.New';
import LABEL_NEWFILTER from '@salesforce/label/c.NewFilter';
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

const booleanOptions = [
    { label: 'TRUE', value: 'true' },
    { label: 'FALSE', value: 'false' }
];

const actionTypeOptions = [
    { label: 'APEX', value: 'Apex' },
    { label: 'FLOW', value: 'Flow'}
];

export default class LinkedObjectItemDetail extends LightningElement {
    labels = {
        actionType: { label: LABEL_ACTION_TYPE },
        className : { label: LABEL_CLASS_NAME },
        methodName: { label: LABEL_METHOD_NAME },
        field: { label: LABEL_FIELD },
        flowName: { label: LABEL_FLOW_NAME },
        new: { label: LABEL_NEW },
        newFilter: { label: LABEL_NEWFILTER },
        operator: { label: LABEL_OPERATOR },
        select: { label: LABEL_SELECT },
        value: { label: LABEL_VALUE }
    };

    actionTypeOptions = actionTypeOptions;
    booleanOptions = booleanOptions;
    operatorOptions = operators;

    @track 
    isWorking = false;

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

    _item;
    @api 
    get item() {
        return this._item;
    }
    set item(value) {
        console.log('[linkedObjectItemDetail.set item] value', value);
        console.log('[linkedObjectItemDetail.set item] sourceObject', this.sourceObject);
        console.log('[linkedObjectItemDetail.set item] linkedObject', this.linkedObject);
        this._item = value;
        this.itemType = value.itemType;
        this.objectName = value.objectName;
        this.fieldName = value.fieldName;
        this.fieldValue = value.fieldValue;
        this.operator = value.operator;
        this.actionType = value.actionType;
        this.actionClassName = value.actionClassName;
        this.actionMethodName = value.actionMethodName;
        this.actionFlowName = value.actionFlowName;
        this.objectToCount = value.objectToCount;
    }

    selectedFieldApiName;
    selectedFieldValue;
    selectedFieldType;


    fieldOptions;
    fieldPicklistValues;
    availableFields;
    showFieldNameSearch = false;
    actionClassName = '';
    actionMethodName = '';
    actionFlowName = '';

    fieldTypeDateTime = false;
    fieldTypeBoolean = false;
    fieldTypeText = false;
    fieldTypeNumeric = false;

    get isAction() {
        return this.item != undefined && this.item.itemType == 'Action';
    }
    get isFilter() {
        return this.item == undefined || this.item.itemType == 'Filter';
    }
    get isCounter() {
        return this.item != undefined && this.item.itemType == 'Counter';
    }

    _objectName;
    @api
    get objectName() {
        return this._objectName;
    }
    set objectName(value) {
        console.log('[linkedObjectFilterDetail.setObject] value', value);
        console.log('[linkedObjectFilterDetail.setObject] sourceObjectInfo',this.sourceObjectInfo == undefined ? this.sourceObjectInfo : JSON.parse(JSON.stringify(this.sourceObjectInfo)));
        console.log('[linkedObjectFilterDetail.setObject] linkedObjectInfo',this.linkedObjectInfo == undefined ? this.linkedObjectInfo : JSON.parse(JSON.stringify(this.linkedObjectInfo)));
        this.isWorking = true;
        this._objectName = value;
        try {
            if (this.sourceObjectInfo != undefined && this.linkedObjectInfo != undefined) {
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

            }  
        }catch(ex) {
            console.log('[linkedObjectFilterDetail.setObject] exception', ex);
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
            if (this.fieldOptions != undefined) {
                const fld = this.fieldOptions[value];
                console.log('fld', JSON.stringify(fld));
                console.log('datatype', fld.dataType);
                switch(fld.dataType) {
                    case "Boolean":
                        this.setFieldType("boolean");
                        if (this.fieldValue == undefined || this.fieldValue == '') { this.fieldValue = 'true'; }
                        break;

                    case "Currency":
                    case "Double":
                    case "Int":
                    case "Percent":
                        this.setFieldType("numeric");
                        break;

                    default:    
                        this.setFieldType("text");
                        break;            
                }
            }
        }catch(ex) {
            console.log('[linkedObjectFilterDetail.handleFieldNameChange] exception', ex);
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


    connectedCallback() {
        console.log('[linkedObjectFilterDetail.connectedCallback] sourceObject, linkedObject', this.sourceObject, this.linkedObject);
        console.log('[linkedObjectFilterDetail.connectedCallback] sourceObjectInfo', this.sourceObjectInfo);
        console.log('[linkedObjectFilterDetail.connectedCallback] linkedObjectInfo', this.linkedObjectInfo);
        if (this.sourceObjectInfo != undefined) {
            this.objectOptions = [...this.objectOptions, {label: this.sourceObjectInfo.label, value: this.sourceObject}];
        }
        if (this.linkedObjectInfo != undefined) {
            this.objectOptions = [...this.objectOptions, {label: this.linkedObjectInfo.label, value: this.linkedObject}];
        } 
        //this.object = this.sourceObject;
        //this.fieldTypeText = true;
        console.log('[linkedObjectFilterDetail.connectedCallback] objectOptions', this.objectOptions);
    }

    handleObjectChange(event) {
        this.objectName = event.detail.value;
    }
    handleFieldNameChange(event) {
        this.fieldName = event.detail.value;
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
    setFieldType(type) {
        this.fieldTypeDateTime = false;
        this.fieldTypeBoolean = false;
        this.fieldTypeText = false;
        this.fieldTypeNumeric = false;

        switch(type) {
            case "datetime":
                this.fieldTypeDateTime = true;
                this.operatorOptions = [...operators.filter(o => o.type.indexOf('date') > -1)];
                break;

            case "boolean":
                this.fieldTypeBoolean = true;
                this.operatorOptions = [...operators.filter(o => o.type.indexOf('boolean') > -1)];
                break;

            case "numeric":
                this.fieldTypeNumeric = true;
                this.operatorOptions = [...operators.filter(o => o.type.indexOf('numeric') > -1)];
                break;

            default:
                this.fieldTypeText = true;
                this.operatorOptions = [...operators.filter(o => o.type.indexOf('text') > -1)];
                break;
        }
    }

    handleActionTypeChange(event) {
        console.log('[linkedObjectItemDetail.handleActionTypeChange] value', event.detail.value);
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
    }

    closeFilter() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
    applyChanges() {
        console.log('[linkedObjectItemDetail.applyChanges]');
        const item = {
            id: this.item.id,
            itemType: this.item.itemType,
            index: this.itemIndex,
            objectName: this.objectName,
            fieldName: this.fieldName,
            fieldValue: this.fieldValue,
            operator: this.operator,
            actionType: this.actionType,
            actionClassName: this.actionClassName,
            actionMethodName: this.actionMethodName,
            actionFlowName: this.actionFlowName,
            objectToCount: this.objectToCount,
            isEditing: false
        };
        console.log('[linkedObjectItemDetail.applyChanges] item', item);

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
    }
}