# frozen_string_literal: true

require 'marginalia'

module Travis
  class Marginalia
    class << self
      def setup
        ::Marginalia.install
      end
    end
  end
end
