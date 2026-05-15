module Audit
  module Events
    class Update < Base
      def initialize(record, in_after_callback = true)
        super(record, in_after_callback)
      end

      def data
       obj =  {
          item: @record,
          event: @record.audit_trail_event || "update",
          whodunnit: Audit::Request.whodunnit
        }

        if record_object?
          obj[:object] = recordable_object(true)
        end
        obj
      end
    end
  end
end
