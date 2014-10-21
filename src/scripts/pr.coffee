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
{Promise} = require 'q'
{PullRequestManager} = require '../pull-request-manager'

module.exports = (robot) ->

  # cancel timer
  timeout = parseInt (process.env.HUBOT_PR_TIMEOUT ? '30000'), 10
  timeoutId = null

  cancel = (res) ->
    if timeoutId?
      clearTimeout timeoutId
      res.send 'canceled'
      timeoutId = null

  list = (res, user, repo) ->
    client = new PullRequestManager()
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
        robot.logger.error err
        res.send 'hubot-pr: error'

  merge = (res, user, repo, number) ->
    if timeoutId?
      res.send 'wait for merging...'
      return
    client = new PullRequestManager()
    client.get(user, repo, number)
      .then (result) ->
        res.send """
          \##{result.number} #{result.title}
          #{result.base.label} <- #{result.head.label}
          #{result.html_url}

          i will start to merge after #{Math.floor(timeout / 1000)} s
          (you can stop it if you type "cancel")
        """
        new Promise (resolve) ->
          timeoutId = setTimeout resolve, timeout
      .then ->
        timeoutId = null
        client.merge(user, repo, number)
      .then (result) ->
        res.send result.message
      .then null, (err) ->
        robot.logger.error err
        res.send 'hubot-pr: error'

  robot.respond /pr\s+(?:([^\/]+)\/)?(\S+)(?:\s+(\d+))?\s*$/i, (res) ->
    user = res.match[1] ? process.env.HUBOT_PR_DEFAULT_USERNAME
    return unless user?
    repo = res.match[2]
    number = res.match[3]
    f = if number? then merge else list
    f res, user, repo, number

  robot.hear /cancel/i, (res) ->
    cancel res
