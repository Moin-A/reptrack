class AddPreferenceColumnToSocialAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :campaign_social_accounts, :preferences, :text
  end
end
