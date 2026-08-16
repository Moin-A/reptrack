class AddColumnsToWorkspaces < ActiveRecord::Migration[7.2]
  def change
    add_column :workspaces, :subdomain,   :string,  if_not_exists: true
    add_column :workspaces, :schema_name, :string,  if_not_exists: true
    add_column :workspaces, :status,      :integer, null: false, default: 0, if_not_exists: true

    add_index :workspaces, :schema_name, unique: true, if_not_exists: true
  end
end
