class AddAccountRefToContacts < ActiveRecord::Migration[7.2]
  def change
    # Nullable: a contact can exist without an account (created outside conversion).
    add_reference :contacts, :account, type: :bigint, null: true, foreign_key: true
  end
end
