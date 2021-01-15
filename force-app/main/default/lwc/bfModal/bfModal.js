import { LightningElement, api, track } from 'lwc';

import LABEL_CANCEL from '@salesforce/label/c.Cancel';

export default class BfModal extends LightningElement {
    labels = {
        cancel: { label: LABEL_CANCEL },
    };

    @track title;
    @track body;
    @track success = {
        variant: 'brand'
    };

    @api
    show() {
        this.template.querySelector('.lwc-modal').classList.remove('slds-hide');
    }
    @api
    hide() {
        this.template.querySelector('.lwc-modal').classList.add('slds-hide');
    }
}