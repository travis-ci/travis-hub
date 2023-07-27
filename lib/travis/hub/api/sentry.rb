require 'sentry-ruby'


module Travis
  module Hub
    class Sentry < Sinatra::Base
      configure do
        ::Sentry.with_scope { |s|
          s&.set_tags( environment: environment )
        }
      end
    end
  end
end
