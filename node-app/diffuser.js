const net = require("net");

var os = require('os'),
    express = require('express'),
    http = require('http'),
    fs = require('fs'),
    ps = require('ps-node'),
    rpio = require('rpio'), // https://github.com/jperkin/node-rpio/
    ip = require('ip');

var tcpport = 3000,
    tcphost = "0.0.0.0", // accept connection from every host
    httpport = 80,
    httpapp = express(),
    httpserver = http.Server(httpapp),
    gpiopin = 7,
    clientConnected = false;

/**
 * TCP server
 */
 
var socket;

net.createServer(function (sock) {
    console.log("Server: Client connected");
    clientConnected = true;
    
    socket = sock;

    // If connection is closed
    sock.on("end", function() {
        console.log("Server: Client disconnected");
        clientConnected = false;
    });

    // Handle the connection error
    sock.on("error", function (err) {
        console.log("connection error");
        console.log(err);
        clientConnected = false;
    });

    // Handle data from client
    sock.on("data", function(data) {
        data = JSON.parse(data);
        console.log("Response from client: %s", data.response);
    });

    // Let's response with a hello message
    sock.write(
        JSON.stringify(
            { response: "Hey there client!" }
        )
    );
})

// Listen for connections
.listen(tcpport, tcphost, function () {
    console.log("Server: Listening");
});

/**
 * GPIO Management
 */
 
rpio.open(gpiopin, rpio.INPUT);
rpio.poll(
    gpiopin,
    function(pin) {
        if (rpio.read(gpiopin)==rpio.LOW) {
            console.log("sound detected !");
            if (socket!=undefined) {
                socket.write('sound-detected');
            }
        }
    }
    //rpio.POLL_LOW // Watch only low events
);

/**
 * HTTP server
 */
 
// public assets
httpapp.use(express.static(__dirname + '/public'))

// show default page
.get('/', function(req, res) {
    // check gst-launch
    ps.lookup(
        {
            command: 'gst-launch.*',
            psargs: '-e'
        },
        function(err, resultList ) {
            if (err) {
                throw new Error( err );
            }
     
            var streamCheck = false;
            
            resultList.forEach(function( process ){
                if( process ){
                    streamCheck = true;
                    console.log( 'PID: %s, COMMAND: %s, ARGUMENTS: %s', process.pid, process.command, process.arguments );
                }
            });
            
            // render template
            res.render('home-diffuser.ejs', {
                hostname: os.hostname(),
                ip: ip.address(),
                streamingStatus: streamCheck ? "Streaming!" : "Not streaming!",
                clientConnected: clientConnected ? "Yes" : "No"
            });
        }
    );
})

// reboot command
.get('/reboot', function(req, res) {
    writeCommand("reboot", 1);
    res.send('ok');
})

// shutdown command
.get('/shutdown', function(req, res) {
    writeCommand("shutdown", 1);
    res.send('ok');
})

// redirect to default page if resource not found
.use(function(req, res, next){
    res.redirect('/');
});

httpserver.listen(httpport);

/**
 * Streaming launch
 */

writeCommand("stream-emit", 1);
 
/**
 * Helper to write file
 */

function writeCommand(filename, value) {
    fs.writeFile("commands/"+filename, value, function(err) {
        if(err) {
            return console.log(err);
        }
        console.log(filename+" file written!");
    });
}
