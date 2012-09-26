// ==UserScript==
// @name           Show Link URL in Corner
// @namespace      SLUC
// @description    When hovering a link, some browsers (cough Firefox) present no information about what action clicking will perform.  This script pops up the target href/URL in the corner of the page, like Chrome does.
// @include        *
// ==/UserScript==

// TODO: Like Chrome's built-in popup, hide it when mouse is in that corner.

var timer = null;
var targetElem = null;

var urlDisplayer = null;

function actOn(elem) {
	return (elem.tagName == 'A');
}

function enteredElement(evt) {
	var elem = evt.target || evt.sourceElement;
	if (actOn(elem)) {
		if (timer) {
			clearTimeout(timer);
		}
		timer = setTimeout(hoverDetected,30);
		targetElem = elem;
	}
}

function leftElement(evt) {
	var elem = evt.target || evt.sourceElement;
	if (actOn(elem)) {
		if (timer) {
			clearTimeout(timer);
			timer = null;
			targetElem = null;
			hideDisplayer();
		}
	}
}

function hideDisplayer() {
	if (urlDisplayer) {
		urlDisplayer.style.display = 'none';
	}
}

function hoverDetected() {
	if (!urlDisplayer) {
		urlDisplayer = document.createElement('div');
		urlDisplayer.style.position = 'fixed';
		urlDisplayer.style.left = '-4px';
		urlDisplayer.style.bottom = '-4px';
		urlDisplayer.style.backgroundColor = '#e8e8e8';
		urlDisplayer.style.color = 'black';
		urlDisplayer.style.padding = '1px 3px 6px 5px';
		urlDisplayer.style.border = '1px solid #a0a0a0';
		urlDisplayer.style.fontSize = '12px';
		urlDisplayer.style.maxHeight = '15px';
		urlDisplayer.style.borderRadius = '4px';
		urlDisplayer.style._mozBorderRadius = '4px';
		urlDisplayer.style.zIndex = 100;
		document.body.appendChild(urlDisplayer);
	}
	urlDisplayer.textContent = targetElem.href;
	urlDisplayer.style.display = 'block';
}

document.body.addEventListener('mouseover',enteredElement,true);
document.body.addEventListener('mouseout',leftElement,true);

