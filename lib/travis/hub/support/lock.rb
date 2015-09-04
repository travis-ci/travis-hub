require 'travis/hub/support/lock/none'
require 'travis/hub/support/lock/postgresql'
require 'travis/hub/support/lock/redis'

module Travis
  module Hub
    module Support
      module Lock
        extend self

        def exclusive(name, options = {}, &block)
          strategy = options[:strategy] || fail('No lock strategy given.')
          const_get(strategy.to_s.camelize).new(name, options).exclusive(&block)
        end
      end
    end
  end
end
