
# Module dependencies.

express = require('express')
routes = require('./routes')
io = require('socket.io')
Board = require('./board')

app = module.exports = express.createServer()
io = io.listen(app)

# Configuration

app.configure () ->
    app.set('views', __dirname + '/views')
    app.set('view engine', 'jade')
    app.use(express.bodyParser())
    app.use(express.methodOverride())
    app.use(app.router)
    app.use(express.static(__dirname + '/public'))

app.configure 'development', () ->
    app.use(express.errorHandler({dumpExceptions: true, showStack: true}))

app.configure 'production', () ->
    app.use(express.errorHandler())

#  Routes

app.get '/', routes.index

# Relay control route
app.post '/relay/:id([0-9]{1,2})', (req, res) ->
    console.log("control request for relay %d:%s", req.params.id, req.body.state)
    
    return res.send({'success': no}) unless req.body.state?

    board.controlRelay(req.params.id, req.body.state, req.body.delay)
    res.send('success': yes)

# Relay status route
app.get '/relays/:id([0-9]{1,2})', (req, res) ->
    relayn = parseInt(req.params.id)
    res.send { 'state': board.relayState[relayn] }

app.get '/relays', (req, res) ->
    res.send { 'state': board.relayState }

app.get '/zones', (req, res) ->
    res.send
        zones: [
            {name: 'Zone 1'
            relay: 1
            state: board.relayState[0]},
            {name: 'Zone 2'
            relay: 2
            state: board.relayState[1]},
            {name: 'Zone 3'
            relay: 4
            state: board.relayState[3]},
            {name: 'Zone 4'
            relay: 5
            state: board.relayState[4]},
            {name: 'Test Zone'
            relay: 6
            state: board.relayState[5]}
        ]

app.listen 3000, ->
    console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env)

# Websocket connections
io.sockets.on 'connection', (socket) ->
    socket.on 'relay', (data) ->
        console.log("ws relay request #{data.state}")

board = new Board "192.168.0.225", 10001
board.connect()

board.on 'relayChange', (data) ->
    io.sockets.emit('relayChange', data)
