jQuery.fn._loadAttach = function() {
  if (!this.hasClass("attachment")) return;

  var scrolled = isFullyScrolled();
  this.removeClass("loading").cvarApplyAttachMaxHeight();
  if (scrolled) scrollToBottom();

  if (this.is(".video-attachment, .audio-attachment")) this.cvarApplyAttachVolume();

  this.trigger("attachment:load");

  return this;
};

jQuery.fn._errorAttach = function() {
  if (!this.hasClass("attachment")) return;

  this.addClass("failed").removeClass("loading").trigger("attachment:error");

  return this;
};

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
    attachment._loadAttach();
  } else
    attachment._errorAttach();

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
        attachment._loadAttach();
      })
      .on("error", function() { // image failed to load
        if (!retry && base64) { // retry with base64
          $(this).attr("src", base64);
          retry = true
        } else { // failed to load base64 or no base64 provided
          $(this).remove();
          attachment._errorAttach();
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
    $("<video controls controlsList='nofullscreen nodownload'>")
      .prop("autoplay", convars.bonchat_attach_autoplay)
      .on("loadeddata", function() {
        if (this.readyState >= 2) attachment._loadAttach();
      })
      .on("error", function() {
        $(this).remove();
        attachment._errorAttach();
      })
      .attr("src", url)
  );

  return this;
};

jQuery.fn._loadAudio = function(url) {
  if (!this.hasClass("audio-attachment")) return;

  var attachment = this;

  attachment.append(
    $("<audio controls controlsList='nofullscreen nodownload'>")
      .prop("autoplay", convars.bonchat_attach_autoplay)
      .on("loadeddata", function() {
        if (this.readyState >= 2) attachment._loadAttach();
      })
      .on("error", function() {
        $(this).remove();
        attachment._errorAttach();
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
          attachment._errorAttach();
        })
        .attr("src", url);
    })
    .attr("src", url);
  
  return this;
};

jQuery.fn.getAttachmentByID = function(id) {
  return $(".attachment[data-id='" + id + "']", this);
};