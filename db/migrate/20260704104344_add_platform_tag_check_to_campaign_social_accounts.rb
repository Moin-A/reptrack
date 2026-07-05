class AddPlatformTagCheckToCampaignSocialAccounts < ActiveRecord::Migration[7.2]
  def change
    add_check_constraint :campaign_social_accounts, "platform_tag IN ('facebook','mastodon','x','instagram','test','test_failure','test_skipped')", name: 'platform_tag_check'
  end
end
