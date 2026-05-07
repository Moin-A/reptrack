module Audit
  module Events
    class Create
      def initialize(record, in_after_callback = false)
        @record = record
        @in_after_callback = in_after_callback
      end

      def data
        data = {
          item: @record,
          event: @record.audit_trail_event || "create",
          whodunnit: Audit::Request.whodunnit
        }
        if @record.respond_to?(:updated_at)
          data[:created_at] = @record.updated_at
        end
        data
      end
    end
  end
end
