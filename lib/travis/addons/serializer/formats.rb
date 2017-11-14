module Travis
  module Addons
    module Serializer
      module Formats
        def format_date(date)
          date && date.strftime('%Y-%m-%dT%H:%M:%SZ')
        end

        def format_date_with_ms(date)
          date && date.strftime('%Y-%m-%dT%H:%M:%S.%3NZ')
        end
      end
    end
  end
end
