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
        attribute_hash = {}
        attrs = record.attributes.keys.filter do |item| ![ :id ].include? item.to_sym end

        record.attributes.each do |key, value|
          attribute_hash[key] = record.attribute_before_last_save(key) if attrs.include?(key)
        end

        attribute_hash
      end
    end
  end
end
