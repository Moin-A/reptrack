class AddAssigneeColumeToUse < ActiveRecord::Migration[7.2]
  def change
    add_column :tasks, :assignee_id, :integer
    add_column :tasks, :bucket, :integer, default: 0
  end
end


