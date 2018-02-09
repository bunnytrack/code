// ==UserScript==
// @name         npmjs.com visual tweaks
// @namespace    http://tampermonkey.net/
// @version      0.6.1
// @description  Styles npmjs.com README pages similarly to GitHub's (font, size, colors, but not syntax highlighting), and makes the content wider
// @author       joeytwiddle
// @copyright    2018, Paul "Joey" Clark (http://neuralyte.org/~joey)
// @license      MIT
// @match        https://www.npmjs.com/*
// @grant        GM_addStyle
// ==/UserScript==

// Motivation: I didn't like the visual context switching between reading Github READMEs and npm READMEs, so I made READMEs on npm look similar to READMEs on Github.

(function() {
    'use strict';

    // I want to scale down the fonts and everything else a bit.  This was an easy way to do that.
    GM_addStyle('.container { transform: scale(0.92); transform-origin: 50% 0; }');

    // Fill (almost) the whole width of the screen, like Wide-Github does.
    GM_addStyle('.container { width: 98%; max-width: 100%; }');

    // Set fonts like GitHub
    GM_addStyle('#readme { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Source Sans Pro", "Lucida Grande", sans-serif; }');
    GM_addStyle('#readme { font-family: line-height: 1.5;}');
    GM_addStyle('pre, code, kbd, samp { font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, Courier, monospace; }');

    // Set font sizes like GitHub
    // A snippet of code appearing within a paragraph
    GM_addStyle('code { font-size: 88%; }');
    // A line of code on its own
    GM_addStyle('pre > code { font-size: 100%; }');
    // A block of code
    GM_addStyle('pre { font-size: 82%; line-height: 1.4; }');

    // Darker text
    GM_addStyle('.markdown p, .markdown li, code { color: rgb(51, 51, 51); }');

    // Padding around code blocks and snippets
    // A snippet of code appearing within a paragraph
    GM_addStyle('code { padding: 0.2em 0.2em; }');
    // A line of code on its own
    GM_addStyle('pre > code { padding: 1em 2em; }');

    // Lighter background on code blocks and snippets
    GM_addStyle('.highlight, code { background-color: #f6f8fa; }');

    // More of a gap after each paragraph?  Wasn't actually needed.  The problem was wrapping due to insufficient width.
    //GM_addStyle('div, .highlight { padding-bottom: 20px; }');

    // Thicker font for section headers
    GM_addStyle('.markdown h1, .markdown h2, .markdown h3, .markdown h4, .markdown h5, .markdown h6 { font-weight: 600; }');

    // Use the npm font for section headers, even though we aren't using it for main text.  (This is a divergence from Github's markdown scheme.)
    //GM_addStyle(".markdown h1, .markdown h2, .markdown h3, .markdown h4, .markdown h5, .markdown h6 { font-family: 'Source Sans Pro', 'Lucida Grande', sans-serif; }");
})();