module Audit
  class ModelConfig
    attr_accessor :model_class

   def initialize(klass)
     @model_class = klass
   end


   def setup(options)
     options[:on] = Array(options[:on])
     setup_options(options)
   end

   private

   def setup_options(options)
    @model_class.class_attribute :paper_trail_options
    @model_class.paper_trail_options = options.dup
     # Set up the options for the audit trail
   end
  end
end
