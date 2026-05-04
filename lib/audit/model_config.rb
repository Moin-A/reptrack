module Audit
  class ModelConfig
    attr_accessor :model_class

   def initialize(klass)
     @model_class = klass
   end

  end
end


