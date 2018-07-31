var http = require('http');
const crypto = require('crypto');
var rn_bridge = require('rn-bridge');

let msg_number=0;

var listVersionsServer = http.createServer( (request, response) => {
    response.end('Versions: ' + JSON.stringify(process.versions));
});

let listVersionsHTTPServer = listVersionsServer.listen(3001);

// Echo every message received from react-native.
rn_bridge.channel.on('message', (msg) => {
    switch(msg) {
        case 'versions':
            msg_number++;
            rn_bridge.channel.send(
                'This is message number ' +
                msg_number +
                '. Versions: ' +
                JSON.stringify(process.versions)
            );
            break;
        case 'suspend':
            listVersionsHTTPServer.close();
            break;
        case 'resume':
            if(!listVersionsHTTPServer.listening)
                listVersionsHTTPServer = listVersionsServer.listen(3001);
            break;
        default:
            break;
    }
});

// Inform react-native node is initialized.
const secret = 'abcdefg';
const hash = crypto.createHmac('sha256', secret)
    .update('I love cupcakes')
    .digest('hex');
console.log(hash);
rn_bridge.channel.send('Node was initialized.'+hash);