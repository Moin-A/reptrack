class RenameAssignedToToAssigneeIdInLeads < ActiveRecord::Migration[7.2]
  def change
    rename_column :leads, :assigned_to, :assignee_id
  end
end
