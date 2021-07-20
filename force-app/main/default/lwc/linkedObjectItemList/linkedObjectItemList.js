import { LightningElement, api } from 'lwc';

import saveItemConfiguration from '@salesforce/apex/LinkedObjectConfig_Controller.saveItemConfiguration';

import LABEL_ACTIONS from '@salesforce/label/c.Actions';
import LABEL_ADDNEW from '@salesforce/label/c.AddNew';
import LABEL_COUNTERS from '@salesforce/label/c.Counters';
import LABEL_INSERT_SUGGESTED_FILTERS from '@salesforce/label/c.InsertSuggestedFilterCriteria';
import LABEL_FILTERS from '@salesforce/label/c.Filters';

export default class LinkedObjectItemList extends LightningElement {
    labels = {
        addNew: { label: LABEL_ADDNEW },
        filters: { label: LABEL_FILTERS },
        actions: { label: LABEL_ACTIONS },
        counters: { label: LABEL_COUNTERS }
    };

    @api 
    title;

    @api 
    itemType;

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

    @api 
    isAdmin = false;

    @api 
    canCreateFilters = false;

    _bfConfig;
    @api 
    get bfConfig() {
        return this._bfConfig;
    }
    set bfConfig(value) {
        console.log('[linkedObjectItemList.set bfConfig] value', value == undefined ? value : JSON.parse(JSON.stringify(value)));
        this._bfConfig = value;
        /*
        if (value == undefined) {
            this.filters = [];
        } else {
            this.filters = [...value.BF_Configuration_Items__r.filter(f => f.Is_Filter__c)];            
        }
        console.log('[linkedObjectFilterList.set bfconfig] filters', this.filters);
        */
        console.log('[linkedObjectItemList.set bfConfig] linkedObjectInfo', this.linkedObjectInfo);
    }

    _items = [];
    @api 
    get items() {        
        return this._items;
    }
    set items(value) {
        console.log('[linkedObjectItemList.set items] value', value == undefined ? value : JSON.parse(JSON.stringify(value)));
        this._items = value;
    }

    @api 
    marketItems = [];

    itemsToDelete = [];
    isWorking = false;

    get hasItems() {
        return this.items == undefined || this.items.length == 0 ? false : true;
    }

    addNewItem() {
        console.log('[linkedObjectItemList.addNewItem] type', this.itemType);
        console.log('[linkedObjectItemList.addNewItem] itemType', this.itemType);
        console.log('[linkedObjectItemList.addNewItem] sourceObject', this.sourceObject);
        console.log('[linkedObjectItemList.addNewItem] sourceObjectInfo', this.sourceObjectInfo);
        console.log('[linkedObjectItemList.addNewItem] linkedObject', this.linkedObject);
        console.log('[linkedObjectItemList.addNewItem] linkedObjectInfo', this.linkedObjectInfo);
        try {
            this.dispatchEvent(new CustomEvent('addnewitem', { 
                detail: {
                    itemType: this.itemType,
                    index: this.items == undefined ? 1 : this.items.length
                }
            }));
            /*
            if (this.items == undefined) { this.items = []; }
            const item = this.createNewItem();
            this.items = [
                ...this.items,
                item
            ];
            */
        }catch(ex) {
            console.log('[linkedObjectItemList.addNewFilter] exception', ex);
        }
        //console.log('[linkedObjectItemList.addNewFilter] items', this.items);
        
    }

    handleMenuSelection(event) {
        try {
            const selectedButton = event.detail.value;
            console.log('[linkedObjectItemList.handleMenuSelection] selectedButton', selectedButton);
            switch (selectedButton) {
                case 'addNew':
                    this.addNewItem();
                    break;

                default:
                    const marketItem = this.marketItems.find(mi => mi.id == selectedButton);
                    console.log('[linkedObjectItemList.handleMenuSelection] marketItems', this.marketItems);
                    console.log('[linkedObjectItemList.handleMenuSelection] marketItem', marketItem);
                    this.dispatchEvent(new CustomEvent('addexistingitem', {
                        detail: {
                            itemType: this.itemType,
                            index: this.items == undefined ? 1 : this.items.length,
                            item: marketItem
                        }
                    }));
            }
        }catch(ex) {
            console.log('[linkedObjectItemList.handleMenuSelection] exception', ex);
        }
    }

