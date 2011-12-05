require 'core_ext/module/async'

Async.class_eval do
  include Travis::Logging

  include Module.new {
    def run(&block)
      super
      info "Async queue size: #{@queue.size}"
    end
  }
end

unless ENV['ENV'] == 'test'
  %w(Archive Email Irc Pusher Webhook).each do |name|
    handler = Travis::Notifications::Handler.const_get(name)
    handler.async :notify
  end
end
