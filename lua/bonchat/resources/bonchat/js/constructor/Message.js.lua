(function() {
  if (window.Message) return;

  const DEFAULT_TEXT_COLOR = "#97d3ff";

  window.Message = {
    new: function(id) {
      return $("<div>")
        .addClass("message")
        .attr("data-id", id != null ? id : "")
        .append($("<div>").addClass("message-content"))
        .append($("<div>").addClass("message-attachments"));
    },
    // jQuery object methods
    setTextColor: function(color) {
      this.data("textColor", color);
    },
    appendText: function(str) {
      $(".message-content", this).append(
        $("<span>")
          .text(str)
          .css("color", this.data("textColor") || DEFAULT_TEXT_COLOR)
      );
      return this;
    },
    appendMarkdown: function(str) {
      $(".message-content", this).append(
        $("<span>")
          .html(markdown.outputHTML(markdown.nestedParse(str)))
          .css("color", this.data("textColor") || DEFAULT_TEXT_COLOR)
      );
      return this;
    },
    appendPlayer: function(name, color, steamID) {
      var elem = $("<span class='player'>")
        .text(name)
        .css("color", color || DEFAULT_TEXT_COLOR);
      if (typeof steamID === "string" && steamID !== "NULL") elem.on("click", function() { glua.showProfile(steamID) });
      $(".message-content", this).append(elem);
      return this;
    },
    appendAttachment: function(url) {
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
    },
    getByID: function(id) {
      return $(".message[data-id='" + id + "']", this);
    }
  };
})();