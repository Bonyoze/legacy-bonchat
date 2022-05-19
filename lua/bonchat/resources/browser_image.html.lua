return [[<html>
  <head>
    <style>
      body {
        margin: 0;
        overflow: hidden;
        -webkit-user-select: none;
        user-select: none;
      }

      #image {
        width: 100%;
        height: 100%;
      }
    </style>
  </head>
  <body>
    <img id="image">
  </body>
  <script type="text/javascript" src="asset://garrysmod/html/js/thirdparty/jquery.js"></script>
  <script type="text/javascript">
    const image = $("#image").hide();

    function loadImage(url) {
      image
        .attr("src", url)
        .on("load", function() {
          $(this).show();
        });
    }
  </script>
</html>]]