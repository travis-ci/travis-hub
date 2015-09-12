module Travis
  module Event
    class PastTense < Struct.new(:string)
      def string
        "#{super}ed".gsub(/eded$|eed$/, 'ed')
      end
    end

    class Underscore < Struct.new(:string)
      def string
        super.gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase.tr('/', ':')
      end
    end
  end
end
