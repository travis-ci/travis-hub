require 'multi_json'

require 'travis'

Travis.logger.info('[hub] loading travis/model')
require 'travis/model'

Travis.logger.info('[hub] loading travis/states_cache')
require 'travis/states_cache'

Travis.logger.info('[hub] loading support/amqp')
require 'travis/support/amqp'

Travis.logger.info('[hub] loading hub/queue')
require 'travis/hub/queue'

Travis.logger.info('[hub] loading hub/error')
require 'travis/hub/error'

Travis.logger.info('[hub] loading hub/solo')
require 'travis/hub/solo'

Travis.logger.info('[hub] loading hub worker')
require 'travis/hub/worker'

Travis.logger.info('[hub] loading hub/dispatcher')
require 'travis/hub/dispatcher'

Travis.logger.info('[hub] loading hub/enqueue')
require 'travis/hub/enqueue'

Travis.logger.info('[hub] loading run_periodically')
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
