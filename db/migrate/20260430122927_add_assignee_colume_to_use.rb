class AddAssigneeColumeToUse < ActiveRecord::Migration[7.2]
  def up
    add_column :tasks, :assignee_id, :integer
    add_column :tasks, :bucket, :integer, default: 0
    add_reference :tasks, :user, foreign_key: true, index: { name: "index_tasks_on_user_id" }
  end

  def down
    remove_foreign_key :tasks, :users, if_exists: true
    remove_index :tasks, name: "index_tasks_on_user_id", if_exists: true
    remove_column :tasks, :user_id, if_exists: true
    remove_column :tasks, :bucket, if_exists: true
    remove_column :tasks, :assignee_id, if_exists: true
  end
end
