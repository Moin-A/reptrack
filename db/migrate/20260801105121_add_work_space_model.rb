class AddWorkSpaceModel < ActiveRecord::Migration[7.2]
  def change
    create_table "workspaces", force: :cascade do |t|
      t.string :name, null: false
    end
  end
end
