module Reptrack
  module Permission
    extend ActiveSupport::Concern

    included do
      has_many :permissions, as: :asset, class_name: "Permission", inverse_of: :asset, dependent: :destroy
    end

    module ClassMethods
      def with_permission
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
    end
  end
end
