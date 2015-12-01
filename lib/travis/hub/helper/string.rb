module Travis
  module Hub
    module Helper
      module String
        def camelize(string)
          string.to_s.sub(/./) { |char| char.upcase }
        end
      end
    end
  end
end
