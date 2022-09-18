(function() {
  if (window.util) return;

  window.util = {
    getURLWhitelist: function() {
      var svList = convars.getString("bonchat_sv_url_whitelist").split(","),
      clList = convars.getString("bonchat_cl_url_whitelist").split(","),
      list = svList.concat(clList);

      // remove duplicates
      list = list.filter(function(item, index) {
        return list.indexOf(item) == index;
      });

      return list;
    },
    isWhitelistedURL: function(href) {
      var a = document.createElement("a");
      a.href = href;
      var domain = a.host.replace(/^www\./, "") + a.pathname;
      return this.getURLWhitelist().some(function(str) {
        var target = str.replace(/^www\./, "");
        if (target.indexOf("/") == -1) target += "/";
        return domain.slice(0, target.length) == target;
      });
    },
    getUTF8ByteLength: function(str) {
      var s = str.length;
      for (var i = str.length - 1; i >= 0; i--) {
        var code = str.charCodeAt(i);
        if (code > 0x7f && code <= 0x7ff) s++;
        else if (code > 0x7ff && code <= 0xffff) s += 2;
        if (code >= 0xdc00 && code <= 0xdfff) i--; // trail surrogate
      }
      return s;
    },
    // jQuery object methods
    isFullyScrolled: function() {
      var e = this.get(0);
      return Math.abs(e.scrollHeight - e.clientHeight - e.scrollTop) < 1;
    },
    scrollToBottom: function() {
      var e = this.get(0);
      e.scrollTop = e.scrollHeight;
      return this;
    },
    getTextClean: function() {
      return this.text().replace(/\u00A0/g, " "); // converts nbsp characters to spaces
    },
    insertTextSafe: function(text) {
      text = text.replace(/[\u000a\u000d\u2028\u2029\u0009]/g, ""); // prevent new lines and tab spaces
      var len = text.length,
      maxLen = convars.getInt("bonchat_msg_max_length") - util.getUTF8ByteLength(util.getTextClean.call(this) + document.getSelection().toString());
      if (len > maxLen) {
        text = text.substring(0, maxLen); // make sure it won't exceed the char limit
        glua.playSound("resource/warning.wav");
      }
      if (text) {
        document.execCommand("insertText", false, text);
        this.scrollLeft(this.get(0).scrollWidth);
      }
    }
  };
})();