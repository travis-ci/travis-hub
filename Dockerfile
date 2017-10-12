FROM ruby:2.4.2

LABEL maintainer Travis CI GmbH <support+travis-app-docker-images@travis-ci.com>

RUN apt-get update && apt-get upgrade -y --no-install-recommends && rm -rf /var/lib/apt/lists/*

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile      /usr/src/app
COPY Gemfile.lock /usr/src/app

ARG bundle_gems__contribsys__com
RUN bundle config https://gems.contribsys.com/ $bundle_gems__contribsys__com \
      && bundle install --deployment \
      && bundle config --delete https://gems.contribsys.com/

COPY . /usr/src/app

CMD /bin/bash
