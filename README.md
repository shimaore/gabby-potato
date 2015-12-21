An automated endpoint for SIP testing
-------------------------------------

Basically:
- shimaore/freeswitch with an automated configurator (based on ENV variables) that connects to a SIP proxy, authenticates, and connects to Socket.IO, and:
  - waits for SIP calls (in which case it triggers Socket.IO)
  - waits for Socket.IO (in which case it triggers SIP calls)

Test
----

    make && npm test
