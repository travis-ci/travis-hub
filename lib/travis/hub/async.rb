require 'core_ext/module/include'
require 'core_ext/module/async'

Async.class_eval do
  include Travis::Logging

  include do
    def run(&block)
      super
      info "Async queue size: #{@queue.size}"
    end
  end
end

unless ENV['ENV'] == 'test'
  Travis.config.notifications.each do |name|
    handler = Travis::Event::Handler.const_get(name.camelize)
    handler.async :notify
  end
end
