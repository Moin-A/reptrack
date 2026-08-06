class Group < ApplicationRecord
  has_many :permissions
  # join_table pinned explicitly: User's table_name is "public.users" (Apartment
  # excluded_model), so the HABTM default would derive "groups_public.users".
  has_and_belongs_to_many :users, join_table: "groups_users"
end
