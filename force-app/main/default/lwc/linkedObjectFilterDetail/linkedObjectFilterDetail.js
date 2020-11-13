import { LightningElement, api } from 'lwc';

import LABEL_FIELD from '@salesforce/label/c.Field';
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

export default class LinkedObjectFilterDetail extends LightningElement {
    labels = {
        field: { label: LABEL_FIELD },
        newFilter: { label: LABEL_NEWFILTER },
        operator: { label: LABEL_OPERATOR },
        select: { label: LABEL_SELECT },
        value: { label: LABEL_VALUE }
    };

    booleanOptions = booleanOptions;

    _filter;

    @api 
    get filter() {
        return this._filter;
    }
    set filter(value) {
        this._filter = value;
        if (value == undefined) {
            this.title = labels.newFilter.label;
            this.object = this.sourceObject;
            this.fieldName = undefined;
            this.fieldValue = undefined;
            this.operator = 'equals';
            this.setFieldType("text");
        } else {
            this.title = value.Name == undefined ? this.labels.newFilter.label : '';
            this.object = value.Object__c;
            this.fieldName = value.FieldName__c;
            this.fieldValue = value.FieldValue__c;
            this.operator = value.Operator__c;

        }

        console.log('[setFilter] filter', value);
        console.log('[setFilter] object, fieldname, fieldvalue, operator', this.object, this.fieldName, this.fieldValue, this.operator);
    }

    @api 
    sourceObject;

    @api 
    sourceObjectInfo;

    @api 
    linkedObject;

    @api 
    linkedObjectInfo;

    selectedFieldApiName;
    selectedFieldValue;
    selectedFieldType;

    isWorking = false;

    title;
    fieldValue;
    fieldName;
    object;
    operator = 'equals';
    fieldOptions;
    fieldPicklistValues;
    availableFields;
    showFieldNameSearch = false;

    fieldTypeDateTime = false;
    fieldTypeBoolean = false;
    fieldTypeText = false;
    fieldTypeNumeric = false;

    _object;
    @api
    get object() {
        return this._object;
    }
    set object(value) {
        console.log('[set.object] value', value);
        this.isWorking = true;
        this._object = value;
        if (this.sourceObjectInfo != undefined && this.linkedObjectInfo != undefined) {
            this.fieldOptions = this.sourceObjectInfo.data.fields;
            if (value == this.linkedObject) {
                this.fieldOptions = this.linkedObjectInfo.data.fields;
            }
            console.log('fieldOptions', this.fieldOptions);
            
            const flds = [];
            Object.keys(this.fieldOptions).forEach(key => {
                const fld = this.fieldOptions[key];
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
        this.isWorking = false;    
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
            console.log('[handleFieldNameChange] exception', ex);
        }
    }

    operatorOptions = operators;

    objectOptions = [];    
    showBooleanValues = false;

    connectedCallback() {
        if (this.sourceObjectInfo != undefined) {
            this.objectOptions = [...this.objectOptions, {label: this.sourceObjectInfo.data.label, value: this.sourceObject}];
        }
        if (this.linkedObjectInfo != undefined) {
            this.objectOptions = [...this.objectOptions, {label: this.linkedObjectInfo.data.label, value: this.linkedObject}];
        }
        this.object = this.sourceObject;
        this.fieldTypeText = true;
        console.log('objectOptions', this.objectOptions);
        console.log('sourceObject, linkedObject', this.sourceObject, this.linkedObject);
    }

    handleObjectChange(event) {
        this.object = event.detail.value;
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

    closeFilter() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
    applyChanges() {
        const filter = {
            Object__c: this.object,
            FieldName__c: this.fieldName,
            FieldValue__c: this.fieldValue,
            Operator__c: this.operator
        };

        this.dispatchEvent(new CustomEvent('save', {detail: filter}));    
    }
}