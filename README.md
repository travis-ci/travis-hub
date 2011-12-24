# What is Travis Hub

Travis Hub collects build logs, state changes and other information from Travis workers, then updates build logs
in the database, propagates messages to browsers via Pusher, detects finished builds, delivers email notifications,
bakes you a pizza and walks your dog.

## Dependencies

Travis Hub is JRuby-based. Install JRuby via RVM (or any other way) and then do

    gem install bundler
    bundle install --gemfile Jemfile

We use the "Jemfile trick" to deploy Hub to Heroku. Other than that, it is just a gemfile.


## License & copyright information ##

See LICENSE file.

Copyright (c) 2011 [Travis CI development team](https://github.com/travis-ci).


