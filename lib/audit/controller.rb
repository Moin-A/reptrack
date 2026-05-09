module Audit
  module Controller
    extend ActiveSupport::Concern

    included do
      before_action :set_audit_trail
    end

    private

    def set_audit_trail
      set_audit_whodunnit
    end

    def user_for_audit
      return unless defined?(current_user)
      current_user.try(:id) || current_user
    end

    def set_audit_whodunnit
      if ::Audit::Request.enabled?
        ::Audit::Request.whodunnit = user_for_audit
      end
    end
  end
end
