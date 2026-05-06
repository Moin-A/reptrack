module Audit
  class ModelConfig
    attr_accessor :model_class

   def initialize(klass)
     @model_class = klass
   end


   def setup(options)
     options[:on] = Array(options[:on])
     setup_options(options)
     setup_association(options)
   end

   private


   def setup_association(options)
        @model_class.class_attribute :has_many_association_name
        @model_class.has_many_association_name = options[:version] || :version
        @model_class.send :attr_accessor, @model_class.has_many_association_name

        define_has_many_versions(options)

   end

   def define_has_many_versions(options)
    ensure_version_option_is_a_hash(options)
    check_has_many_class_name(options)
    check_has_many_association_name(options)
   end

   def check_has_many_class_name(options)
    @model_class.class_attribute :versions_class_name
    @model_class.versions_class_name = options[:versions][:class_name] || "Audit::Version"
   end

   def check_has_many_association_name(options)
    @model_class.class_attribute :versions_association_name
    @model_class.versions_association_name = options[:versions][:name] || :versions

   end

   def setup_options(options)
    @model_class.class_attribute :paper_trail_options
    @model_class.paper_trail_options = options.dup


     # Set up the options for the audit trail
   end

   def ensure_version_option_is_a_hash(options)
     unless options[:versions].is_a?(Hash)
      if options[:versions]
        ActiveSupport::Deprecation.new.warn("version option should be a hash with a key name", caller(1))
      end
       options[:versions] = {
          name: options[:versions]
        }
     end
   end
  end
end
