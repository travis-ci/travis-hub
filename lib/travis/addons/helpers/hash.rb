module Travis
  module Addons
    module Helpers
      module Hash
        def deep_symbolize_keys(hash)
          hash.each_with_object({}) do |(key, value), result|
            result[begin
              key.to_sym
            rescue StandardError
              key
            end || key] = case value
                          when Array
                            value.map { |value| value.is_a?(Hash) ? value.deep_symbolize_keys : value }
                          when Hash
                            value.deep_symbolize_keys
                          else
                            value
                          end
          end
        end
      end
    end
  end
end
