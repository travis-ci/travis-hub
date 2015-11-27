require 'unlimited-jce-policy-jdk7' if RUBY_PLATFORM == 'java'
require 'travis/hub/app'

module Travis
  module Hub
    attr_accessor :context

    def config
      puts "Calling Hub.config is deprected. Called from #{caller.first}"
      context.config
    end

    def logger
      puts "Calling Hub.logger is deprected. Called from #{caller.first}"
      context.logger
    end

    extend self
  end
end
