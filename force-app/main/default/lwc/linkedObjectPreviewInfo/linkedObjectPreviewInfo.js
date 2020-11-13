import { LightningElement, api } from 'lwc';

import getCount from '@salesforce/apex/LinkedObjectConfig_Controller.getCount';

export default class LinkedObjectPreviewInfo extends LightningElement {
    labels = {
        countby: { label: 'Count by:'},
        fields: { label: 'Fields:'}
    };

    @api 
    recordId;

    @api
    type;

    @api 
    index = 1;

    @api 
    title;

    @api 
    infoText;

    _rows;
    @api 
    get rows() {
        return this._rows;
    }
    set rows(value) {
        this._rows = value;
        this.getFieldInfo();
    }

    @api 
    fieldObjectInfo;

    @api
    counters;

    _fields;
    fieldOptions = [];
    @api 
    get fields() {
        return this._fields;
    }
    set fields(value) {
        this._fields = value;
        const options = [];
        console.log('[linkedObjectPreviewInfo.set fields] fieldObjectInfo', this.fieldObjectInfo);
        if (this.fieldObjectInfo != undefined && this.fieldObjectInfo.data != undefined) {
            this._fields.forEach(fld => {
                const field = this.fieldObjectInfo.data.fields[fld];
                options.push({label: field.label, value: field.apiName});
            });
        } else {
            this._fields.forEach(fld => {
                options.push({label: fld, value: fld});
            });
        }
        this.fieldOptions = [...options];
    }

    _selectedField;
    @api
    get selectedField() {
        return this._selectedField;
    }
    set selectedField(value) {
        this._selectedField = value;
        if (value == undefined || value == '') {
            this.infoText = '';
            this.title = '';
        } else {
            if (this.rows != undefined && this.rows.length > 0) {
                this.getFieldInfo();
            }    
        }
    }

    chart;
    chartjsInitialised = false;

    get isTextTemplate() {
        return this.type == undefined || this.type == 'text';
    }

    get isChartTemplate() {
        return this.type == 'chart';
    }    


    renderedCallback() {
        /*
        if (this.chartjsInitialised) {
            return;
        }
        this.chartjsInitialised = true;

        Promise.all([
            loadScript(this, chartjs+'/chartjs/Chart.min.js'),
            loadStyle(this, chartjs+'/chartjs/Chart.min.css')
        ])
        .then(() => {
            window.Chart.platform.disableCSSInjection = true;

            const canvas = document.createElement('canvas');
            const el = this.template.querySelector('div.chart');
            console.log('[linkedObjectPreviewInfo.renderredCallback] chart element', el);
            if (el) {
                el.appendChild('canvas');
            }
            const ctx = canvas.getContext('2d');
            this.chart = new window.Chart(ctx, this.config);
        })
        .catch(error => {
            this.error = error;
        });
        */
    }

    handleFieldSelection(event) {
        this.selectedField = event.detail.value;
        console.log('[linkedObjectPreviewInfo.handleFieldSelection] selectedField', this.selectedField);
        this.dispatchEvent(new CustomEvent('fieldupdate', { detail: { fieldName: this.selectedField, index: this.index }}));
    }

    getFieldInfo() {
        if (this.selectedField == null || this.selectedField == '') {
            this.title = '';
            this.infoText = '';
            return;
        }

        const fld = this.fieldOptions.find(f => f.value == this.selectedField);
        console.log('[linkedObjectPreviewInfo.getFieldInfo] fld', fld);
        if (fld) {
            console.log('[linkedObjectPreviewInfo.getFieldInfo] fields', this.fields);
            const detailsMap = new Map();
            console.log('[linkedObjectPreviewInfo.getFieldInfo] selectedField', this.selectedField);
            this.rows.map(row => {
                let counter = 0; 
                let fieldValue = row[this.selectedField];
                if (detailsMap.has(fieldValue)) {
                    counter = detailsMap.get(fieldValue);
                }
    
                counter++;
                detailsMap.set(fieldValue, counter);
            });    

            this.title = fld.label;
            this.infoText = detailsMap.size;
        } else {
            const counter = this.counters.find(ctr => ctr.Name == this.selectedField);
            console.log('[linkedObjectPreviewInfo.getFieldInfo] counter', counter);
            if (counter) {
                this.title = counter.Counter_Label__c;
                getCount({sourceRecordId: this.recordId,
                          objectToCount: counter.Object_to_Count__c,
                          fieldNameToQuery: counter.Field_Name_to_Query__c})
                .then(result => {
                    this.error = undefined;
                    this.infoText = result.count;
                    console.log('[linkedObjectPreviewInfo.getCount] result', JSON.parse(JSON.stringify(result)));
                })
                .catch(error => {
                    this.error = error;
                });    
            } else {
                this.title = '';
                this.infoText = '';
            }
        }
    }

}