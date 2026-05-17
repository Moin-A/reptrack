module Audit
  module Events
    class Destroy < Base
      def initialize(record, in_after_callback = false)
        @record = record
        @in_after_callback = in_after_callback
      end

      def data
        {
          item: @record,
          event: "destroy",
          whodunnit: Audit::Request.whodunnit,
          object: @record.attributes
        }
        if record_object?
         data[:object] = recordable_object
        end
       
        data
      end

    
    end
  end
end
