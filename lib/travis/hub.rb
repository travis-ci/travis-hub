require 'travis/support/database'
require 'travis/support/exceptions'
require 'travis/support/instrumentation'
require 'travis/support/logger'

require 'travis/hub/config'
require 'travis/hub/app'
require 'travis/hub/handler/metrics'

module Travis
  module Hub
    QUEUE = 'builds'

    attr_reader :logger

    def config
      @config ||= Config.load
    end

    def env
      config.env
    end

    def logger
      @logger ||= Logger.configure(Travis::Logger.new(STDOUT))
    end

    def logger=(logger)
      @logger = Logger.configure(logger)
    end

    extend self
  end

  extend Hub
end

