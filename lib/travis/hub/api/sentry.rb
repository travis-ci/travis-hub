require 'sentry-ruby'

module Travis
  module Hub
    class Sentry < Sinatra::Base
      configure do
        ::Sentry.with_scope do |s|
          s&.set_tags(environment:)
        end
      end
    end
  end
end
