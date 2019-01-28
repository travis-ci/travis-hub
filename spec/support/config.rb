module Support
  module Config
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      def config(vars)
        before { define_config(vars) }
        after  { undefine_config(vars) }
      end
    end

    def define_config(vars)
      vars.each { |key, value| context.config[key] = value }
    end

    def undefine_config(vars)
      vars.each { |key, _| context.config[key] = nil }
    end
  end
end

