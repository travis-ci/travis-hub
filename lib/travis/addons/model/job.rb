require 'travis/hub/model/job'

Job.class_eval do
  def log_id
    log.id
  end

  def obfuscated_config
    Travis::SecureConfig.obfuscate(config, repository.key)
  end
end
