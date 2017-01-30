const net = require("net");

var os = require('os'),
    express = require('express'),
    http = require('http'),
    fs = require('fs'),
    ps = require('ps-node'),
    ip = require('ip');

var tcpport = 3000,
    tcphost = "localhost",
    httpport = 80,
    httpapp = express(),
    httpserver = http.Server(httpapp),
    retryTimeout = 2000,
    volumeDownTimeout = 1000 * 60 * 5,
    volumeDownTimeoutId,
    socket = new net.Socket(),
    serverConnected = false;

/**
 * TCP client
 */
 
// Let's handle the data we get from the server
socket.on("data", function (data) {
    if (data=="sound-detected") {
        // cancel any volume down pending request
        if (volumeDownTimeoutId!==undefined) {
            clearTimeout(volumeDownTimeoutId);
        )
        // request volume up
        writeCommand("volume", 100);
        // request volume down i X minutes
        volumeDownTimeoutId = setTimeout(function(){
            writeCommand("volume", 0);
        }, volumeDownTimeout);
    } else {
        data = JSON.parse(data);
        console.log("Response from server: %s", data.response);
        // Respond back
        socket.write(
            JSON.stringify(
                { response: "Hey there server!" }
            )
        );
    }
});

// If connection is closed
socket.on("end", function() {
    console.log("Disconnected from server");
    serverConnected = false;
    setTimeout(connect, retryTimeout);
});

// Handle the connection error
socket.on("error", function (err) {
    console.log('Connection error');
    serverConnected = false;
    console.log(err);
    setTimeout(connect, retryTimeout);
});

function connect() {
    console.log('Trying to connect');
    socket.connect(tcpport, tcphost, function () {
        console.log("Client: Connected to server");
        serverConnected = true;
        // launch streaming playback
        writeCommand("stream-play", 1);
    });
}

connect();

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
            res.render('home-receiver.ejs', {
                hostname: os.hostname(),
                ip: ip.address(),
                streamingStatus: streamCheck ? "Playing!" : "Not playing!",
                volumeStatus: fs.readFileSync("commands/volume"),
                serverConnected: serverConnected ?  "Yes" : "No";
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
