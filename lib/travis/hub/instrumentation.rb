unless ENV['ENV'] == 'test'
  %w(Archive Email Github Irc Pusher Webhook).each do |name|
    handler = Travis::Event::Handler.const_get(name)
    handler.send(:include, Travis::Event::Instrumentation)
  end
end

