require 'unlimited-jce-policy-jdk7' if RUBY_PLATFORM == 'java'

require 'travis/logger'
require 'travis/hub/config'
require 'travis/hub/app'
require 'travis/hub/model'
require 'travis/hub/service'
require 'travis/hub/handler/metrics'

module Travis
  module Hub
    # Context = Struct.new(:config, :features, :logger, :metrics, :redis)

    # QUEUE = 'builds.next'
    QUEUE = 'builds'

    attr_reader :logger

    def config
      @config ||= Config.load
    end

    def logger
      @logger ||= Logger.configure(Travis::Logger.new(STDOUT))
    end

    def logger=(logger)
      @logger = Logger.configure(logger)
    end

    extend self
  end
end
