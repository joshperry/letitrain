"strict mode"
$ ->
    $('#zones a').click (e) ->
        e.preventDefault() # Don't follow the link
        el = $(this)

        # Toggle the visual
        #el.toggleClass 'on'

        # Figure out the relay and whether to turn it off or on
        relay = el.data "relay"
        state = if el.hasClass 'on' then false else true

        # Actuate the relay
        $.ajax
            url: "/relay/#{relay}"
            type: "POST"
            data: JSON.stringify {"state": state}
            contentType: "application/json; charset=utf-8"
            dataType: "json"

    socket = io.connect '/'

    socket.on 'relayChange', (data) ->
        el = $("#zones a[data-relay='#{data.relay + 1}']")
        if data.state
            console.log('added class')
            el.addClass("on")
        else
            console.log('removed class')
            el.removeClass("on")

        $('#update').text("Relay #{data.relay} turned #{if data.state then 'on' else 'off'} #{(new Date()).toString()}")

    $('#but').click (e) ->
        socket.emit 'relay', {"state": true}
