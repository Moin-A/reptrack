class AddRoleTable < ActiveRecord::Migration[7.2]
  def up
    create_table :roles do |t|
      t.string :name
      t.string :description
      t.timestamps
    end

    create_table :role_users do |t|
      t.references :role, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end

  def down
    drop_table :role_users if table_exists?(:role_users)
    drop_table :roles if table_exists?(:roles)
  end
end
