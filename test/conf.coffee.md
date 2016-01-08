    {expect} = require 'chai'

    describe 'Configuration', ->
      conf = require '../conf'

      it 'should compile', ->
        cfg =
          client_socket: 5721
          server_host: 'example.net'
          server_socket: 6712
          domain: 'example.com'
          username: 'foo'
          password: 'bar'
          expire: 1800
        process.env.SPOOL = '/opt/freeswitch/var/spool'
        expect(conf cfg).to.equal '''
          <?xml version="1.0" encoding="utf-8" ?>
          <document type="freeswitch/xml">
          <section name="configuration">
          <configuration name="switch.conf">
          <settings>
          <param name="switchname" value="freeswitch-gabby-potato@voyageur.shimaore.net"/>
          <param name="core-db-name" value="/dev/shm/freeswitch/core-gabby-potato.db"/>
          <param name="rtp-start-port" value="49152"/>
          <param name="rtp-end-port" value="65534"/>
          <param name="max-sessions" value="2000"/>
          <param name="sessions-per-second" value="2000"/>
          <param name="min-idle-cpu" value="1"/>
          <param name="loglevel" value="debug"/>
          </settings>
          </configuration>
          <configuration name="modules.conf">
          <modules>
          <load module="mod_logfile"/>
          <load module="mod_event_socket"/>
          <load module="mod_commands"/>
          <load module="mod_dptools"/>
          <load module="mod_httapi"/>
          <load module="mod_sndfile"/>
          <load module="mod_shout"/>
          <load module="mod_sofia"/>
          <load module="mod_spandsp"/>
          <load module="mod_tone_stream"/>
          </modules>
          </configuration>
          <configuration name="logfile.conf">
          <settings>
          <param name="rotate-on-hup" value="true"/>
          </settings>
          <profiles>
          <profile name="default">
          <settings>
          <param name="logfile" value="log/freeswitch.log"/>
          <param name="rollover" value="10000000"/>
          <param name="uuid" value="true"/>
          </settings>
          <mappings>
          <map name="important" value="err,crit,alert"/>
          </mappings>
          </profile>
          </profiles>
          </configuration>
          <configuration name="event_socket.conf">
          <settings>
          <param name="nat-map" value="false"/>
          <param name="listen-ip" value="127.0.0.1"/>
          <param name="listen-port" value="5721"/>
          <param name="password" value="ClueCon"/>
          </settings>
          </configuration>
          <configuration name="httapi.conf">
          <settings>
          </settings>
          <profiles>
          <profile name="default">
          <params>
          <param name="gateway-url" value=""/>
          <param name="gateway-credentials" value=""/>
          <param name="auth-scheme" value="basic"/>
          <param name="enable-cacert-check" value="true"/>
          <param name="enable-ssl-verifyhost" value="true"/>
          <param name="timeout" value="120"/>
          </params>
          </profile>
          </profiles>
          </configuration>
          <configuration name="spandsp.confg">
          <modem-settings>
          <param name="verbose" value="true"/>
          <param name="total-modems" value="2"/>
          <param name="directory" value="/opt/freeswitch/var/spool/modem"/>
          <param name="dialplan" value="inline:&apos;socket:example.net:6712 async full&apos;"/>
          <param name="context" value="dummy-unused"/>
          </modem-settings>
          <fax-settings>
          <param name="verbose" value="true"/>
          <param name="use-ecm" value="true"/>
          <param name="disable-v17" value="false"/>
          <param name="ident" value="Gabby Potato"/>
          <param name="header" value="Gabby Potato over SpanDSP"/>
          <param name="spool-dir" value="/opt/freeswitch/var/spool/fax"/>
          <param name="file-prefix" value="fax-rx-"/>
          </fax-settings>
          </configuration>
          <configuration name="sofia.conf">
          <global_settings>
          <param name="log-level" value="1"/>
          <param name="debug-presence" value="0"/>
          </global_settings>
          <profiles>
          <profile name="softphone">
          <gateways>
          <gateway name="example.com">
          <param name="username" value="foo"/>
          <param name="password" value="bar"/>
          <param name="expire-seconds" value="1800"/>
          <param name="register" value="true"/>
          <param name="register-transport" value="udp"/>
          <param name="ping" value="15"/>
          <param name="extension-in-contact" value="true"/>
          <param name="cid-type" value="none"/>
          </gateway>
          </gateways>
          <settings>
          <param name="user-agent-string" value="FreeSWITCH/SoftPhone"/>
          <param name="debug" value="0"/>
          <param name="sip-trace" value="true"/>
          <param name="dialplan" value="inline:&apos;socket:example.net:6712 async full&apos;"/>
          <param name="context" value="dummy-unused"/>
          <param name="sip-ip" value="auto"/>
          <param name="ext-sip-ip" value="auto-nat"/>
          <param name="local-network-acl" value="localnet.auto"/>
          <param name="stun-enabled" value="true"/>
          <param name="manage-presence" value="false"/>
          <param name="max-proceeding" value="3"/>
          <param name="nonce-ttl" value="60"/>
          <param name="auth-calls" value="false"/>
          <param name="auth-all-packets" value="false"/>
          <param name="disable-register" value="true"/>
          <param name="challenge-realm" value="auto_from"/>
          <param name="inbound-late-negotiation" value="true"/>
          <param name="rtp-ip" value="auto"/>
          <param name="ext-rtp-ip" value="auto-nat"/>
          <param name="inbound-codec-negotiation" value="generous"/>
          <param name="suppress-cng" value="false"/>
          <param name="vad" value="none"/>
          <param name="codec-prefs" value="PCMA"/>
          <param name="rfc2833-pt" value="101"/>
          <param name="rtp-timeout-sec" value="300"/>
          <param name="rtp-hold-timeout-sec" value="1800"/>
          <param name="dtmf-duration" value="100"/>
          <param name="hold-music" value=""/>
          <param name="use-rtp-timer" value="true"/>
          <param name="rtp-timer-name" value="soft"/>
          </settings>
          </profile>
          </profiles>
          </configuration>
          </section>
          </document>

      '''
