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
    sourceObject;

    @api 
    linkedObject;

    @api
    type;

    @api 
    index = 1;

    @api 
    title;

    @api 
    infoText;

    @api 
    includeAllData = false;

    _sourceObjectRows;
    @api 
    get sourceObjectRows() {
        return this._sourceObjectRows;
    }
    set sourceObjectRows(value) {
        this._sourceObjectRows = value;
        this.getFieldInfo();
    }

    _linkedObjectRows;
    @api 
    get linkedObjectRows() {
        return this._rows;
    }
    set linkedObjectRows(value) {
        this._linkedObjectRows = value;
        this.getFieldInfo();
    }

    @api 
    fieldObjectInfo;

    _counters;
    @api
    get counters() {
        return this._counters;
    }
    set counters(value) {
        this._counters = value;
        console.log('[linkedObjectPreviewInfo.set counters] counters', value);
    }

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
            this.getFieldInfo();
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

        console.log('[linkedObjectPreviewInfo.getFieldInfo] fieldOptions', this.fieldOptions);
        const fld = this.fieldOptions.find(f => f.value == this.selectedField);
        console.log('[linkedObjectPreviewInfo.getFieldInfo] fld', fld);
        if (fld) {
            console.log('[linkedObjectPreviewInfo.getFieldInfo] fields', this.fields);
            const detailsMap = new Map();
            console.log('[linkedObjectPreviewInfo.getFieldInfo] selectedField', this.selectedField);
            this.linkedObjectRows.map(row => {
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
        } else if (this.counters != undefined) {
            console.log('[linkedObjectPreviewInfo.getFieldInfo] counters', JSON.parse(JSON.stringify(this.counters)));
            const counter = this.counters.find(ctr => ctr.id == this.selectedField);
            console.log('[linkedObjectPreviewInfo.getFieldInfo] counter', counter);
            if (counter) {
                this.title = counter.counterLabel;
                if (counter.objectToCount == this.sourceObject) {
                    const result = [];
                    this.sourceObjectRows.every(r => {
                        if (result.indexOf(r[counter.fieldName]) < 0) {
                            result.push(r[counter.fieldName]);
                        }
                    });
                    this.infoText = result.length;
                } else {               
                    //const result = this.linkedObjectRows.filter(r => r[counter.fieldName] == this.recordId);
                    //this.infoText = result.length;
                         
                    getCount({sourceRecordId: this.recordId,
                            objectToCount: counter.objectToCount,
                            fieldNameToQuery: counter.fieldName})
                    .then(result => {
                        this.error = undefined;
                        this.infoText = result.count;
                        console.log('[linkedObjectPreviewInfo.getCount] result', JSON.parse(JSON.stringify(result)));
                    })
                    .catch(error => {
                        this.error = error;
                    });   
                    
                } 
            } else {
                this.title = '';
                this.infoText = '';
            }
        }
    }

}