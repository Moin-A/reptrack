module Reptrack
  module Preferences
    module PreferableClassMethods
      def defined_preferences
        []
      end

      def preference_default_getter_method_name(name)
        name
      end

      def preference_default_setter_method_name(name)
        "#{name}="
      end

      def preference(name, type, options = {})
        options.assert_valid_keys(:default, :encryption_key)
        name = name.to_sym
        defined_singleton_preferences = (@defined_singleton_preferences ||= [])
        defined_singleton_preferences << name.to_sym

        define_singleton_method :defined_preferences do
          super() + defined_singleton_preferences
        end

        default = if options[:default].is_a?(Proc)
          options[:default]
        else
          proc { options[:default].dup }
        end

        define_method preference_default_getter_method_name(name) do
          preferences.fetch(name) do
            default_value = instance_exec(&default)
            preferences[name] = default_value
            default_value
          end
        end

        define_method preference_default_setter_method_name(name) do |value|
          preferences[name] = value
        end
      end
    end
  end
end
