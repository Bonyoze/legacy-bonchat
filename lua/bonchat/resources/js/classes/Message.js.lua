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

// message constructor
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
          link.data("attachment", attach);
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

jQuery.fn.getMessageByID = function(id) {
  return $(".message[data-id='" + id + "']", this);
};