    Axon = require 'axon'
    FS = require 'esl'
    fs = require 'fs'
    child_process = require 'child_process'
    debug = (require 'debug') 'gabby-potato:server'
    {hostname} = require 'os'

    run = ->
      cwd = process.cwd()

      cfg =
        hostname: process.env.HOSTNAME ? hostname()
        username: process.env.USERNAME
        password: process.env.PASSWORD
        domain: process.env.DOMAIN
        expire: process.env.EXPIRE ? 1800
        server_socket: 25722
        server_host: '127.0.0.1'
        fsconf: "#{cwd}/conf/freeswitch.xml"
        log: "#{cwd}/log"

      try
        cmd = JSON.parse process.argv[2]
        cfg = Object.assign cfg, cmd if cmd?

Generate configuration file

      xml = (require './conf') cfg
      fs.writeFileSync cfg.fsconf, xml, 'utf-8'

Handle inbound calls

      pub = Axon.socket 'pub'
      pub.bind 3000

Is the `sub` necessary? We can send events over the Event Socket using the UUID.

      sub = Axon.socket 'sub'
      sub.bind 3001

      call_handler = ->
        pub.send @uuid, @data

        sub.on 'message', (uuid,cmd,data) =>
          return unless uuid is @uuid
          this[cmd].apply this, data

      server = FS.server call_handler

Start FreeSwitch

      debug 'Starting FreeSwitch'
      child = child_process.spawn '/opt/freeswitch/bin/freeswitch',
        [
          '-c'
          '-nf'
          '-conf', "#{cwd}/conf"
          '-log', "#{cwd}/log"
          '-db', '/dev/shm/freeswitch'
          '-temp', "#{cwd}/log"
        ],
        stdio: 'inherit'
      child.on 'error', (error) ->
        debug "Failed to start FreeSwitch: #{error}"
      child.on 'exit', (code) ->
        debug "FreeSwitch exit'ed with code #{code}."
      child.on 'close', (code) ->
        debug "FreeSwitch closed stdio with code #{code}."
        server.close -> process.exit 0
      server.listen cfg.server_socket, cfg.server_host

      debug 'Ready.'

    @run = run
    if require.main is module
      run()
