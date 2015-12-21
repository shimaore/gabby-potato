    seem = require 'seem'
    IO = require 'socket.io-client'
    FS = require 'esl'
    fs = require 'fs'
    Promise = require 'bluebird'
    Supervisor = require 'supervisord'
    pkg = require './package'
    debug = (require 'debug') pkg.name

    run = seem ->
      supervisor = Promise.promisifyAll Supervisor.connect process.env.SUPERVISOR

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
      fs.writeFileSync cfg.fsconf, xml, 'utf-8'

The client connects to FreeSwitch and is able to send commands.

      io = IO process.env.IO
      client_handler = ->
        debug 'Client started'
        io.emit 'client started',
          username: cfg.username
          domain: cfg.domain
        io.on 'originate', seem (destination,ack) =>
          {uuid} = yield @queue_api "originate sofia/gateway/#{cfg.domain}/#{destination}"
          ack? uuid
        io.on 'action', seem ({uuid,application,data},ack) =>
          res = yield @command_uuid uuid, application, data
          ack? res

`stop` will stop the FreeSwitch process, but Supervisord will automatically restart it.

        io.on 'stop', seem (data,ack) =>
          {uuid} = yield @queue_api 'fsctl shutdown asap'
          ack? uuid

`shutdown` will stop Supervisord, effectively terminating the Docker.io container.

        io.on 'shutdown', seem ->
          yield supervisor.shutdownAsync()

        @on 'DTMF', ({body}) =>
          io.emit 'dtmf', body['DTMF-Digit']
        @on 'freeswitch_disconnect_notice', ->
          io.emit 'freeswitch_disconnect_notice'

The server is called by FreeSwitch and handle a call.

      server = FS.server ->
        call_io = IO process.env.IO
        call_io.emit 'inbound call', @data
        call_io.on 'action', seem ({application,data},ack) =>
          res = yield @command application, data
          ack? res

      server.listen cfg.server_socket, '127.0.0.1'

Start FreeSwitch

      start_client = ->
        debug "Client: connecting to #{cfg.client_socket}"
        client = FS.client client_handler, (error) ->
          debug "Client handler error: #{error}", error
          client = null
          start_client()

        sc = client.connect cfg.client_socket, '127.0.0.1'
        sc.once 'error', seem (error) ->
          debug "Client error: #{error}, re-trying in 500 ms"
          sc = client = null
          yield Promise.delay 500
          start_client()
        sc

      debug 'Starting FreeSwitch'
      yield supervisor.startProcessAsync 'freeswitch'
      debug 'FreeSwitch started, starting client.'
      start_client()

      debug 'Ready.'

    @run = run
    if require.main is module
      run()
