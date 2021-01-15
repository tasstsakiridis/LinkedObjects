import { LightningElement } from 'lwc';

import LABEL_CANCEL from '@salesforce/label/c.Cancel';

export default class BfPopover extends LightningElement {
    labels = {
        cancel: { label: LABEL_CANCEL }
    };
}