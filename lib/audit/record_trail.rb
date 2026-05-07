module Audit
    class RecordTrail
        def initialize(record)
            @record = record
        end

         def save_version?
            if_condition = @record.audit_trail_options[:if]
            unless_condition = @record.audit_trail_options[:unless]
            (if_condition.blank? || if_condition.call(@record)) && !unless_condition.try(:call, @record)
         end

        def track_changes
            # Logic to track changes for the @record
        end

        def record_update
        end

        def record_destroy
        end 

        def record_create
        end
    end
end