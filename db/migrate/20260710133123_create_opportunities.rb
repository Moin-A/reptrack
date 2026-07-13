class CreateOpportunities < ActiveRecord::Migration[7.2]
  def change
    create_table :opportunities do |t|
      t.string  :name, null: false
      t.string  :stage
      t.string  :access, default: "Private"
      t.date    :closes_on
      t.integer :probability
      t.decimal :amount,   precision: 12, scale: 2
      t.decimal :discount, precision: 12, scale: 2
      t.string  :background_info

      # An opportunity belongs to the account the deal sits under, and remembers
      # the lead it was converted out of. Both are optional: opportunities can
      # also be created directly, outside the lead-conversion flow.
      t.references :account,  type: :bigint, null: true, foreign_key: true
      t.references :lead,     type: :bigint, null: true, foreign_key: true
      t.references :user,     type: :bigint, null: true, foreign_key: true
      t.references :assignee, type: :bigint, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
