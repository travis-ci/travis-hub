require 'active_support/notifications'
require 'active_support/core_ext/string/inflections'
require 'securerandom' # wat
require 'travis/metrics'
require 'travis/instrumentation/instrument'
require 'travis/instrumentation/publisher/log'
require 'travis/instrumentation/publisher/memory'

module Travis
  module Instrumentation
    class << self
      attr_reader :publishers

      def setup(logger)
        @publishers = []
        publishers << Publisher::Log.new(logger)
      end

      def publish(event)
        publishers && publishers.each { |publisher| publisher.publish(event) }
      end

      def meter(event, options = {})
        return if options[:level] == :debug

        started_at, finished_at = options[:started_at], options[:finished_at]

        if finished_at
          Metriks.timer(event).update(finished_at - started_at)
        else
          Metriks.meter(event).mark
        end
      end
    end

    def instrumentation_key=(instrumentation_key)
      @instrumentation_key = instrumentation_key
    end

    def instrumentation_key
      @instrumentation_key ||= name.underscore.gsub('/', '.')
    end

    def instrument(name, options = {})
      wrapped = "#{name}_without_instrumentation"
      alias_method(wrapped, name)
      remove_method(name)
      private(wrapped)
      class_eval instrumentation_template(name, options[:scope], wrapped, options[:level] || :info, options[:on])
    end

    private

      def instrumentation_template(name, scope, wrapped, level, status)
        status ||= [:received, :completed, :failed]
        status   = Array(status) unless status.is_a?(Array)

        options  = 'target: self, args: args, started_at: started_at, level: ' + level.inspect
        meter    = 'Travis::Instrumentation.meter "#{event}:%s", ' + options
        publish  = 'ActiveSupport::Notifications.publish "#{event}:%s", ' + options

        <<-RUBY
          def #{name}(*args, &block)
            started_at = Time.now.to_f
            event = self.class.instrumentation_key.dup #{"<< '.' << #{scope}" if scope} << ".#{name}"
            #{publish % 'received' if status.include?(:received)}
            result = #{wrapped}(*args, &block)
            #{"#{meter   % 'completed'}, finished_at: Time.now.to_f, result: result" if status.include?(:completed)}
            #{"#{publish % 'completed'}, finished_at: Time.now.to_f, result: result" if status.include?(:completed)}
            result
          rescue Exception => e
            #{"#{meter   % 'failed'}, exception: [e.class.name, e.message]" if status.include?(:failed)}
            #{"#{publish % 'failed'}, exception: [e.class.name, e.message]" if status.include?(:failed)}
            raise
          end
        RUBY
      end
  end
end
