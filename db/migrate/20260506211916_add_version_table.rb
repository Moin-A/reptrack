class AddVersionTable < ActiveRecord::Migration[7.2]
  TEXT_BYTES = 1_073_741_823

  def change
    create_table :audit_versions do |t|
      t.string   :item_type,  null: false
      t.bigint   :item_id,    null: false
      t.string   :event,      null: false
      t.string   :whodunnit
      t.text     :object,     limit: TEXT_BYTES
      t.datetime :created_at
    end
    add_index :audit_versions, [ :item_type, :item_id ]
  end
end
