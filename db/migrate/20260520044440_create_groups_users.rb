class CreateGroupsUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :groups_users, id: false do |t|
      t.references :group, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false
    end
    add_index :groups_users, [ :group_id, :user_id ], unique: true, name: "index_groups_users_on_group_id_and_user_id"
  end
end
