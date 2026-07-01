FactoryBot.define do
  factory :social_account, class: "Campaign::SocialAccount" do
    association :user
    platform_tag { "mastodon" }
    sequence(:label) { |n| "Social Account #{n}" }
    credentials { {} }
    active { true }
  end
end
