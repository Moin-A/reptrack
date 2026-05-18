class AddAddressTable < ActiveRecord::Migration[7.2]
  def change
    create_table :addresses do |t|
      t.string :street1
      t.string :street2
      t.string :city
      t.string :state
      t.string :zipcode
      t.string :country
      t.string :address_type
      t.string :website, null: true
      t.integer :addressable_id
      t.string :addressable_type
      t.references :account, foreign_key: true
      t.timestamps
    end
    add_index :addresses, [ :addressable_id, :addressable_type ], name: "index_addresses_on_addressable_id_and_addressable_type"
  end
end
