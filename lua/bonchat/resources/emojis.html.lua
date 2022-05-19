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

      #search-container {
        position: fixed;
        padding: 4px;
        left: 0;
        right: 0;
        top: 0;
        background: rgba(0,0,0,0.5);
        border-radius: 4px;
      }
      #search-button {
        float: right;
        margin-left: 2px;
        width: 1.375rem;
        height: 1.375rem;
        cursor: pointer;
        -webkit-user-select: none;
        user-select: none;
      }
      #search-entry {
        resize: none;
        overflow: hidden;
        outline: none;
        color: #fff;
        white-space: nowrap;
      }
      #search-entry[placeholder]:empty:before {
        content: attr(placeholder);
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
        margin: auto;
        margin-top: 0.5rem;
        width: 15rem; /* (1.375 + 0.125) * 10 */
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
    <div id="search-container">
      <img id="search-button" src="asset://garrysmod/materials/icon16/zoom.png">
      <div contenteditable id="search-entry" spellcheck="false" oninput="if(this.innerHTML.trim()==='<br>')this.innerHTML=''"></div>
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
    const searchButton = $("#search-button"),
    searchEntry = $("#search-entry"),
    categoryContainer = $("#category-container");

    const LOAD_BUTTON_TEXT = "Click to view more",
    LOADING_LABEL_TEXT = "Loading emojis...",
    ENTRY_PLACEHOLDER_TEXT = "type something...";

    const queryMaxLen = 128;

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
        }

        // append load button if more pages can still be loaded
        if (last !== 1)
          $("<div class='load-button-wrapper'>")
            .append($("<span class='load-button'>").text(LOAD_BUTTON_TEXT))
            .appendTo(this.CATEGORY_EMOJIS);
      };
      this.clearPages = function() {
        this.CATEGORY_EMOJIS.empty()
      };

      this.CATEGORY_WRAPPER.data("obj", this);
      categories[id] = this;
    }

    function getCategory(id) {
      return categories[id];
    }

    function submitEntry() {
      glua.searchEmojis(searchEntry.text());
      searchEntry // reset entry
        .attr("placeholder", ENTRY_PLACEHOLDER_TEXT)
        .text("");
    }
  
    searchButton.on("click", submitEntry);

    searchEntry
      .attr("placeholder", ENTRY_PLACEHOLDER_TEXT)
      .focus()
      .on("keypress", function(e) {
        if (e.which == 13) { // submit on enter
          submitEntry();
          return false;
        }
        // prevent newlines and exceeding the char limit
        return !e.ctrlKey && !e.metaKey && !e.altKey && e.which != 8 && searchEntry.text().length < queryMaxLen;
      })
      .on("paste", function(e) {
        // prevent pasting html or newlines into the entry
        e.preventDefault();
        var paste = e.originalEvent.clipboardData.getData("text/plain");
        if (paste && paste.length) {
          document.execCommand("insertText", false,
            paste
              .replace(/[\r\n]/g, "") // remove newlines
              .substring(0, queryMaxLen - searchEntry.text().length + document.getSelection().toString().length) // make sure pasting it won't exceed the char limit
          );
        }
      })
      .on("focusout", function() {
        searchEntry.focus(); // regain the focus
      });

    $(document)
      .on("click", function(e) {
        var elem = $(e.target);
        if (elem.hasClass("load-button")) { // try to load next page
          glua.loadPage(elem.closest(".category").data("obj").ID); // load more emojis
          elem.remove();
        } else if (elem.hasClass("emoji")) // paste the emoji into the chatbox entry
          glua.insertText(elem.data("shortcode") + " ");
      })
      .on("mouseover", function(e) {
        var elem = $(e.target);
        if (elem.hasClass("emoji")) // show shortcode in entry placeholder
          searchEntry.attr("placeholder", elem.data("shortcode"));
      });

    submitEntry(); // initialize
  </script>
</html>]]