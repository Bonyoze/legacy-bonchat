<html>
  <head>
    <meta charset="utf-8">
    <style>
      PRELUA: return BonChat.GetResource("bonchat/css/bonchat.css")
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
  <!-- inject libs -->
  <script>
    PRELUA: return BonChat.GetResource("bonchat/js/lib/util.js")
    PRELUA: return BonChat.GetResource("bonchat/js/lib/convars.js")
    PRELUA: return BonChat.GetResource("bonchat/js/lib/markdown.js")
    PRELUA: return BonChat.GetResource("bonchat/js/lib/emojis.js")
    PRELUA: return BonChat.GetResource("bonchat/js/constructor/Message.js")
  </script>
  <!-- add convars -->
  POSTLUA:
    self:AddJSConVar("bonchat_sv_url_whitelist")
    self:AddJSConVar("bonchat_msg_max_length")
    self:AddJSConVar("bonchat_msg_max_attachments")
    self:AddJSConVar("bonchat_cl_url_whitelist")
    self:AddJSConVar("bonchat_auto_dismiss")
    self:AddJSConVar("bonchat_link_max_length")
    self:AddJSConVar("bonchat_load_attachments")
    self:AddJSConVar("bonchat_attach_max_height")
    self:AddJSConVar("bonchat_attach_autoplay")
    self:AddJSConVar("bonchat_attach_volume")
  :ENDLUA
  <!-- convar callbacks -->
  <script>
    // jQuery object methods
    jQuery.fn.applyLinkMaxLength = function() {
      this.each(function() {
        var link = $(this),
        url = link.attr("href"),
        len = convars.getInt("bonchat_link_max_length");
        if (url.length > len)
          link.text(url.slice(0, len) + "...");
        else
          link.text(url);
      });
      return this;
    };
    jQuery.fn.applyAttachMaxHeight = function() {
      $("> img, > video", this).css("max-height", (5 + convars.getInt("bonchat_attach_max_height") / 5) + "rem");
      return this;
    };
    jQuery.fn.applyAttachVolume = function() {
      return $("> video, > audio", this).prop("volume", convars.getFloat("bonchat_attach_volume"));
    };

    convars.addConVarCallback("bonchat_link_max_length", function() {
      $(".link").applyLinkMaxLength();
    });
    convars.addConVarCallback("bonchat_attach_max_height", function() {
      $(".attachment").applyAttachMaxHeight();
    });
    convars.addConVarCallback("bonchat_attach_volume", function() {
      $(".video-attachment, .audio-attachment").applyAttachVolume();
    });
  </script>
  <!-- defines -->
  <script>
    const body = $("body"),
    chatbox = $("#chatbox"),
    loadBtnWrapper = $("#load-button-wrapper"),
    loadBtn = $("#load-button"),
    msgContainer = $("#message-container"),
    entry = $("#text-entry"),
    entryInput = $("#entry-input"),
    entryButton = $("#entry-button");

    const MSG_PUBLIC_CHAT_TEXT = "Send a message in public chat",
    MSG_TEAM_CHAT_TEXT = "Send a message in team chat",
    LOAD_BTN_TEXT = " hidden messages — Click to load",
    LOAD_BTN_LOADING_TEXT = "Loading messages..."

    var panelIsOpen = false,
    chatMode = 1, // 1 = public
    hoverLabelTimeout = null;

    function isFullyScrolled() {
      return util.isFullyScrolled.call(chatbox);
    }

    function scrollToBottom() {
      util.scrollToBottom.call(chatbox);
    }

    function pad(n) {
      return ("00" + n).slice(-2);
    }

    function getTimestampText(s) { // H:MM AM/PM
      s = s - new Date().getTimezoneOffset() * 60000;
      var ms = s % 1000;
      s = (s - ms) / 1000;
      var secs = s % 60;
      s = (s - secs) / 60;
      var mins = s % 60;
      var hrs = (s - mins) / 60;

      return ((hrs - 1) % 12 + 1) + ":" + pad(mins) + " " + (hrs % 24 >= 12 ? "PM" : "AM");
    }

    function getTextClean() {
      return util.getTextClean.call(entryInput);
    }

    function insertTextSafe(text) {
      return util.insertTextSafe.call(entryInput, text);
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
      $(".dismissible").each(function() { glua.dismissMessage($(this).data("id")) });
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

    jQuery.fn.resetFadeOut = function() {
      return this.css({
        "-webkit-transition": "initial",
        "transition": "initial",
        "opacity": "initial"
      });
    };

    function sendMessage(elem, prependHidden) {
      var content = $(".message-content", elem),
      attachments = $(".message-attachments", elem);

      // set send time
      elem.data("sendTime", Date.now());

      var scrolled = isFullyScrolled();

      // show dismiss button
      if (elem.hasClass("dismissible")) content.prepend($("<span class='dismiss-button'>"));

      // show timestamp
      if (elem.hasClass("show-timestamp")) content.prepend($("<span class='timestamp'>").text(getTimestampText(elem.data("sendTime"))));
      
      // load link attachments
      /*var seenURLs = {};
      elem.find(".link").each(function() {
        if (attachments.children().length >= convars.getInt("bonchat_msg_max_attachments")) return;

        var link = $(this),
        url = link.attr("href");

        if (seenURLs[url] || !isWhitelistedURL(url)) return;
        seenURLs[url] = true;

        // try to load attachment
        var attach = elem.appendAttachment(url)
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
      });*/
      
      // load emojis
      elem.find(".pre-emoji").each(function() {
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

      elem.find(".link").applyLinkMaxLength();

      if (prependHidden)
        elem.prependTo(msgContainer); // prepend the hidden message
      else
        elem.appendTo(msgContainer); // append the new message

      // remove oldest message if exceeding 100 total
      if (!prependHidden) {
        var msgs = msgContainer.children();
        if (msgs.length > 100) msgs.first().remove();
      }

      if (scrolled || !panelIsOpen) scrollToBottom();

      if (!panelIsOpen) elem.startFadeOut(3000, 10000); // start fade out animation
    }
  </script>
  <!-- listeners -->
  <script>
    loadBtn.on("click", function() {
      loadBtn
        .addClass("loading")
        .text(LOAD_BTN_LOADING_TEXT);
      glua.prependHiddenMessages(msgContainer.children().length);
    });

    entryButton.on("click", function() {
      glua.say(getTextClean());
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
          glua.onTabKey(getTextClean());
        }
      })
      .on("keypress", function(e) {
        // prevent registering certain keys and exceeding the char limit
        if (util.getUTF8ByteLength(getTextClean() + String.fromCharCode(e.which)) > convars.bonchat_msg_max_length) {
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
            item.getAsString(insertTextSafe);
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
          case elem.is(".emoji"): // clicked on an emoji
            entryInput.focus();
            insertTextSafe(elem.attr("alt") + " "); // paste the emoji into the entry
            break;
          case elem.is(".dismiss-button"): // clicked on a msg dismiss button
            glua.dismissMessage(elem.parents(".message").data("id"));
            break;
          case elem.is(".link"):
            var href = elem.attr("href"),
            attach = elem.data("attachment");
            if (attach && attach.length) {
              var title = href.split("/").pop(),
              safe = attach.is(".blocked") || attach.is(".hidden");
              switch (true) {
                case attach.is(".image-attachment"):
                  var img = $("img", attach);
                  glua.openImage(
                    title,
                    img.attr("src"),
                    img.prop("naturalWidth"),
                    img.prop("naturalHeight"),
                    img.prop("width"),
                    img.prop("height"),
                    safe
                  );
                  break;
                case attach.is(".video-attachment"):
                  var video = $("video", attach);
                  glua.openVideo(
                    title,
                    video.attr("src"),
                    video.prop("videoWidth"),
                    video.prop("videoHeight"),
                    null,
                    null,
                    safe
                  );
                  break;
                case attach.is(".audio-attachment"):
                  var audio = $("audio", attach);
                  glua.openAudio(
                    title,
                    audio.attr("src"),
                    300,
                    54,
                    null,
                    null,
                    safe
                  );
                  break;
              }
            } else
              glua.openPage(href);
            break;
          case elem.is(".safe-link"):
            glua.openPage(elem.attr("href"), true);
            break;
          case elem.is("img") && elem.parent().is(".image-attachment"):
            var attach = elem.parent(),
            title = attach.attr("href").split("/").pop();
            glua.openImage(
              title,
              elem.attr("src"),
              elem.prop("naturalWidth"),
              elem.prop("naturalHeight"),
              elem.prop("width"),
              elem.prop("height"),
              attach.is(".blocked") || attach.is(".hidden")
            );
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
  </script>
  <script>
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
      $(".video-attachment video, .audio-attachment audio").trigger("pause").prop("currentTime", 0);
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
</html>