class CreateSocialAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :campaign_social_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :platform_tag, null: false
      t.string :label, null: false
      t.jsonb :credentials, null: false, default: {}
      t.datetime :credentials_renewed_at
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
