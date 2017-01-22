<?php

if (isset($_REQUEST['action'])) {
    $action = filter_var ( $_REQUEST['action'], FILTER_SANITIZE_STRING);
    
    switch ($action) {
        case 'shutdown':
            $res = file_put_contents('shutdown', 1);
            break;
        case 'reboot':
            $res = file_put_contents('reboot', 1);
            break;
    }
}
else {
?>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
    <title>bbfone controller</title>

    <!-- Bootstrap -->
    <link href="css/bootstrap.min.css" rel="stylesheet">
    <link href="css/font-awesome.min.css" rel="stylesheet">
    
    <style>
    .btn{margin-bottom:10px;}
    </style>

  </head>
  <body>

    <div class="container-fluid">
        
        <div class="row">
            <div class="col-xs-12">

                <button type="button" class="btn btn-danger btn-lg btn-block" autocomplete="off" data-toggle="collapse" data-target="#shutdown-info" id="shutdown">
                     <i class="fa fa-stop-circle-o" aria-hidden="true"></i> Shutdown
                </button>
                <div class="collapse" id="shutdown-info">
                    <div class="well">
                    Shutting down, you can unpkug in about 15 seconds.
                    </div>
                </div>

                <button type="button" class="btn btn-info btn-lg btn-block" autocomplete="off" data-toggle="collapse" data-target="#reboot-info" id="reboot">
                    <i class="fa fa-undo" aria-hidden="true"></i> Reboot
                </button>
                <div class="collapse" id="reboot-info">
                    <div class="well">
                    Rebooting, please wait.
                    </div>
                </div>
        
            </div>
        </div>
        
    </div>
    
    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="js/jquery.min.js"></script>
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <script src="js/bootstrap.min.js"></script>
    
    <script type="text/javascript">
    $( document ).ready(function() {
        $('#shutdown').on('click', function () {
            $.ajax({
                url: "/control/index.php?action=shutdown",
            });
        });
        $('#reboot').on('click', function () {
            $.ajax({
                url: "/control/index.php?action=reboot",
            });
        });
    });
    </script>
  </body>
</html>

<?php
}
