import { LightningElement, api } from 'lwc';

import LABEL_NEW from '@salesforce/label/c.New';

export default class LinkedObjectItemSummary extends LightningElement {
    labels = {
        new: { label: LABEL_NEW }
    };

    _item;
    @api 
    get item() {
        return this._item;
    }
    set item(value) {
        this._item = value;
        if (value != undefined) {
            this.itemIndex = value.index;
            switch (value.itemType) {
                case 'Action':
                    this.title = value.actionClassName + '.' + value.actionMethodName;
                    this.subTitle = value.actionType;
                    break;

                case 'Filter':
                    this.title = value.object + '.' + value.fieldName;
                    this.subTitle = value.operator + ' ' + value.fieldValue;
                    break;

                case 'Counter':
                    this.title = value.object + '.' + value.fieldValue;
                    this.subTitle = '';
                    break;
            }
        }
    }

    itemIndex = 0;
    title = '';
    subTitle = '';

    editItem() {
        this.dispatchEvent(new CustomEvent('edit'));
    }
    deleteItem() {
        this.dispatchEvent(new CustomEvent('delete', { 
            bubbles: true, 
            detail: {
                index: this.item.itemIndex,
                item: this.item
            }
        }));
    }

}