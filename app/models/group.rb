class Group < ApplicationRecord
  has_many :permissions
  has_many :users, through: :groups_users
end