    {renderable} = L = require 'acoustic-line'
    {hostname} = require 'os'
    pkg = require './package.json'

    module.exports = renderable (cfg) ->
      {doctype,document,section,configuration,settings,params,param,modules,module,load,network_lists,list,node,global_settings,profiles,profile,mappings,map,context,extension,condition,action,macros} = L
      modules_to_load = [
        'mod_logfile'
        'mod_event_socket'
        'mod_commands'
        'mod_dptools'
        'mod_dialplan_xml'
        'mod_sofia'
        'mod_tone_stream'
      ]

      doctype()
      document 'freeswitch/xml', ->
        section 'configuration', ->
          configuration 'switch.conf', ->
            settings ->
              param 'switchname', "freeswitch-#{pkg.name}@#{hostname()}"
              param 'core-db-name', "/dev/shm/freeswitch/core-#{pkg.name}.db"
              param 'rtp-start-port', 49152
              param 'rtp-end-port', 65534
              param 'max-sessions', 2000
              param 'sessions-per-second', 2000
              param 'min-idle-cpu', 1
              param 'loglevel', 'err'
          configuration 'modules.conf', ->
            modules ->
              for module in modules_to_load
                load {module}
          configuration 'logfile.conf', ->
            settings ->
              param 'rotate-on-hup', true
            profiles ->
              profile 'default', ->
                settings ->
                  param 'logfile', "log/freeswitch.log"
                  param 'rollover', 10*1000*1000
                  param 'uuid', true
                mappings ->
                  map 'important', 'err,crit,alert'
          configuration 'event_socket.conf', ->
            settings ->
              param 'nat-map', false
              param 'listen-ip', '127.0.0.1'
              # Inbound-Socket port
              param 'listen-port', cfg.client_socket
              param 'password', 'ClueCon'

          configuration 'sofia.conf', ->
            global_settings ->
              param 'log-level', 1
              param 'debug-presence', 0
            profiles ->
              profile 'softphone', ->
                gateways ->
                  gateway cfg.domain, ->
                    param 'username', cfg.username
                    param 'password', cfg.password
                    param 'expire-seconds', cfg.expire
                    param 'register', true
                    param 'register-transport', 'udp'

                settings ->
                  param "user-agent-string" , "FreeSWITCH/SoftPhone"
                  param "debug" , 0
                  param "sip-trace" , no
                  param "context" , "public"
                  param "rfc2833-pt" , 101
                  # param "sip-port" , "auto"
                  param "dialplan" , "XML"
                  param "dtmf-duration" , 100
                  param "codec-prefs" , "PCMA"
                  param "use-rtp-timer" , true
                  param "rtp-timer-name" , "soft"
                  param "rtp-ip" , "auto"
                  param "sip-ip" , "auto"
                  param "hold-music" , ""
                  param "apply-nat-acl" , "rfc1918"
                  param "manage-presence" , false
                  param "max-proceeding" , 3
                  param "inbound-codec-negotiation" , "generous"
                  param "nonce-ttl" , 60
                  param "auth-calls" , false
                  param "auth-all-packets" , false
                  # param "ext-rtp-ip" , "auto"
                  # param "ext-sip-ip" , "auto"
                  param "rtp-timeout-sec" , 300
                  param "rtp-hold-timeout-sec" , 1800
                  param "disable-register" , true
                  param "challenge-realm" , "auto_from"

        section 'dialplan', ->
          extension 'socket', ->
            condition 'destination_number', '^.+$', ->
              action 'set', 'mode=invite'
              action 'socket', "127.0.0.1:#{cfg.server_socket} async full"
          extension 'refer', ->
            condition '${sip_refer_to}', '^.+$', ->
              action 'set', 'mode=refer'
              action 'socket', "127.0.0.1:#{cfg.server_socket} async full"

