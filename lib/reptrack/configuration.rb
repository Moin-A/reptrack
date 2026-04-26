module Reptrack
    class Configuration
        include Preferences::Preferable
        alias_method :preferences, :preferences_store
    end
end