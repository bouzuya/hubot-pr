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

  describe 'listeners[0].regex (pr)', ->
    beforeEach ->
      @sender = new User 'bouzuya', room: 'hitoridokusho'
      @callback = @sinon.spy()
      @robot.listeners[0].callback = @callback

    describe 'receive "@hubot pr hitoridokusho/hibot "', ->
      beforeEach ->
        message = '@hubot pr hitoridokusho/hibot '
        @robot.adapter.receive new TextMessage(@sender, message)

      it 'calls with "@hubot pr hitoridokusho/hibot "', ->
        assert @callback.callCount is 1
        match = @callback.firstCall.args[0].match
        assert match.length is 4
        assert match[0] is '@hubot pr hitoridokusho/hibot '
        assert match[1] is 'hitoridokusho'
        assert match[2] is 'hibot'
        assert match[3] is undefined

    describe 'receive "@hubot pr hitoridokusho/hibot 2 "', ->
      beforeEach ->
        message = '@hubot pr hitoridokusho/hibot 2 '
        @robot.adapter.receive new TextMessage(@sender, message)

      it 'calls with "@hubot pr hitoridokusho/hibot 2 "', ->
        assert @callback.callCount is 1
        match = @callback.firstCall.args[0].match
        assert match.length is 4
        assert match[0] is '@hubot pr hitoridokusho/hibot 2 '
        assert match[1] is 'hitoridokusho'
        assert match[2] is 'hibot'
        assert match[3] is '2'

    describe 'receive "@hubot pr hibot "', ->
      beforeEach ->
        message = '@hubot pr hibot '
        @robot.adapter.receive new TextMessage(@sender, message)

      it 'calls with "@hubot pr hibot "', ->
        assert @callback.callCount is 1
        match = @callback.firstCall.args[0].match
        assert match.length is 4
        assert match[0] is '@hubot pr hibot '
        assert match[1] is undefined
        assert match[2] is 'hibot'
        assert match[3] is undefined

    describe 'receive "@hubot pr hibot 2 "', ->
      beforeEach ->
        message = '@hubot pr hibot 2 '
        @robot.adapter.receive new TextMessage(@sender, message)

      it 'calls with "@hubot pr hibot 2 "', ->
        assert @callback.callCount is 1
        match = @callback.firstCall.args[0].match
        assert match.length is 4
        assert match[0] is '@hubot pr hibot 2 '
        assert match[1] is undefined
        assert match[2] is 'hibot'
        assert match[3] is '2'

  describe 'listeners[1].regex (cancel)', ->
    beforeEach ->
      @sender = new User 'bouzuya', room: 'hitoridokusho'
      @callback = @sinon.spy()
      @robot.listeners[1].callback = @callback

    describe 'receive "??? cancel ???"', ->
      beforeEach ->
        message = '??? cancel ???'
        @robot.adapter.receive new TextMessage(@sender, message)

      it 'calls with "cancel"', ->
        assert @callback.callCount is 1
        match = @callback.firstCall.args[0].match
        assert match.length is 1
        assert match[0] is 'cancel'

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

    describe 'receive "@hubot pr hibot 1" (use default username)', ->
      beforeEach ->
        {pullRequests} = require 'github/api/v3.0.0/pullRequests'
        @sinon.stub pullRequests, 'get', (msg, block, callback) =>
          callback null, @sampleGetResult
        @sinon.stub pullRequests, 'merge', (msg, block, callback) =>
          callback null, @sampleMergeResult
        @pr
          match: ['@hubot pr hibot', undefined, 'hibot', '1']
          send: @send

      it 'merges [hitoridokusho/]hibot 1', (done) ->
        setTimeout =>
          try
            assert @send.callCount is 2
            assert @send.firstCall.args[0] is """
              #1 TITLE
              hitoridokusho:master <- bouzuya:add-hubot-merge-pr
              https://github.com/hitoridokusho/hibot/pull/1

              i will start to merge after 0 s
              (you can stop it if you type "cancel")
              """
            assert @send.secondCall.args[0] is \
              'Pull Request successfully merged'
            done()
          catch e
            done e
        , 20 # 20 > 10
