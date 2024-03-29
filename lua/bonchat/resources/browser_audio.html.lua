return [[<html>
  <head>
    <style>
      body {
        margin: 0;
        overflow: hidden;
        -webkit-user-select: none;
        user-select: none;
      }

      audio {
        display: block;
        max-width: 100%;
        max-height: 100%;
      }
    </style>
  </head>
  <body>
    <audio controls controlsList="nofullscreen nodownload" autoplay>
  </body>
  <script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/jquery.js"></script>
  <script type="text/javascript">
    const elem = $("audio").hide();

    function loadElem(url) {
      elem
        .attr("src", url)
        .on("loadeddata", function() {
          if (this.readyState >= 2) $(this).show();
        });
    }
  </script>
</html>]]