require 'travis/hub'
require 'travis/hub/sidekiq/worker'
require 'travis/hub/support/sidekiq'

Travis::Hub.context = Travis::Hub::Context.new
