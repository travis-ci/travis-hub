module Travis
  module Hub
    module Support
      module Lock
        class None < Struct.new(:name, :options)
          def exclusive
            yield
          end
        end
      end
    end
  end
end
