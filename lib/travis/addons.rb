require 'travis/addons/instrument'
require 'travis/addons/model'
require 'travis/addons/handlers'
require 'travis/event/subscription'

module Travis
  AdminMissing      = Class.new(StandardError)
  RepositoryMissing = Class.new(StandardError)

  module Addons
    class << self
      attr_reader :config

      def setup(config = {})
        @config = config

        Handlers.constants(false).each do |name|
          handler = Handlers.const_get(name)
          name    = name.to_s.underscore
          Event::Handler.register(name, handler)
          handler.setup if handler.respond_to?(:setup)
        end

        Travis::Encrypt.setup(key: config[:encryption][:key])
      end
    end
  end
end
