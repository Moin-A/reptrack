class CreatePublications < ActiveRecord::Migration[7.2]
  def change
    create_table :campaign_publications do |t|
      t.references :post, null: false, foreign_key: { to_table: :campaign_posts }
      t.references :social_account, null: false, foreign_key: { to_table: :campaign_social_accounts }
      t.string :status, null: false, default: "ready"
      t.string :remote_id
      t.string :url
      t.integer :attempts, null: false, default: 0
      t.jsonb :failures, null: false, default: []
      t.datetime :published_at
      t.datetime :last_attempted_at

      t.timestamps
    end

    add_index :campaign_publications, [ :post_id, :social_account_id ], unique: true
  end
end
