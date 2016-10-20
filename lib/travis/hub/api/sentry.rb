require 'raven'

module Travis
  module Hub
    class Sentry < Sinatra::Base
      configure do
        Raven.configure { |c| c.tags = { environment: environment } }
        use Raven::Rack
      end
    end
  end
end
