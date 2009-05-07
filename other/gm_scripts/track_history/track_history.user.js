// ==UserScript==
// @name           track_history
// @namespace      noggieb
// @description    Presents a list/tree of the browsing path you took to reach the current page.  Allows you to go to neighbouring link without having to go Back.
// @include        *
// ==/UserScript==

// As well as displaying the tree of other pages, we could display *all* the
// links from the previous page, to allow fast switching.  (Or better: all the
// links with the same xpath?).

// I guess our database could be:
// All documents this session (URL), with a list of all their links (and their
// names+levels!), to which we may add extra links to if we later find an
// unknown link with this as referer.
// That doesn't yet contain tree information, although enough information to
// build it.
// Oh we should really include backlinks - the document.referrer of each URL.

// We could provide the feature that the history thingy will switch between
// the offered links using hidden/shown IFrames, a bit like tags.

// TODO:
// Cleanup old data!
// Curious: How does http://stories.swik.net/jaunty_jackalope_ubuntu_springs_into_beta add images next to the links *after* I have generated them?!
// We keep getting renderered according to the page styles.  We need to disable that, so that we look the same all the time!

// DONE:
// Track secondary (followed) links.




//// General functions ////

function getXPath(node) {
	var parent = node.parentNode;
	if (!parent) {
		return '';
	}
	var siblings = parent.childNodes;
	var totalCount = 0;
	var thisCount = -1;
	for (var i=0;i<siblings.length;i++) {
		var sibling = siblings[i];
		if (sibling.nodeType == node.nodeType) {
			totalCount++;
		}
		if (sibling == node) {
			thisCount = totalCount;
		}
	}
	return getXPath(parent) + '/' + node.nodeName.toLowerCase() + (totalCount>1 ? '[' + thisCount + ']' : '' );
}

function objectToArray(o) {
	var ret = new Array();
	for (var key in o) {
		var value = o[key];
		// GM_log("objectToArray: '"+key+"' -> '"+value+"'");
		ret[ret.length] = value;
	}
	return ret;
}

function getItemsMatching(l,c) {
	if (!l.item && !l.length) {
		// GM_log("Could not process (non-list) "+l+" with condition "+c);
		// return;
		l = objectToArray(l);
	}
	if (l.item) {
		GM_log("getItemsMatching() has actually never been testing with .item()");
	}
	var ret = new Array();
	for (var i=0;i<l.length;i++) {
	// for (var it in l) { // working ok? yes but not for real arrays :P
		var it = ( l.item ? l.item(i) : l[i] );
		// if (it && it.url && Math.random()<0.1)
			// GM_log("  Running condition on "+it.url);
		if (!it) {
			//// TODO: Why is this happening?
			// GM_log("  That is odd - it["+i+"] = "+it);
			continue;
		}
		if (c(it)) {
			ret[ret.length] = it;
		}
	}
	return ret;
}

function getIndexOf(o,l) {
	for (var i=0;i<l.length;i++) {
		if (l[i] == o)
			return i;
	}
	return -1;
}

function makeLinkAbsolute(url) {
	if (url.indexOf("://") >= 0) {
		return url;
	} else {
		var docTop = "" + document.location;
		var i = docTop.lastIndexOf('/');
		if (i>=0) {
			docTop = docTop.substring(0,i+1);
		}
		GM_log("Absolutized "+url+" to "+docTop+url);
		return docTop + url;
	}
}

