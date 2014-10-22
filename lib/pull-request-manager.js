
var GitHub, Promise, PullRequestManager;

Promise = require('q').Promise;

GitHub = require('github');

PullRequestManager = (function() {
  function PullRequestManager(_arg) {
    var token;
    token = (_arg != null ? _arg : {}).token;
    this.github = new GitHub({
      version: '3.0.0'
    });
    this.github.authenticate({
      type: 'oauth',
      token: token
    });
  }

  PullRequestManager.prototype.list = function(user, repo) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.github.pullRequests.getAll({
          user: user,
          repo: repo
        }, function(err, ret) {
          if (err != null) {
            return reject(err);
          } else {
            return resolve(ret);
          }
        });
      };
    })(this));
  };

  PullRequestManager.prototype.get = function(user, repo, number) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.github.pullRequests.get({
          user: user,
          repo: repo,
          number: number
        }, function(err, ret) {
          if (err != null) {
            return reject(err);
          } else {
            return resolve(ret);
          }
        });
      };
    })(this));
  };

  PullRequestManager.prototype.merge = function(user, repo, number) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.github.pullRequests.merge({
          user: user,
          repo: repo,
          number: number
        }, function(err, ret) {
          if (err != null) {
            return reject(err);
          } else {
            return resolve(ret);
          }
        });
      };
    })(this));
  };

  return PullRequestManager;

})();

module.exports.PullRequestManager = PullRequestManager;
