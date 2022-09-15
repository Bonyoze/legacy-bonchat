return [[<html>
  <head>
    <meta charset="utf-8">
    <style>
      PRELUA: return BonChat.GetResource("css/bonchat.css")
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
    PRELUA: return BonChat.GetResource("js/lib/util.js")
    PRELUA: return BonChat.GetResource("js/lib/convars.js")
    PRELUA: return BonChat.GetResource("js/lib/markdown.js")
    PRELUA: return BonChat.GetResource("js/lib/emojis.js")
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
    // jquery object methods
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
      jQuery.fn.applyLinkMaxLength.call($(".link"));
    });
    convars.addConVarCallback("bonchat_attach_max_height", function() {
      jQuery.fn.applyAttachMaxHeight.call($(".attachment"));
    });
    convars.addConVarCallback("bonchat_attach_volume", function() {
      jQuery.fn.applyAttachVolume.call($(".video-attachment, .audio-attachment"));
    });
  </script>
  <!-- misc functions -->
  <script>
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

    function getURLWhitelist() {
      var svList = convars.getString("bonchat_sv_url_whitelist").split(","),
      clList = convars.getString("bonchat_cl_url_whitelist").split(","),
      list = svList.concat(clList);

      // remove duplicates
      list = list.filter(function(item, index) {
        return list.indexOf(item) == index;
      });

      return list;
    }

    function isWhitelistedURL(href) {
      var a = document.createElement("a");
      a.href = href;
      var domain = a.host.replace(/^www\./, "") + a.pathname;
      return this.getURLWhitelist().some(function(str) {
        var target = str.replace(/^www\./, "");
        if (target.indexOf("/") == -1) target += "/";
        return domain.slice(0, target.length) == target;
      });
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
  </script>
  <!-- main script -->
  <script>
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

    function isFullyScrolled() {
      return util.isFullyScrolled.call(chatbox);
    }

    function scrollToBottom() {
      util.scrollToBottom.call(chatbox);
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
          case elem.is(".emoji"): // clicked on an emoji
            entryInput.focus();
            insertText(elem.attr("alt") + " "); // paste the emoji into the entry
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
</html>]]