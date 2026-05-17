module VersionConcern
    extend ActiveSupport::Concern

    included do
        belongs_to :item, polymorphic: true, optional: true
    end

    class_methods do

    end

    def reify(options = {})
      unless self.class.column_names.include?("object")
        raise Error, "reify requires an object column"
      end
      return nil if object.nil?
      ::Audit::Reifier.reify(self, options)
    end
end
