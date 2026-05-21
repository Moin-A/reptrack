class AddColumnszToAccountTable < ActiveRecord::Migration[7.2]
  def up
    add_column :accounts, :user_id, :bigint unless column_exists?(:accounts, :user_id)
    add_index :accounts, :user_id unless index_exists?(:accounts, :user_id)
  end

  def down
    remove_index :accounts, :user_id if index_exists?(:accounts, :user_id)
    remove_column :accounts, :user_id if column_exists?(:accounts, :user_id)
  end
end
