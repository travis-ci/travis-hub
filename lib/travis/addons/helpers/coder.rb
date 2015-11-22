require 'coder'

module Travis
  module Addons
    module Helpers
      module Coder
        def deep_clean_strings(obj)
          case obj
          when ::Hash, Hashr
            obj.to_h.map { |key, value| [key, deep_clean_strings(value)] }.to_h
          when Array
            obj.map { |obj| deep_clean_strings(obj) }
          when String
            ::Coder.clean(obj)
          else
            obj
          end
        end
      end
    end
  end
end

