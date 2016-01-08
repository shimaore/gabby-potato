    {renderable} = L = require 'acoustic-line'
    {hostname} = require 'os'
    pkg = require './package.json'

    module.exports = renderable (cfg) ->
      {doctype,document,section,configuration,settings,params,param,modules,module,load,network_lists,list,node,global_settings,profiles,profile,mappings,map,context,extension,condition,action,macros,gateways,gateway} = L
      modules_to_load = [
        'mod_logfile'
        'mod_event_socket'
        'mod_commands'
        'mod_dptools'
        'mod_httapi'
        'mod_sndfile'
        'mod_shout'
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
              param 'loglevel', 'debug'
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
          configuration name:'httapi.conf', ->
            settings ->
            profiles ->
              # In mod_httapi.c/fetch_cache_data(), the profile_name might be set as a parameter, a setting, or defaults to `default`.
              profile name:'default', ->
                params ->
                  param 'gateway-url', cfg.httapi_url ? ''
                  param 'gateway-credentials', cfg.httapi_credentials ? ''
                  param 'auth-scheme', cfg.httapi_authscheme ? 'basic'
                  param 'enable-cacert-check', cfg.httapi_cacert_check ? true
                  param 'enable-ssl-verifyhost', cfg.httpapi_verify_host ? true
                  param 'timeout', cfg.httapi_timeout ? 120

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
                    param 'ping', 15
                    param 'extension-in-contact', true
                    param 'cid-type', 'none'

                settings ->
                  param "user-agent-string" , "FreeSWITCH/SoftPhone"
                  param "debug" , 0
                  param "sip-trace" , yes

See [inline dialplain in SIP profile](https://wiki.freeswitch.org/wiki/Misc._Dialplan_Tools_InlineDialplan#SIP_Profile).

                  param "dialplan" , "inline:'socket:#{cfg.server_host}:#{cfg.server_socket} async full'"
                  param "context" , 'dummy-unused'
                  param "sip-ip" , "auto"
                  param "ext-sip-ip" , "auto-nat"
                  # param "sip-port" , "auto"

                  # param "apply-nat-acl" , "rfc1918"
                  param 'local-network-acl', 'localnet.auto'
                  param 'stun-enabled', true

                  param "manage-presence" , false
                  param "max-proceeding" , 3
                  param "nonce-ttl" , 60
                  param "auth-calls" , false
                  param "auth-all-packets" , false
                  param "disable-register" , true
                  param "challenge-realm" , "auto_from"

RTP/SDP

Enter the dialplan without codec neg done.

                  param 'inbound-late-negotiation', true

                  param "rtp-ip" , "auto"
                  param "ext-rtp-ip" , "auto-nat"

                  param "inbound-codec-negotiation" , "generous"
                  param 'suppress-cng', false
                  param 'vad', 'none'

                  param "codec-prefs" , "PCMA"

                  param "rfc2833-pt" , 101
                  param "rtp-timeout-sec" , 300
                  param "rtp-hold-timeout-sec" , 1800

Media

                  param "dtmf-duration" , 100
                  param "hold-music" , ""
                  param "use-rtp-timer" , true
                  param "rtp-timer-name" , "soft"
