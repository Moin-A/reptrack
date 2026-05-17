module Audit
  module Reifier
    class << self
      def reify(version, options = {})
        attrs = JSON.parse(version.object)
        model = init_model(version, attrs)
        model
      end

      private

      def init_model(version, attrs)
       
        if version.item.present?
         version.item 
        else
          model = version.item_type.constantize
          model.new(attrs)
        end
      end
    end
  end
end
