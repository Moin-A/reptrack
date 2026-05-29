class Permission < ApplicationRecord
  belongs_to :group, optional: true
  belongs_to :user, optional: true
  belongs_to :asset, polymorphic: true
  validates_uniqueness_of :user_id, scope: %w[asset_id group_id asset_type]

  scope :assigned_to_user, ->(user) { where(user_id: user.id) }
  scope :assigned_to_group, ->(group) { where(group_id: group.id) }
  scope :for_asset, ->(asset) { where(asset_id: asset.id, asset_type: asset.class.name) }
  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :for_group, ->(group) { where(group_id: group.id) }
end
