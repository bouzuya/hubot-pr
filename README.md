# hubot-pr

A Hubot script that list / merge the pull request.

This script inspired by [hubot-list-pr][gh:bouzuya/hubot-list-pr] and [hubot-merge-pr][gh:bouzuya/hubot-merge-pr].

## Installation

    $ npm install git://github.com/bouzuya/hubot-pr.git

or

    $ # TAG is the package version you need.
    $ npm install 'git://github.com/bouzuya/hubot-pr.git#TAG'

## Sample Interaction

    bouzuya> hubot help pr
      hubot> hubot pr [<user>/]<repo> - list pull requests
      hubot> hubot pr [<user>/]<repo> <N> - merge a pull request

    (list)
    bouzuya> hubot pr hitoridokusho/hibot
      hubot> #1 pull request 1
               https://github.com/hitoridokusho/hibot/pull/1
             #2 pull request 2
               https://github.com/hitoridokusho/hibot/pull/2
    (merge)
    bouzuya> hubot pr hitoridokusho/hibot 2
      hubot> #2 pull request 2
             hitoridokusho:master <- bouzuya:add-hubot-merge-pr
             https://github.com/hitoridokusho/hibot/pull/2
             i will start to merge after 30 s
             (you can stop it if you type "cancel")
      hubot> Pull Request successfully merged

    (HUBOT_PR_DEFAULT_USERNAME=hitoridokusho)
    (list)
    bouzuya> hubot pr hibot
      hubot> #1 pull request 1
                 https://github.com/hitoridokusho/hibot/pull/1
             #2 pull request 2
                 https://github.com/hitoridokusho/hibot/pull/2
    (merge)
    bouzuya> hubot pr hibot 2
      hubot> #2 pull request 2
             hitoridokusho:master <- bouzuya:add-hubot-merge-pr
             https://github.com/hitoridokusho/hibot/pull/2
             i will start to merge after 30 s
             (you can stop it if you type "cancel")
      hubot> Pull Request successfully merged

See [`src/scripts/pr.coffee`](src/scripts/pr.coffee) for full documentation.

## License

MIT

## Development

### Run test

    $ npm test

### Run robot

    $ npm run robot


## Badges

[![Build Status][travis-badge]][travis]
[![Dependencies status][david-dm-badge]][david-dm]

[travis]: https://travis-ci.org/bouzuya/hubot-pr
[travis-badge]: https://travis-ci.org/bouzuya/hubot-pr.svg?branch=master
[david-dm]: https://david-dm.org/bouzuya/hubot-pr
[david-dm-badge]: https://david-dm.org/bouzuya/hubot-pr.png
[gh:bouzuya/hubot-list-pr]: https://github.com/bouzuya/hubot-list-pr
[gh:bouzuya/hubot-merge-pr]: https://github.com/bouzuya/hubot-merge-pr
