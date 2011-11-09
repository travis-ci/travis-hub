require 'hashr'

module Travis
  class Handler
    autoload :Job,     'travis/handler/job'
    autoload :Worker,  'travis/handler/worker'

    attr_reader :event, :payload

    def initialize(event, payload)
      @event = event
      @payload = Hashr.new(payload)
    end
  end
end

