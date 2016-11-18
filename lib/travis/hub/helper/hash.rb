module Travis
  module Hub
    module Helper
      module Hash
        def deep_symbolize_keys(hash)
          hash.map do |key, obj|
            obj = case obj
            when Array
              obj.map { |obj| deep_symbolize_keys(obj) }
            when ::Hash
              deep_symbolize_keys(obj)
            else
              obj
            end
            [key.to_sym, obj]
          end.to_h
        end
      end
    end
  end
end
