import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import saveConfig from '@salesforce/apex/LinkedObjectConfig_Controller.saveConfig';

import LABEL_INSERT_SUGGESTED_FILTERS from '@salesforce/label/c.InsertSuggestedFilterCriteria';
import LABEL_FILTERS from '@salesforce/label/c.Filters';

export default class LinkedObjectFilterList extends LightningElement {
    label = {
        filters: { label: LABEL_FILTERS }
    };

    @api 
    filterLogic;

    @api 
    sourceObject;

    @api 
    sourceObjectInfo;

    @api 
    linkedObject;

    @api
    linkedObjectInfo;

    @api 
    market;

    @api 
    recordId;

    @api 
    filterType;

    _bfConfig;
    @api 
    get bfConfig() {
        return this._bfConfig;
    }
    set bfConfig(value) {
        console.log('[linkedObjectFilterList.set bfConfig] value', value == undefined ? value : JSON.parse(JSON.stringify(value)));
        this._bfConfig = value;
        /*
        if (value == undefined) {
            this.filters = [];
        } else {
            this.filters = [...value.BF_Configuration_Items__r.filter(f => f.Is_Filter__c)];            
        }
        console.log('[linkedObjectFilterList.set bfconfig] filters', this.filters);
        */
        console.log('[linkedObjectFilterList.set bfConfig] linkedObjectInfo', this.linkedObjectInfo);
    }

    _filters = [];
    @api 
    get filters() {
        return this._filters;
    }
    set filters(value) {
        this._filters = value;
    }

    filtersToDelete = [];

    get title() {
        return LABEL_FILTERS;
    }
    get suggestedFiltersLabel() {
        return LABEL_INSERT_SUGGESTED_FILTERS;
    }
    
    get hasFilters() {
        return this.filters == undefined || this.filters.length == 0 ? false : true;
    }

    showFilterLogic = false;

    handleNewFilterSelect(event) {
        console.log('[linkedObjectFilterList.handleNewFilterSelect] type', event.detail.value);
        if (event.detail.value == 'newfilter') {
            this.addNewFilter();
        } else if (event.detail.value == 'newfilterlogic') {
            this.addNewFilterLogic();
        }
    }
    addNewFilter() {
        console.log('[linkedObjectFilterList.addNewFilter]');
        try {
            if (this.filters == undefined) { this.filters = []; }
            this.filters = [
                ...this.filters,
                {
                    Id: '',
                    Object__c: this.sourceObject,
                    FieldName__c: '',
                    FieldValue__c: '',
                    Operator__c: 'equals',
                    isEditing: true    
                }
            ];
        }catch(ex) {
            console.log('[linkedObjectFilterList.addNewFilter] exception', ex);
        }
        console.log('[linkedObjectFilterList.addNewFilter] filters', this.filters);

    }
    addNewFilterLogic() {
        this.showFilterLogic = true;
    }

    removeFilter(event) {
        try {
            const index = event.detail;   
            const filterToRemove = this.filters.slice(index, index+1)[0];
            console.log('[linkedObjectFilterList.removeFilter] filterToRemove.Id', filterToRemove.Id);
            if (filterToRemove.Id != undefined && filterToRemove.Id != '') {
                this.filtersToDelete.push(filterToRemove);
            }
            const splicedFilters = [];
            this.filters.splice(index, 1);
            console.log('[linkedObjectFilterList.removeFilter] filters spliced', splicedFilters);

            this.filters.forEach(f => {
                console.log('[linkedObjectFilterList.removeFilter] f', f);
                const uf = {...f};
                if (f.Index__c > index) {
                    uf.Index__c--;
                }

                splicedFilters.push(uf);
            });
            this.filters = [...splicedFilters];
            
            console.log('[linkedObjectFilterList.removeFilter] index', index);
            console.log('[linkedObjectFilterList.removeFilter] filters', this.filters);
            console.log('[linkedObjectFilterList.removeFilter] filterToRemove', filterToRemove);
            console.log('[linkedObjectFilterList.removeFilter] filtersToDelete', this.filtersToDelete);

            if (this.filterType == 'action') {
                this.dispatchEvent(new CustomEvent('save', { detail: this.filters }));
            } else {
                this.save();
            }
        }catch(ex) {
            console.log('[linkedObjectFilterList.removeFilter] exception', ex);
        }

    }
    updateFilter(event) {
        try {
            const updatedFilter = event.detail.filter;
            const index = event.detail.index;
            this.filters = [...this.filters];
            this.filters[index] = updatedFilter;  

            console.log('[linkedObjectFilterList.updateFilter] updatedFilter', JSON.stringify(updatedFilter));
            console.log('[linkedObjectFilterList.updateFilter] index', index);
            console.log('[linkedObjectFilterList.updateFilter] filters', JSON.stringify(this.filters));

            if (this.filterType == 'action') {
                this.dispatchEvent(new CustomEvent('save', { detail: this.filters }));
            } else {
                this.save();
            }

        }catch(ex) {
            console.log('[linkedObjectFilterList.updateFilter] exception', ex);
        }
    }

    save() {
        console.log('[linkedObjectFilterList.save]');
        
        try {
            saveConfig({
                configId: this.bfConfig == undefined ? '' : this.bfConfig.Id,
                sourceObject: this.sourceObject,
                linkedObject: this.linkedObject,
                market: this.market,
                sourceObjectRecordId: this.recordId,
                sourceObjectRecordType: '',
                filters: this.filters.map(f => JSON.stringify(f)),
                filtersToRemove: this.filtersToDelete.map(f => f.Id)
            })
            .then((result) => {
                console.log('[linkedObjectFilterList.save] result', result);
                const updatedConfig = {
                    Id: result.Id,
                    BF_Configuration_Items__r: result.items
                };
                this.bfConfig = {...updatedConfig};
                this.filtersToDelete = [];

                this.dispatchEvent(new CustomEvent('refresh', { detail: result.Id }));            
            })
            .catch((error) => {
                console.log('[linkedObjectFilterList.save] error', error);
            });
        }catch(ex) {
            console.log('[linkedObjectFilterList.save] exception', ex);
        }
    }
}