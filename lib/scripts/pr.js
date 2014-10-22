// Description
//   A Hubot script that list / merge the pull request
//
// Configuration:
//   HUBOT_PR_DEFAULT_USERNAME
//   HUBOT_PR_TOKEN
//   HUBOT_PR_TIMEOUT
//
// Commands:
//   hubot pr [<user>/]<repo> - list pull requests
//   hubot pr [<user>/]<repo> <N> - merge a pull request
//
// Author:
//   bouzuya <m@bouzuya.net>
//
var HubotPullRequest, PullRequestManager;

PullRequestManager = require('../pull-request-manager').PullRequestManager;

HubotPullRequest = (function() {
  function HubotPullRequest() {
    this.waitList = [];
  }

  HubotPullRequest.prototype.list = function(res, user, repo) {
    var client;
    client = this._client();
    return client.list(user, repo).then(function(pulls) {
      var message;
      if (pulls.length === 0) {
        return;
      }
      message = pulls.map(function(p) {
        return "\#" + p.number + " " + p.title + "\n  " + p.html_url;
      }).join('\n');
      return res.send(message);
    }).then(null, function(err) {
      res.robot.logger.error(err);
      return res.send('hubot-pr: error');
    });
  };

  HubotPullRequest.prototype.confirmMerging = function(res, user, repo, number) {
    var client;
    client = this._client();
    return client.get(user, repo, number).then((function(_this) {
      return function(result) {
        var room, timeout, timerId, userId, _ref;
        res.send("\#" + result.number + " " + result.title + "\n" + result.base.label + " <- " + result.head.label + "\n" + result.html_url + "\n\nOK ? [yes/no]");
        timeout = parseInt((_ref = process.env.HUBOT_PR_TIMEOUT) != null ? _ref : '30000', 10);
        userId = res.message.user.id;
        room = res.message.room;
        timerId = setTimeout(function() {
          return _this.waitList = _this.waitList.filter(function(i) {
            return i.timerId !== timerId;
          });
        }, timeout);
        return _this.waitList.push({
          userId: userId,
          room: room,
          user: user,
          repo: repo,
          number: number,
          timerId: timerId
        });
      };
    })(this)).then(null, function(err) {
      res.robot.logger.error(err);
      return res.send('hubot-pr: error');
    });
  };

  HubotPullRequest.prototype.merge = function(res) {
    var client, item, number, repo, user;
    item = this._itemFor(res);
    if (item == null) {
      return;
    }
    this._removeItem(item);
    user = item.user, repo = item.repo, number = item.number;
    client = this._client();
    return client.merge(user, repo, number).then(function(result) {
      return res.send("merged: " + user + "/" + repo + "#" + number + " : " + result.message);
    }).then(null, function(err) {
      res.robot.logger.error(err);
      return res.send('hubot-pr: error');
    });
  };

  HubotPullRequest.prototype.cancel = function(res) {
    var item, number, repo, user;
    item = this._itemFor(res);
    if (item == null) {
      return;
    }
    this._removeItem(item);
    user = item.user, repo = item.repo, number = item.number;
    return res.send("canceled: " + user + "/" + repo + "#" + number);
  };

  HubotPullRequest.prototype._client = function() {
    return new PullRequestManager({
      token: process.env.HUBOT_PR_TOKEN
    });
  };

  HubotPullRequest.prototype._itemFor = function(res) {
    var room, userId;
    userId = res.message.user.id;
    room = res.message.room;
    return this.waitList.filter(function(i) {
      return i.userId === userId && i.room === room;
    })[0];
  };

  HubotPullRequest.prototype._removeItem = function(item) {
    return this.waitList = this.waitList.filter(function(i) {
      return i.timerId !== item.timerId;
    });
  };

  return HubotPullRequest;

})();

module.exports = function(robot) {
  var pr;
  pr = new HubotPullRequest();
  robot.respond(/pr\s+(?:([^\/]+)\/)?(\S+)(?:\s+#(\d+))?\s*$/i, function(res) {
    var f, number, repo, user, _ref;
    user = (_ref = res.match[1]) != null ? _ref : process.env.HUBOT_PR_DEFAULT_USERNAME;
    if (user == null) {
      return;
    }
    repo = res.match[2];
    number = res.match[3];
    f = number != null ? pr.confirmMerging : pr.list;
    return f.apply(pr, [res, user, repo, number]);
  });
  robot.hear(/y(?:es)?/i, function(res) {
    return pr.merge(res);
  });
  return robot.hear(/n(?:o)?/i, function(res) {
    return pr.cancel(res);
  });
};
