require 'bunny'
require 'multi_json'

module Travis
  class Amqp
    class << self
      def setup(config)
        @instance ||= new(config)
      end
    end

    attr_reader :connection, :channel

    def initialize(config)
      @connection = Bunny.new(config.to_h).tap { |connection| connection.start }
      # TODO channels must not be shared across threads, set this to Thread.current?
      @channel = connection.create_channel
    end

    def subscribe(queue, options, &handler)
      key = "reporting.jobs.#{queue}"
      queue = channel.queue(key, durable: true).bind('reporting', routing_key: key)
      queue.subscribe(options, &handler)
      sleep
    rescue => e
      puts e.message, e.backtrace
    end

    def ack(info)
      channel.ack(info.delivery_tag)
    end

    def publish(key, type, payload)
      payload = MultiJson.encode(payload)
      exchange = channel.topic('reporting', durable: true, auto_delete: false)
      exchange.publish(payload, type: type, routing_key: "reporting.jobs.#{key}")
    rescue => e
      puts e.message, e.backtrace
    end

    def fanout(key, payload)
      payload = MultiJson.encode(payload)
      exchange = channel.exchange(key, type: :fanout)
      exchange.publish(payload)
    rescue => e
      puts e.message, e.backtrace
    end

    #   TODO
    #   def declare_exchanges_and_queues
    #     channel.exchange('reporting', durable: true, auto_delete: false, type: :topic)
    #     channel.queue('builds.linux', durable: true, exclusive: false)
    #   end
  end
end
