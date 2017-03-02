require 'unlimited-jce-policy-jdk7' if RUBY_PLATFORM == 'java'
require 'travis/hub/context'
require 'travis/hub/handler'

module Travis
  module Hub
    attr_accessor :context

    def config
      puts "Calling Hub.config is deprecated. Called from #{caller.first}"
      context.config
    end

    def logger
      puts "Calling Hub.logger is deprecated. Called from #{caller.first}"
      context.logger
    end

    extend self
  end
end
