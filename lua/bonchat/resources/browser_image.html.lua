return [[<html>
  <head>
    <style>
      body {
        margin: 0;
        overflow: hidden;
        -webkit-user-select: none;
        user-select: none;
      }

      img {
        width: 100%;
        height: 100%;
      }
    </style>
  </head>
  <body>
    <img>
  </body>
  <script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/jquery.js"></script>
  <script type="text/javascript">
    const elem = $("img").hide();

    function loadElem(url) {
      elem
        .attr("src", url)
        .on("load", function() {
          $(this).show();
        });
    }
  </script>
</html>]]