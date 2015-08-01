require 'multi_json'

require 'travis'

Travis.logger.info('[hub] loading dependencies')
require 'travis/states_cache'
require 'travis/support/amqp'
require 'travis/hub/queue'
require 'travis/hub/error'
require 'travis/hub/solo'
require 'travis/hub/worker'
require 'travis/hub/dispatcher'
Travis.logger.info('[hub] done loading dependencies')

$stdout.sync = true

module Travis
  module Hub
    TYPES = { 'solo' => Solo, 'worker' => Worker, 'dispatcher' => Dispatcher }
    extend self

    def new(type = nil, *args)
      type ||= 'solo'
      TYPES.fetch(type).new(type, *args)
    end
  end
end
