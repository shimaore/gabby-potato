    seem = require 'seem'
    uuid = require 'uuid'
    pkg = require './package'
    debug = (require 'debug') "#{pkg.name}:client_handler"

    Promise = require 'bluebird'
    fs = Promise.promisifyAll require 'fs'
    path = require 'path'

    module.exports = client_handler = (cfg,io) ->
      ->

Events towards/from the Socket.IO client
----------------------------------------

        debug 'Client started'
        io.on 'originate', seem (destination,ack) =>
          uuid = uuid.v4()
          cmd = "originate {origination_uuid=#{uuid},sip_cid_type=none}sofia/gateway/#{cfg.domain}/#{destination} '&socket(#{cfg.server_host}:#{cfg.server_socket} async full)'"
          debug 'originate', {destination,uuid,cmd}
          res = yield @api(cmd).catch (error) ->
            debug "originate: #{error}", error
            {error:"#{error}"}
          debug 'originate: ack', {ack,uuid,res}
          ack? if res.error? then {uuid,error:res.error} else {uuid,response:res.body}
        io.on 'action', seem ({uuid,application,data},ack) =>
          res = yield @command_uuid uuid, application, data
          debug 'action: ack', {ack,res}
          ack? res

`stop` will stop the FreeSwitch process, but Supervisord will automatically restart it.

        io.on 'stop', seem (data,ack) =>
          {uuid} = yield @queue_api 'fsctl shutdown asap'
          debug 'action: stop', {ack,uuid}
          ack? uuid

`shutdown` will stop Supervisord, effectively terminating the Docker.io container.

        io.on 'shutdown', seem ->
          debug 'shutdown'
          yield supervisor.shutdownAsync()

        io.on 'put-fax', seem ({data,name},ack) ->
          debug 'put-fax', {name}
          name ?= uuid.v4()
          file = path.join process.env.SPOOL, 'fax', name
          debug 'put-fax', {file,name}
          res = yield fs.writeFileAsync(file, data).catch (error) ->
            debug "put-fax: writeFileAsync: #{error}", {file}
            error:"#{error}"
          debug 'put-fax: ack', {file,name,res}
          ack? {file,name,res}

        io.on 'get-fax', seem (name,ack) ->
          debug 'get-fax', {name}
          file = path.join process.env.SPOOL, 'fax', name
          debug 'get-fax', {file}
          res = {}
          data = yield fs.readFileAsync(file).catch (error) ->
            debug "get-fax: readFileAsync: #{error}", {file}
            res = error:"#{error}"
            null
          debug 'get-fax: ack', {file,name}
          ack? {data,file,name,res}

Events towards/from the Event Layer Socket
------------------------------------------

        @on 'DTMF', ({body}) =>
          io.emit 'dtmf', body['DTMF-Digit']
        @on 'freeswitch_disconnect_notice', ->
          io.emit 'freeswitch_disconnect_notice'

Indicate to the Socket.IO partner that we are ready
---------------------------------------------------

        io.emit 'client started',
          username: cfg.username
          domain: cfg.domain
        debug 'Ready'
