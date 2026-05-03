class AddColumnsToUsers < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :name, :string, if_not_exists: true
  end

  def down
    remove_column :users, :name
  end
end
