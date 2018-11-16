require 'bunny'
require 'multi_json'

module Travis
  class Amqp
    class << self
      def setup(config, enterprise = false)
        @instance ||= new(config, enterprise).tap do |amqp|
          amqp.setup
        end
      end
    end

    attr_reader :connection, :channel

    def initialize(config, enterprise = false)
      @connection = Bunny.new(config.to_h).tap { |connection| connection.start }
      # TODO channels must not be shared across threads, set this to Thread.current?
      @channel = connection.create_channel
      @enterprise = enterprise
    end

    def setup
      # TODO required on enterprise. move details to config?
      if @enterprise
        channel.exchange('reporting', durable: true, auto_delete: false, type: :topic)
        channel.queue('builds.linux', durable: true, exclusive: false)
      end
    end

    def subscribe(queue, options, &handler)
      key = "reporting.jobs.#{queue}"
      queue = channel.queue(key, durable: true).bind('reporting', routing_key: key)
      queue.subscribe(options, &handler)
      sleep
    rescue => e
      Raven.capture_exception(e)
    end

    def ack(info)
      channel.ack(info.delivery_tag)
    end

    def publish(key, type, payload)
      payload = MultiJson.encode(payload)
      exchange = channel.topic('reporting', durable: true, auto_delete: false)
      exchange.publish(payload, type: type, routing_key: "reporting.jobs.#{key}")
    rescue => e
      Raven.capture_exception(e)
    end

    def fanout(key, payload)
      payload = MultiJson.encode(payload)
      exchange = channel.exchange(key, type: :fanout)
      exchange.publish(payload)
    rescue => e
      Raven.capture_exception(e)
    end
  end
end
