# frozen_string_literal: true

require 'marginalia'

module Travis
  module Hub
    module Sidekiq
      class Marginalia
        def initialize(options = {})
          @options = options
        end

        def call(worker, job, queue)
          ::Marginalia.set('app', @options[:app])
          yield
        ensure
          ::Marginalia.clear!
        end
      end
    end
  end
end
