module Audit
  module Events
    class Update < Base
      def initialize(record, force:, in_after_callback:, is_touch:)
        super(record, force:, in_after_callback:, is_touch:)
        @force = force
      end

      def data
       obj =  {
          item: @record,
          event: @record.audit_trail_event || "update",
          whodunnit: Audit::Request.whodunnit
        }

        if record_object?
          obj[:object] = recordable_object
        end
        obj
      end
    end
  end
end
