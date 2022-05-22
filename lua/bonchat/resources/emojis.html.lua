return [[<html>
  <head>
    <style>
      html {
        font-size: 14px;
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
        -webkit-user-select: none;
        user-select: none;
      }
      #entry-input {
        resize: none;
        overflow: hidden;
        outline: none;
        color: #fff;
        white-space: nowrap;
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
        margin-top: 40px;
        overflow-x: hidden;
        overflow-y: scroll;
        -webkit-user-select: none;
        user-select: none;
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
        padding-bottom: 1rem;
      }
      .category .category-title {
        font-weight: bold;
        color: #fff;
        pointer-events: none;
      }
      .category .category-emojis {
        display: table;
        margin: 0.5rem auto 0 auto;
        text-align: center;
      }

      .category-emojis .load-button-wrapper {
        margin-top: 1rem;
        width: 100%;
        text-align: center;
        font-size: 0.75rem;
        font-weight: bold;
      }
      .category-emojis {
        margin: 0.125rem;
      }

      .load-button {
        padding: 4px;
        color: #fff;
        background-color: rgba(0,0,0,0.5);
        border-radius: 4px;
        cursor: pointer;
      }

      .loading-label {
        font-style: italic;
        padding: 4px;
        color: #fff;
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

      .invalid-emoji {
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
  <script type="text/javascript"> // item parsers script
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
  <script type="text/javascript">
    const entryButton = $("#entry-button"),
    entryInput = $("#entry-input"),
    categoryContainer = $("#category-container");

    const LOAD_BUTTON_TEXT = "Click to view more",
    LOADING_LABEL_TEXT = "Loading emojis...",
    ENTRY_PLACEHOLDER_TEXT = "type something...";

    const entryMaxInput = 128;

    var categories = {};
    
    function Category(id, source, parser) {
      this.ID = id;
      this.SOURCE = source ? source : null;
      this.PARSER = parser ? itemParsers[parser] : itemParsers[id];

      this.CATEGORY_WRAPPER = $("<div class='category'>").appendTo(categoryContainer)
      this.CATEGORY_TITLE = $("<span class='category-title'>").appendTo(this.CATEGORY_WRAPPER);
      this.CATEGORY_EMOJIS = $("<div class='category-emojis'>").appendTo(this.CATEGORY_WRAPPER);

      this.setTitle = function(title) {
        this.CATEGORY_TITLE.text(title || "");
      };
      this.appendPage = function(data, last) {
        // try removing wrapper from previous query or page load
        $(".load-button-wrapper", this.CATEGORY_EMOJIS).remove();

        for (var i = 0; i < data.length; i++) {
          var item = this.PARSER(data[i]);
          if (item.name && item.src)
            $("<img class='emoji'>")
              .data("name", item.name)
              .data("shortcode", ":" + (this.SOURCE ? this.SOURCE + ":" : "") + item.name + ":")
              .appendTo(this.CATEGORY_EMOJIS)
              .on("error", function() {
                // incase the emoji fails to load, mark it invalid
                $(this)
                  .off()
                  .replaceWith($("<span class='invalid-emoji'>"));
              })
              .attr("src", item.src);
          else
            $("<span class='invalid-emoji'>").appendTo(this.CATEGORY_EMOJIS);
          
          if ((i + 1) % 10 == 0) this.CATEGORY_EMOJIS.append($("<br>"));
        }

        // append load button if more pages can still be loaded
        if (last !== 1) this.appendLoadBtn(LOAD_BUTTON_TEXT);
      };
      this.clearPages = function() {
        this.CATEGORY_EMOJIS.empty()
      };
      this.appendLoadBtn = function(text, isLabel) {
        $("<div class='load-button-wrapper'>")
          .append($("<span>")
            .attr("class", isLabel ? "loading-label" : "load-button")
            .text(text)
          )
          .appendTo(this.CATEGORY_EMOJIS);
      };

      this.CATEGORY_WRAPPER.data("obj", this);
      categories[id] = this;
    }

    function submitEntry() {
      glua.searchEmojis(entryInput.text());
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
      text = text
        .replace(/[\u000a\u000d\u2028\u2029\u0009]/g, "") // prevent new lines and tab spaces
        .substring(0, entryMaxInput - getUTF8ByteLength(getText()) + getUTF8ByteLength(document.getSelection().toString())); // make sure it won't exceed the char limit
      if (text) document.execCommand("insertText", false, text);
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
        return !e.ctrlKey && !e.metaKey && !e.altKey && e.which != 8 && e.which != 9 && getUTF8ByteLength(getText() + String.fromCharCode(e.which)) < entryMaxInput;
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
        if (elem.hasClass("load-button")) { // try to load next page
          glua.loadPage(elem.closest(".category").data("obj").ID); // load more emojis
          elem.remove();
        } else if (elem.hasClass("emoji")) // paste the emoji into the chatbox entry
          glua.insertText(elem.data("shortcode") + " ");
        
        entryInput.focus();
      })
      .on("mouseover", function(e) {
        var elem = $(e.target);
        if (elem.hasClass("emoji")) entryInput.attr("placeholder", elem.data("shortcode")); // show shortcode in entry placeholder
      });

    glua.searchEmojis(""); // initialize
  </script>
</html>]]