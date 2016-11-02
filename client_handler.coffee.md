    seem = require 'seem'
    UUID = require 'uuid'
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
          uuid = UUID.v4()
          if typeof destination is 'string'
            opts =
              destination: destination
          else
            opts = destination
          opts.params ?= {}
          opts.params.origination_uuid = uuid
          opts.params.sip_cid_type ?= 'none'

          params = []
          for own k,v of opts.params
            params.push "#{k}=#{v}"
          params_string = params.join ','

          cmd = "originate {#{params_string}}sofia/gateway/#{cfg.domain}/#{opts.destination} '&socket(#{cfg.server_host}:#{cfg.server_socket} async full)'"
          debug 'originate', {opts,uuid,cmd}
          res = yield @api(cmd).catch (error) ->
            msg = error.stack ? error.toString()
            debug "originate: #{msg}"
            {error:"#{msg}"}
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

`put-fax` will put a file in the fax spool directory.

        io.on 'put-fax', seem ({data,name},ack) ->
          debug 'put-fax', {name}
          name ?= UUID.v4()
          file = path.join process.env.SPOOL, 'fax', name
          debug 'put-fax', {file,name}

          error = null
          yield fs.writeFileAsync(file, data).catch (e) ->
            debug "put-fax: writeFileAsync: #{e}", {file}
            error = "#{file}: #{e}"

          debug 'put-fax: ack', {file,name,error}
          ack? if error? then {name,error} else {file,name}

`get-fax` will get a file from the fax spool directory.

        io.on 'get-fax', seem (name,ack) ->
          debug 'get-fax', {name}
          file = path.join process.env.SPOOL, 'fax', name
          debug 'get-fax', {file}

          error = null
          data = yield fs.readFileAsync(file).catch (e) ->
            debug "get-fax: readFileAsync: #{e}", {file}
            error = "#{file}: #{e}"
            null

          debug 'get-fax: ack', {file,name,error}
          ack? if error? then {name,error} else {data,file,name}

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
