return [[<html>
  <head>
    <style>
      body {
        margin: 0;
        overflow: hidden;
        -webkit-user-select: none;
        user-select: none;
      }

      video {
        width: 100%;
        height: 100%;
      }
    </style>
  </head>
  <body>
    <video controls autoplay loop>
  </body>
  <script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/jquery.js"></script>
  <script type="text/javascript">
    const elem = $("video").hide();

    function loadElem(url) {
      elem
        .attr("src", url)
        .on("loadeddata", function() {
          if (this.readyState >= 2) $(this).show();
        });
    }
  </script>
</html>]]