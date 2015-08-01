# require 'pusher'
require 'travis/support'
require 'travis/support/database'
require 'travis/addons'
require 'travis/config/defaults'
require 'travis/event'
require 'travis/features'
require 'travis/notification'
require 'travis/redis_pool'
require 'travis/services'

require 'travis/model/broadcast'
require 'travis/model/commit'
require 'travis/model/build'
require 'travis/model/job'
require 'travis/model/repository'
require 'travis/model/request'
require 'travis/model/user'

# require 'travis/errors'

module Travis
  # class UnknownRepository < StandardError; end
  # class GithubApiError    < StandardError; end
  # class AdminMissing      < StandardError; end
  # class RepositoryMissing < StandardError; end
  # class LogAlreadyRemoved < StandardError; end
  # class AuthorizationDenied < StandardError; end
  # class JobUnfinished     < StandardError; end

  class << self
    def setup(options = {})
      @config = Config.load(*options[:configs])
      @redis = Travis::RedisPool.new(config.redis)

      Travis.logger.info('Setting up Travis::Core')

      # Github.setup
      # Addons.register
      Services.register
      # Enqueue::Services.register
      # Github::Services.register
      # Logs::Services.register
      # Requests::Services.register
    end

    attr_accessor :redis, :config

    # def states_cache
    #   @states_cache ||= Travis::StatesCache.new
    # end
  end

  setup
end
