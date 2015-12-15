    seem = require 'seem'
    IO = require 'socket.io-client'

    cfg =
      username: process.env.USERNAME
      password: process.env.PASSWORD
      domain: process.env.DOMAIN
      expire: process.env.EXPIRE ? 1800
      client_socket: 5721
      server_socket: 5722
      fsconf: './conf/freeswitch.xml'
      log: './log'

Generate configuration file

    xml = (require './conf') cfg
    fs.writeFileSync  xml, 'utf-8'

The client connects to FreeSwitch and is able to send commands.

    FS = require 'esl'

    io = IO process.env.IO
    client = FS.client ->
      io.emit 'client started',
        username: cfg.username
        domain: cfg.domain
      io.on 'originate', seem (destination,ack) =>
        {uuid} = yield @queue_api 'originate', "sofia/gateway/#{cfg.domain}/#{destination}"
        ack? uuid
      io.on 'action', seem ({uuid,application,data},ack) =>
        res = yield @command_uuid uuid, application, data
        ack? res

      @on 'DTMF', ({body}) =>
        io.emit 'dtmf', body['DTMF-Digit']

    client.connect cfg.client_socket, '127.0.0.1'

The server is called by FreeSwitch and handle a call.

    server = FS.server ->
      call_io = IO process.env.IO
      call_io.emit 'inbound call', @data
      call_io.on 'action', seem ({application,data},ack) =>
        res = yield @command application, data
        ack? res

    server.listen cfg.server_socket, '127.0.0.1'

Start FreeSwitch

    fs = children.spawn '/opt/freeswitch/bin/freeswitch',
      [
        '-conf', cfg.fsconf
        '-log', cfg.log
        '-db', '/dev/shm/freeswitch'
      ],
      stdio: ['ignore','pipe','pipe']

    fs.stderr.on 'data', (data) ->
      debug 'fs stderr', data
    fs.on 'close', (code) ->
      debug 'fs close', code
    fs.stdout.on 'data', (data) ->
      debug 'fs stdout', data
    fs.on 'error', (error) ->
      debug "fs error: #{error}"

    debug 'Ready.'
