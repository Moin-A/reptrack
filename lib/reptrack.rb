module Reptrack
  class << self
    def config
        @config ||= AppConfiguration.new
        yield @config if block_given?
        @config
    end
  end
end
