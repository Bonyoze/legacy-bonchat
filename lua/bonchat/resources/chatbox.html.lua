return [[<html>
  <head>
    <title>BonChat Chatbox</title>
    <style>
      html, body {
        margin: 0;
        overflow: hidden;
      }

      html {
        font-size: 14px;
      }

      body {
        font-family: Verdana;
        font-size: 1rem;
        line-height: 1.375rem;
        text-shadow: 1px 1px 1px #000, 1px 1px 2px #000;
      }

      /* hiding when chatbox is closed */

      .chatbox-closed #entry {
        display: none;
      }
      .chatbox-closed #chatbox::-webkit-scrollbar-track, .chatbox-closed #chatbox::-webkit-scrollbar-thumb, .chatbox-closed #chatbox .message {
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

      #entry {
        position: fixed;
        left: 0;
        right: 0;
        bottom: 0;
        padding: 4px;
        resize: none;
        overflow: hidden;
        outline: none;
        background: rgba(0,0,0,0.5);
        border-radius: 4px;

        color: #fff;
        white-space: nowrap;
      }

      .message {
        padding: 4px;
        white-space: pre-wrap;
        word-wrap: break-word;
        max-height: 250px;
        overflow-x: hidden;
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

      .link {
        color: #00aff4;
      }

      .attachment {
        display: block;
        margin-top: 4px;
      }

      .image-attachment img {
        vertical-align: top;
        display: inline-block;
        max-width: 100%;
        max-height: 200px;
        border-radius: 4px;
      }

      .emoji {
        vertical-align: top;
        display: inline-block;
        width: 1.375rem;
        height: 1.375rem;
      }
    </style>
  </head>
  <body>
    <div id="chatbox"></div>
    <div contenteditable id="entry" spellcheck="false"></div>
  </body>
  <script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/jquery.js"></script>
  <script> // whitelist script
    const WHITELIST_PROTOCOLS = [
      "https",
      "http"
    ],
    WHITELIST_DOMAINS = [
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
      "tenor.com"
    ],
    WHITELIST_FORMATS = [
      "png",
      "jpg", "jpeg",
      "gif",
      "mp4",
      "webm",
      "ogg",
      "mp3",
      "wav"
    ];

    function isWhitelistedURL(href) {
      var url = document.createElement("a");
      url.href = href;

      var protocol = url.protocol.slice(0, -1),
      domain = url.hostname + url.pathname,
      format = url.pathname.split("/");
      format = format[format.length - 1].split(".");
      format = format[format.length - 1];

      return WHITELIST_PROTOCOLS.some(function(x) { return x == protocol; })
        && WHITELIST_DOMAINS.some(function(x) { return domain.substring(0, x.length) == x; })
        && WHITELIST_FORMATS.some(function(x) { return x == format; });
    }
  </script>
  <script> // emojis script
    function getEmojiByShortcode(shortcode) {
      // TWEMOJI_DATA constant is set by GLua
      if (TWEMOJI_DATA) return TWEMOJI_DATA[shortcode];
    }

    // used in markdown parsing as a fallback for what platform to get emojis from
    const EMOJI_DEFAULT_PLATFORM = "discord";

    // twemoji
    
    const TWEMOJI_VERSION = "14.0.2",
    TWEMOJI_FOLDER = "svg",
    TWEMOJI_EXT = ".svg",
    TWEMOJI_BASE = "https://twemoji.maxcdn.com/v/" + TWEMOJI_VERSION + "/" + TWEMOJI_FOLDER + "/";

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

    function buildTwemojiURL(char) {
      return TWEMOJI_BASE + grabTheRightIcon(char) + TWEMOJI_EXT;
    }

    // discord emojis

    const DISCORD_EMOJI_BASE = "https://cdn.discordapp.com/emojis/";

    function buildDiscordEmojiURL(id, animated) {
      return DISCORD_EMOJI_BASE + id + "." + (animated ? "gif" : "png");
    }

    // steam emojis

    const STEAM_EMOJI_BASE = "https://steamcommunity-a.akamaihd.net/economy/emoticon/";

    function buildSteamEmojiURL(name) {
      return STEAM_EMOJI_BASE + name;
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
            platform: capture[2],
            name: capture[3]
          };
        },
        html: function(node) {
          var text = sanitizeText(node.originalText);
          switch (node.platform ? node.platform.toLowerCase() : EMOJI_DEFAULT_PLATFORM) {
            case "discord": // twemoji isn't really a platform but discord is and it's well-known for using it
            case "d":
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
            case "twitch":
            case "t":
              return text; // WIP
            default:
              return text;
          }
        }
      },
      /*discord_emoji: {
        match: /^<(a?):(\w+):(\d+)>/,
        parse: function(capture) {
          return {
            animated: capture[1] == "a",
            name: capture[2],
            id: capture[3]
          };
        },
        html: function(node) {
          return htmlTag("img", "", {
            class: "emoji",
            src: buildDiscordEmojiURL(node.id, node.animated),
            alt: "<" + (node.animated ? "a" : "") + ":" + node.name + ":" + node.id + ">"
          });
        }
      },*/
      autolink: {
        match: /^<([^:\s>]+:\/\/[^\s>]+)>/,
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
        match: /^([^:\s]+:\/\/\S+)/,
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
          if (/^\d{1,3},\d{1,3},\d{1,3}/.test(node.content))
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
          return;
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
    entry = $("#entry");

    var msgMaxLen = 2048; // temporary

    function isFullyScrolled() {
      var e = chatbox.get(0);
      return Math.abs(e.scrollHeight - e.clientHeight - e.scrollTop) < 1;
    }

    function scrollToBottom() {
      var e = chatbox.get(0);
      e.scrollTop = e.scrollHeight;
    }

    function getMessageByID(id) {
      return $(".message[message-id='" + id + "']");
    }

    var msgID = 0;

    function Message() {
      this.elem = $("<div class='message'>");
      this.textColor = "#97d3ff"; // this is the default text color
      this.setTextColor = function(str) {
        if (str) this.textColor = str;
      };
      this.appendText = function(str) {
        var markdownHTML = outputHTML(nestedParse(str));
        this.elem.append(
          $("<span>")
            .html(markdownHTML)
            .css("color", this.textColor)
        );
      };
      this.send = function() {
        var scrolled = isFullyScrolled();
        this.elem.appendTo(chatbox);
        if (scrolled) scrollToBottom();

        // load attachments
        this.elem.find(".link").each(function() {
          var elem = $(this);
          if (!elem.parents(".spoiler").length) {
            var url = elem.attr("href");
            if (url && isWhitelistedURL(url)) {
              // try to load the image
              var img = $("<img>")
                .on("load", function() {
                  var scrolled = isFullyScrolled();

                  // build image attachment using the loaded image
                  $("<div class='attachment image-attachment'>")
                    .append($("<a>")
                      .attr("href", url)
                      .append(img.attr("alt", url))
                    )
                    .appendTo(elem.closest(".message"));

                  elem.remove(); // remove the link

                  if (scrolled) scrollToBottom();
                })
                .on("error", function() { img.remove(); })
                .attr("src", url);
            }
          }
        });

        // load emojis
        this.elem.find(".pre-emoji").each(function() {
          var elem = $(this),
          img = $("<img>")
            .on("load", function() {
              img.off();
              // replace it with the loaded image
              elem.replaceWith(img.addClass("emoji"));
            })
            .on("error", function() { img.remove(); })
            .attr("src", elem.attr("src"));
        })
      }
    }

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

    /*function checkVideoContent(src, success, fail) {
      var e = $("<video>");
      console.log("testing video")
      e.on("loadedmetadata", function() {
        console.log("test2")
        if (e.prop("videoHeight") && e.prop("videoWidth"))
          success();
        else {
          console.log("test3")
          fail();
        }
      });
      e.on("error", fail);
      e.append($("<source>").attr("src", src));
      e.prop("preload", "metadata");
      //e.get(0).play();
    }

    function checkAudioContent(src, success, fail) {
      var e = $("<audio>");
      console.log("testing audio")
      e.prop("preload", "metadata");
      e.on("loadedmetadata", function() {
        console.log("" + e.get(0).duration)
        success();
      });
      e.on("error", fail);
      e.attr("src", src);
    }*/

    entry
      .on("keypress", function(e) {
        // prevent newlines and exceeding the char limit
        return !e.which != 13 && !e.ctrlKey && !e.metaKey && !e.altKey && e.which != 8 && entry.text().length < msgMaxLen;
      })
      .on("paste", function(e) {
        // prevent pasting html or newlines into the entry
        e.preventDefault();
        var paste = e.originalEvent.clipboardData.getData("text/plain");
        if (paste && paste.length) {
          document.execCommand("insertText", false,
            paste
              .replace(/[\r\n]/g, "") // remove newlines
              .substring(0, msgMaxLen - entry.text().length + document.getSelection().toString().length) // make sure pasting it won't exceed the char limit);
          )
        }
      });

    $(document)
      .on("click", function(e) { // prevent page redirects and instead call a lua function
        var elem = $(e.target),
        url = elem.attr("href") || elem.parents().attr("href");
        if (url) {
          event.preventDefault(); // prevent redirect
          if (elem.is("img"))
            glua.showImage(url,
              elem.prop("naturalWidth"),
              elem.prop("naturalHeight"),
              elem.prop("width"),
              elem.prop("height")
            );
          else
            glua.openURL(url);
        }
      });

    const CHATBOX_PANEL_OPEN = function() {
      $("html").removeClass("chatbox-closed");
      entry.focus(); // focus so the user can type in it
    },
    CHATBOX_PANEL_CLOSE = function() {
      $("html").addClass("chatbox-closed");
      entry.text(''); // clear the entry
      scrollToBottom(); // reset scroll
    }
  </script>
</html>]]