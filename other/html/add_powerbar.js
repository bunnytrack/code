
/* WARNING! This file was auto-generated by jpp.  You probably want to be editing add_powerbar.js.jpp instead. */



// ==UserScript==
// @name           Alert Watcher
// @namespace      alertwatcher
// @description    Watch for possible malicious alert/confirm/prompt loops and allow the user to break out.
// @include        *
// ==/UserScript==

/*

This was originally a userscript, but now it can be loaded into any web page.
Useful if there might be dangerous scripts around!

TODO CONSIDER TEST: If there is a frameset, do we need to traverse the frames
in the frameset?

CONSIDER: Should we advise callers to source us at the beginning or end of the
parent document?  If there is an alert during the first document parse, loading
later would be bad.  But if the document was like powerbar, empty but creating
its own frames by javascript, then wouldn't it be better to load alert_watcher
at the end?

I suspect neither of these problems really exist.  Well maybe it IS a problem
is a script re-writes the page.

*/

var unsafeWindow = window;

var init = function()
{
 var lasttime = 0;
 var nexttime = 0;
 var oldconfirm = unsafeWindow.confirm;

 var remap = function(func) {
  var oldfunc = unsafeWindow[func];
  unsafeWindow[func] = function() {
   var d = new Date();
   var now = d.valueOf();
   if (nexttime <= now) {
    if (!oldconfirm.apply(this,arguments)) {
     nexttime = now + 10000;
    }
   }
  }
 }

 remap('alert');
 remap('prompt');
 remap('confirm');
}();
var exploder = (navigator.appName == "Microsoft Internet Explorer");
var nutscrape = (navigator.appName == "Netscape"); // also what Mozilla reports
var konqueror = (navigator.appName == "Konqueror"); // also what Mozilla reports
// var browserCanRewriteFramesUsingDocumentDotWrite = nutscrape;
 // #define LOG(str) log(str)
 //// Works from within DHTML on<action> thingies.  Actually it doesn't cos they are always in quotes and hence not interpreted, so to do it I have to put "top.log" in the string.  Damn!
 var logText = "";
 function log(str) {
  str = niceDate() + ": " + str;
  logText += str + '\n';
  while (countCharIn(logText,'\n') > 7) {
   // alert("Reducing from: "+logText);
   logText = logText.substring(logText.indexOf('\n')+1);
   // alert("To: "+logText);
  }
  var element;
  try {
   element = top.powerBarFrame.document.getElementById("logElementId");
  } catch (e) {
   alert("Error logging: " + e + "  Log was: \"" + logText + "\"");
  }
  if (element) {
   element.innerHTML = toHtml(logText);
   // element.innerHTML = ( skipEscaping ? logText : toHtml(logText) );
   // element.innerHTML = logText;
   // Attempt at forced refresh:
   /*
			// if (element.style.visibility == "visible") {
				try { // konq:
					element.style = "visibility: hidden";
					element.style.width = 50;
				} catch (e) { // moz:
					element.style.visibility = "visibility: hidden";
				}
			// } else {
				try { // konq:
					element.style = "visibility: visible";
					element.style.width = 20;
				} catch (e) { // moz:
					element.style.visibility = "visibility: visible";
				}
			// }
			*/
  }
 }
/////////////////////////////// Constants ///////////////////////////////
/////////// Options: (will be load/saveable using cookies...) ///////////
var listOfOptions = [ "opt_powerBarPosition", "opt_ButtonsOnPowerBarForms", "opt_ClockEnabled", "opt_JSTesterEnabled", "opt_ViewInnerHtmlButton", "opt_JSReflectorEnabled", "opt_XPathGrabberEnabled" ];
var opt_powerBarPosition = "bottom";
var opt_ButtonsOnPowerBarForms = true;
var opt_ClockEnabled = true;
var opt_JSTesterEnabled = true;
var opt_ViewInnerHtmlButton = true;
var opt_JSReflectorEnabled = true;
var opt_XPathGrabberEnabled = true;
/////////////////////////// Runtime constants ///////////////////////////
var defaultSubmitButton = ( opt_ButtonsOnPowerBarForms ? '<INPUT type="button" value="Go" onclick="submit()">' : "" );
var powerBarFrame; // == powerBarFrame
var mainFrame;
var powerBarWindow;
var powerBarLocationFormElement;
var lastKnownLocation = "";
var todoList = "";
/////////////////////////// Runtime variables ///////////////////////////
//////////////////////// PowerBar initialisation ////////////////////////
 var originalPage = document.documentElement.innerHTML;
 // powerBarFrame = window.frames[0];
 // mainFrame = window.frames[1];
 // generatePowerBar();
