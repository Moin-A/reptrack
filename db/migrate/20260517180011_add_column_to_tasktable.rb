class AddColumnToTasktable < ActiveRecord::Migration[7.2]
  def change
    add_column :tasks, :asset_id, :integer
    add_column :tasks, :asset_type, :string
    add_index :tasks, [ :asset_id, :asset_type ], name: "index_tasks_on_asset_id_and_asset_type"
  end
end
