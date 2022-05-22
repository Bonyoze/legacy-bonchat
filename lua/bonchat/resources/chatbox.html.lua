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

      /* hiding when panel is closed */

      .panel-closed #text-entry {
        display: none;
      }
      .panel-closed #chatbox::-webkit-scrollbar-track, .panel-closed #chatbox::-webkit-scrollbar-thumb, .panel-closed #chatbox .message {
        background: transparent;
      }
      
      #chatbox {
        display: block;
        position: absolute;
        height: auto;
        bottom: 0;
        top: 0;
        left: 0;
        right: 0;
        margin-bottom: 30px;
        padding-right: 2px;
        overflow-x: hidden;
        overflow-y: scroll;
      }
      #chatbox::-webkit-scrollbar {
        width: 8px;
      }
      #chatbox::-webkit-scrollbar-track {
        background: rgba(0,0,0,0.5);
        border-radius: 4px;
      }
      #chatbox::-webkit-scrollbar-thumb {
        background: rgb(30,30,30);
        border-radius: 4px;
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
        -webkit-user-select: none;
        user-select: none;
      }
      #entry-input {
        resize: none;
        overflow: hidden;
        outline: none;
        color: #fff;
        white-space: pre;
      }
      #entry-input[placeholder]:empty:before {
        content: attr(placeholder);
        cursor: text;
        position: absolute;
        opacity: 0.65;
      }

      .timestamp {
        font-size: 0.8rem;
        color: #fff;
        background-color: rgba(0,0,0,0.5);
        border-radius: 4px;
        margin: -0.24rem 4px -0.24rem 0;
        padding: 0.24rem;
        -webkit-user-select: none;
        user-select: none;
        pointer-events: none;
      }

      .player {
        font-weight: bold;
        cursor: pointer;
      }

      .message {
        padding: 4px;
        white-space: pre-wrap;
        word-wrap: break-word;
        overflow: hidden;
      }
      .message:first-child {
        border-top-left-radius: 4px;
        border-top-right-radius: 4px;
      }
      .message:last-child {
        border-bottom-left-radius: 4px;
        border-bottom-right-radius: 4px;
      }
      .message:nth-child(odd) {
        background: rgba(0,0,0,0.5);
      }
      .message:nth-child(even) {
        background: rgba(30,30,30,0.5);
      }
      .message:hover {
        background: rgba(0,0,0,0.25);
      }

      .message-content *, .message-attachments * {
        vertical-align: top;
      }

      /* message option styling */

      .message.center-content > .message-content {
        display: table;
        margin: 0 auto;
        text-align: center;
      }
      .message.center-attachments > .message-attachments {
        display: table;
        margin: 0 auto;
      }
      .message.unselect-content > .message-content, .message.unselect-attachments > .message-attachments {
        -webkit-user-select: none;
        user-select: none;
      }
      .message.untouch-content > .message-content, .message.untouch-attachments > .message-attachments {
        pointer-events: none;
      }

      /* markdown styling */

      .spoiler {
        margin: -0.15rem;
        padding: 0.15rem;
        background: #000;
      }
      .spoiler span {
        opacity: 0;
      }
      .spoiler:hover span {
        opacity: 1;
      }

      a.link {
        color: #00aff4;
      }

      div.attachment {
        margin-top: 4px;
      }

      div.image-attachment img {
        display: inline-block;
        max-width: 100%;
        max-height: 200px;
        border-radius: 4px;
      }

      img.emoji {
        display: inline-block;
        width: 1.375rem;
        height: 1.375rem;
        cursor: pointer;
      }
      .emoji.jumbo {
        width: 3em;
        height: 3em;
      }
    </style>
  </head>
  <body>
    <div id="chatbox"></div>
    <div id="text-entry">
      <img id="entry-button" src="asset://garrysmod/materials/icon16/tick.png">
      <div contenteditable id="entry-input" spellcheck="false" oninput="if (this.innerHTML.trim() === '<br>') this.innerHTML = ''"></div>
    </div>
  </body>
  <script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/jquery.js"></script>
  <script> // whitelist script
    const WHITELIST_DOMAINS = [
      // Steam
      "cdn.akamai.steamstatic.com",
      // Discord
      "cdn.discordapp.com",
      "media.discordapp.net",
      // Twitter
      "pbs.twimg.com",
      // Dropbox
      "www.dropbox.com",
      "dl.dropboxusercontent.com",
      // Imgur
      "i.imgur.com",
      // Tenor
      "tenor.com",
      // Facepunch
      "files.facepunch.com"
    ];

    function isWhitelistedURL(href) {
      var url = document.createElement("a");
      url.href = href;
      var domain = url.hostname + url.pathname;
      return WHITELIST_DOMAINS.some(function(x) { return domain.substring(0, x.length) == x; });
    }
  </script>
  <script> // emojis script
    var EMOJI_DATA = {}; // EMOJI_DATA gets populated by GLua

    function getEmojiByShortcode(shortcode) {
      if (EMOJI_DATA) return EMOJI_DATA[shortcode];
    }

    const TWEMOJI_BASE = "https://twemoji.maxcdn.com/v/14.0.2/svg/",
    DISCORD_EMOJI_BASE = "https://cdn.discordapp.com/emojis/",
    STEAM_EMOJI_BASE = "https://steamcommunity-a.akamaihd.net/economy/emoticon/",
    SILKICON_BASE = "asset://garrysmod/materials/icon16/";

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

    // emoji sources

    function buildTwemojiURL(char) {
      return TWEMOJI_BASE + grabTheRightIcon(char) + ".svg";
    }

    function buildDiscordEmojiURL(id, animated) {
      return DISCORD_EMOJI_BASE + id + "." + (animated ? "gif" : "png");
    }

    function buildSteamEmojiURL(name) {
      return STEAM_EMOJI_BASE + name;
    }

    function buildSilkiconURL(name) {
      return SILKICON_BASE + name + ".png";
    }
  </script>
  <script> // markdown script
    const SANITIZE_TEXT_REGEX = /[<>&"'/`]/g,
    SANITIZE_TEXT_CODES = {
        "<": "&lt;",
        ">": "&gt;",
        "&": "&amp;",
        '"': "&quot;",
        "'": "&#x27;",
        "/": "&#x2F;",
        "`": "&#96;"
    };

    function sanitizeText(text) {
      return text.replace(SANITIZE_TEXT_REGEX, function(char) {
        return SANITIZE_TEXT_CODES[char];
      });
    }

    function sanitizeURL(url) {
      if (url == null) return null;
      try {
        var prot = decodeURIComponent(url)
          .replace(/[^A-Za-z0-9/:]/g, "")
          .toLowerCase();
        if (prot.indexOf("javascript:") === 0
          || prot.indexOf("vbscript:") === 0
          || prot.indexOf("data:") === 0
        ) return null;
      } catch (e) {
        return null;
      }
      return url;
    };

    function htmlTag(tagName, content, attributes, isClosed) {
      attributes = attributes || {};
      isClosed = typeof isClosed !== "undefined" ? isClosed : true;

      var attributeString = "";
      for (var attr in attributes) {
        var attribute = attributes[attr];
        // removes falsey attributes
        if (Object.prototype.hasOwnProperty.call(attributes, attr) && attribute) {
          attributeString += " " +
            sanitizeText(attr) + '="' +
            sanitizeText(attribute) + '"';
          }
      }

      var unclosedTag = "<" + tagName + attributeString + ">";

      if (isClosed) {
        return unclosedTag + content + "</" + tagName + ">";
      } else {
        return unclosedTag;
      }
    };

    const rules = {
      escape: {
        match: /^\\([^0-9A-Za-z\s])/,
        parse: function(capture) {
          return {
            type: "text",
            content: capture[1]
          };
        },
        html: null
      },
      spoiler: {
        match: /^\|\|([\s\S]+?)\|\|/,
        parse: function(capture, parse) {
          return {
            content: parse(capture[1])
          };
        },
        html: function(node, output) {
          return htmlTag("span", htmlTag("span", output(node.content)), { class: "spoiler" });
        }
      },
      emoji: {
        match: /^((?::([^\s:]+))?:([^\s:]+):)/,
        parse: function(capture) {
          return {
            originalText: capture[1],
            source: capture[2],
            name: capture[3]
          };
        },
        html: function(node) {
          var text = sanitizeText(node.originalText);
          switch (node.source ? node.source.toLowerCase() : null) {
            case null: // use twemoji if not set
              var char = getEmojiByShortcode(node.name);
              if (char) {
                return htmlTag("span", text, {
                  class: "pre-emoji",
                  src: buildTwemojiURL(char)
                });
              } else
                return text;
            case "steam":
            case "s":
              return htmlTag("span", text, {
                class: "pre-emoji",
                src: buildSteamEmojiURL(node.name)
              });
            case "icon":
            case "i":
              return htmlTag("span", text, {
                class: "pre-emoji",
                src: buildSilkiconURL(node.name)
              });
            default:
              return text;
          }
        }
      },
      discord_emoji: {
        match: /^(<(a?):(\w+):(\d+)>)/,
        parse: function(capture) {
          return {
            originalText: capture[1],
            animated: capture[2] == "a",
            name: capture[3], // this isn't even needed to get the Discord emoji
            id: capture[4]
          };
        },
        html: function(node) {
          var text = sanitizeText(node.originalText);
          return htmlTag("span", text, {
            class: "pre-emoji",
            src: buildDiscordEmojiURL(node.id, node.animated)
          });
        }
      },
      autolink: {
        match: /^<([^: >]+:\/[^ >]+)>/,
        parse: function(capture) {
          return {
            content: capture[1]
          }
        },
        html: function(node) {
          return htmlTag("a", node.content, { class: "link", href: sanitizeURL(node.content) });
        }
      },
      url: {
        match: /^(https?:\/\/[^\s<]+[^<.,:;"')\]\s])/,
        parse: function(capture) {
          return {
            content: capture[1]
          };
        },
        html: function(node) {
          return htmlTag("a", node.content, { class: "link", href: sanitizeURL(node.content) });
        }
      },
      em: {
        match: /^\b_((?:__|\\[\s\S]|[^\\_])+?)_\b|^\*(?=\S)((?:\*\*|\\[\s\S]|\s+(?:\\[\s\S]|[^\s\*\\]|\*\*)|[^\s\*\\])+?)\*(?!\*)/,
        parse: function(capture, parse) {
          return {
            content: parse(capture[2] || capture[1])
          };
        },
        html: function(node, output) {
          return htmlTag("em", output(node.content));
        }
      },
      strong: {
        match: /^\*\*((?:\\[\s\S]|[^\\])+?)\*\*(?!\*)/,
        parse: function(capture, parse) {
          return {
            content: parse(capture[1])
          }
        },
        html: function(node, output) {
          return htmlTag("strong", output(node.content));
        }
      },
      u: {
        match: /^__((?:\\[\s\S]|[^\\])+?)__(?!_)/,
        parse: function(capture, parse) {
          return {
            content: parse(capture[1])
          }
        },
        html: function(node, output) {
          return htmlTag("u", output(node.content));
        }
      },
      strike: {
        match: /^~~([\s\S]+?)~~(?!_)/,
        parse: function(capture, parse) {
          return {
            content: parse(capture[1])
          };
        },
        html: function(node, output) {
          return htmlTag("del", output(node.content));
        }
      },
      color: {
        match: /^(\$([a-z0-9,]+)\$?)/i,
        parse: function(capture) {
          return {
            originalText: capture[1],
            content: capture[2]
          };
        },
        html: function(node) {
          if (/^\d{1,3},\d{1,3},\d{1,3}$/.test(node.content))
            return htmlTag("span", null, { style: "color:rgb(" + node.content + ")" }, false);
          else if (/^([0-9a-f]{6}|[0-9a-f]{3})$/i.test(node.content))
            return htmlTag("span", null, { style: "color:#" + node.content }, false);
          else {
            var s = new Option().style;
            s.color = node.content;
            if (s.color)
              return htmlTag("span", null, { style: "color:" + node.content }, false);
            else
              return sanitizeText(node.originalText);
          }
        }
      },
      br: {
        match: /^\n/,
        parse: function() {
          return {};
        },
        html: function() {
          return "<br>";
        }
      },
      text: {
        match: /^[\s\S]+?(?=[^0-9A-Za-z\s\u00c0-\uffff-]|\n\n|\n|\w+:\S|$)/,
        parse: function(capture) {
          return {
            content: capture[0]
          }
        },
        html: function(node) {
          return sanitizeText(node.content);
        }
      }
    },
    ruleList = Object.keys(rules);

    function nestedParse(source) {
      var result = [];

      while (source) {
        var ruleType = null,
        rule = null,
        capture = null;

        var i = 0;
        var currRuleType = ruleList[0]
        var currRule = rules[currRuleType];

        do {
          var currCapture = currRule.match.exec(source);

          if (currCapture) {
            ruleType = currRuleType;
            rule = currRule;
            capture = currCapture;
          }
          
          i++
          currRuleType = ruleList[i];
          currRule = rules[currRuleType];
        } while (currRule && !capture);
        
        if (rule == null || capture == null) throw new Error("Could not find a matching rule");
        if (capture.index) throw new Error("'match' must return a capture starting at index 0");

        var parsed = rule.parse(capture, nestedParse)

        if (Array.isArray(parsed)) {
          Array.prototype.push.apply(result, parsed);
        } else {
          if (parsed.type == null) parsed.type = ruleType;
          result.push(parsed);
        }

        source = source.substring(capture[0].length);
      }

      return result;
    }

    function outputHTML(ast) {
      if (Array.isArray(ast)) {
        var result = "";

        // map output over the ast, except group any text
        // nodes together into a single string output.
        for (var i = 0; i < ast.length; i++) {
          var node = ast[i];
          if (node.type === "text") {
            node = { type: "text", content: node.content };
            for (; i + 1 < ast.length && ast[i + 1].type === "text"; i++) {
              node.content += ast[i + 1].content;
            }
          }

          result += outputHTML(node);
        }

        return result;
      } else {
        return rules[ast.type].html(ast, outputHTML);
      }
    }
  </script>
  <script>
    const chatbox = $("#chatbox"),
    entryInput = $("#entry-input"),
    entryButton = $("#entry-button");

    var panelIsOpen = false,
    entryMaxInput = 126; // gmod's chat message limit

    function getTimestampText(s) { // H:MM AM/PM
      function pad(n) {
        return ("00" + n).slice(-2);
      }

      s = s - new Date().getTimezoneOffset() * 60000;

      var ms = s % 1000;
      s = (s - ms) / 1000;
      var secs = s % 60;
      s = (s - secs) / 60;
      var mins = s % 60;
      var hrs = (s - mins) / 60;

      return ((hrs - 1) % 12 + 1) + ":" + pad(mins) + " " + (hrs % 24 >= 12 ? "PM" : "AM");
    }

    function isFullyScrolled() {
      var e = chatbox.get(0);
      return Math.abs(e.scrollHeight - e.clientHeight - e.scrollTop) < 1;
    }

    function scrollToBottom() {
      var e = chatbox.get(0);
      e.scrollTop = e.scrollHeight;
    }

    jQuery.fn.resetFadeOut = function() {
      this.css({
        "-webkit-transition": "initial",
        "transition": "initial",
        "opacity": "initial"
      });
    }

    jQuery.fn.startFadeOut = function(duration, delay) {
      var now = Date.now();
      this.each(function() {
        var e = $(this),
          timeSinceSent = now - e.data("sendTime"),
          opac = Math.max((duration - Math.max(timeSinceSent - delay, 0)) / duration, 0);
        if (opac == 0)
          e.css("opacity", "0");
        else {
          var transition = "opacity "
            + Math.max(duration - Math.max(timeSinceSent - delay, 0), 0) // new duration
            + "ms linear "
            + Math.max(delay - timeSinceSent, 0) // new delay
            + "ms";
          e.css({
            "opacity": opac, // starting opacity
            "-webkit-transition": transition,
            "transition": transition,
            "opacity": "0"
          });
        }
      })
    }

    function Message() {
      this.MAX_ATTACHMENTS = 5;

      this.MSG_WRAPPER = $("<div class='message'>");
      this.MSG_CONTENT = $("<div class='message-content'>").appendTo(this.MSG_WRAPPER);
      this.MSG_ATTACHMENTS = $("<div class='message-attachments'>").appendTo(this.MSG_WRAPPER);
      
      this.textColor = "#97d3ff"; // this is the default text color

      this.setTextColor = function(str) {
        if (str) this.textColor = str;
      };
      this.appendText = function(str) {
        this.MSG_CONTENT.append(
          $("<span>")
            .text(str)
            .css("color", this.textColor)
        );
      };
      this.appendMarkdown = function(str) {
        var markdownHTML = outputHTML(nestedParse(str));
        this.MSG_CONTENT.append(
          $("<span>")
            .html(markdownHTML)
            .css("color", this.textColor)
        );
      };
      this.appendPlayer = function(name, color, steamID) {
        var elem = $("<span class='player'>")
          .text(name)
          .css("color", color || this.textColor);
        
        if (steamID && steamID != "NULL") elem.on("click", function() { glua.showProfile(steamID) });
        
        this.MSG_CONTENT.append(elem);
      };
      this._loadAttachments = function() {
        var maxAttachments = this.MAX_ATTACHMENTS,
        attachments = this.MSG_ATTACHMENTS,
        links = this.MSG_WRAPPER.find(".link").slice(0, this.MAX_ATTACHMENTS);
        
        // keep only whitelisted links and remove duplicates
        var seen = {}
        links = links.filter(function() {
          var url = $(this).attr("href");
          return url && !seen.hasOwnProperty(url) && isWhitelistedURL(url) ? seen[url] = true : false;
        });

        // load the attachments
        links.each(function(index) {
          var link = $(this),
          url = $(this).attr("href");

          var scrolled = isFullyScrolled();

          // try to load the attachment
          var attachmentContainer = $("<div class='attachment image-attachment'>").appendTo(attachments),
          // append first so the order of the attachments doesn't mix up incase they load faster than any before it
          img = $("<img>")
            .on("load", function() { // image loaded
              img.off();

              link.remove();
              attachments.append(
                // setup attachment using the loaded image
                attachmentContainer
                  .append($("<a>")
                    .attr("href", url)
                    .append(img.attr("alt", url))
                  )
              );
              
              if (scrolled) scrollToBottom();
            })
            .on("error", function() { // failed to load image
              attachmentContainer.remove()
              img.remove();
            })
            .attr("src", url);
        });
      };
      this._loadEmojis = function() {
        this.MSG_WRAPPER.find(".pre-emoji").each(function() {
          var pre = $(this),
          url = pre.attr("src"),
          img = $("<img>")
            .on("load", function() {
              img.off();
              // replace it with the loaded image
              pre.replaceWith(img
                .addClass("emoji")
                .attr("alt", pre.text())
              );
            })
            .on("error", function() { img.remove(); })
            .attr("src", url);
        });
      };
      this.send = function() {
        // set send time
        this.MSG_WRAPPER.data({
          sendTime: Date.now()
        });

        // show timestamp
        if (this.MSG_WRAPPER.hasClass("show-timestamp"))
          this.MSG_CONTENT.prepend(
            $("<span class='timestamp'>")
              .text(getTimestampText(this.MSG_WRAPPER.data("sendTime")))
          );

        var scrolled = isFullyScrolled();
        this.MSG_WRAPPER.appendTo(chatbox);
        if (scrolled) scrollToBottom();

        // load attachments
        this._loadAttachments();

        // load emojis
        this._loadEmojis();

        // start fade out animation
        if (!panelIsOpen) this.MSG_WRAPPER.startFadeOut(3000, 10000);
      }
    };

    function checkImageContent(src, success, fail) {
      var img = $("<img>")
        .on("load", function() {
          img.remove();
          success();
        })
        .on("error", function() {
          img.remove();
          fail();
        })
        .attr("src", src);
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

    entryButton
      .on("click", function() {
        glua.say(getText());
        entryInput
          .text("")
          .focus();
      });

    entryInput
      .on("keydown", function(e) { // prevent default tab functionality
        if (e.which == 9) { // toggle the chat mode on tab
          e.preventDefault();
          glua.toggleChatMode();
        }
      })
      .on("keypress", function(e) {
        // prevent registering certain keys and exceeding the char limit
        return !e.ctrlKey && !e.metaKey && !e.altKey && e.which != 8 && e.which != 13 && getUTF8ByteLength(getText() + String.fromCharCode(e.which)) < entryMaxInput;
      })
      .on("paste", function(e) {
        // prevent pasting html or newlines into the entry
        e.preventDefault();
        var paste = e.originalEvent.clipboardData.getData("text/plain");
        insertText(paste);
      });

    $(document)
      .on("click", function(e) {
        var elem = $(e.target),
        url = elem.attr("href") || elem.parents().attr("href");
        if (url) { // check if clicking would've caused a redirect
          // prevent page redirect and instead open the image with Glua
          event.preventDefault();
          if (elem.is("img"))
            glua.openImage(url,
              elem.prop("naturalWidth"),
              elem.prop("naturalHeight"),
              elem.prop("width"),
              elem.prop("height")
            );
          else
            glua.openPage(url);
        } else if (elem.hasClass("emoji")) { // check if clicked on an emoji
          //entryInput.focus();
          insertText(elem.attr("alt") + " "); // paste the emoji into the entry
        }
      });
    
    function PANEL_OPEN(mode) {
      panelIsOpen = true;
      $("html").removeClass("panel-closed");
      entryInput
        .attr("placeholder", "typing in " + (mode == 1 ? "public" : "team") + " chat...")
        .focus(); // focus so the user can type in it
      $(".message").resetFadeOut();
    }

    function PANEL_CLOSE() {
      panelIsOpen = false;
      $("html").addClass("panel-closed");
      entryInput.text(""); // clear the entry
      scrollToBottom(); // reset scroll
      $(".message").startFadeOut(3000, 10000);
    }
  </script>
</html>]]