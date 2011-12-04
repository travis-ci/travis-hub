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
