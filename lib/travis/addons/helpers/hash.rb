module Travis
  module Addons
    module Helpers
      module Hash
        def deep_symbolize_keys(hash)
          hash.inject({}) { |result, (key, value)|
            result[(key.to_sym rescue key) || key] = case value
            when Array
              value.map { |value| value.is_a?(Hash) ? value.deep_symbolize_keys : value }
            when Hash
              value.deep_symbolize_keys
            else
              value
            end
            result
          }
        end
      end
    end
  end
end
