An automated endpoint for SIP testing
-------------------------------------

Basically:
- shimaore/freeswitch with an automated configurator (based on ENV variables) that connects to a SIP proxy, authenticates, and:
  - gives access to the FreeSwitch event socket
  - provides Axon notifications for inbound calls
