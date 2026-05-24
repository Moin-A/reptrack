class CreatePermissionTable < ActiveRecord::Migration[7.2]
  def up
    create_table :groups do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table :permissions do |t|
      t.references :user, foreign_key: true, null: false
      t.references :group, foreign_key: true, null: false
      t.string :action, null: false, default: "all"
      t.timestamps
      t.references :asset, polymorphic: true, null: false
    end
  end

  def down
    drop_table :permissions, if_exists: true
    drop_table :groups, force: :cascade
  end
end
