class Job < ActiveRecord::Base
  module Normalize
    def config
      super || {}
    end

    def state=(state)
      super(state.try(:to_sym))
    end

    def state
      super.try(:to_sym)
    end
  end
end
