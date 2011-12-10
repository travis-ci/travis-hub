
unless ENV['ENV'] == 'test'
  %w(Archive Email Irc Pusher Webhook).each do |name|
    handler = Travis::Notifications::Handler.const_get(name)
    handler.send(:include, Travis::Notifications::Instrumentation)
  end
end

