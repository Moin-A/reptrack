class AddStatusToCampaignPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :campaign_posts, :status, :string
    add_index :campaign_posts, :status
  end
end
