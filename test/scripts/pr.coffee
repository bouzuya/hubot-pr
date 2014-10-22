{Robot, User, TextMessage} = require 'hubot'
assert = require 'power-assert'
path = require 'path'
sinon = require 'sinon'

describe 'pr', ->
  beforeEach (done) ->
    @sinon = sinon.sandbox.create()
    # for warning: possible EventEmitter memory leak detected.
    # process.on 'uncaughtException'
    @sinon.stub process, 'on', -> null
    # http response
    @sampleMergeResult =
      merged: true
      message: 'Pull Request successfully merged'
    @sampleGetResult =
      number: 1
      html_url: 'https://github.com/hitoridokusho/hibot/pull/1'
      title: 'TITLE'
      head:
        label: 'bouzuya:add-hubot-merge-pr'
      base:
        label: 'hitoridokusho:master'
    @sampleGetAllResult = [
      number: 1
      html_url: 'https://github.com/hitoridokusho/hibot/pull/1'
      title: 'TITLE'
    ]
    # env
    @env = {}
    @env.HUBOT_PR_DEFAULT_USERNAME = process.env.HUBOT_PR_DEFAULT_USERNAME
    @env.HUBOT_PR_TIMEOUT          = process.env.HUBOT_PR_TIMEOUT
    process.env.HUBOT_PR_DEFAULT_USERNAME = 'hitoridokusho'
    process.env.HUBOT_PR_TIMEOUT = 10
    # github
    GitHub = require 'github'
    @sinon.stub GitHub.prototype, 'authenticate', -> # do nothing
    # robot
    @robot = new Robot(path.resolve(__dirname, '..'), 'shell', false, 'hubot')
    @robot.adapter.on 'connected', =>
      @robot.load path.resolve(__dirname, '../../src/scripts')
      done()
    @robot.run()


  afterEach (done) ->
    process.env.HUBOT_PR_TIMEOUT = @env.HUBOT_PR_TIMEOUT
    process.env.HUBOT_PR_DEFAULT_USERNAME = @env.HUBOT_PR_DEFAULT_USERNAME
    @robot.brain.on 'close', =>
      @sinon.restore()
      done()
    @robot.shutdown()

  describe 'patterns', ->
    [
      [
        message: 'hubot pr hitoridokusho/hibot'
        matches: [
          'hubot pr hitoridokusho/hibot'
          'hitoridokusho'
          'hibot'
          undefined
        ]
      ,
        message: 'hubot pr hitoridokusho/hibot #1'
        matches: [
          'hubot pr hitoridokusho/hibot #1'
          'hitoridokusho'
          'hibot'
          '1'
        ]
      ,
        message: 'hubot pr hibot'
        matches: [
          'hubot pr hibot'
          undefined
          'hibot'
          undefined
        ]
      ,
        message: 'hubot pr hibot #1'
        matches: [
          'hubot pr hibot #1'
          undefined
          'hibot'
          '1'
        ]
      ]
    ,
      [
        message: 'yes'
        matches: ['yes']
      ,
        message: 'y'
        matches: ['y']
      ,
        message: 'Y'
        matches: ['Y']
      ]
    ,
      [
        message: 'no'
        matches: ['no']
      ,
        message: 'n'
        matches: ['n']
      ,
        message: 'N'
        matches: ['N']
      ]
    ].forEach (tests, index) ->
      describe "listeners[#{index}].regex", ->
        tests.forEach ({ message, matches }) ->
          beforeEach ->
            @index = index
            @message = message
            @matches = matches

          describe 'receive ' + message, ->
            it 'should match', ->
              callback = @sinon.spy()
              @robot.listeners[@index].callback = callback
              sender = new User 'bouzuya', room: 'hitoridokusho'
              @robot.adapter.receive new TextMessage(sender, @message)
              actualMatches = callback.firstCall.args[0].match.map((i) -> i)
              assert callback.callCount is 1
              assert.deepEqual actualMatches, @matches

  describe 'listeners[0].callback (pr)', ->
    beforeEach ->
      @pr = @robot.listeners[0].callback
      @send = @sinon.spy()

    describe 'receive "@hubot pr hibot" (use default username)', ->
      beforeEach ->
        {pullRequests} = require 'github/api/v3.0.0/pullRequests'
        @sinon.stub pullRequests, 'getAll', (msg, block, callback) =>
          callback null, @sampleGetAllResult
        @pr
          match: ['@hubot pr hibot', undefined, 'hibot']
          send: @send

      it 'lists [hitoridokusho/]hibot pull requests', (done) ->
        setTimeout =>
          try
            assert @send.callCount is 1
            assert @send.firstCall.args[0] is '''
              #1 TITLE
                https://github.com/hitoridokusho/hibot/pull/1
            '''
            done()
          catch e
            done e
        , 10

    describe 'receive "@hubot pr hibot #1" (use default username)', ->
      beforeEach ->
        {pullRequests} = require 'github/api/v3.0.0/pullRequests'
        @sinon.stub pullRequests, 'get', (msg, block, callback) =>
          callback null, @sampleGetResult
        @sinon.stub pullRequests, 'merge', (msg, block, callback) =>
          callback null, @sampleMergeResult
        @pr
          match: ['@hubot pr hibot #1', undefined, 'hibot', '1']
          send: @send
          message:
            user:
              id: 1

      it 'merges [hitoridokusho/]hibot #1', (done) ->
        setTimeout =>
          try
            assert @send.callCount is 1
            assert @send.firstCall.args[0] is """
              #1 TITLE
              hitoridokusho:master <- bouzuya:add-hubot-merge-pr
              https://github.com/hitoridokusho/hibot/pull/1

              OK ? [yes/no]
              """
            done()
          catch e
            done e
        , 20 # 20 > 10
