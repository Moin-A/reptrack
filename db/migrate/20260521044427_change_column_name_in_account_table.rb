class ChangeColumnNameInAccountTable < ActiveRecord::Migration[7.2]
  def change
    rename_column :accounts, :assigned_to, :assignee_id
  end
end
