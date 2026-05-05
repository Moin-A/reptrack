module Audit
  module AuditTrail
    extend ActiveSupport::Concern

    class Error < StandardError; end

    class_methods do
      def has_paper_trail(defaults = {})
        if instance_variable_defined?(:@_audit_trail_configured)
          raise Error, "has_paper_trail must be called only once"
        end
        @_audit_trail_configured = true
        defaults = Reptrack.config.audit_trail_defaults
           audit_trail.setup(defaults)
      end

      def audit_trail
        @_audit_trail ||= ModelConfig.new(self)
      end
    end
  end
end
