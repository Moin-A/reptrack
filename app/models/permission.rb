class Permission < ApplicationRecord
  belongs_to :group
  belongs_to :user
  belongs_to :asset, polymorphic: true
end