// FIXED: If we put this call early, we end up being unable to see processJs. Ok we did top.processJs = processJs. :)
// If we put this call late, we end up being unable to see mainFrame!
powerbar_init();
function createFrameset() {
 var distrib = ( opt_powerBarPosition == "top" ? "50%,50%" : "50%,50%" );
  var startFrameSet = '<frameset rows="' + distrib + '">';
  var powerBarFrameHtml = '<frame src="about:blank">';
  // var mainFrameHtml     = '<frame src="http://www.google.com/">';
  var mainFrameHtml = '<frame src="about:blank">';
  var endFrameSet = '</frameset>';
  var framesetHtml = "";
  framesetHtml += startFrameSet;
  framesetHtml += ( opt_powerBarPosition == "top" ? powerBarFrameHtml : mainFrameHtml );
  framesetHtml += ( opt_powerBarPosition == "bottom" ? powerBarFrameHtml : mainFrameHtml );
  framesetHtml += endFrameSet;
  powerBarWindow = top.window;
  document.writeln(framesetHtml);
 /*
	powerBarWindow.initDone = true;
	powerBarWindow.document.writeln(framesetHtml);
	powerBarWindow.initDone = true;
	*/
 // #ifdef BOOKMARKLET
  // powerBarFrame = document.getElementById("powerBarFrame");
  // mainFrame = document.getElementById("mainFrame");
 // #else
 powerBarFrame = powerBarWindow.frames[ ( opt_powerBarPosition == "top" ? 0 : 1 ) ];
 mainFrame = powerBarWindow.frames[ ( opt_powerBarPosition == "top" ? 1 : 0 ) ];
 top.powerBarFrame = powerBarFrame;
 top.mainFrame = mainFrame;
 // #endif
 if (true) {
   document.log = log;
   top.log = log;
   // These are needed for some calls to log() to work.
   document.niceDate = niceDate;
   document.toHtml = toHtml;
   top.jsReflectorShow = jsReflectorShow;
   powerBarFrame.log = log;
   mainFrame.log = log;
  top.processJs = processJs;
  powerBarFrame.processJs = processJs;
 }
}
// TODO: Move init code for each module to that module and out of here.
//       Have it called automatically, either with reflection, or with "#define"s!
function generatePowerBar() {
 // Note: Since this HTML will sit in a different frame, calls to powerBar's functions and vars must be made with a preceding "top."
 var powerBarHtml = "";
 powerBarHtml += '<table><tr><td valign="top" align="center">';
 //// Location URL textfield:
 //// TODO BUG: These references to top.powerBarFrame fail!
 powerBarHtml += '<FORM name="locationForm" onsubmit="top.changeLocation(top.mainFrame,top.powerBarFrame.locationForm.locationBox.value)" action="javascript:">';
 powerBarHtml += 'Location:\n';
 powerBarHtml += '<INPUT id="locationBox" name="locationBox" type="text" size="30" value="http://www.google.com/">';
 // powerBarHtml += defaultSubmitButton;
 if (opt_ButtonsOnPowerBarForms) {
  powerBarHtml += '<INPUT type="button" value="Go" onclick="top.changeLocation(top.mainFrame,getElementById(\'locationBox\').value)">';
 }
 powerBarHtml += '</FORM>';
 // powerBarHtml += '</td><td valign="top" align="center">';
 if (opt_ViewInnerHtmlButton) {
  // BUG: in Konqueror works on initially-loaded page, but not on Google's page.
  // powerBarHtml += '<INPUT type="button" value="View innerHTML" onclick="try { top.writeToWindow(\'Inner HTML of some page at some point\',top.toHtml(top.mainFrame.document.documentElement.innerHTML)) } catch (e) { top.log(e); }">';
  powerBarHtml += '<INPUT type="button" value="View innerHTML" onclick="top.viewInnerHtml()">';
  powerBarHtml += '<BR>';
 }
 if (opt_XPathGrabberEnabled) {
  powerBarHtml += '<INPUT id="XPathGrabberButton" type="button" value="XPathGrabber" onclick="top.xPathGrabber()">'; // but mozilla needs this too!
  powerBarHtml += '<BR>';
 }
 // powerBarHtml += '</td><td valign="top" align="center">';
 // TODO factorise these forms with their actions duplicated in the buttons etc.
 if (opt_JSReflectorEnabled) {
  // powerBarHtml += '<FORM onsubmit="top.jsReflectorInit()" action="javascript:">'; // but this needed for mozilla
  // powerBarHtml += 'JS reflector:\n';
  powerBarHtml += '<FORM name="jsReflectorForm" onsubmit="top.jsReflectorShow(path.value)" action="javascript:">';
  powerBarHtml += '<INPUT name="path" type="text" size="10" value="top.mainFrame">';
  powerBarHtml += '<INPUT type="button" value="JSReflect" onclick="top.jsReflectorShow(path.value)">';
  // powerBarHtml += '<INPUT type="button" value="JSReflect" onclick="top.jsReflectorInit()">'; // but mozilla needs this too!
  // powerBarHtml += '</FORM>';
  powerBarHtml += '<BR>';
 }
 // Javascript tester textfield:
 if (opt_JSTesterEnabled) {
  // powerBarHtml += '<FORM action="javascript:top.processJs(code.value)">'; // worked fine for konq
  powerBarHtml += '<FORM onsubmit="top.processJs(code.value)" action="javascript:">'; // but this needed for mozilla
  powerBarHtml += 'JavaScript tester:<BR>\n';
  // powerBarHtml += '<INPUT id="codeToExecute" name="code" type="text" size="30" value="type some javascript here">';
  // powerBarHtml += '<TEXTAREA id="codeToExecute" name="code" type="text" columns="20" rows="3">type some javascript here</TEXTAREA>';
  powerBarHtml += '<TEXTAREA id="codeToExecute" name="code" type="text" columns="20" rows="3">Type some javascript here, e.g.: thisbox = top.powerBarFrame.document.getElementsByTagName("textarea")[0]; thisbox.cols=60; thisbox.rows=20; </TEXTAREA>\n';
  powerBarHtml += '<BR>\n';
  // powerBarHtml += '<INPUT type="button" value="Go" onclick="submit()">'; // worked fine for konq
  if (opt_ButtonsOnPowerBarForms) {
   powerBarHtml += '<INPUT type="button" value="Go" onclick="top.processJs(code.value)">'; // but mozilla needs this too!
   powerBarHtml += '<INPUT type="button" value="Unescape" onclick="code.value = unescape(code.value);">';
   powerBarHtml += '<INPUT type="button" value="Escape" onclick="code.value = escape(code.value);">';
  }
  // powerBarHtml += defaultSubmitButton;
  powerBarHtml += '</FORM>';
  powerBarHtml += '<BR>';
 }
 powerBarHtml += '</td><td valign="top" align="center">';
 // Clock:
 if (opt_ClockEnabled) {
  powerBarHtml += '<div id="clockHook">clock loading...</div>';
 }
 // Options button:
 powerBarHtml += '<INPUT type="button" value="Options..." onclick="top.editOptions()">';
 // powerBarHtml += '</td><td valign="top" align="center">'
 // powerBarHtml += '<INPUT type="button" value="Wake up PowerBar!" onclick="top.refreshTimer()">';
  powerBarHtml += '<INPUT type="button" value="Show log" onclick="alert(document.getElementById(\''+"logElementId"+'\').innerHTML)">';
  powerBarHtml += "<P>" + '<font size="-1">PowerBar log:<BR><div id="' + "logElementId" + '"></div></font>';
 powerBarHtml += '</td></tr></table>';
 // powerBarHtml += '<A href="http://www.zvon.org/xxl/JSDOMFactory/index.html">See also</A>';
 writeToFrame(powerBarFrame,powerBarHtml);
 powerBarLocationFormElement = powerBarFrame.document.forms[0];
 // alert("Getting: "+document.getElementById(LOG_ELEMENT_ID));
 // powerBarHtml += '<SCRIPT type="text/javascript"> top.powerBarFrame = window; </script>';
 top.log("generatePowerBar() finished.");
}
var timerId;
function refreshTimer() {
 clearTimeout(timerId);
 timerId = setTimeout('updatePowerBar()',1000);
}
top.initDone = false;
function powerbar_init() {
 if (top.initDone || top.initDone==false) {
  top.log("Blocked second init.");
  alert("Blocked second init.");
  return;
 }
 /*
	var extra = "";
	if (top.document.frames) {
		for (var i=0;i<top.document.frames.length;i++) {
			if (top.document.frames[i]==self) {
				extra += "\nI am frame number "+i;
			}
		}
	}
	extra += "\ninitDone = "+top.initDone;
	alert("[Init] self="+self+" document.location="+document.location + extra);
	*/
 /*for (var frame in document.frames) {*/
 top.initDone = true;
 createFrameset();
 generatePowerBar();
 // TODO: Make this use referer, or last in browser's history, or url provided via CGI, or attach to last used window, or something useful.
 // alert('Writing to frame '+mainFrame);
 // try { console.log('Writing to frame '+mainFrame); } catch (e) { }
 if (originalPage && originalPage!="") {
  writeToFrame(mainFrame,originalPage);
 } else
 writeToFrame(mainFrame,"Welcome to PowerBar."
  + "<P>PowerBar is an addition to your browser to provide much-needed features for web-surfers and web-developers."
  + "  It will allow you to make interactive changes to the pages you read, and create useful filters to aid your surfing."
  + "  It will provide debugging tools for Javascript and the DOM."
  + "<P>New features:"
  + "<BLOCKQUOTE><TL>"
  + "<LI>JavaScript reflector lets you examine JS objects."
  + "<LI>XPath grabber for Mozilla and Konqueror."
  + "</TL></BLOCKQUOTE>"
  + "<P>Planned features:"
  + "<BLOCKQUOTE><TL>"
  + "<LI>Allow user to hide unwanted elements on page with a killer-click (useful to remove bits before printing)."
  + "<LI>Attach to and debug windows which are already running without a PowerBar."
  + "<LI>Make all table cells, blockquotes, and lists foldable."
  + "<LI>Other useful stuff ... eg. sort table by value in row N, hide all images matching REGEXP, highlight words matching REGEXP"
  + "</TL></BLOCKQUOTE>"
  + "<P>Urgent issues:"
  + "<BLOCKQUOTE><TL>"
  + "<LI>Need to port to IE."
  + "<LI>How to I get javascript to talk between windows?"
  + "<LI>Can we stop log freezes in Konqueror?!"
  + "<LI>How do we (ahem) get round security preventing access to pages from other sites?"
  + "</TL></BLOCKQUOTE>"
  + "<A href='javascript: function attachClickListener(node,clickProcessor) { if (node.captureEvents) { node.captureEvents(Event.CLICK); } node.onmouseup = clickProcessor; var kids = node.childNodes; for (var i=0;i<kids.length;i++) { attachClickListener(kids[i],clickProcessor); } } function processClick(event) { var node = event.srcElement; if (!node) { node = event.currentTarget; } node.innerHTML=\"\"; attachClickListener(document,null); } attachClickListener(document,processClick); '>Nuke next item clicked</A>"
 );
 updatePowerBar();
}
///////////////////////////// PowerBar calls /////////////////////////////
function updatePowerBar() {
 top.log("updatePowerBar() called.");
 //// Watch for change of address in mainFrame from user following link, and update location textbox.
 //// Disabled because too sensitive (on init, and even if user is typing!)
 var urlOfMainFrame = mainFrame.location;
 // var urlInTextBox = powerBarFrame.document.forms[0].location;
 try {
  if (powerBarFrame.document.forms["locationForm"]) {
   var urlInTextBox = powerBarFrame.document.forms["locationForm"].locationBox.value;
   // if (urlOfMainFrame != urlInTextBox.value) {
   if (urlOfMainFrame != lastKnownLocation) {
    top.log("URL changed from " + lastKnownLocation + " to " + urlOfMainFrame);
    urlInTextBox.value = urlOfMainFrame; // BUG: doesn't work for Mozilla
    lastKnownLocation = urlOfMainFrame;
   }
  }
  if (opt_ClockEnabled) {
   var clockElem = powerBarFrame.document.getElementById('clockHook');
   clockElem.innerHTML = "" + niceDate();
  }
  processTodoList();
  refreshTimer();
 } catch (e) {
  top.log(e);
 }
}
function processTodoList() {
 while (todoList != "") {
  // powerBarFrame.document.body.innerHTML += "Trying to pop from list:\n" + todoList+"\n\n";
  // alert("Trying to pop from list:\n" + todoList);
  var i = todoList.indexOf("\n");
  var line;
  if (i>=0) {
   line = todoList.substring(0,i);
   todoList = todoList.substring(i+1);
  } else {
   line = todoList;
   todoList = "";
  }
  var result;
  try {
   result = eval(line);
  } catch (e) {
   result = e;
  }
  // alert("processTodoList(): Tried:\n<EVAL>" + line + "</EVAL>\nGot:\n<RESULT>"+result+"</RESULT>");
 }
}
function changeLocation(frame,url) {
 // writeToFrame(frame,'<script type="text/javascript">window.location = "' + url + '";</script>');
 lastKnownLocation = url;
 //// This works, but we have no control over the new DOM!
 // frame.location = url;
 mainFrame.location = url;
 return;
 var tidyUrl = '/cgi-bin/joey/tidy?url=';
 if (new XMLHttpRequest()) {
  // Mozilla:
  var httpRequest = new XMLHttpRequest();
  httpRequest.open('GET', tidyUrl+url, false);
  httpRequest.send(null);
  var xmlDocument = httpRequest.responseXML;
  alert(xmlDocument.documentElement.nodeName)
  // Fails with xmlDocument == null.
 } else if (new ActiveXObject('Microsoft.XMLHTTP')) {
  // Konqueror / IE:
  var httpRequest = new ActiveXObject('Microsoft.XMLHTTP');
  httpRequest.open('GET', tidyUrl+url, false);
  httpRequest.send();
  var xmlDocument = httpRequest.responseXML;
  if (xmlDocument == null)
   top.log("[WARN] "+"Tried to request "+tidyUrl+url+" but got xmlDocument="+xmlDocument);
  else
   alert("Got xmlDocument = "+xmlDocument.documentElement.nodeName);
 }
 refreshTimer();
}
//////////////////////////// PowerBar modules ////////////////////////////
//////////////////////////// Module: Options
function componentTypeForJSType(jsType) {
 return (
  jsType == "boolean" ? "checkbox" :
  jsType == "string" ? "text" :
  jsType == "number" ? "text" :
  "button"
 );
}
function editOptions() {
 var html = "";
 html += "<FORM action='javascript:top.generatePowerBar()'>";
 for (var i=0;i<listOfOptions.length;i++) {
  var option = listOfOptions[i];
  var value = eval(option);
  var type = typeof(value);
  var componentType = componentTypeForJSType(type);
  var componentValueBit = ( type == "boolean" ? (value ? "checked" : "")
                                              : "value='" + value + "'" );
  var componentAction = ( type == "boolean" ? "onclick='top."+option+"=status; top.log(\"\"+top."+option+");'"
                                            : "onblur='top."+option+"=value; top.log(\"\"+top."+option+");'" ); // top.submitOptions(this);
  html += "Option \""+option+"\": ";
  html += '<INPUT id="' + option + '" name="' + option + '" type="' + componentType + '" ' + componentValueBit + ' ' + componentAction + '>';
  html += "<BR>";
  // html += "option "+option+" has value = "+value+" and type "+type+"<BR>";
 }
 html += "<INPUT type='submit' value='OK'>";
 html += "</FORM>";
 writeToFrame(mainFrame,html);
}
// var thingy;
// function submitOptions(thing) {
 // thingy = thing;
 // alert("Got a thing: " + tryeval(thing) + " of type=" + trytypeof(thing));
 // jsReflectorShow("top.thingy");
 generatePowerBar();
