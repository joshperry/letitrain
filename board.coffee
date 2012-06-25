net = require('net')

# Connect to the board
class Board extends require('events').EventEmitter
    constructor: (@ipaddress, @port) ->
        @rbuf = ''
        @relayState = [off, off, off, off, off, off, off, off, off, off]

    connect: ->
        console.log("connecting to board")
        @connection = net.connect(@port, @ipaddress)
        @connection.setEncoding('utf8')

        # Connection established handler
        @connection.on 'connect', () => # Fat arrow, rebind 'this' to containing class, not connection
            # Request all relay status update on connection
            @connection.write('SR\n')

        # Incoming data handler
        @connection.on 'data', (data) =>
            # Buffer incoming data until we get an \r
            @rbuf += data
            while (index = @rbuf.indexOf('\r')) isnt -1
                response = @rbuf.slice(0, index)
                # Submit full response for processing
                this.processResponse(response)
                @rbuf = if @rbuf.length > index + 1 then @rbuf.slice(index + 1) else ''
        
        # Disconnection handler
        @connection.on 'end', () =>
            console.log("Board closed connection")
            @connection = null

    # Send a relay control command to the board
    controlRelay: (relayNumber, state, delay) ->
        sstate = if state then '1' else '0'
        command = if delay? then "#{relayNumber}T#{sstate}#{delay}\r" else "#{relayNumber}R#{sstate}\r"
        @connection.write(command)

        console.log("relay command sent: %s", command)

    # Process each \r seperated response from the board
    processResponse: (data) ->
        console.log("Board Response: #{data} (#{data.length})")
        
        # Update relay state from relay state responses
        match = data.match(/(\d+)[rR]([01])/)
        if match?
            relayn = parseInt(match[1]) - 1
            state = if match[2] is '1' then on else off
            @relayState[relayn] = state
            this.emit('relayChange', {relay: relayn, state: state})
            console.log("state for relay #{relayn}:#{state}")

module.exports = Board
