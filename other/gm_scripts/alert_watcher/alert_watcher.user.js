// ==UserScript==
// @name           Alert Watcher
// @namespace      alertwatcher
// @description    Protects your browser from infinite alert loops.  Overrides the default alert/confirm/prompt dialogs with versions that allow further messages to be cancelled.  You need never be Rick-Rolled again!  This script is actually a combination of some other greasemonkey anti-alert-loop scripts.
// @include        *
// ==/UserScript==

// BUG TODO: We stop further dialogs if the user hit Cancel, which is fine when
// we replace alert, but for the others, the user might have hit Cancel for a
// valid reason.
// Solution: If they hit Cancel on a dialog which would have had a Cancel
// button anyway, then we could ask a second question "Cancel All Alerts?".
// Mmm that's hassle, so we should revert to original system, which detected
// when there were multiple popups!
// TODO: Work off the non-GM version.

var resetTime = 60; // This many seconds after user Cancels alerts, re-enable them.  60 gives you a whole minute to leave the page.  I prefer 10 when I am developing.

// The online version of the script at:
//   http://hwi.ath.cx/javascript/alert_watcher.user.js
// can be embedded into any web-page, to protect users who are not using GreaseMonkey or Mozilla.
// However this version cannot, at least until we shim unsafeWindow.

var init = function()
{
	var nexttime = 0;
	var oldalert = unsafeWindow.alert;
	var oldconfirm = unsafeWindow.confirm;

	var remap = function(func) {
		var oldfunc = unsafeWindow[func];
		if (oldfunc == oldalert) {
			oldfunc = oldconfirm; // So that user can press Cancel when given an alert.
		}
		unsafeWindow[func] = function() {
			var d = new Date();
			var now = d.valueOf();
			if (nexttime <= now) {
				//var result = oldfunc.apply(this,arguments);
				// But in Firefox 24 that was producing: NS_ERROR_XPC_BAD_OP_ON_WN_PROTO: Illegal operation on WrappedNative prototype object
				// And another install said: 'confirm' called on an object that does not implement interface Window
				// So I changed it to:
				//var result = oldfunc.apply(unsafeWindow,arguments);
				// I swear that worked for a while, but then in Firefox 28: Permission denied to access property 'length'
				// Attempting another fix - this seems to work ... for now!
				var result = oldfunc.apply(window,arguments);
				if (!result) {
					nexttime = now + 1000*resetTime;
				}
			}
			return result;
		}
	}

	remap('alert');
	remap('prompt');
	remap('confirm');
}();

