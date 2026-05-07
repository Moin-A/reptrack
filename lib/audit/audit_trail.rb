module Audit
  module AuditTrail
    extend ActiveSupport::Concern

    class Error < StandardError; end

    class_methods do
      def has_paper_trail(options = {})
        if instance_variable_defined?(:@_audit_trail_configured)
          raise Error, "has_paper_trail must be called only once"
        end
        @_audit_trail_configured = true
        merged = Reptrack.config.audit_trail_defaults.merge(options)
        audit_trail.setup(merged)
      end

      def audit_trail
        @_audit_trail ||= ModelConfig.new(self)
      end
    end

    def audit_trail
      RecordTrail.new(self)
    end
  end
end
