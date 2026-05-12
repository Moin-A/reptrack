class AddColumnToAccount < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :category, :integer
  end
end
