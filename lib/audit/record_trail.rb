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

        def handle_version_errors(e, version, event)
            raise e
        end

        def record_create
            return unless save_version?

            build_version_on_create(in_after_callback: true).tap do |version|
                version.save!
                # Because the version object was created using version_class.new instead
                # of versions_assoc.build?, the association cache is unaware. So, we
                # invalidate the `versions` association cache with `reset`.
                @record.versions.reset
            rescue StandardError => e
                handle_version_errors e, version, :create
            end
        end

        def build_version_on_create(in_after_callback:)
            event = Events::Create.new(@record, in_after_callback)

            # Merge data from `Event` with data from PT-AT. We no longer use
            # `data_for_create` but PT-AT still does.
            data = event.data

            # Pure `version_class.new` reduces memory usage compared to `versions_assoc.build`
            Audit::Version.new(data)
        end
    end
end