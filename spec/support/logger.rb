require 'active_support/concern'

module Support
  module Logger
    extend ActiveSupport::Concern

    included do
      let(:stdout) { StringIO.new }
      before       { Travis::Hub.logger = Travis::Logger.new(stdout) }
      before       { Travis::Instrumentation.setup(Travis::Hub.logger) }
    end
  end
end
