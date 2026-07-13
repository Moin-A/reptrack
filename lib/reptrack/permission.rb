module Reptrack
  module Permission
    extend ActiveSupport::Concern


    module ClassMethods
      def with_permission
        has_many :permissions, as: :asset, class_name: "Permission", inverse_of: :asset, dependent: :destroy
        include InstanceMethods
      end
    end

    module InstanceMethods
      [ "user", "group" ].each do |model|
            class_eval(%{
            def #{model}_ids=(ids)
            if access!='Shared'
             permissions_to_remove = ::Permission.where(asset: self).where(#{model}_id: #{model}_ids)
            else
             permissions_to_remove = ::Permission.where(asset: self).where(#{model}_id: #{model}_ids - ids)
            end

            permissions_to_remove.each do |permission|
             permission.destroy
            end

            ids.each do |id|
                ::Permission.find_or_create_by(asset: self, #{model}_id: id)
            end if access=='Shared'

            end

            def #{model}_ids
                ::Permission.where(asset: self).map(&:#{model}_id)
            end

            })
    end

    # Remove all shared permissions if no longer shared
    #--------------------------------------------------------------------------
    def access=(value)
      remove_permissions unless value == "Shared"
      super(value)
    end

    # Removes all permissions on an object
    #--------------------------------------------------------------------------
    def remove_permissions
      # we don't use dependent => :destroy so must manually remove
      permissions_to_remove = if id && self.class
                                ::Permission.where(asset_id: id, asset_type: self.class.name).to_a
      else
                                []
      end

      permissions_to_remove.each do |p|
        permissions.delete(p)
        p.destroy
      end
    end

      def save_with_model_permissions(model)
        self.access    = model.access
        self.user_ids  = model.user_ids
        self.group_ids = model.group_ids
        save
      end
    end
  end
end

ActiveRecord::Base.include Reptrack::Permission
