require 'active_support/concern'

module Support
  module Logger
    extend ActiveSupport::Concern

    included do
      let(:stdout)  { StringIO.new }
      let(:logger)  { Travis::Logger.new(stdout) }
      let(:context) { Travis::Hub::Context.new(logger: logger) }
      before        { Travis::Instrumentation.setup(context.logger) }
    end
  end
end
