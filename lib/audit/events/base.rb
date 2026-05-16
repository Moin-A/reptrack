module Audit
  module Events
    class Base
      attr_accessor :record, :in_after_callback

      def initialize(record, force:, in_after_callback:, is_touch:)
        @record = record
        @force = force
        @in_after_callback = in_after_callback
        @is_touch = is_touch
      end

      def record_object?
        @record.version_class_name.constantize.column_names.include?("object")
      end

      def recordable_object
        attrs = record.attributes.except(*record.audit_trail_options[:skip])
        attrs.each_key do |key|
          attrs[key] = record.attribute_before_last_save(key)
        end
        attrs
      end
    end
  end
end
