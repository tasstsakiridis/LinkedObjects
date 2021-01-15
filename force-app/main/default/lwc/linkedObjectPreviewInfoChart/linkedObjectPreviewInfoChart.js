import { LightningElement, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { parseBoolean, sanitize } from 'c/utils';

import chartjs from '@salesforce/resourceUrl/chartjs';

const generateRandomNumber = () => {
    return Math.round(Math.random() * 100);
};

export default class LinkedObjectPreviewInfoChart extends LightningElement {
    @api
    type;

    @api 
    title;

    @api 
    infoText;

    chart;
    chartjsInitialised = false;

    _chartjsLoadedCallback;
    @api 
    get chartjsloadedCallback() {
        return this._chartjsLoadedCallback;
    }
    set chartjsloadedCallback(value) {
        this._chartjsLoadedCallback = value;
        this._callChartjsLoadedCallback();
    }

    _canvasOnChange;
    @api 
    get canvasOnChange() {
        return this._canvasOnChange;
    }
    set canvasOnChange(value) {
        this.getCanvas().removeEventListener('mouseover', this._canvasOnChange);
        this._canvasOnChange = value;
        this.getCanvas().addEventListener('change', this._canvasOnChange);
    }

    _canvasOnClick;
    @api
    get canvasOnClick() {
        return this._canvasOnClick;
    }
    set canvasOnClick(value) {
        this.getCanvas().removeEventListener('mouseoover', this._canvas_canvasOnClickOnMouseOver);
        this._canvasOnClick = value;
        this.getCanvas().addEventListener('click', this._canvasOnClick);
    }

    _canvasOnMouseOver;
    @api 
    get canvasOnMouseOver() {
        return this._canvasOnMouseOver;
    }
    set canvasOnMouseOver(value) {
        this.getCanvas().removeEventListener('mouseover', this._canvasOnMouseOver);
        this._canvasOnMouseOver = value;
        this.getCanvas().addEventListener('mouseover', this._canvasOnMouseOver);
    }

    _canvasOnMouseOut;
    @api 
    get canvasOnMouseOut() {
        return this._canvasOnMouseOut;
    }
    set canvasOnMouseOut(value) {
        this.getCanvas().removeEventListener('mouseover', this._canvasOnMouseOut);
        this._canvasOnMouseOut = value;
        this.getCanvas().addEventListener('mouseover', this._canvasOnMouseOut);
    }

    @api 
    get responsive() {
        return this._payload.responsive;
    }
    set responsive(value) {
        this._payload.responsive = parseBoolean(value);
    }

    @api 
    get responsiveAnimationDuration() {
        return this._payload.responsiveAnimationDuration;
    }
    set responsiveAnimationDuration(value) {
        this._payload.responsiveAnimationDuration = value;
    }

    @api 
    get maintainAspectRatio() {
        return this._payload.maintainAspectRatio;
    }
    set maintainAspectRatio(value) {
        this._payload.maintainAspectRatio = parseBoolean(value);
    }

    @api 
    get aspectRatio() {
        return this._payload.aspectRatio;
    }
    set aspectRatio(value) {
        this._payload.aspectRatio = value;
    }

    @api 
    get callbackResize() {
        return this._payload.onResize;
    }
    set callbackResize(value) {
        this._payload.onResize = value;
    }

    @api 
    get events() {
        return this._payload.events;
    }
    set events(value) {
        this._payload.events = sanitize(value);
    }

    @api 
    get callbackClick() {
        return this._payload.onClick;
    }
    set callbackClick(value) {
        this._payload.onClick = value;
    }

    @api 
    get callbackHover() {
        return this._payload.onHover;
    }
    set callbackHover(value) {
        this._payload.onHover = value;
    }


    config = {
        type: 'doughnut',
        data: {
            datasets: [
                {
                    data: [
                        generateRandomNumber(),
                        generateRandomNumber(),
                        generateRandomNumber(),
                        generateRandomNumber(),
                        generateRandomNumber()
                    ],
                    backgroundColor: [
                        'rgb(255, 99, 132)',
                        'rgb(255, 159, 64)',
                        'rgb(255, 205, 86)',
                        'rgb(75, 192, 192)',
                        'rgb(54, 162, 235)'
                    ],
                    label: 'Dataset 1'
                }
            ],
            labels: ['Red','Orange','Yellow','Green','Blue']
        },
        options: {
            responsive: true,
            legend: {
                display: false
            },
            animation: {
                animateScale: true,
                animateRotate: true 
            }
        }
    };

    renderedCallback() {
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

            try {
                const canvas = document.createElement('canvas');
                const el = this.template.querySelector('div.chart');
                console.log('[linkedObjectPreviewInfo.renderredCallback] chart element', el);
                if (el) {
                    el.appendChild('canvas');
                }
                const ctx = canvas.getContext('2d');
                this.chart = new window.Chart(ctx, this.config);
                console.log('[linkedObjectPreviewInfoChart.renderedCallback] chart', this.chart);
            }catch(ex) {
                console.log('[linkedObjectPreviewInfoChart.renderedCallback] exception', ex);    
            }
        })
        .catch(error => {
            this.error = error;
        });
    }
}