// }
//////////////////////////// Module: JavaScript tester
function processJs(codeToExecute) {
 var result;
 try {
  result = eval(codeToExecute);
 } catch (e) {
  result = e;
 }
 /* var report = "I executed\n<CODE>" + codeToExecute + "</CODE>\nand got\n<RESULT>" + result + "</RESULT>"; */
 var report = result;
 var htmlReport = toHtml(report);
  top.log(report);
 refreshTimer();
}
//////////////////////////// Module: JavaScript reflector
var jsReflectorHistory = new Array();
function jsReflectorInit() {
 jsReflectorShow("top.powerBarFrame");
}
// TODO: popup reflector in a separate window
function jsReflectorShow(objName) {
 if (!arrayContains(jsReflectorHistory,objName)) {
  jsReflectorHistory.push(objName);
 }
 top.log("jsReflectorShow(\"" + objName + "\");");
 try {
  var obj = tryeval(objName);
  var html = "";
  html += "Go back to: ";
  for (var i=0;i<jsReflectorHistory.length;i++) {
   var prevObjName = jsReflectorHistory[i];
   html += "<a href='javascript:opener.jsReflectorShow(\"" + prevObjName + "\")'>" + prevObjName + "</a>";
   if (i < jsReflectorHistory.length - 1) {
    html += ", ";
   }
  }
  // var editableObjName = "<INPUT type='text' size='30' value='" + objName + "' onblur='javascript:if (value!=defaultValue) { top.jsReflectorShow(value) }'>";
  /** BUG TESTING: apostrophes in the input get lost.  should be fixed now but i left < and > unescaped :P **/
  var editableObjName = "<INPUT type='text' size='30' value='" + objName.replace(/'/g,'&apos;') + "' onchange='javascript:if (value!=defaultValue) { top.jsReflectorShow(value) }'>";
  html += "<h3>Inspecting: " + trytypeof(obj) + " " + editableObjName + " = " + obj + "</h3>";
  // Ripped off the web, testing here:
  var i = 0;
  var list = "";
  var fnlist = "";
  for (var name in obj) { // BUG: Mozilla doesn't find the "document" in window objects!
   var globName = objName + "." + name;
   var value = "<neverset>";
   var type = "<neverset>";
   try {
    // TODO: mmm silly me, isn't this exactly the same as obj[name] ?
    value = eval("obj." + name);
    type = trytypeof(value);
    // We need to ensure it can be evaluated as a string or it might fail when added to HTML later:
    value = "" + value;
   } catch (e) {
    value = "<unattainable> (" + e + ")";
   }
   if (type=='function') {
    // fnlist += " "+name;
    // DONE We need partial escaping, not CGI, but to hide '"'s '<'s '>'s etc.
    // fnlist += " <SPAN title=\""+escape(value)+"\">"+name+"</SPAN>";
    // PFF powerbar is quite smelly - we could be using span.title :P
    fnlist += " <SPAN title=\""+value.replace(/"/g,'&quot;').replace(/</g,'&lt;').replace(/>/g,'&gt;')+"\">"+name+"</SPAN>";
    continue;
   }
   var link = 'javascript:opener.jsReflectorShow("' + globName + '")';
   list += "<tr>";
   list += "<td align='right'>" + type + "&nbsp;</td>";
   list += "<td align='center'><a href='" + link + "'>" + name + "</a></td>";
   // list += "<td align='left'>&nbsp;=&nbsp;" + toHtml(strip(value)) + "</td>";
   list += "<td align='left'>&nbsp;=&nbsp;" + toHtml(strip(value).replace(/\n/g,' ')) + "</td>";
   list += "</tr>";
   list += "\n"; // for sortLines
  }
  list = sortLines(list);
  if (fnlist != "")
   list = "Functions: " + fnlist + "<P/>\n" + list;
  // html += "<blockquote>";
  html += "<table cellpadding='0' cellspacing='0'>";
  html += list;
  html += "</table>";
  // html += "</blockquote>";
   // writeToFrame(mainFrame,html);
   writeToFrame(powerBarFrame,html);
 } catch (e) {
  top.log(e);
 }
}
//////////////////////////// Module: XPath grabber
var cnt;
function xPathGrabber() {
 cnt = 0;
 try {
  onAllNodesDo(top.mainFrame.document,"",attachClickListener,doNothing); // not working! hence showShapeOld
 } catch (e) {
  top.log("Problem during onAllNodesDo(): " + e);
 }
 top.log("Added XPath click capture to " + cnt + " nodes.");
}
function attachClickListener(context,node) {
 // if (node.childNodes.length == 0) {
 if (node.captureEvents) {
  node.captureEvents(Event.CLICK); // only Moz needs this
 }
 node.onmouseup = processClick;
 cnt++;
 // node.onmouseup = 'alert("Node " + this + " has XPath = " + getXPath(this));';
 // }
}
// var eventObj;
var lastXPath = "";
// This gets called for every node below the mouse, not just the first one!
function processClick(evt) {
 var node = evt.srcElement;
 if (!node) {
  node = evt.currentTarget;
 }
 var xpath = getXPath(node);
 if (lastXPath.substring(0,xpath.length) == xpath) {
  return;
 } else {
  lastXPath = xpath;
 }
 // alert("Node " + node + " has " + node.childNodes.length + " kids and XPath:\n" + getXPath(node));
 // LOG(getXPath(node) + ": \"" + toHtml(node.)));
 var col = randomColour();
 // log("XPath: <font color='"+col+"'>" + getXPath(node) + "</font>");
 log("XPath: " + getXPath(node));
 if (node.style) {
  try {
   node.style.backgroundColor = col;
  } catch (e) {
   top.log(e);
  }
 }
 // evt.currentTarget.onmouseup = "";
 // eventObj = node;
 // jsReflectorShow("top.eventObj");
}
function getXPath(node) {
 var parent = node.parentNode;
 if (!parent) {
  return "";
 }
 var siblings = parent.childNodes;
 var totalCount = 0;
 var thisCount = -1;
 for (var i=0;i<siblings.length;i++) {
  var sibling = siblings[i];
  if (sibling.tagName == node.tagName) {
   totalCount++;
  }
  if (sibling == node) {
   thisCount = totalCount;
  }
 }
 //// Extended info xpath: could also show name, id, other attribs if present:
 // return getXPath(parent) + "/" + node.nodeName + "[" + thisCount + "/" + totalCount + "]";
 //// Pure xpath:
 // return getXPath(parent) + "/" + node.nodeName + "[" + thisCount + "]";
 //// Neat when it can be:
 return getXPath(parent) + "/" + node.nodeName.toLowerCase() + (totalCount>1 ? "[" + thisCount + "]" : "" );
}
//////////////////////////// Module: View inner HTML
function viewInnerHtml() {
 var targetPath = "top.mainFrame.document.documentElement.innerHTML";
 try {
  top.log("viewInnerHtml() called");
  var innerHTML = eval(targetPath);
  top.log("Got innerHTML length " + innerHTML.length);
  var toHtml = top.toHtml(innerHTML);
  top.log("Got toHtml length " + toHtml.length);
  top.writeToWindow('Inner HTML of some page at some point',toHtml);
  top.log("Wrote to window");
 } catch (e) {
  top.log(e);
  whereDoesPathBreak(targetPath);
 }
}
/////////////////////////// Library functions ///////////////////////////
function writeToFrame(frame,html) {
 top.log("Writing "+html.length+" bytes to "+frame+" "+frame.id);
 // if (frame.document.open()) {
  frame.document.open();
  frame.document.write("<html><body>"); // you used to need /some/ kind of surrounding tag if you are just writing text
  frame.document.write(html);
  frame.document.write("</body></html>"); // these tags seemed sensible to me
  frame.document.close();
 /*if (top.functions.length > */
 // } else {
  // try {
   // frame.location = "about:blank";
  // } catch (e) {
   // alert("Setting "+frame+".location to blank threw: "+e);
  // }
  // frame.document.body.innerHTML = html;
 // }
}
function writeToWindow(title,contents,options) {
 // var w = window.open('about:blank','jsReflector','menubar,resizable,scrollbars,width=800,height=600');
 //// 'about:blank' causes Konqueror to empty window after writing the yummy stuff, so...
 if (!options) {
  options = 'menubar,resizable,scrollbars,width=800,height=600';
 }
 var w = window.open('',title,options);
 // Dammit something goes wrong here with Konqueror if it is put in mode (open new windows in new tab)
 writeToFrame(w,contents);
 // w.document.writeln('<b>Generated XPath of selected HTML Element:</b><br>');
 // w.document.open();
 // w.document.write("<HTML><BODY>");
 // w.document.write(contents);
 // w.document.write("</BODY></HTML>");
 // w.document.close();
 w.focus();
 w.jsReflectorShow = new Function(top.jsReflectorShow);
 /*w.processJs = new Function(top.processJs);*/
 if (w.opener == null) // for older browsers, tell the child window we are the parent:
  w.opener = self;
}
function escapeString(text) {
 var map = new Array(); // TODO: more!
 map['\n'] = "\\n";
 map['\t'] = "\\t";
 map['\"'] = "\\\"";
 map['\\'] = "\\\\";
 var str = "";
 for (var i=0;i<text.length;i++) {
  var c = text.charAt(i);
  str += ( map[c] ? map[c] : c );
 }
 return str;
}
function toHtml(text) {
 var map = new Array(); // TODO: more!
 map['\n'] = "<BR>";
 map[' '] = "&nbsp;";
 map['\"'] = "&quot;";
 map['<'] = "&lt;";
 map['>'] = "&gt;";
 var html = "";
 for (var i=0;i<text.length;i++) {
  var c = text.charAt(i);
  html += ( map[c] ? map[c] : c );
 }
 return html;
}
function countCharIn(str,srch) {
 var cnt = 0;
 for (var i=0;i<str.length;i++) {
  if (str.charAt(i) == srch)
   cnt++;
 }
 return cnt;
}
function niceDate() {
 var now = "" + new Date();
 var bits = splitAt(now," ");
 return bits[1] + " " + bits[2] + " " + bits[4];
}
function strip(str) {
 if (str.length > 100) {
  return str.substring(0,100 - 3) + "...";
 }
 return str;
}
function trytypeof(obj) {
 try {
  var type = typeof(obj);
  return type;
 } catch (e) {
  return "TYPE_ERROR: "+e;
 }
}
function tryeval(code) {
 try {
  var res = eval(code);
  return res;
 } catch (e) {
  return "EVAL_ERROR: "+e;
 }
}
function splitAt(str,srch) {
 var list = new Array();
 var i = 0;
 while (true) {
  var j = str.indexOf(srch);
  if (j < 0)
   break;
  list[i] = str.substring(0,j);
  str = str.substring(j + 1);
  i++;
 }
 list[i] = str;
 return list;
}
function sortLines(linesStr) {
 var lines = splitAt(linesStr,'\n');
 lines = lines.sort();
 return lines.join("\n");
 /*
	var lines = splitAt(linesStr,'\n');
	linesStr = ""; // can wait till later but why not save memory?!
	// bubblesort
	for (var start = 0; start<lines.length; start++) {
		for (var i = 0; i<lines.length - 1; i++) {
			// if (lines[i] > lines[i + 1]) {
			// if (lines[i].compareTo(lines[i + 1]) > 0) {
			// if (false) {
			if (!areOrderedStrings(lines[i],lines[i + 1])) {
				// alert("Swapping " + i + " and " + (i + 1) + "." );
				var tmp = lines[i];
				lines[i] = lines[i + 1];
				lines[i + 1] = tmp;
			}
		}
	}
	for (var i = 0; i<lines.length; i++) {
		linesStr += lines[i] + '\n';
	}
	return linesStr;
	*/
}
function areOrderedStrings(a,b) { // is a <= b ?
 return (a.localeCompare(b) >= 0);
 /*
	for (var i=0;i<a.length;i++) {
		// all chars so far have been identical
		if (i >= b.length) return false;
		if (a.charAt(i) < b.charAt(i)) return true;
		if (a.charAt(i) > b.charAt(i)) return false;
	}
	return true; // b is either identical or longer
	*/
}
// From starfield3dj10.html:
function doNothing(context,node) {
 return context;
}
// Note: possible difference in implementation: if context is always going to be a reference to an object (as opposed to a primitive), then it needn't be passed back by the action functions.
function onAllNodesDo(node,context,actionBefore,actionAfter) {
 // TODO: if context is observably null, then needn't pass to actionBefore/After (which in turn shouldn't/needn't accept it).  Note change to doNothing required too!
 context = actionBefore(context,node);
 var kids = node.childNodes;
 for (var i=0;i<kids.length;i++) {
  var k = kids[i];
  context = onAllNodesDo(k,context,actionBefore,actionAfter);
 }
 context = actionAfter(context,node);
 return context;
}
function randomColour() {
 var hex = "0123456789abcdef";
 var col = "#";
 for (var i=0;i<6;i++) {
  col += hex.charAt(Math.random()*16);
 }
 return col;
}
function arrayContains(array,item) {
 for (var i=0;i<array.length;i++) {
  if (array[i] == item) {
   return true;
  }
 }
 return false;
}
function whereDoesPathBreak(path) {
 var i = -1;
 while (true) {
  var oldi = i;
  i = path.indexOf(".",i+1);
  if (i == oldi || i == -1)
   break;
  var testPath = path.substring(0,i);
  try {
   var result = eval(testPath);
   var works = "works: " + result;
   top.log(testPath + " returned: " + result);
  } catch (e) {
   top.log(testPath + " failed with \"" + e + "\"!");
   alert(testPath + " failed with \"" + e + "\"!");
   break;
   // ...
  }
 }
}
top.powerbar_init = powerbar_init;
