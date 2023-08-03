FROM ruby:2.6.10-slim

LABEL maintainer Travis CI GmbH <support+travis-hub-docker-images@travis-ci.com>

RUN ( \
   bundle config set no-cache 'true'; \
   bundle config --global frozen 1; \
   bundle config set deployment 'true'; \
   mkdir -p /app; \
)

WORKDIR /app

COPY Gemfile      /app
COPY Gemfile.lock /app
ARG bundle_gems__contribsys__com

RUN ( \
   apt-get update ; \
   apt-get upgrade -y ; \
   apt-get install -y git make gcc g++ libpq-dev curl \
   && rm -rf /var/lib/apt/lists/*; \
   curl -sLO http://ppa.launchpad.net/rmescandon/yq/ubuntu/pool/main/y/yq/yq_3.1-2_amd64.deb && \
   dpkg -i yq_3.1-2_amd64.deb && \
   rm -f yq_3.1-2_amd64.deb; \
   gem install bundler -v '2.3.14'; \
   bundle config https://gems.contribsys.com/ $bundle_gems__contribsys__com \
      && bundle config set without 'development test' \
      && bundle install --deployment \
      && bundle config --delete https://gems.contribsys.com/; \
   apt-get remove -y gcc g++ make git perl && apt-get -y autoremove; \
   bundle clean && rm -rf /app/vendor/bundle/ruby/2.5.0/cache/*; \
   rm -rf /usr/local/bundle/cache/\*.gem; \
   find /usr/local/bundle/gems/ \( -name '*.c' -o -name '*.h' -o -name '*.cpp' -o -name '*.o' \) -delete; \
   find /app/vendor/ \( -name '*.c' -o -name '*.h' -o -name '*.cpp' -o -name '*.o' \) -delete; \
)

COPY . /app
