require 'multi_json'

require 'travis'
require 'travis/model'
require 'travis/states_cache'
require 'travis/support/amqp'
require 'travis/hub/queue'
require 'travis/hub/error'
require 'travis/hub/solo'
require 'travis/hub/worker'
require 'travis/hub/dispatcher'
require 'travis/hub/enqueue'
require 'core_ext/kernel/run_periodically'

$stdout.sync = true

module Travis
  module Hub
    TYPES = { 'solo' => Solo, 'worker' => Worker, 'dispatcher' => Dispatcher, 'enqueue' => Enqueue }
    extend self

    def new(type = nil, *args)
      type ||= 'solo'
      TYPES.fetch(type).new(type, *args)
    end
  end
end
