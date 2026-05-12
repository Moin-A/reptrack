class CreateAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts do |t|
      t.string :name
      t.integer :assigned_to
      t.integer :rating
      t.string :email
      t.string :phone
      t.string :access

      t.timestamps
    end
  end
end
