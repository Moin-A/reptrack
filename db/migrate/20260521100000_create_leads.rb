class CreateLeads < ActiveRecord::Migration[7.1]
  def change
    create_table :leads do |t|
      t.integer  :user_id
      t.integer  :assigned_to
      t.string   :first_name,      limit: 64,  default: "", null: false
      t.string   :last_name,       limit: 64,  default: "", null: false
      t.string   :access,          limit: 8,   default: "Public"
      t.string   :title,           limit: 64
      t.string   :company,         limit: 64
      t.string   :source,          limit: 32
      t.string   :status,          limit: 32
      t.string   :referred_by,     limit: 64
      t.string   :email,           limit: 254
      t.string   :alt_email,       limit: 254
      t.string   :phone,           limit: 32
      t.string   :mobile,          limit: 32
      t.string   :blog,            limit: 128
      t.string   :linkedin,        limit: 128
      t.string   :facebook,        limit: 128
      t.string   :twitter,         limit: 128
      t.integer  :rating,                      default: 0,     null: false
      t.boolean  :do_not_call,                 default: false, null: false
      t.string   :background_info
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
