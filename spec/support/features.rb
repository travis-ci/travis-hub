module Support
  module Features
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      def feature(name, args)
        before { set_feature(name, args) }
        after  { unset_feature(name, args) }
      end
    end

    def set_feature(name, args)
      args.each do |key, value|
        case key
        when :owner
          owner = User.find_by_login(value) || Organization.find_by_login(value)
          raise "Could not find owner for feature flag #{name}: #{value}" unless owner

          Travis::Features.activate_owner(name, owner)
        else
          raise "Unknown feature #{name} subject: #{key}, #{value}"
        end
      end
    end

    def unset_feature(name, args)
      args.each do |key, value|
        case key
        when :owner
          owner = User.find_by_login(value) || Organization.find_by_login(value)
          raise "Could not find owner for feature flag #{name}: #{value}" unless owner

          Travis::Features.deactivate_owner(name, owner)
        else
          raise "Unknown feature #{name} subject: #{key}, #{value}"
        end
      end
    end
  end
end
