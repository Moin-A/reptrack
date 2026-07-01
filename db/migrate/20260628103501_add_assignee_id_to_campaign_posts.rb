class AddAssigneeIdToCampaignPosts < ActiveRecord::Migration[7.2]
  def change
    # assignee is optional (a post may be unassigned); references a user.
    add_reference :campaign_posts, :assignee, type: :bigint, null: true,
                  foreign_key: { to_table: :users }
  end
end
