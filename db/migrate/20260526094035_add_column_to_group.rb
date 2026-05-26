class AddColumnToGroup < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :access, :string, default: "Public"
  end
end
