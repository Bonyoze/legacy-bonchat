return [[<html>
  <head>
    <style>
      html, body {
        margin: 0;
        padding: 0;
        overflow: hidden;
      }

      img {
        width: 100%;
        height: 100%;
        cursor: pointer;
        -webkit-user-select: none;
        user-select: none;
      }
    </style>
  </head>
  <body></body>
  <script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/jquery.js"></script>
  <script>
    $(document)
      .on("click", function() {
        glua.openURL($("img").attr("src"));
      });
  </script>
</html>]]