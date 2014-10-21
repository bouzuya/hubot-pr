# Description
#   A Hubot script that list / merge the pull request
#
# Configuration:
#   HUBOT_PR_DEFAULT_USERNAME
#   HUBOT_PR_TOKEN
#   HUBOT_PR_TIMEOUT
#
# Commands:
#   hubot pr [<user>/]<repo> - list pull requests
#   hubot pr [<user>/]<repo> <N> - merge a pull request
#
# Author:
#   bouzuya <m@bouzuya.net>
#
{PullRequestManager} = require '../pull-request-manager'

class HubotPullRequest
  constructor: ->
    @waitList = []

  list: (res, user, repo) ->
    client = @_client()
    client.list(user, repo)
      .then (pulls) ->
        return if pulls.length is 0
        message = pulls
          .map (p) -> """
              \##{p.number} #{p.title}
                #{p.html_url}
            """
          .join '\n'
        res.send message
      .then null, (err) ->
        res.robot.logger.error err
        res.send 'hubot-pr: error'

  confirmMerging: (res, user, repo, number) ->
    client = @_client()
    client.get(user, repo, number)
      .then (result) =>
        res.send """
          \##{result.number} #{result.title}
          #{result.base.label} <- #{result.head.label}
          #{result.html_url}

          OK ? [yes/no]
        """
        timeout = parseInt (process.env.HUBOT_PR_TIMEOUT ? '30000'), 10
        userId = res.message.user.id
        room = res.message.room
        timerId = setTimeout =>
          @waitList = @waitList.filter (i) -> i.timerId isnt timerId
        , timeout
        @waitList.push { userId, room, user, repo, number, timerId }
      .then null, (err) ->
        res.robot.logger.error err
        res.send 'hubot-pr: error'

  merge: (res) ->
    item = @_itemFor res
    return unless item?
    @_removeItem item
    { user, repo, number } = item
    client = @_client()
    client.merge(user, repo, number)
      .then (result) ->
        res.send "merged: #{user}/#{repo}##{number} : #{result.message}"
      .then null, (err) ->
        res.robot.logger.error err
        res.send 'hubot-pr: error'

  cancel: (res) ->
    item = @_itemFor res
    return unless item?
    @_removeItem item
    { user, repo, number } = item
    res.send "canceled: #{user}/#{repo}##{number}"

  _client: ->
    new PullRequestManager(token: process.env.HUBOT_PR_TOKEN)

  _itemFor: (res) ->
    userId = res.message.user.id
    room = res.message.room
    @waitList.filter((i) -> i.userId is userId and i.room is room)[0]

  _removeItem: (item) ->
    @waitList = @waitList.filter (i) -> i.timerId isnt item.timerId

module.exports = (robot) ->
  pr = new HubotPullRequest()

  robot.respond /pr\s+(?:([^\/]+)\/)?(\S+)(?:\s+#(\d+))?\s*$/i, (res) ->
    user = res.match[1] ? process.env.HUBOT_PR_DEFAULT_USERNAME
    return unless user?
    repo = res.match[2]
    number = res.match[3]
    f = if number? then pr.confirmMerging else pr.list
    f.apply pr, [res, user, repo, number]

  robot.hear /y(?:es)?/i, (res) ->
    pr.merge res

  robot.hear /n(?:o)?/i, (res) ->
    pr.cancel res
