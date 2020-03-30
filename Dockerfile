FROM ruby:2.4.9-slim

LABEL maintainer Travis CI GmbH <support+travis-hub-docker-images@travis-ci.com>

# packages required for bundle install
RUN ( \
   apt-get update ; \
   apt-get install -y --no-install-recommends git make gcc g++ libpq-dev curl \
   && rm -rf /var/lib/apt/lists/* \
)

RUN ( \
   curl -sLO http://ppa.launchpad.net/rmescandon/yq/ubuntu/pool/main/y/yq/yq_3.1-2_amd64.deb && \
   dpkg -i yq_3.1-2_amd64.deb && \
   rm -f yq_3.1-2_amd64.deb; \
)

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile      /app
COPY Gemfile.lock /app

ARG bundle_gems__contribsys__com
RUN bundle config https://gems.contribsys.com/ $bundle_gems__contribsys__com \
      && bundle install --deployment \
      && bundle config --delete https://gems.contribsys.com/
RUN gem install --user-install executable-hooks

COPY . /app
