module Audit
  module Events
    class Base

      attr_accessor :record, :in_after_callback

      def initialize(record, in_after_callback = true)
        @record = record
        @in_after_callback = in_after_callback
      end

      def record_object?
        @record.version_class_name.constantize.column_names.include?("object")
      end

      def recordable_object(ar)
      end

    end
  end
end
