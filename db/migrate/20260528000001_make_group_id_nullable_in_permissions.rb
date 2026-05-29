class MakeGroupIdNullableInPermissions < ActiveRecord::Migration[7.2]
  def change
    change_column_null :permissions, :group_id, true
  end
end
