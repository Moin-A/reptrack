class Permission < ApplicationRecord
  belongs_to :group
  belongs_to :user
  belongs_to :asset, polymorphic: true
  validates_uniqueness_of :user_id, scope: %w[asset_id group_id asset_type]

  scope :assigned_to_user, ->(user) { where(user_id: user.id) }
  scope :assigned_to_group, ->(group) { where(group_id: group.id) }
  
end