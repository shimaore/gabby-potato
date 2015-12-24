    seem = require 'seem'
    IO = require 'socket.io-client'
    FS = require 'esl'
    fs = require 'fs'
    Promise = require 'bluebird'
    Supervisor = require 'supervisord'
    pkg = require './package'
    debug = (require 'debug') "#{pkg.name}:server"

    run = seem ->
      supervisor = Promise.promisifyAll Supervisor.connect process.env.SUPERVISOR

      cfg =
        username: process.env.USERNAME
        password: process.env.PASSWORD
        domain: process.env.DOMAIN
        expire: process.env.EXPIRE ? 1800
        client_socket: 5721
        client_host: '127.0.0.1'
        server_socket: 5722
        server_host: '127.0.0.1'
        fsconf: './conf/freeswitch.xml'
        log: './log'

Generate configuration file

      xml = (require './conf') cfg
      fs.writeFileSync cfg.fsconf, xml, 'utf-8'

The client connects to FreeSwitch and is able to send commands.

      io = IO process.env.IO
      client_handler = (require './client_handler') cfg, io

The server is called by FreeSwitch and handle a call.

      server = FS.server ->

Start a new Socket.IO stream for this call.

        call_io = IO process.env.IO
        call_io.on 'action', seem ({application,data},ack) =>
          debug 'action', {application,data}
          res = yield @command application, data
          debug 'action response', ack, res
          ack? res
        call_io.emit 'inbound call', @data

      debug "Starting server on #{cfg.server_host}:#{cfg.server_socket}"
      server.listen cfg.server_socket, cfg.server_host

Start FreeSwitch

      start_client = ->
        debug "Client: connecting to #{cfg.client_host}:#{cfg.client_socket}"
        client = FS.client client_handler, (error) ->
          debug "Client handler error: #{error}", error
          client = null
          start_client()

        sc = client.connect cfg.client_socket, cfg.client_host
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
