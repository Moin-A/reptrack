class Group < ApplicationRecord
  has_many :permissions
  has_and_belongs_to_many :users
end
