class CreateContacts < ActiveRecord::Migration[7.2]
  def change
    create_table :contacts do |t|
      t.integer  :assigned_to
      t.integer  :reports_to
      t.string   :first_name,      limit: 64,  default: "", null: false
      t.string   :last_name,       limit: 64,  default: "", null: false
      t.string   :title,           limit: 64
      t.string   :department,      limit: 64
      t.string   :source,          limit: 32
      t.string   :access,          limit: 8,   default: "Public"
      t.string   :email,           limit: 254
      t.string   :alt_email,       limit: 254
      t.string   :phone,           limit: 32
      t.string   :mobile,          limit: 32
      t.string   :fax,             limit: 32
      t.string   :blog,            limit: 128
      t.string   :linkedin,        limit: 128
      t.string   :facebook,        limit: 128
      t.string   :twitter,         limit: 128
      t.date     :born_on
      t.boolean  :do_not_call,                 default: false, null: false
      t.string   :background_info
      t.datetime :deleted_at
      t.references :lead, foreign_key: true
      t.references :user, foreign_key: true
      t.references :assignee, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
