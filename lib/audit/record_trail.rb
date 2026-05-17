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

        def record_update(force:, in_after_callback:, is_touch:)
            return unless save_version?
            build_version_on_update(force:, in_after_callback:, is_touch:).tap do |version|
                version.save!
                @record.versions.reset
            rescue StandardError => e
                handle_version_errors e, version, :update
            end
        end

        def record_destroy
            return unless save_version?

            build_version_on_destroy(in_after_callback: @in_after_callback).tap do |version|
                version.save!
                @record.versions.reset
            rescue StandardError => e
                handle_version_errors e, version, :destroy
            end
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
            data = Events::Create.new(@record, in_after_callback).data
            Audit::Version.new(data)
        end

        def build_version_on_update(force:, in_after_callback:, is_touch:)
            data = Events::Update.new(@record, force:, in_after_callback:, is_touch:).data
            Audit::Version.new(data)
        end

        def build_version_on_destroy(in_after_callback:)
            data = Events::Destroy.new(@record, in_after_callback).data
            Audit::Version.new(data)
        end
    end
end
