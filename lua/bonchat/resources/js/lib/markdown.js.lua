return [[(function() {
  if (window.markdown) return;

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

  window.markdown = {
    _rules: {
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
          return this.htmlTag("span", this.htmlTag("span", output(node.content)), { class: "spoiler" });
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
          var text = this.sanitizeText(node.originalText);
          switch (node.source ? node.source.toLowerCase() : "default") {
            case "default": // use twemoji if not set
              var char = getEmojiByShortcode(node.name);
              if (char) {
                return this.htmlTag("span", text, {
                  class: "pre-emoji",
                  src: buildTwemojiURL(char)
                });
              } else
                return text;
            case "steam":
            case "s":
              return this.htmlTag("span", text, {
                class: "pre-emoji",
                src: buildSteamEmojiURL(node.name)
              });
            case "icon":
            case "i":
              return this.htmlTag("span", text, {
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
          var text = this.sanitizeText(node.originalText);
          return this.htmlTag("span", text, {
            class: "pre-emoji",
            src: buildDiscordEmojiURL(node.id, node.animated)
          });
        }
      },
      safe_link: {
        match: /^<([^: >]+:\/\/+[^ >]+)>/,
        parse: function(capture) {
          return {
            content: capture[1]
          };
        },
        html: function(node) {
          return this.htmlTag("span", node.content, { class: "safe-link", href: node.content });
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
          return this.htmlTag("span", node.content, { class: "link", href: node.content });
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
          return this.htmlTag("em", output(node.content));
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
          return this.htmlTag("strong", output(node.content));
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
          return this.htmlTag("u", output(node.content));
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
          return this.htmlTag("del", output(node.content));
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
            return this.htmlTag("span", null, { style: "color:rgb(" + node.content + ")" }, false);
          else if (/^([0-9a-f]{6}|[0-9a-f]{3})$/i.test(node.content))
            return this.htmlTag("span", null, { style: "color:#" + node.content }, false);
          else {
            var s = new Option().style;
            s.color = node.content;
            if (s.color)
              return this.htmlTag("span", null, { style: "color:" + node.content }, false);
            else
              return this.sanitizeText(node.originalText);
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
          return this.sanitizeText(node.content);
        }
      }
    },
    setRule: function(name, match, parse, html) {
      this._rules[name] = { match, parse, html };
    },
    removeRule: function(name) {
      delete this._rules[name];
    },
    sanitizeText: function(text) {
      return text.replace(SANITIZE_TEXT_REGEX, function(char) {
        return SANITIZE_TEXT_CODES[char];
      });
    },
    htmlTag: function(tagName, content, attributes, isClosed) {
      attributes = attributes || {};
      isClosed = typeof isClosed !== "undefined" ? isClosed : true;
  
      var attributeString = "";
      for (var attr in attributes) {
        var attribute = attributes[attr];
        // removes falsey attributes
        if (Object.prototype.hasOwnProperty.call(attributes, attr) && attribute) {
          attributeString += " " +
            this.sanitizeText(attr) + '="' +
            this.sanitizeText(attribute) + '"';
          }
      }
  
      var unclosedTag = "<" + tagName + attributeString + ">";
  
      if (isClosed)
        return unclosedTag + content + "</" + tagName + ">";
      else
        return unclosedTag;
    },
    nestedParse: function(source) {
      const ruleList = Object.keys(this._rules);
      var result = [];
  
      while (source) {
        var ruleType = null,
        rule = null,
        capture = null;
  
        var i = 0;
        var currRuleType = ruleList[0];
        var currRule = this._rules[currRuleType];
  
        do {
          var currCapture = currRule.match.exec(source);
  
          if (currCapture) {
            ruleType = currRuleType;
            rule = currRule;
            capture = currCapture;
          }
          
          i++
          currRuleType = ruleList[i];
          currRule = this._rules[currRuleType];
        } while (currRule && !capture);
        
        if (rule == null || capture == null) throw new Error("Could not find a matching rule");
        if (capture.index) throw new Error("'match' must return a capture starting at index 0");
  
        var parsed = rule.parse(capture, this.nestedParse);
  
        if (Array.isArray(parsed))
          Array.prototype.push.apply(result, parsed);
        else {
          if (parsed.type == null) parsed.type = ruleType;
          result.push(parsed);
        }
  
        source = source.substring(capture[0].length);
      }
  
      return result;
    },
    outputHTML: function(ast) {
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
  
          result += this.outputHTML(node);
        }
  
        return result;
      } else
        return this._rules[ast.type].html(ast, this.outputHTML);
    }
  };
})();]]