function stripAnchor(url) {
	return url.replace(/#[^#]*$/,'');
}

function arrayToJSON(a) {
	var out = "[{";
	var first = true;
	for (var key in a) {
		if (first)
			first=false;
		else
			out += ", ";
		out += uneval(key) + ":" + uneval(a[key]);
	}
	out += "}]";
	return out;
}

// function deserialize(name, def) {
	// return eval(GM_getValue(name, (def || '({})')));
// }



function saveData() {
	GM_setValue('g_track_history_data',uneval(data));
	// GM_setValue('g_track_history_data',arrayToJSON(data));
}

function loadData() {
	data = eval(GM_getValue('g_track_history_data'));
	// if (data)
		// data = data[0];
}

function addDataForThisPage() {
	var pageData = new Object();
	pageData.url = ""+document.location; // stripAnchor?
	pageData.title = document.title;
	pageData.links = new Array();
	for (var i=0;i<document.links.length;i++) {
		var link = document.links[i];
		if (link.href.match('^\s*javascript:'))
			continue;
		pageData.links[i] = new Object();
		pageData.links[i].url = makeLinkAbsolute(link.href);
		pageData.links[i].title = link.textContent;
		pageData.links[i].xpath = getXPath(link).replace(/\[[0-9]*\]/g,'');
	}
	data[document.location] = pageData;
}

function clearHistoryData() {
	data = new Object();
	saveData();
}



var html = "";



var data;
loadData();
GM_log("I am here.");
// html += "Loaded data: "+data+"<BR/>\n";
// html += "Loaded data: "+data.length+"<BR/>\n";
// html += "Loaded data: "+uneval(data)+"<BR/>\n";
if (!data) {
	// var data = new Array(); // Fails uneval().  (TOTEST: right?!)
	data = new Object(); // Survives uneval().
}
// html += "Starting data: "+uneval(data)+"<BR/>\n";
// html += "Starting data: "+data.length+"<BR/>\n";

// Add data for this page
addDataForThisPage();

// alert('data.length = '+data.length);

GM_log("Saving...");
saveData();
// html += "Saved data: "+data+"<BR/>\n";
// html += "Saved data: "+uneval(data)+"<BR/>\n";
// html += "Saved data: "+eval(uneval(data)).length+"<BR/>\n";
// loadData(); // Testing
// html += "Reloaded data: "+data+"<BR/>\n";
// html += "Reloaded data: "+uneval(data)+"<BR/>\n";
// html += "Reloaded data: "+eval(uneval(data)).length+"<BR/>\n";
GM_log("Saved.");





function pageContainsLinkTo(pageData,url) {
	// GM_log("Checking "+pageData.links.length+" links...");
	return getItemsMatching(pageData.links, function(link){ /*if (Math.random()<0.01) { GM_log("link="+link+" link.url="+link.url); }*/ return link!=undefined && link.url==url; } ).length > 0;
}

function findPagesContainingLinkTo(url) {
	return getItemsMatching(data, function(pageData){ return pageContainsLinkTo(pageData,url); } );
}

function drawHistoryTree() {
}

function showNeighbours() {
	// Find the page which took us to this page:

	// document.referrer works well, but only for the first display
	// Once the user starts following the links we offer them, document.referrer
	// is no longer relevant!
	/*
	var parentPageData = data[document.referrer];
	if (!parentPageData) {
		html += "Unknown referrer: " + document.referrer + "<BR/>\n";
		return;
	}
	*/

	/*
	for (var i in data) {
		GM_log("data: "+i);
		var pd = data[i];
		GM_log("  length="+pd.links.length);
		for (var j in pd.links) {
			GM_log("  j = "+j);
			GM_log("  l = "+pd.links[j].title);
			break;
		}
	}
	*/

	GM_log("Seeking links to "+document.location);
	var parentPages = findPagesContainingLinkTo(""+document.location);
	GM_log("Got parentPages = "+parentPages);
	GM_log("With length = "+parentPages.length);
	// Remove self!  (There may be links from self to self.)
	parentPages = getItemsMatching(parentPages, function(pageData){ return (!pageData.url) || stripAnchor(pageData.url) != stripAnchor(""+document.location); } );
	if ((!parentPages) || (parentPages.length < 1)) {
		html += "I do not know how we got to this page.<BR/>\n";
		if (document.referrer)
			html += "Referrer was <A href='"+document.referrer+"'>referrer</A>.<BR/>\n";
		return;
	}
	if (parentPages.length > 1) {
		// html += "(One of "+parentPages.length+" options)<BR/>\n";
		html += "Multiple pages link to this: ";
		// for (var pageData in parentPages) { // FAIL
		for (var i=0;i<parentPages.length;i++) {
			var pageData = parentPages[i];
			// html += pageData.title + " ";
			html += "<A href='"+pageData.url+"'>"+pageData.title+"</A>" + " ";
		}
		html += "<BR/><BR/>\n";
	}
	var parentPageData = parentPages[0];

	// Find all links in that page with the same xpath as our link:
	var linksToMe = getItemsMatching(parentPageData.links, function(link){ return link.url == ""+document.location });
	if (linksToMe.length < 1) {
		html += "Could not find myself in " + document.referrer + "!<BR/>\n";
		return;
	}
	var myLink = linksToMe[0];
	var myXPathWas = myLink.xpath;
	var group = getItemsMatching(parentPageData.links, function(link){ return link.xpath == myXPathWas });
	var myIndex = getIndexOf(myLink,group);
	// html += "Got group: "+group+"<BR/>\n";
	html += "<FONT size='+0'>";
	html += (myIndex+1)+" of "+group.length+" from ";
	html += "<A href='"+document.referrer+"'>"+parentPageData.title+"</A>";
	html += "</FONT><BR/>\n";
	html += "<FONT size='-1'>\n";
	// html += "<BLOCKQUOTE>\n";
	html += "<P style='padding-left: 16px;'>\n";
	for (var i=0;i<group.length;i++) {
		var link = group[i];
		if (link.url == ""+document.location)
			html += "<B>"+link.title+"</B>";
		else
			html += "<A href='"+link.url+"'>"+link.title+"</A>";
		html += "<BR/>\n";
	}
	html += "</FONT>\n";
	// html += "</BLOCKQUOTE>\n";
	html += "</P>\n";
}

var historyBlock = document.createElement("DIV");

historyBlock.id = 'historyFloat';
historyBlock.style.position = 'fixed';
historyBlock.style.left = '4px';
historyBlock.style.top = '4px';
historyBlock.style.zIndex = '1000';
// historyBlock.style.setProperty('z-index','1000');
historyBlock.style.border = 'solid 1px black';
historyBlock.style.backgroundColor = 'white';
historyBlock.style.padding = '6px';

showNeighbours();
drawHistoryTree();

// data = eval(GM_getValue("g_track_history_data"));

var clearButton = "<A target='_self' href='javascript:(function(){ clearHistoryData(); })();'>Clear</A>";

html += "<DIV style='text-align: right'>(We have "+objectToArray(data).length+" pages of history. "+clearButton+")</DIV>\n";

html =
	"<FONT size='-1'>"
	+ "<DIV style='float: right; padding-left: 12px;'>"
	+"[<A target='_self' href='javascript:(function(){ var h = document.getElementById(&quot;historyResults&quot;); h.style.display = (h.style && h.style.display?&quot;&quot;:&quot;none&quot;); })();'>-</A>] "
	+"[<A target='_self' href='javascript:(function(){ var h = document.getElementById(&quot;historyFloat&quot;); h.parentNode.removeChild(h); })();'>X</A>]"
	+ "</DIV>\n"
	+ "<DIV id='historyResults'>\n"
	+ html
	+ "</DIV>\n"
	+ "</FONT>\n";

historyBlock.innerHTML = html;

document.body.appendChild(historyBlock);
GM_log("I am NOT HERE.");

// historyBlock.style = 'position: fixed; top: 4px; left: 4px; z-index: 10000; border: solid 1px black; background-color: white; padding: 6px;';

// FAIL
// historyBlock.onclick = 'javascript:alert(self);self.parentNode.removeChild(self);';

top.data = data; // a reference for debugging

