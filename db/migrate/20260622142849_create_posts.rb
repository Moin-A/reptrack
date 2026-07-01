class CreatePosts < ActiveRecord::Migration[7.2]
  def change
    create_table :campaign_posts do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.string :url
      t.jsonb :media, null: false, default: []
      t.jsonb :platform_overrides, null: false, default: {}

      t.timestamps
    end
  end
end
