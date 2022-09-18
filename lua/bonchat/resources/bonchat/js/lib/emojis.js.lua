(function() {
  if (window.emojis) return;

  const SHORTCODE_DATA = JSON.parse('PRELUA: local data = util.JSONToTable(BonChat.GetResource("bonchat/shortcode_data.json")) local tbl = {} for _, v in pairs(data) do for i = 1, #v, 2 do tbl[v[i]] = v[i + 1] end end return util.TableToJSON(tbl) :ENDLUA'),
  UFE0Fg = /\uFE0F/g,
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

  function getIcon(rawText) {
    // if variant is present as \uFE0F
    return toCodePoint(rawText.indexOf(U200D) < 0 ?
      rawText.replace(UFE0Fg, "") :
      rawText
    );
  }

  window.emojis = {
    _emojis: {
      twemoji: function(name) {
        var char = SHORTCODE_DATA[name];
        if (char) return "https://twemoji.maxcdn.com/v/14.0.2/svg/" + getIcon(char) + ".svg";
      },
      steam: function(name) {
        return "https://steamcommunity-a.akamaihd.net/economy/emoticon/" + name;
      },
      icon16: function(name) {
        return "asset://garrysmod/materials/icon16/" + name + ".png";
      },
      discord: function(id, animated) {
        return "https://cdn.discordapp.com/emojis/" + id + "." + (animated ? "gif" : "png");
      }
    },
    getURL: function(group) {
      var groupFn = this._emojis[group];
      if (groupFn != null) return groupFn.call(null, Array.prototype.slice.call(arguments, 1));
    },
    addEmojiGroup: function(name, fn) {
      this._emojis[name.toLowerCase()] = fn;
    },
    removeEmojiGroup: function(name) {
      delete this.emojis[name.toLowerCase()];
    }
  };
})();