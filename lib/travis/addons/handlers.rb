module Travis
  module Addons
    module Handlers
      require 'travis/addons/handlers/campfire'
      require 'travis/addons/handlers/email'
      require 'travis/addons/handlers/flowdock'
      require 'travis/addons/handlers/github_status'
      require 'travis/addons/handlers/hipchat'
      require 'travis/addons/handlers/irc'
      require 'travis/addons/handlers/keenio'
      require 'travis/addons/handlers/pusher'
      require 'travis/addons/handlers/scheduler'
      require 'travis/addons/handlers/states_cache'
      require 'travis/addons/handlers/webhook'
      require 'travis/addons/handlers/slack'
      require 'travis/addons/handlers/pushover'
    end
  end
end
