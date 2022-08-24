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
        top: 0;
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

      #category-container {
        position: absolute;
        height: auto;
        bottom: 0;
        top: 0;
        left: 0;
        right: 0;
        margin-top: 30px;
        overflow-x: hidden;
        overflow-y: scroll;
      }
      #category-container::-webkit-scrollbar {
        width: 8px;
      }
      #category-container::-webkit-scrollbar-track {
        background: rgba(0,0,0,0.5);
        border-radius: 4px;
      }
      #category-container::-webkit-scrollbar-thumb {
        background: rgb(30,30,30);
        border-radius: 4px;
      }

      .category {
        padding-bottom: 0.5rem;
      }
      .category .category-title {
        font-weight: bold;
        color: #fff;
        pointer-events: none;
      }
      .category .category-emojis {
        display: table;
        margin: 0.5rem auto 0 auto;
        padding: 0.5rem;
        border-radius: 4px;
        background-color: rgba(50,50,50,0.35);
      }

      .category-emojis {
        margin: 0.125rem;
      }
      .category-emojis .load-button-wrapper {
        width: 100%;
        text-align: center;
      }

      .load-button {
        padding: 4px;
        color: #fff;
        font-size: 0.8rem;
        font-weight: bold;
        background-color: rgba(0,0,0,0.5);
        border-radius: 4px;
        cursor: pointer;
      }

      .loading-label {
        font-style: italic;
        padding: 4px;
        color: #fff;
        font-size: 0.8rem;
        font-weight: bold;
        background-color: rgba(0,0,0,0.5);
        border-radius: 4px;
        cursor: pointer;
      }
      
      .emoji {
        display: inline-block;
        margin: 0.125rem;
        width: 1.375rem;
        height: 1.375rem;
        cursor: pointer;
      }

      .blank-emoji {
        display: inline-block;
        margin: 0.125rem;
        width: 1.375rem;
        height: 1.375rem;
      }
    </style>
  </head>
  <body>
    <div id="text-entry">
      <img id="entry-button" src="asset://garrysmod/materials/icon16/zoom.png">
      <div contenteditable id="entry-input" spellcheck="false" oninput="if (this.innerHTML.trim() === '<br>') this.innerHTML = ''"></div>
    </div>
    <div id="category-container"></div>
  </body>
  <script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/jquery.js"></script>
  <script> // item parsers script
    const UFE0Fg = /\uFE0F/g,
    U200D = String.fromCharCode(0x200D);

    function toCodePoint(unicodeSurrogates, sep) {
      var
        r = [],
        c = 0,
        p = 0,
        i = 0;
      while (i < unicodeSurrogates.length) {
        c = unicodeSurrogates.charCodeAt(i++);
        if (p) {
          r.push((0x10000 + ((p - 0xD800) << 10) + (c - 0xDC00)).toString(16));
          p = 0;
        } else if (0xD800 <= c && c <= 0xDBFF) {
          p = c;
        } else {
          r.push(c.toString(16));
        }
      }
      return r.join(sep || "-");
    }

    function grabTheRightIcon(rawText) {
      // if variant is present as \uFE0F
      return toCodePoint(rawText.indexOf(U200D) < 0 ?
        rawText.replace(UFE0Fg, "") :
        rawText
      );
    }

    var itemParsers = {
      twemoji: function(item) {
        return {
          name: item[0],
          src: "https://twemoji.maxcdn.com/v/14.0.2/svg/" + grabTheRightIcon(item[1]) + ".svg"
        };
      },
      silkicon: function(item) {
        return {
          name: item,
          src: "asset://garrysmod/materials/icon16/" + item + ".png"
        };
      },
      steam: function(item) {
        return {
          name: item,
          src: "https://steamcommunity-a.akamaihd.net/economy/emoticon/" + item
        };
      }
    };
  </script>
  <script> // main script
    const entryButton = $("#entry-button"),
    entryInput = $("#entry-input"),
    categoryContainer = $("#category-container");

    // strings for elements whose text is updated by js
    const ENTRY_PLACEHOLDER_TEXT = "Search for emojis",
    LOAD_BUTTON_TEXT = "Click to view more",
    LOADING_LABEL_TEXT = "Loading emojis...";

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

    /*
      set the title of the category
        title: the text to set the title to
    */
    jQuery.fn.setTitle = function(title) {
      if (!this.hasClass("category")) return;

      $(".category-title", this).text(title || "");

      return this;
    };

    /*
      append a page of emojis to the category
        data: a list of emojis
        last: set to 1 or true if this is the last page
    */
    jQuery.fn.appendPage = function(data, last) {
      if (!this.hasClass("category")) return;

      var emojis = $(".category-emojis", this),
      source = this.data("source"),
      parser = this.data("parser");

      // try removing wrapper from previous query or page load
      $(".load-button-wrapper", emojis).remove();

      if (data.length) { // load emojis
        for (var i = 0; i < Math.ceil(data.length / 10) * 10; i++) {
          var item = data[i],
          valid = false;

          if (item) {
            item = parser(item);
            if (item.name && item.src) {
              $("<img class='emoji'>")
                .data("name", item.name)
                .data("shortcode", ":" + (source ? source + ":" : "") + item.name + ":")
                .appendTo(emojis)
                .on("error", function() {
                  // incase the emoji fails to load, fill the space with a blank element
                  $(this)
                    .off()
                    .replaceWith($("<span class='blank-emoji'>"));
                })
                .attr("src", item.src);
              valid = true;
            }
          }
          
          if (!valid) $("<span class='blank-emoji'>").appendTo(emojis);
          
          if ((i + 1) % 10 === 0) emojis.append($("<br>"));
        }

        // append load button if more pages can still be loaded
        if (!last) this.appendLoadBtn(LOAD_BUTTON_TEXT);
      } else
        this.hide();
      
      return this;
    };

    /*
      remove all pages from the category
    */
    jQuery.fn.clearPages = function() {
      if (!this.hasClass("category")) return;

      $(".category-emojis", this).empty();

      return this;
    };

    /*
      adds a load button or loading label
        text:    the text that should be on the button/label
        isLabel: set to 1 or true if it should be a loading label
    */
    jQuery.fn.appendLoadBtn = function(text, isLabel) {
      if (!this.hasClass("category")) return;

      var emojis = $(".category-emojis", this),
      scrolled = isFullyScrolled();

      $("<div class='load-button-wrapper'>")
        .css("margin-top", emojis.children().length ? "0.5rem" : "0")
        .append($("<span>")
          .attr("class", isLabel ? "loading-label" : "load-button")
          .text(text)
        )
        .appendTo(emojis);

      if (scrolled) scrollToBottom();

      return this;
    };

    function Category(id, source, parser) {
      this.CATEGORY_WRAPPER = $("<div class='category' data-id='" + id + "'>")
        .data("source", source || null)
        .data("parser", parser ? itemParsers[parser] : itemParsers[id])
        .appendTo(categoryContainer);
      this.CATEGORY_TITLE = $("<span class='category-title'>").appendTo(this.CATEGORY_WRAPPER);
      this.CATEGORY_EMOJIS = $("<div class='category-emojis'>").appendTo(this.CATEGORY_WRAPPER);
    }

    function getCategoryByID(id) {
      return $(".category[data-id='" + id + "']", categoryContainer);
    }

    function submitEntry() {
      glua.searchEmojis(getText());
      entryInput // reset entry input
        .attr("placeholder", ENTRY_PLACEHOLDER_TEXT)
        .text("")
        .focus();
      categoryContainer.scrollTop(0);
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
        // prevent pasting html or new lines into the entry
        e.preventDefault();
        var paste = e.originalEvent.clipboardData.getData("text/plain");
        insertText(paste);
      });

    $(document)
      .on("click", function(e) {
        var elem = $(e.target);

        switch (true) {
          case elem.hasClass("load-button"):  // try to load next page
            glua.loadPage(elem.closest(".category").attr("data-id")); // load more emojis
            elem.remove();
            break;
          case elem.hasClass("emoji"): // paste the emoji into the chatbox entry
            glua.insertText(elem.data("shortcode") + " ");
            break;
        }
        
        entryInput.focus();
      })
      .on("mouseover", function(e) {
        var elem = $(e.target);

        // show hover label
        if (elem.is(entryButton)) { // entry button text
          startHoverLabel("Search for emojis");
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

    glua.searchEmojis(""); // initialize
  </script>
</html>]]