    Docker = require 'dockerode'
    Zappa = require 'zappajs'
    Promise = require 'bluebird'
    docker = new Docker()
    pkg = require '../package.json'
    debug = (require 'debug') "#{pkg.name}:test:private"

    cfg =
      host: '127.0.0.1'
      port: 3456
    describe "Registered", ->
      @timeout 20000
      started = false
      name = "#{pkg.name}-test-1"
      container = null
      it 'Should start', (done) ->
        Zappa.run cfg.host, cfg.port, ->
          @on 'connection', ->
            debug 'Zappa: connection'
          @on 'client started', ->
            debug 'Zappa: client started'
            started = true
            @emit 'stop'
          @on 'freeswitch_disconnect_notice', ->
            debug 'Zappa: FS disconnect notice'
            Promise
            .delay 500
            .then =>
              @emit 'shutdown'
              done() if started
        .server.on 'listening', ->
          debug "Zappa listening, starting docker"
          docker.run "shimaore/#{pkg.name}:#{pkg.version}",
            [],
            [process.stdout,process.stderr],
            {
              Env:[
                "USERNAME=foo"
                "PASSWORD=bar"
                "DOMAIN=phone.example.net"
                "EXPIRE=1800"
                "IO=http://#{cfg.host}:#{cfg.port}"
                "DEBUG=*"
              ]
              HostConfig:
                NetworkMode:'host'
              name
              Tty: false
            },
            (error,data,container) ->
              debug 'Container terminated', {error,data,container}
          .on 'container', (new_container) ->
            debug 'Got container', new_container
            container = new_container

`container.remove` apparently sends the command, but doesn't return (and doesn't actually remove anything).

      after (done) ->
        container.stop {}, (error,data) ->
          debug "Container stop, error: #{error}", container, data
          container.remove (error,data) ->
            debug "Container remove, error: #{error}", container, data
            done()
