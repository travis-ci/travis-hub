require 'travis/secure_config'
require 'travis/hub/model/build'

Build.class_eval do
  belongs_to :repository
  belongs_to :request
  belongs_to :pull_request
  belongs_to :tag
  belongs_to :commit

  def pull_request?
    event_type == 'pull_request'
  end

  def obfuscated_config
    Travis::SecureConfig.obfuscate(config, repository.key)
  end
end
