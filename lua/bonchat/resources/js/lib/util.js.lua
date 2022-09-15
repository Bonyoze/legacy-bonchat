return [[(function() {
  if (window.util) return;

  window.util = {
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
    startFadeOut: function(duration, delay) {
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
    },
    resetFadeOut: function() {
      return this.css({
        "-webkit-transition": "initial",
        "transition": "initial",
        "opacity": "initial"
      });
    }
  };
})();]]