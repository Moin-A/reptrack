module Reptrack
  module Preferences
    module Persistable
      extend ActiveSupport::Concern

      included do
        include Preferable

        after_initialize :initialize_preferences_defaults
      end

      private

      def initialize_preferences_defaults
        if has_attribute?(:preferences)
          self.preferences = default_preferences.merge(preferences || {})
        end
      end
    end
  end
end
