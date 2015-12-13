// ==UserScript==
// @name           Download YouTube Captions
// @namespace      DYTC
// @description    Lets you download the captions of a YouTube video in SRT or TXT format, if they exist.
// @include        http://*youtube.com/watch*
// @include        https://*youtube.com/watch*
// @author         Tim Smart, gw111zz, joeytwiddle
// @copyright      2009 Tim Smart; 2011 gw111zz; 2015 joeytwiddle
// @license        GNU GPL v3.0 or later. http://www.gnu.org/copyleft/gpl.html
// @version        1.0.2
// @grant          GM_xmlhttpRequest
// @grant          GM_openInTab
// @grant          GM_addStyle
// ==/UserScript==

// TODO: Auto-update when video changes.

var PLAYER              = unsafeWindow.document.getElementById('movie_player'),
    VIDEO_ID            = unsafeWindow.yt.getConfig('VIDEO_ID'),
    TITLE               = unsafeWindow.ytplayer.config.args.title,
    FORMATS             = {srt: '.srt', text: 'text'},
    FORMAT_SELECTOR_ID  = 'format_selector',
    caption_array = [];

var makeTimeline = function (time) {
  var string,
      time_array   = [],
      milliseconds = Math.round(time % 1 * 1000).toString();

  while (3 > milliseconds.length) {
    milliseconds = '0' + milliseconds;
  }

  time_array.push(Math.floor(time / (60 * 60)));
  time_array.push(Math.floor((time - (time_array[0] * 60 * 60)) / 60));
  time_array.push(Math.floor(time - ((time_array[1] * 60) + (time_array[0] * 60 * 60))));

  for (var i = 0, il = time_array.length; i < il; i++) {
    string = '' + time_array[i];

    if (1 === string.length) {
      time_array[i] = '0' + string;
    }
  }

  return time_array.join(":") + "," + milliseconds;
}

function loadCaption (selector) {
  var caption = caption_array[selector.selectedIndex - 1];

  if (!caption) return;

  GM_xmlhttpRequest({
    method: 'GET',
    url: 'http://video.google.com/timedtext?hl=' + caption.lang_code +
         '&lang=' + caption.lang_code + '&name=' + caption.name + '&v=' + VIDEO_ID,
    onload:function(xhr) {
      if (xhr.responseText !== "") {
        var caption, previous_start, start, end,
            captions      = new DOMParser().parseFromString(xhr.responseText, "text/xml").getElementsByTagName('text'),
            textarea      = document.createElement("textarea"),
            output_format = FORMATS[document.getElementById(FORMAT_SELECTOR_ID).value] || FORMATS['srt'],
            srt_output    = ''; 

        for (var i = 0, il = captions.length; i < il; i++) {
          caption = captions[i];
          start   = +caption.getAttribute('start');

          if (0 <= previous_start) {
            textarea.innerHTML = captions[i - 1].textContent.replace(/</g, "&lt;").
                                                             replace( />/g, "&gt;" );
            if (output_format === FORMATS['text']) {
              srt_output += textarea.value + "\n";
            } else {
              srt_output += (i + 1) + "\n" + makeTimeline(previous_start) + ' --> ' +
                            makeTimeline(start) + "\n" + textarea.value + "\n\n";
            }
            previous_start = null;
          }

          if (end = +caption.getAttribute('dur')) {
            end = start + end;
          } else {
            if (captions[i + 1]) {
              previous_start = start;
              continue;
            }
            end = PLAYER.getDuration();
          }

          textarea.innerHTML = caption.textContent.replace(/</g, "&lt;").replace(/>/g, "&gt;");
          if (output_format === FORMATS['text']) {  
            srt_output += textarea.value + "\n";
          } else {
            srt_output   += (i + 1) + "\n" + makeTimeline(start) + ' --> ' +
                                makeTimeline(end) + "\n" + textarea.value + "\n\n";
          }
        }

        textarea = null;

        GM_openInTab("data:text/srt;charset=utf-8," + encodeURIComponent(srt_output));
      } else {
        alert("Error: No response from server.");
      }

      selector.options[0].selected = true;

    }
  });
}

function loadCaptions (select) {
  GM_xmlhttpRequest({
    method: 'GET',
    url:    'http://video.google.com/timedtext?hl=en&v=' + VIDEO_ID + '&type=list',
    onload: function( xhr ) {

      var caption, option, caption_info,
          captions = new DOMParser().parseFromString(xhr.responseText, "text/xml").
                                     getElementsByTagName('track');
                                
      if (captions.length === 0) {
        if (select) {
          select.options[0].textContent = '---';
          select.disabled = true;
        }
        select = document.getElementById(FORMAT_SELECTOR_ID);
        if (select) {
          select.options[0].textContent = '---';
          select.disabled = true;
        }
        return;
      }

      for (var i = 0, il = captions.length; i < il; i++) {
        caption      = captions[i];
        option       = document.createElement('option');
        caption_info = {
          name:      caption.getAttribute('name'),
          lang_code: caption.getAttribute('lang_code'),
          lang_name: caption.getAttribute('lang_translated')
        };

        caption_array.push(caption_info);
        option.textContent = caption_info.lang_name;

        select.appendChild(option);
      }

      select.options[0].textContent = 'Lang';
      select.disabled               = false;

      // I have three userscripts that add buttons to this div:
      // - Download_YouTube_Captions (this one)
      // - Download_YouTube_Videos_as_MP4
      // - YouTube_Popout_Button
      // When all of them are together, they are too wide!
      // But if we reduce the padding from the site's 10px to 8px, then they all fit nicely.
      GM_addStyle(".yt-uix-button { padding: 0 8px; }");
    }
  });
}

function loadFormats (select) {
  var type

  for (type in FORMATS) {
    option             = document.createElement('option');
    option.value       = type;
    option.textContent = FORMATS[type];

    select.appendChild(option);
  }

  select.options[0].textContent = 'Format';
  select.disabled               = false;
}

(function () {
  var div      = document.createElement('div'),
      select   = document.createElement('select'),
      option   = document.createElement('option'),
      controls = document.getElementById('watch8-secondary-actions') || document.getElementsByClassName("watch-secondary-actions")[0] || document.getElementById('watch8-action-buttons') || document.getElementsByClassName("watch-action-buttons")[0] || document.getElementById('watch7-headline');

  div.setAttribute( 'style', 'display: inline-block; margin: 6px;' );

  select.id       = 'captions_selector';
  select.disabled = true;

  option.textContent = 'Loading...';
  option.selected    = true;

  select.appendChild(option);
  select.addEventListener('change', function() {
    loadCaption(this);
  }, false);

  div.appendChild(select);


  var format_div       = document.createElement('div'),
      format_select    = document.createElement('select'),
      format_option    = document.createElement('option');

  format_div.setAttribute('style', 'display: inline-block; margin: 6px;');

  format_select.id         = FORMAT_SELECTOR_ID;
  format_select.disabled   = true;

  format_option.textContent    = 'Loading...';
  format_option.selected       = true;

  format_select.appendChild(format_option);

  format_div.appendChild(format_select);

  //controls.appendChild(format_div);
  //controls.appendChild(div);
  var insertBeforeElement = controls.getElementsByClassName('yt-uix-menu')[0] || div.firstChild;
  controls.insertBefore(format_div, insertBeforeElement);
  controls.insertBefore(div, insertBeforeElement);

  loadFormats(format_select);
  loadCaptions(select);
})();