    finishedLoading(event) {
        this.items.forEach(i => {
            if (i.id == event.detail) {

            }
        })
    }

    handleCancelEdit(event) {
        if (event.detail.id == '') {
            this.items.splice(event.detail.itemIndex, 1);
        }
    }

    createNewItem() {
        return {
            id: '',
            type: this.itemType,
            object: this.sourceObject,
            fieldName: '',
            fieldValue: '',
            operator: 'equals',
            actionType: 'apex',
            actionClassName: '',
            actionMethodName: '',
            actionFlowName: '',
            index: this.items.length,
            isEditing: true    
        }
    }

    removeItem(event) {
        try {
            const index = event.detail;   
            const itemToRemove = this.items.slice(index, index+1)[0];
            console.log('[linkedObjectItemList.removeItem] itemToRemove.Id', itemToRemove.Id);
            if (itemToRemove.Id != undefined && itemToRemove.Id != '') {
                this.itemsToDelete.push(itemToRemove);
            }
            const splicedItems = [];
            this.items.splice(index, 1);
            console.log('[linkedObjectItemList.removeItem] items spliced', splicedItems);

            this.items.forEach(f => {
                console.log('[linkedObjectItemList.removeItem] f', f);
                const uf = {...f};
                if (f.Index__c > index) {
                    uf.Index__c--;
                }

                splicedItems.push(uf);
            });
            this.items = [...splicedItems];
            
            console.log('[linkedObjectItemList.removeItem] index', index);
            console.log('[linkedObjectItemList.removeItem] items', this.items);
            console.log('[linkedObjectItemList.removeItem] itemToRemove', itemToRemove);
            console.log('[linkedObjectItemList.removeItem] itemsToDelete', this.itemsToDelete);

            if (itemToRemove.id != undefined && itemToRemove.id.length > 0) {
                deleteItemConfiguration({ itemId: itemToRemove.id })
                .then(result => {
                    console.log('[linkedObjectItemList.deleteItemConfiguration] error',JSON.parse(JSON.stringify(result)));                    
                })
                .catch(error => {
                    this.error = error;
                    console.log('[linkedObjectItemList.deleteItemConfiguration] error',JSON.parse(JSON.stringify(error)));
                });
            }
        }catch(ex) {
            console.log('[linkedObjectFilterList.removeFilter] exception', ex);
        }

    }
    updateItem(event) {
        console.log('[linkedObjectItemList.updateItem] event', JSON.parse(JSON.stringify(event.detail)));
/*
        try {
            const item = event.detail.item;
            const index = event.detail.index;
            console.log('[linkedObjectItemList.updateItem', JSON.stringify(item));
            console.log('[linkedObjectItemList.updateItem] index', index);

            saveItemConfiguration({
                configId: this.bfConfig.Id,
                item: item
            })
            .then(result => {
                console.log('[linkedObjectItemDetail.saveItemConfiguration] result',JSON.parse(JSON.stringify(result)));
                const items = [...this.items];
                items[result.itemIndex] = result.item;
                this.items = [...items];

                if (result.item.itemType == 'Filter' || result.item.itemType == 'Counter') {
                    this.dispatchEvent(new CustomEvent('refresh'));
                }
            })
            .catch(error => {
                this.error = error;
                console.log('[linkedObjectItemDetail.saveItemConfiguration] error',JSON.parse(JSON.stringify(error)));
            });
    
            console.log('[linkedObjectItemList.updateItem] filters', JSON.stringify(this.items));

        }catch(ex) {
            console.log('[linkedObjectItemList.updateItem] exception', ex);
        }
        */
    }

}