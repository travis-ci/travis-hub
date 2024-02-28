require 'active_support/concern'

module Support
  module Context
    extend ActiveSupport::Concern

    included do
      let(:stdout)  { StringIO.new }
      let(:logger)  { Travis::Logger.new(stdout) }
      let(:metrics) { Travis::Metrics.setup({}, logger) }
      let(:context) do
        Travis::Hub::Context.new(
          logger:,
          metrics:
        )
      end
      before        { Travis::Hub.context = context }
      before        { Travis::Instrumentation.setup(context.logger) }
    end
  end
end
