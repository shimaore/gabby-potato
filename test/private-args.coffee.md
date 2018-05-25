    Docker = require 'dockerode'
    docker = new Docker()
    pkg = require '../package.json'
    debug = (require 'debug') "#{pkg.name}:test:private"
    Axon = require 'axon'
    FS = require 'esl'
    (require 'chai').should()

    sleep = (timeout) ->
      new Promise (resolve) -> setTimeout resolve, timeout

    describe 'When starting the docker image with arguments', ->
      @timeout 20000
      started = false

      before (done) ->
        @timeout 30*1000
        docker
        .run 'shimaore/gabby-potato-for-test',
          [],
          if process.env.DEBUG_FS then [process.stdout,process.stderr] else null,
          {
            Cmd: [ JSON.stringify
              username:'foo'
              password:'bar'
              domain:'phone.example.net'
            ]
            HostConfig:
              PortBindings:
                '8021/tcp': [HostPort: '9021']
                '3000/tcp': [HostPort: '4000']
                '3001/tcp': [HostPort: '4001']
            Tty: false
          },
          (error,data,container) ->
            debug 'Container terminated', {error,data,container}
        .on 'container', (new_container) ->
          debug 'Got container', new_container
          await sleep 22*1000
          debug 'Assuming FreeSwitch is ready, starting tests.'
          done()
        return

      after ->
        @timeout 25*1000
        await sleep 22*1000

      it 'should start', (done) ->
        @timeout 10*1000
        FS
        .client ->
          res = await @api 'reloadxml'
          res.should.have.property 'body', '+OK [Success]\n'
          await @exit().catch -> yes
          @end()
          done()
        .connect 9021
        return

      it 'should stop', (done) ->
        FS
        .client ->
          res = await @api 'fsctl shutdown'
          res.should.have.property 'body', '+OK\n'
          done()
        .on 'error', (error) ->
          debug "Caught #{error}"
        .connect 9021
        return
