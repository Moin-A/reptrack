module Audit
  module Events
    class Update
      def initialize(record, in_after_callback = true)
        @record = record
        @in_after_callback = in_after_callback
      end

      def data
        {
          item: @record,
          event: @record.audit_trail_event || "update",
          whodunnit: Audit::Request.whodunnit
        }
      end
    end
  end
end
