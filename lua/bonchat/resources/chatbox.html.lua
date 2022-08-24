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

      /* hiding when panel is closed */

      .panel-closed #text-entry, .panel-closed .dismiss-button {
        visibility: hidden;
      }
      .panel-closed #chatbox::-webkit-scrollbar-track, .panel-closed #chatbox::-webkit-scrollbar-thumb, .panel-closed #message-container > .message {
        background-color: transparent;
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
      #load-button-wrapper {
        margin: 2px 0 4px 0;
        width: 100%;
        text-align: center;
      }
      #load-button {
        padding: 4px;
        color: #fff;
        font-size: 0.8rem;
        font-weight: bold;
        background-color: rgba(0,0,0,0.5);
        border-radius: 4px;
        margin: 0 auto;
        text-align: center;
        cursor: pointer;
      }
      #load-button.loading {
        font-style: italic;
        cursor: default;
        pointer-events: none;
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

      .player {
        font-weight: bold;
        cursor: pointer;
      }

      div.message {
        padding: 0.25rem;
        min-height: 1.4rem;
        white-space: pre-wrap;
        word-wrap: break-word;
        overflow: hidden;
        pointer-events: all;
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
        background-color: rgba(0,0,0,0.1);
      }
      .message:nth-child(even) {
        background-color: rgba(0,0,0,0.2);
      }
      .message:hover {
        background-color: rgba(0,0,0,0.3);
      }

      .message-content, .message-attachments {
        -webkit-user-select: text;
        user-select: text;
      }

      .message-content *, .message-attachments * {
        vertical-align: top;
      }

      /* message option styling */

      .message.dismissible > .message-content {
        padding-right: 4rem;
      }
      .message.dismissible > .message-content > .dismiss-button {
        position: absolute;
        font-size: 0.8rem;
        color: #00aff4;
        cursor: pointer;
        right: 6px;
        -webkit-user-select: none;
        user-select: none;
        pointer-events: all;
      }
      .dismiss-button:before {
        content: "Dismiss";
      }
      .dismiss-button:hover {
        text-decoration: underline;
      }

      .message.center-content > .message-content {
        display: table;
        margin: 0 auto;
        text-align: center;
      }
      .message.center-attachments > .message-attachments {
        display: table;
        margin: 0 auto;
      }
      .message.unselect-content > .message-content *, .message.unselect-attachments > .message-attachments * {
        -webkit-user-select: none;
        user-select: none;
      }
      .message.untouch-content > .message-content *, .message.untouch-attachments > .message-attachments * {
        pointer-events: none;
      }

      .message.show-timestamp > .message-content > .timestamp {
        font-size: 0.8rem;
        color: #fff;
        background-color: rgba(0,0,0,0.5);
        border-radius: 4px;
        margin: -0.25rem 4px -0.25rem 0;
        padding: 0.25rem;
        -webkit-user-select: none;
        user-select: none;
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

      span.link, span.autolink {
        color: #00aff4;
        cursor: pointer;
        pointer-events: all;
      }
      span.link:hover, span.autolink:hover {
        text-decoration: underline;
      }

      div.attachment {
        display: inline-block;
        margin-top: 4px;
        margin-right: 4px;
        border-radius: 4px;
        color: #fff;
        overflow: hidden;
        cursor: pointer;
      }
      .attachment > * {
        display: inline-block;
        max-width: 100%;
        border-radius: 4px;
        /* height is handled by cvar */
      }
      .attachment.loading, .attachment.failed, .attachment.blocked, .attachment.hidden {
        padding: 0.25rem;
        font-size: 0.8rem;
        background-color: rgba(0,0,0,0.5);
        -webkit-user-select: none;
        user-select: none;
      }
      .attachment.loading > *, .attachment.failed > *, .attachment.blocked > *, .attachment.hidden > * {
        display: none;
      }
      .attachment.loading::before {
        content: "Attachment (loading...)";
      }
      .attachment.failed::before {
        content: "Attachment (failed to load)";
      }
      .attachment.blocked::before {
        content: "Attachment (not whitelisted)";
      }
      .attachment.hidden::before {
        content: "Attachment (hidden)";
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
    <div id="chatbox">
      <div id="load-button-wrapper">
        <span id="load-button"></span>
      </div>
      <div id="message-container"></div>
    </div>
    <div id="text-entry">
      <img id="entry-button">
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
      // Youtube
      "youtube.com",
      "youtu.be",
      // Twitter
      "twitter.com",
      "pbs.twimg.com",
      // Dropbox
      "dropbox.com",
      "dl.dropboxusercontent.com",
      // Imgur
      "i.imgur.com",
      // Tenor
      "tenor.com",
      // Facepunch
      "files.facepunch.com",
      // Github
      "user-images.githubusercontent.com",
      // Reddit
      "i.redd.it",
      "preview.redd.it"
    ];

    function isWhitelistedURL(href) {
      var a = document.createElement("a");
      a.href = href;
      var domain = a.host.replace(/^www\./, "") + a.pathname;
      return WHITELIST_DOMAINS.some(function(str) {
        var target = str.replace(/^www\./, "");
        if (target.indexOf("/") == -1) target += "/";
        return domain.slice(0, target.length) == target;
      });
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
        match: /^<([^: >]+:\/\/+[^ >]+)>/,
        parse: function(capture) {
          return {
            content: capture[1]
          };
        },
        html: function(node) {
          return htmlTag("span", node.content, { class: "autolink", href: node.content });
        }
      },
      link: {
        match: /^(https?:\/\/[^\s<]+[^<.,:;"')\]\s])/,
        parse: function(capture) {
          return {
            content: capture[1]
          };
        },
        html: function(node) {
          return htmlTag("span", node.content, { class: "link", href: node.content });
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
          };
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
          };
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
        match: /^(&([a-z0-9,]+)&)/i,
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
          };
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
        var currRuleType = ruleList[0];
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

        var parsed = rule.parse(capture, nestedParse);

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
  <script> // convars script
    var convars = {};

    jQuery.fn.cvarApplyLinkMaxLength = function() {
      this.each(function() {
        var link = $(this),
        url = link.attr("href");
        if (url.length > convars.bonchat_link_max_length)
          link.text(url.slice(0, convars.bonchat_link_max_length) + "...");
        else
          link.text(url);
      });
      return this;
    }

    jQuery.fn.cvarApplyAttachMaxHeight = function() {
      this.find("img, video").css("max-height", (5 + convars.bonchat_attach_max_height / 5) + "rem");
      return this;
    }

    const cvarCallbacks = {
      // serverside
      bonchat_msg_max_length: function(val) {
        convars.bonchat_msg_max_length = parseInt(val); // int
      },
      bonchat_msg_max_attachments: function(val) {
        convars.bonchat_msg_max_attachments = parseInt(val) // int
      },
      // clientside
      bonchat_auto_dismiss: function(val) {
        convars.bonchat_auto_dismiss = parseInt(val) == 1; // bool
      },
      bonchat_link_max_length: function(val) {
        convars.bonchat_link_max_length = parseInt(val); // int
        $(".link").cvarApplyLinkMaxLength();
      },
      bonchat_load_attachments: function(val) {
        convars.bonchat_load_attachments = parseInt(val) == 1; // bool
      },
      bonchat_attach_max_height: function(val) {
        convars.bonchat_attach_max_height = parseInt(val); // int
        $(".attachment").cvarApplyAttachMaxHeight();
      }
    }

    function updateConVar(name, val) {
      convars[name] = val;
      applyConVarChanges(name);
    }

    function applyConVarChanges(name) {
      var val = convars[name],
      callback = cvarCallbacks[name];
      if (val != undefined && callback) {
        var scrolled = isFullyScrolled();
        callback(val);
        if (scrolled) scrollToBottom(); // just in case the height of the chatbox changes
      }
    }
  </script>
  <script> // main script
    const body = $("body"),
    chatbox = $("#chatbox"),
    loadBtnWrapper = $("#load-button-wrapper"),
    loadBtn = $("#load-button"),
    msgContainer = $("#message-container"),
    entry = $("#text-entry"),
    entryInput = $("#entry-input"),
    entryButton = $("#entry-button");

    // strings for elements whose text is updated by js
    const MSG_PUBLIC_CHAT_TEXT = "Send a message in public chat",
    MSG_TEAM_CHAT_TEXT = "Send a message in team chat",
    LOAD_BTN_TEXT = " hidden messages — Click to load",
    LOAD_BTN_LOADING_TEXT = "Loading messages..."

    var panelIsOpen = false,
    chatMode = 1, // 1 = public
    hoverLabelTimeout = null;

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
      return this.css({
        "-webkit-transition": "initial",
        "transition": "initial",
        "opacity": "initial"
      });
    };

    jQuery.fn.startFadeOut = function(duration, delay) {
      var now = Date.now();
      return this.each(function() {
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
      });
    };

    // message functions

    const DEFAULT_TEXT_COLOR = "#97d3ff";

    /*
      append text to a message's content
        str:   the string to use for the text
        color: the color of the text (optional)
    */
    jQuery.fn.appendText = function(str, color) {
      if (!this.hasClass("message")) return;

      var content = $(".message-content", this);

      content.append(
        $("<span>")
          .text(str)
          .css("color", color || DEFAULT_TEXT_COLOR)
      );

      return this;
    };

    /*
      append markdown text to a message's content
        str:   the string to use for the text
        color: the color of the text (optional)
    */
    jQuery.fn.appendMarkdown = function(str, color) {
      if (!this.hasClass("message")) return;

      var content = $(".message-content", this);

      var markdownHTML = outputHTML(nestedParse(str));
      content.append(
        $("<span>")
          .html(markdownHTML)
          .css("color", color || DEFAULT_TEXT_COLOR)
      );

      return this;
    };

    /*
      append a player name to a message's content
        name:    the name of the player
        color:   the color of the player's name (optional)
        steamID: the steam id to use when showing the player's profile (optional, "NULL" will interpret the player as a bot and won't show a profile)
    */
    jQuery.fn.appendPlayer = function(name, color, steamID) {
      if (!this.hasClass("message")) return;

      var content = $(".message-content", this);

      var elem = $("<span class='player'>")
        .text(name)
        .css("color", color || DEFAULT_TEXT_COLOR);
      
      if (steamID && steamID != "NULL") elem.on("click", function() { glua.showProfile(steamID) });
      
      content.append(elem);

      return this;
    };

    jQuery.fn._load = function() {
      if (!this.hasClass("attachment")) return;

      var scrolled = isFullyScrolled();
      this.removeClass("loading").cvarApplyAttachMaxHeight();
      if (scrolled) scrollToBottom();
      this.trigger("attachment:load");

      return this;
    };

    jQuery.fn._error = function() {
      if (!this.hasClass("attachment")) return;

      this.addClass("failed").removeClass("loading").trigger("attachment:error");

      return this;
    };

    function urlIsDomain(href, domains) {
      var a = document.createElement("a");
      a.href = href;
      var domain = a.host.replace(/^www\./, "") + a.pathname;
      return domains.some(function(str) {
        var target = str.replace(/^www\./, "");
        if (target.indexOf("/") == -1) target += "/";
        return domain == target;
      });
    }

    jQuery.fn._loadEmbed = function(url, metas) {
      if (!this.hasClass("embed-attachment")) return;

      var attachment = this,
      properties = {};

      for (tag of metas) {
        if (tag.property && tag.content && properties[tag.property] === undefined) properties[tag.property] = tag.content;
      }

      var a = document.createElement("a");
      a.href = url;

      var domain = a.host.replace(/^www\./, ""),
      path = a.pathname;

      if ((domain == "youtube.com" && path == "/watch") || domain == "youtu.be") {
        attachment.append(
          $("<iframe style='border: none; width: 288; height: 162'>")
            .attr("src", properties["og:video:secure_url"] || properties["og:video:url"])
        );
        attachment._load();
      /*} else if (domain == "twitter.com") {
        attachment._load();*/
      } else
        attachment._error();

      return this;
    };

    jQuery.fn._loadImage = function(url, base64) {
      if (!this.hasClass("image-attachment")) return;
      
      var attachment = this,
      retry;

      attachment.append(
        $("<img>")
          .on("load", function() { // image loaded
            $(this).off();
            attachment._load();
          })
          .on("error", function() { // image failed to load
            if (!retry && base64) { // retry with base64
              $(this).attr("src", base64);
              retry = true
            } else { // failed to load base64 or no base64 provided
              $(this).remove();
              attachment._error();
            }
          })
          .attr("src", url)
      );

      return this;
    };

    jQuery.fn._loadVideo = function(url) {
      if (!this.hasClass("video-attachment")) return;
      
      var attachment = this;

      attachment.append(
        $("<video controls>")
          .on("loadeddata", function() {
            if (this.readyState >= 2) attachment._load();
          })
          .on("error", function() {
            $(this).remove();
            attachment._error();
          })
          .attr("src", url)
      );

      return this;
    };

    jQuery.fn._loadAudio = function(url) {
      if (!this.hasClass("audio-attachment")) return;

      var attachment = this;

      attachment.append(
        $("<audio controls>")
          .on("loadeddata", function() {
            if (this.readyState >= 2) attachment._load();
          })
          .on("error", function() {
            $(this).remove();
            attachment._error();
          })
          .attr("src", url)
      );

      return this;
    };

    jQuery.fn._loadMedia = function(url) {
      if (!this.hasClass("attachment")) return;

      var attachment = this;

      // check all media types
      $("<img>")
        .on("load", function() {
          $(this).remove();
          attachment.addClass("image-attachment")._loadImage(url);
        })
        .on("error", function() {
          $(this).remove();
          $("<video>") // this checks for both video and audio (audio can be used in a video tag)
            .on("loadeddata", function() {
              if (this.readyState >= 2) {
                $(this).remove();
                if (this.videoHeight) // audio can be discerned by checking if it doesn't have valid video dimensions
                  attachment.addClass("video-attachment")._loadVideo(url);
                else // invalid video dimensions (must be audio)
                  attachment.addClass("audio-attachment")._loadAudio(url);
              }
            })
            .on("error", function() {
              $(this).remove();
              attachment._error();
            })
            .attr("src", url);
        })
        .attr("src", url);
      
      return this;
    };

    /*
      append an attachment to a message
        url: the attachment link
    */
    jQuery.fn.appendAttachment = function(url) {
      if (!this.hasClass("message")) return;

      var msgID = this.data("id"),
      attachID = this.data("attachIDNum"),
      attachments = $(".message-attachments", this);

      this.data("attachIDNum", ++attachID); // increment attachment id
      
      var attachment = $("<div class='attachment' data-id='" + attachID + "'>")
        .data("id", attachID)
        .data("load", function() {
          attachment.empty().addClass("loading");

          // fix tenor gif url
          var sep = url.match(/(.*?)([?#].+)/), hostpath = sep ? sep[1] : url, paramhash = sep ? sep[2] : "";
          if ((hostpath.indexOf("https://tenor.com/view/") == 0 || hostpath.indexOf("https://www.tenor.com/view/") == 0) && hostpath.indexOf(".gif") != url.length - 4)
            url = hostpath + ".gif" + paramhash;

          glua.loadAttachment(msgID, attachID, url);
        })
        .attr("href", url); // used for hover label and opening in browser

      if (!convars.bonchat_load_attachments)
        attachment.addClass("hidden").trigger("attachment:error");
      else if (!isWhitelistedURL(url))
        attachment.addClass("blocked").trigger("attachment:error");
      else {
        attachment.data("load")();
      }

      attachment.appendTo(attachments);
      
      return attachment;
    };

    function Message(id) {
      this.MSG_WRAPPER = $("<div class='message' data-id='" + (typeof id == "number" ? id : "") + "'>");
      this.MSG_CONTENT = $("<div class='message-content'>").appendTo(this.MSG_WRAPPER);
      this.MSG_ATTACHMENTS = $("<div class='message-attachments'>").appendTo(this.MSG_WRAPPER);

      var wrapper = this.MSG_WRAPPER,
      content = this.MSG_CONTENT,
      attachments = this.MSG_ATTACHMENTS;

      wrapper
        .data("id", id)
        .data("attachIDNum", 0);

      this.setTextColor = function(str) {
        if (str) this.textColor = str;
      };
      this.appendText = function(str) {
        wrapper.appendText(str, this.textColor);
      };
      this.appendMarkdown = function(str) {
        wrapper.appendMarkdown(str, this.textColor);
      };
      this.appendPlayer = function(name, color, steamID) {
        wrapper.appendPlayer(name, color || this.textColor, steamID);
      };
      this.appendAttachment = function(url) {
        if (attachments.children().length >= convars.bonchat_msg_max_attachments) return;
        wrapper.appendAttachment(url);
      };
      this.send = function(prependHidden) {
        // set send time
        wrapper.data("sendTime", Date.now());

        var scrolled = isFullyScrolled();

        // show dismiss button
        if (wrapper.hasClass("dismissible"))
          content.prepend(
            $("<span class='dismiss-button'>")
          );

        // show timestamp
        if (wrapper.hasClass("show-timestamp"))
          content.prepend(
            $("<span class='timestamp'>")
              .text(getTimestampText(wrapper.data("sendTime")))
          );
        
        // load link attachments
        var seenURLs = {};
        wrapper.find(".link").each(function() {
          if (attachments.children().length >= convars.bonchat_msg_max_attachments) return;

          var link = $(this),
          url = link.attr("href");

          if (seenURLs[url] || !isWhitelistedURL(url)) return;
          seenURLs[url] = true;

          // try to load attachment
          var attach = wrapper.appendAttachment(url)
            .on("attachment:load", function() { // success
              var scrolled = isFullyScrolled();
              attach.off().show();
              if (scrolled) scrollToBottom();
            })
            .on("attachment:error", function() {
              attach.remove();
            })
            .hide();
        });
        
        // load emojis
        wrapper.find(".pre-emoji").each(function() {
          var pre = $(this),
          url = pre.attr("src"),
          img = $("<img class='emoji'>")
            .on("load", function() {
              img.off();
              // replace it with the loaded image
              pre.replaceWith(img.attr("alt", pre.text()));
            })
            .on("error", function() {
              img.remove();
            })
            .attr("src", url);
        });

        wrapper.find(".link").cvarApplyLinkMaxLength();

        if (prependHidden)
          wrapper.prependTo(msgContainer); // prepend the hidden message
        else
          wrapper.appendTo(msgContainer); // append the new message

        // remove oldest message if exceeding 100 total
        if (!prependHidden) {
          var msgs = msgContainer.children();
          if (msgs.length > 100) msgs.first().remove();
        }

        if (scrolled || !panelIsOpen) scrollToBottom();

        if (!panelIsOpen) wrapper.startFadeOut(3000, 10000); // start fade out animation
      }
    };

    function getMessageByID(id) {
      return $(".message[data-id='" + id + "']", msgContainer);
    }

    function getAttachmentByID(id, msg) {
      return $(".attachment[data-id='" + id + "']", msg);
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
      maxLen = convars.bonchat_msg_max_length - getUTF8ByteLength(getText()) + getUTF8ByteLength(document.getSelection().toString());
      if (len > maxLen) {
        text = text.substring(0, maxLen); // make sure it won't exceed the char limit
        glua.playSound("resource/warning.wav");
      }
      if (text) {
        document.execCommand("insertText", false, text);
        entryInput.scrollLeft(entryInput.get(0).scrollWidth);
      }
    }

    function updateLoadBtn(total) {
      if (total > 100) {
        var totalHidden = total - msgContainer.children().length;
        if (totalHidden) {
          loadBtn.text(totalHidden + LOAD_BTN_TEXT + (totalHidden > 100 ? " 100" : ""));
          loadBtnWrapper.show();
        } else
          loadBtnWrapper.hide();
      } else
        loadBtnWrapper.hide();
    }

    function resetLoadBtn(total) {
      var msgs = msgContainer.children();
      msgs.slice(0, msgs.length - 100).remove(); // remove hidden messages
      updateLoadBtn(total);
    }

    function startHoverLabel(text) {
      hoverLabelTimeout = setTimeout(function() {
        glua.showHoverLabel(text);
      }, 1000);
    }

    function dismissMessages() {
      $(".dismiss-button").each(function() {
        glua.dismissMessage($(this).parents(".message").data("id"));
      });
    }

    function restartImageAnims() {
      $(".image-attachment img").each(function() {
        var elem = $(this),
        src = elem.attr("src");
        elem.attr("src", "").attr("src", src);
      });
    }

    function applyChatMode(mode) {
      chatMode = mode;
      entryInput.attr("placeholder", mode == 1 ? MSG_PUBLIC_CHAT_TEXT : MSG_TEAM_CHAT_TEXT);
      entryButton.attr("src", "asset://garrysmod/materials/icon16/" + (mode == 1 ? "world" : "group") + "_edit.png");
    }

    loadBtn.on("click", function() {
      loadBtn
        .addClass("loading")
        .text(LOAD_BTN_LOADING_TEXT);
      glua.prependHiddenMessages(msgContainer.children().length);
    });

    entryButton.on("click", function() {
      glua.say(getText());
      entryInput
        .text("")
        .focus();
    });

    entryInput
      .on("focus", function() {
        glua.isTyping(true); // update is typing status
      })
      .on("keydown", function(e) { // prevent default tab functionality
        if (e.which == 9) { // toggle the chat mode on tab
          e.preventDefault();
          glua.onTabKey(getText());
        }
      })
      .on("keypress", function(e) {
        // prevent registering certain keys and exceeding the char limit
        if (getUTF8ByteLength(getText() + String.fromCharCode(e.which)) > convars.bonchat_msg_max_length) {
          glua.playSound("resource/warning.wav");
          return false;
        }
        return !e.ctrlKey && !e.metaKey && !e.altKey && e.which != 8 && e.which != 13;
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
        if (!$(e.target).closest(chatbox).length) return; // only the chatbox and its children

        switch (true) {
          case elem.hasClass("emoji"): // clicked on an emoji
            entryInput.focus();
            insertText(elem.attr("alt") + " "); // paste the emoji into the entry
            break;
          case elem.hasClass("dismiss-button"): // clicked on a msg dismiss button
            glua.dismissMessage(elem.parents(".message").data("id"));
            break;
          case elem.closest("[href!=''][href]").length != 0: // clicked on an element with an href or parent with href
            e.preventDefault();

            // open the page or media with Glua (or the Steam browser overlay)
            var safe = elem.is(".blocked") || elem.is(".hidden");

            if (elem.is("img") && elem.parent(".image-attachment").length)
              glua.openImage(
                elem.parent().attr("href"),
                elem.attr("src"),
                elem.prop("naturalWidth"),
                elem.prop("naturalHeight"),
                elem.prop("width"),
                elem.prop("height"),
                safe
              );
            else if (elem.is("video") && elem.parent(".video-attachment").length) {
              glua.openVideo(
                elem.parent().attr("href"),
                elem.attr("src"),
                elem.prop("videoWidth"),
                elem.prop("videoHeight"),
                null,
                null,
                safe
              );
            } else
              glua.openPage(elem.closest("[href!=''][href]").attr("href"), safe);
            break;
        }

        if (!entryInput.is(":focus")) glua.isTyping(false); // update is typing status
      })
      .on("mouseover", function(e) {
        var elem = $(e.target),
        url = elem.closest("[href!=''][href]").attr("href");

        // show hover label
        if (elem.is(entryButton)) { // is hovering over the entry button
          startHoverLabel("Send a message in " + (chatMode == 1 ? "public" : "team") + " chat");
        } else if (elem.is(".emoji")) { // is hovering over an emoji
          startHoverLabel(elem.attr("alt"));
        } else if (url) { // is hovering over an element with an href
          startHoverLabel(url);
        }
      })
      .on("mouseout", function() {
        // reset hover label
        clearTimeout(hoverLabelTimeout);
        glua.hideHoverLabel();
      });
    
    // functions only called by GLua when the panel entity opens or closes

    function PANEL_OPEN(mode) {
      panelIsOpen = true;
      applyChatMode(mode); // set chat mode (public/team)
      body.removeClass("panel-closed"); // unhide the elements hidden when the panel was closed
      msgContainer.children().resetFadeOut(); // unfade the messages
      restartImageAnims(); // restart the animation of gif image attachments
      entryInput.focus(); // focus so the user can type in it
    }

    function PANEL_CLOSE(totalMsgs) {
      panelIsOpen = false;
      if (convars.bonchat_auto_dismiss) dismissMessages(); // auto dismiss messages
      resetLoadBtn(totalMsgs); // clears any hidden messages loaded with the load button
      body.addClass("panel-closed"); // hide some elements when the panel is closed
      scrollToBottom(); // reset scroll
      msgContainer.children().startFadeOut(3000, 10000); // start fading out messages
      entryInput.text(""); // clear the entry
    }

    // keep scrolled to bottom while panel is closed
    setInterval(function() {
      if (!panelIsOpen) scrollToBottom();
    }, 100);
  </script>
</html>]]