const http = require('http');

var handler = function(request, response) {
    response.writeHead(200);
    response.end("<h1>Hello world from nodejs!</h1>");
};

module.exports = function() {
    return true;
}

if(process.argv[2] != null && process.argv[2] == 'listen') {
    var www = http.createServer(handler);
    www.listen(80);
}