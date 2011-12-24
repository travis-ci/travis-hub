# What is Travis Hub

Travis Hub collects build logs, state changes and other information from Travis workers, then updates build logs
in the database, propagates messages to browsers via [Pusher](http://pusher.com), detects finished builds, delivers email and IRC notifications,
bakes you a pizza and walks your dog.


## Dependencies

### Messaging Broker

Travis Hub communicates with other applications using [RabbitMQ](http://rabbitmq.com) (via [Hot Bunnies](https://github.com/ruby-amqp/hot_bunnies)).
Please refer to [amqp gem's Getting Started guide](http://rubyamqp.info/articles/getting_started/) to learn [how to install RabbitMQ](http://rubyamqp.info/articles/getting_started/#installing_rabbitmq) on your platform,
we won't duplicate all that information here.


### JRuby and libraries

Travis Hub is JRuby-based. Make sure you have Sun or OpenJDK 6, install JRuby via RVM (or any other way) and then do

    gem install bundler
    bundle install --gemfile Jemfile

Hub uses [travis-core](https://github.com/travis-ci/travis-core) and [travis-support](https://github.com/travis-ci/travis-support) that evolve
rapidly, so keep your eye on those two.


### Jemfile?

We use the "Jemfile trick" to deploy Hub to Heroku. Other than that, it is just a gemfile. You also don't have to use Maven
locally during development, it is only used during deployment.


## Disabling Features

Quite often during development you want to disable things like email delivery and [Pusher](http://pusher.com/) notifications.
Hub lets you do that.

TBD


## License & copyright information ##

See LICENSE file.

Copyright (c) 2011 [Travis CI development team](https://github.com/travis-ci).


