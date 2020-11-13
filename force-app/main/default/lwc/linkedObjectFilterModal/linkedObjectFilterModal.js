import { LightningElement, api, track } from 'lwc';

export default class LinkedObjectFilterModal extends LightningElement {
    @track title;
    @track body;
    @track success = {
        variant: 'brand'
    };

    _size;
    @api
    get size() {
        return this._size;
    }
    set size(value) {
        this._size = 'slds-modal_'+value;        
    }

    modalClassList = "slds-modal slds-fade-in-open slds-modal_small";
    connectedCallback() {
        this.modalClassList = 'slds-modal slds-fade-in-open ' + this.size;
    }

    @api
    show() {
        console.log('[linkedObjectFilterMoodal.show]');
        this.template.querySelector('.lwc-modal').classList.remove('slds-hide');
    }
    @api
    hide() {
        this.template.querySelector('.lwc-modal').classList.add('slds-hide');
    }    

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));    
    }
}