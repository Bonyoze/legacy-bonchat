return [[<html>
  <head>
    <meta charset="utf-8">
    <style>
      html {
        font-size: 14px;
        -webkit-user-select: none;
        user-select: none;
      }

      body {
        margin: 0;
        overflow: hidden;
        font-family: Verdana;
        font-size: 1rem;
        line-height: 1.375rem;
        text-shadow: 1px 1px 1px #000, 1px 1px 2px #000;
        opacity: 0.9999;
      }

      #text-entry {
        position: fixed;
        padding: 4px;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0,0,0,0.5);
        border-radius: 4px;
      }
      #entry-button {
        float: right;
        margin-left: 2px;
        width: 1.375rem;
        height: 1.375rem;
        cursor: pointer;
      }
      #entry-input {
        resize: none;
        overflow: hidden;
        outline: none;
        color: #fff;
        white-space: nowrap;
        -webkit-user-select: text;
        user-select: text;
      }
      #entry-input[placeholder]:empty:before {
        content: attr(placeholder);
        cursor: text;
        position: absolute;
        opacity: 0.65;
      }

      #attachment-container {
        position: absolute;
        height: auto;
        bottom: 0;
        top: 0;
        left: 0;
        right: 0;
        margin-bottom: 30px;
        overflow-x: hidden;
        overflow-y: scroll;
      }
      #attachment-container::-webkit-scrollbar {
        width: 8px;
      }
      #attachment-container::-webkit-scrollbar-track {
        background: rgba(0,0,0,0.5);
        border-radius: 4px;
      }
      #attachment-container::-webkit-scrollbar-thumb {
        background: rgb(30,30,30);
        border-radius: 4px;
      }

      .attachment {
        margin-right: 4px;
        margin-bottom: 4px;
        padding: 4px;
        background-color: rgba(0,0,0,0.2);
        border-radius: 4px;
        overflow: hidden;
      }
      .attachment-button {
        float: right;
        margin-left: 2px;
        width: 1.375rem;
        height: 1.375rem;
        cursor: pointer;
      }
      .attachment-title {
        overflow: hidden;
        font-weight: bold;
      }
      .attachment-label {
        margin-top: 4px;
        padding: 4px;
        background-color: rgba(0,0,0,0.5);
        border-radius: 4px;
        color: #fff;
      }
      .attachment.failed .attachment-title::before {
        color: #f00;
        content: "Invalid input";
      }
      .attachment:not(.failed) .attachment-title::before {
        color: #0f0;
        content: "Successfully added";
      }
      .attachment:not(.failed) .attachment-label {
        overflow: hidden;
        color: #00aff4;
        white-space: nowrap;
        cursor: pointer;
      }
      .attachment:not(.failed) .attachment-label:hover {
        text-decoration: underline;
      }
    </style>
  </head>
  <body>
    <div id="attachment-container"></div>
    <div id="text-entry">
      <img id="entry-button" src="asset://garrysmod/materials/icon16/tick.png">
      <div contenteditable id="entry-input" spellcheck="false" oninput="if (this.innerHTML.trim() === '<br>') this.innerHTML = ''"></div>
    </div>
  </body>
  <script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/jquery.js"></script>
  <script> // main script
    const entryButton = $("#entry-button"),
    entryInput = $("#entry-input"),
    attachmentContainer = $("#attachment-container");

    // strings for elements whose text is updated by js
    const ENTRY_PLACEHOLDER_TEXT = "Add an attachment";

    const ENTRY_MAX_INPUT = 128;

    var hoverLabelTimeout = null;

    function isFullyScrolled() {
      var e = categoryContainer.get(0);
      return Math.abs(e.scrollHeight - e.clientHeight - e.scrollTop) < 1;
    }

    function scrollToBottom() {
      var e = categoryContainer.get(0);
      e.scrollTop = e.scrollHeight;
    }

    function Attachment(id, str) {
      this.ATTACHMENT_WRAPPER = $("<div class='attachment' data-id='" + id + "'>").appendTo(attachmentContainer);
      this.ATTACHMENT_BUTTON = $("<img class='attachment-button' src='asset://garrysmod/materials/icon16/cancel.png'>").appendTo(this.ATTACHMENT_WRAPPER);
      this.ATTACHMENT_TITLE = $("<div class='attachment-title'>").appendTo(this.ATTACHMENT_WRAPPER);
      this.ATTACHMENT_LABEL = $("<div class='attachment-label'>").text(str).attr("href", str).appendTo(this.ATTACHMENT_WRAPPER);

      var wrapper = this.ATTACHMENT_WRAPPER;

      wrapper.data("id", id);

      if (str.match(/^(https?:\/\/[^\s<]+[^<.,:;"')\]\s])/)) { // is valid link
        glua.readyAttachment(id, str);
      } else {
        wrapper.addClass("failed");
      }
    }

    function getAttachmentByID(id) {
      return $(".attachment[data-id='" + id + "']", attachmentContainer);
    }

    function submitEntry() {
      glua.addAttachment(getText());
      entryInput // reset entry input
        .attr("placeholder", ENTRY_PLACEHOLDER_TEXT)
        .text("")
        .focus();
    }

    function getUTF8ByteLength(str) {
      var s = str.length;
      for (var i = str.length - 1; i >= 0; i--) {
        var code = str.charCodeAt(i);
        if (code > 0x7f && code <= 0x7ff) s++;
        else if (code > 0x7ff && code <= 0xffff) s += 2;
        if (code >= 0xdc00 && code <= 0xdfff) i--; // trail surrogate
      }
      return s;
    }

    // get clean text from entry
    function getText() {
      return entryInput.text().replace(/\u00A0/g, " "); // converts nbsp characters to spaces
    }

    // append text into the input safely
    function insertText(text) {
      text = text.replace(/[\u000a\u000d\u2028\u2029\u0009]/g, ""); // prevent new lines and tab spaces
      var len = text.length,
      maxLen = ENTRY_MAX_INPUT - getUTF8ByteLength(getText()) + getUTF8ByteLength(document.getSelection().toString());
      if (len > maxLen) {
        text = text.substring(0, maxLen); // make sure it won't exceed the char limit
        glua.playSound("resource/warning.wav");
      }
      if (text) {
        document.execCommand("insertText", false, text);
        entryInput.scrollLeft(entryInput.get(0).scrollWidth);
      }
    }

    function startHoverLabel(text) {
      hoverLabelTimeout = setTimeout(function() {
        glua.showHoverLabel(text);
      }, 1000);
    }

    entryButton.on("click", submitEntry);

    entryInput
      .attr("placeholder", ENTRY_PLACEHOLDER_TEXT)
      .focus()
      .on("keydown", function(e) { // prevent default tab functionality
        if (e.which == 9) e.preventDefault();
      })
      .on("keypress", function(e) {
        if (e.which == 13) {
          submitEntry(); // submit on enter
          return false;
        }

        // prevent registering certain keys and exceeding the char limit
        return !e.ctrlKey && !e.metaKey && !e.altKey && e.which != 8 && getUTF8ByteLength(getText() + String.fromCharCode(e.which)) < ENTRY_MAX_INPUT;
      })
      .on("paste", function(e) {
        // handle pasting text and images
        e.preventDefault();

        var items = e.originalEvent.clipboardData.items;
        if (!items) return;

        var foundText, foundImage;

        for (var i = 0; i < items.length; i++) {
          var item = items[i];

          if (!foundText && item.kind == "string" && item.type.match("^text/plain")) {
            foundText = true;
            item.getAsString(insertText);
          } else if (!foundImage && item.kind == "file" && item.type.match("^image/")) {
            foundImage = true;
            var file = item.getAsFile(),
            reader = new FileReader();

            reader.onloadend = function() { // this only works in Chromium branch due to a bug in the version used by Awesomium
              var bStr = reader.result; // this will return an empty string if not on Chromium branch
              if (bStr) glua.pasteImage(btoa(bStr));
            };
            reader.readAsBinaryString(file);
          }

          if (foundText && foundImage) break;
        }
      });

    $(document)
      .on("click", function(e) {
        var elem = $(e.target);

        switch (true) {
          case elem.hasClass("attachment-button"):  // remove the attachment
            glua.removeAttachment(elem.parent().data("id"));
            break;
          case elem.hasClass("attachment-label") && elem.parents(".attachment:not(.failed)").length != 0:
            glua.openPage(elem.attr("href"));
            break;
        }
        
        entryInput.focus();
      })
      .on("mouseover", function(e) {
        var elem = $(e.target);

        // show hover label
        if (elem.is(entryButton)) { // entry button text
          startHoverLabel("Add an attachment");
        } else if (elem.is(".emoji")) { // emoji text
          var shortcode = elem.data("shortcode")
          entryInput.attr("placeholder", shortcode); // show shortcode in entry placeholder
          startHoverLabel(shortcode);
        }
      })
      .on("mouseout", function() {
        // reset hover label
        clearTimeout(hoverLabelTimeout);
        glua.hideHoverLabel();
      });
    
    entryInput.focus();
  </script>
</html>]]