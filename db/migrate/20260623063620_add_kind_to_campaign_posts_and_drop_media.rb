class AddKindToCampaignPostsAndDropMedia < ActiveRecord::Migration[7.2]
  def change
    add_column :campaign_posts, :kind, :string, null: false, default: "post"
    # media is now handled by Active Storage (has_many_attached :media)
    remove_column :campaign_posts, :media, :jsonb, null: false, default: []
  end
end
